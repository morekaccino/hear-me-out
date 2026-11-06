import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'pcm_stream.dart';
import 'yin.dart';

/// A single pitch analysis result.
///
/// [timestamp] is for display and debugging only. Use [sampleIndex] or
/// [sampleTime] for alignment, onset detection, and scoring.
class PitchFrame {
  const PitchFrame({
    required this.frequency,
    required this.clarity,
    required this.rms,
    required this.timestamp,
    this.sampleIndex = 0,
    this.sampleTime = Duration.zero,
  });

  final double frequency;
  final double clarity;
  final double rms;
  final DateTime timestamp;
  final int sampleIndex;
  final Duration sampleTime;

  bool get voiced => frequency > 0 && clarity >= 0.5;
}

abstract class PitchSource {
  Stream<PitchFrame> get frames;

  Future<bool> ensurePermission();

  Future<bool> start();

  Future<void> stop();

  Future<void> dispose();
}

/// Sample rate and channel count the platform actually delivered.
class PcmCaptureConfig {
  const PcmCaptureConfig({required this.sampleRate, required this.channels});

  final int sampleRate;
  final int channels;

  @override
  bool operator ==(Object other) {
    return other is PcmCaptureConfig &&
        other.sampleRate == sampleRate &&
        other.channels == channels;
  }

  @override
  int get hashCode => Object.hash(sampleRate, channels);
}

/// Narrow seam over the platform recorder so the sample clock can be tested
/// without starting a microphone.
abstract class PcmCapture {
  Future<bool> hasPermission();

  Future<void> setOnConfigChanged(
    void Function(PcmCaptureConfig config)? callback,
  );

  Future<Stream<Uint8List>> startStream({
    required int sampleRate,
    required int channels,
  });

  Future<void> stop();

  Future<void> dispose();
}

/// Creates the platform PCM capture used by the pitch source and the phrase
/// recorder.
///
/// Keeping one factory means both recording paths use the same request shape
/// (48 kHz PCM16 mono with a 44.1 kHz fallback) and the same effective-format
/// callback.
PcmCapture createPlatformPcmCapture() => _RecordPcmCapture(AudioRecorder());

class RecordPitchSource implements PitchSource {
  RecordPitchSource({PcmCapture Function()? captureFactory})
    : _captureFactory = captureFactory ?? _createRecordCapture;

  /// Android, iOS, macOS, and most browsers accept 48 kHz.
  static const int preferredCaptureSampleRate = 48000;

  /// Some older devices and browsers only expose 44.1 kHz.
  static const int fallbackCaptureSampleRate = 44100;

  /// YIN is tuned for roughly 22 kHz after resampling.
  static const int analysisSampleRate = 22050;

  static const int frameSize = 2048;
  static const int hopSize = 1024;
  static const int requestedChannels = 1;

  final PcmCapture Function() _captureFactory;
  final _controller = StreamController<PitchFrame>.broadcast();
  final _buffer = <double>[];

  PcmCapture? _capture;
  StreamSubscription<Uint8List>? _subscription;
  Pcm16StreamDecoder? _decoder;
  YinPitchDetector? _detector;
  PcmCaptureConfig? _effectiveConfig;
  bool _running = false;
  int _captureGeneration = 0;

  /// Absolute analysis-sample index at `_buffer[0]`.
  int _frameStart = 0;

  /// Total analysis samples received from the decoder.
  int _decodedSamples = 0;

  bool _frameEmitted = false;

  DateTime? _streamEpoch;

  static PcmCapture _createRecordCapture() => createPlatformPcmCapture();

  @override
  Stream<PitchFrame> get frames => _controller.stream;

  @override
  Future<bool> ensurePermission() async {
    _capture ??= _captureFactory();
    return _capture!.hasPermission();
  }

  @override
  Future<bool> start() async {
    if (_running) return true;
    final capture = _capture ??= _captureFactory();
    if (!await capture.hasPermission()) return false;

    _resetStreamState();
    _effectiveConfig = const PcmCaptureConfig(
      sampleRate: preferredCaptureSampleRate,
      channels: requestedChannels,
    );

    Stream<Uint8List> stream;
    try {
      stream = await _startCapture(capture, preferredCaptureSampleRate);
    } catch (_) {
      await _stopCapture(capture);
      _effectiveConfig = const PcmCaptureConfig(
        sampleRate: fallbackCaptureSampleRate,
        channels: requestedChannels,
      );
      stream = await _startCapture(capture, fallbackCaptureSampleRate);
    }

    final config = _effectiveConfig!;
    _decoder = Pcm16StreamDecoder(
      inputSampleRate: config.sampleRate,
      channels: config.channels,
      outputSampleRate: analysisSampleRate,
    );
    _detector = YinPitchDetector(sampleRate: analysisSampleRate.toDouble());
    _streamEpoch = DateTime.now();
    _running = true;
    _subscription = stream.listen(
      _onBytes,
      onError: (_) => _running = false,
      cancelOnError: false,
    );
    return true;
  }

