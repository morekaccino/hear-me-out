import 'dart:async';
import 'dart:typed_data';

import 'pcm_stream.dart';
import 'pitch_source.dart';

/// One mono take at the analysis sample rate.
///
/// [samples] are normalized to -1..1. [sourceSampleRate] and [sourceChannels]
/// record what the platform actually delivered, so a diagnostic can explain a
/// resample without guessing.
class PhraseTake {
  const PhraseTake({
    required this.samples,
    required this.sampleRate,
    required this.sourceSampleRate,
    required this.sourceChannels,
  });

  final List<double> samples;
  final int sampleRate;
  final int sourceSampleRate;
  final int sourceChannels;

  double get durationSeconds =>
      sampleRate <= 0 ? 0 : samples.length / sampleRate;
}

/// Records a phrase take through the existing [PcmCapture] seam.
///
/// The recorder asks for 48 kHz mono PCM16 and follows the effective format
/// reported by the platform. It resamples to 22.05 kHz using
/// [Pcm16StreamDecoder], flushes the decoder on stop, and disposes the capture
/// exactly once. It never reads a wall clock: the scorer aligns samples to the
/// fixed grid, not to timestamps.
class PhraseRecorder {
  PhraseRecorder({
    required this.capture,
    this.requestedSampleRate = 48000,
    this.requestedChannels = 1,
    this.outputSampleRate = analysisSampleRate,
  }) : assert(requestedSampleRate > 0),
       assert(requestedChannels > 0),
       assert(outputSampleRate > 0);

  static const int analysisSampleRate = 22050;

  /// Android, iOS, macOS, and most browsers accept 48 kHz.
  static const int preferredSampleRate = 48000;

  /// Some older devices and browsers only expose 44.1 kHz.
  static const int fallbackSampleRate = 44100;

  final PcmCapture capture;
  final int requestedSampleRate;
  final int requestedChannels;
  final int outputSampleRate;

  final List<double> _samples = <double>[];
  StreamSubscription<Uint8List>? _subscription;
  Pcm16StreamDecoder? _decoder;
  PcmCaptureConfig? _config;
  bool _running = false;
  bool _captureStarted = false;
  bool _disposed = false;
  int _generation = 0;

  bool get isRecording => _running;

  int get sampleCount => _samples.length;

  /// Starts a take. A second call while running is a no-op.
  Future<bool> start() async {
    if (_disposed) {
      throw StateError('PhraseRecorder has been disposed');
    }
    if (_running) return true;

    final generation = ++_generation;
    final permission = await capture.hasPermission();
    if (generation != _generation || _disposed) return false;
    if (!permission) return false;

    _samples.clear();
    _config = PcmCaptureConfig(
      sampleRate: requestedSampleRate,
      channels: requestedChannels,
    );

    await capture.setOnConfigChanged((config) {
      if (generation == _generation) _onConfigChanged(config);
    });
    if (generation != _generation || _disposed) return false;

    final stream = await _startStream(generation, requestedSampleRate);
    if (generation != _generation || _disposed) {
      _captureStarted = true;
      await _stopCapture();
      return false;
    }

    _captureStarted = true;
    final config = _config!;
    _decoder = Pcm16StreamDecoder(
      inputSampleRate: config.sampleRate,
      channels: config.channels,
      outputSampleRate: outputSampleRate,
    );
    _subscription = stream.listen(
      (bytes) {
        if (generation == _generation) _onBytes(bytes);
      },
      onError: (_) {
        if (generation == _generation) _running = false;
      },
      cancelOnError: false,
    );
    _running = true;
    return true;
  }

  /// Stops the take, flushes decoded samples, and returns a mono take.
  ///
  /// The returned samples are a copy; the recorder is ready for another take.
  Future<PhraseTake> stop() async {
    _generation++;
    _running = false;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      // Cancellation can complete after the platform closes its stream. Late
      // bytes are ignored by the generation guard, so stop must not block the
      // UI on a platform cancel.
      unawaited(subscription.cancel());
    }

    final decoder = _decoder;
    _decoder = null;
    if (decoder != null) {
      final tail = decoder.flush();
      if (tail.isNotEmpty) _samples.addAll(tail);
    }

    final take = PhraseTake(
      samples: List<double>.unmodifiable(_samples),
      sampleRate: outputSampleRate,
      sourceSampleRate: _config?.sampleRate ?? requestedSampleRate,
      sourceChannels: _config?.channels ?? requestedChannels,
    );
    _samples.clear();
    _config = null;

    await _stopCapture();
    return take;
  }

  /// Stops any take and releases the platform capture. Safe to call twice.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await stop();
    } catch (_) {
      // A platform stop failure must not skip the capture dispose.
    }
    try {
      await capture.dispose();
    } catch (_) {
      // The platform may already have released the recorder.
    }
  }

  /// Starts the platform stream at the preferred rate, retrying once at the
  /// 44.1 kHz fallback when the first attempt fails.
  ///
  /// The failed capture is stopped before the retry so a platform that opened a
  /// recorder before throwing cannot leave a second recorder alive.
  Future<Stream<Uint8List>> _startStream(int generation, int sampleRate) async {
    try {
      return await capture.startStream(
        sampleRate: sampleRate,
        channels: requestedChannels,
      );
    } catch (_) {
      if (sampleRate == fallbackSampleRate) rethrow;

      _captureStarted = true;
      await _stopCapture();
      if (generation != _generation || _disposed) {
        throw StateError('Phrase recording start was superseded');
      }

      _config = PcmCaptureConfig(
        sampleRate: fallbackSampleRate,
        channels: requestedChannels,
      );
      await capture.setOnConfigChanged((config) {
        if (generation == _generation) _onConfigChanged(config);
      });

      try {
        return await capture.startStream(
          sampleRate: fallbackSampleRate,
          channels: requestedChannels,
        );
      } catch (_) {
        _captureStarted = true;
        await _stopCapture();
        rethrow;
      }
    }
  }

  void _onConfigChanged(PcmCaptureConfig config) {
    // A mid-take format correction would change the meaning of samples that
    // are already buffered. Accept a correction only before the first sample;
    // every normal platform reports its format at stream start.
    if (_samples.isNotEmpty) return;
    _config = config;
    final decoder = _decoder;
    if (decoder == null) return;
    if (decoder.inputSampleRate == config.sampleRate &&
        decoder.channels == config.channels) {
      return;
    }
    _decoder = Pcm16StreamDecoder(
      inputSampleRate: config.sampleRate,
      channels: config.channels,
      outputSampleRate: outputSampleRate,
    );
  }

  void _onBytes(Uint8List bytes) {
    if (!_running || bytes.isEmpty) return;
    final decoder = _decoder;
    if (decoder == null) return;
    final decoded = decoder.add(bytes);
    if (decoded.isNotEmpty) _samples.addAll(decoded);
  }

  Future<void> _stopCapture() async {
    if (!_captureStarted) return;
    _captureStarted = false;
    try {
      await capture.setOnConfigChanged(null);
    } catch (_) {
      // The platform may already have released the callback.
    }
    try {
      await capture.stop();
    } catch (_) {
      // The recorder may already be stopped or unavailable.
    }
  }
}