  Future<Stream<Uint8List>> _startCapture(
    PcmCapture capture,
    int sampleRate,
  ) async {
    final generation = ++_captureGeneration;
    await capture.setOnConfigChanged((config) {
      if (generation == _captureGeneration) {
        _onConfigChanged(config);
      }
    });
    return capture.startStream(
      sampleRate: sampleRate,
      channels: requestedChannels,
    );
  }

  void _onConfigChanged(PcmCaptureConfig config) {
    _effectiveConfig = config;
    final decoder = _decoder;
    if (decoder == null) return;
    if (config.sampleRate == decoder.inputSampleRate &&
        config.channels == decoder.channels) {
      return;
    }

    // The platform corrected the format after the stream started. Drop the
    // samples decoded at the old format and restart at the next frame
    // boundary so the sample clock stays monotonic. Before the first frame is
    // published, the clock can safely restart at zero.
    _buffer.clear();
    if (_frameEmitted) {
      _frameStart = _decodedSamples;
    } else {
      _decodedSamples = 0;
      _frameStart = 0;
    }
    _decoder = Pcm16StreamDecoder(
      inputSampleRate: config.sampleRate,
      channels: config.channels,
      outputSampleRate: analysisSampleRate,
    );
  }

  void _onBytes(Uint8List bytes) {
    if (!_running || bytes.isEmpty) return;
    final decoder = _decoder;
    if (decoder == null) return;
    _onDecodedSamples(decoder.add(bytes));
  }

  void _onDecodedSamples(List<double> samples) {
    if (samples.isEmpty) return;
    if (_buffer.isEmpty) {
      _frameStart = _decodedSamples;
    }
    _buffer.addAll(samples);
    _decodedSamples += samples.length;

    while (_buffer.length >= frameSize) {
      final frame = _buffer.sublist(0, frameSize);
      final estimate = _detector!.detect(frame);
      final sampleTime = _durationForSample(_frameStart);
      _controller.add(
        PitchFrame(
          frequency: estimate.frequency,
          clarity: estimate.clarity,
          rms: estimate.rms,
          timestamp: _streamEpoch!.add(sampleTime),
          sampleIndex: _frameStart,
          sampleTime: sampleTime,
        ),
      );
      _buffer.removeRange(0, hopSize);
      _frameStart += hopSize;
      _frameEmitted = true;
    }
  }

  static Duration _durationForSample(int sampleIndex) {
    return Duration(
      microseconds:
          (sampleIndex * Duration.microsecondsPerSecond / analysisSampleRate)
              .round(),
    );
  }

  @override
  Future<void> stop() async {
    _running = false;
    _captureGeneration++;
    await _subscription?.cancel();
    _subscription = null;
    _resetStreamState();

    final capture = _capture;
    if (capture == null) return;
    try {
      await capture.setOnConfigChanged(null);
    } catch (_) {
      // The platform may already have released the callback.
    }
    await _stopCapture(capture);
  }

  Future<void> _stopCapture(PcmCapture capture) async {
    try {
      await capture.stop();
    } catch (_) {
      // The recorder may already be stopped or unavailable.
    }
  }

  void _resetStreamState() {
    _buffer.clear();
    _decoder = null;
    _detector = null;
    _effectiveConfig = null;
    _frameStart = 0;
    _decodedSamples = 0;
    _frameEmitted = false;
    _streamEpoch = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
    final capture = _capture;
    _capture = null;
    try {
      await capture?.dispose();
    } catch (_) {
      // Nothing else to release.
    }
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}

class _RecordPcmCapture implements PcmCapture {
  _RecordPcmCapture(this._recorder);

  final AudioRecorder _recorder;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> setOnConfigChanged(
    void Function(PcmCaptureConfig config)? callback,
  ) {
    return _recorder.setOnConfigChanged(
      callback == null
          ? null
          : (RecordConfig config) => callback(
              PcmCaptureConfig(
                sampleRate: config.sampleRate,
                channels: config.numChannels,
              ),
            ),
    );
  }

  @override
  Future<Stream<Uint8List>> startStream({
    required int sampleRate,
    required int channels,
  }) {
    return _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: channels,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );
  }

  @override
  Future<void> stop() => _recorder.stop();

  @override
  Future<void> dispose() => _recorder.dispose();
}
