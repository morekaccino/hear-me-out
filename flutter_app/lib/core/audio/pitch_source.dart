import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'yin.dart';

class PitchFrame {
  const PitchFrame({
    required this.frequency,
    required this.clarity,
    required this.rms,
    required this.timestamp,
  });

  final double frequency;
  final double clarity;
  final double rms;
  final DateTime timestamp;

  bool get voiced => frequency > 0 && clarity >= 0.5;
}

abstract class PitchSource {
  Stream<PitchFrame> get frames;

  Future<bool> ensurePermission();

  Future<bool> start();

  Future<void> stop();

  Future<void> dispose();
}

class RecordPitchSource implements PitchSource {
  static const int captureSampleRate = 44100;
  static const int decimation = 2;
  static const int analysisSampleRate = captureSampleRate ~/ decimation;
  static const int frameSize = 4096;
  static const int hopSize = 2048;

  final _controller = StreamController<PitchFrame>.broadcast();
  final _buffer = <double>[];

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _subscription;
  YinPitchDetector? _detector;
  bool _running = false;

  @override
  Stream<PitchFrame> get frames => _controller.stream;

  @override
  Future<bool> ensurePermission() async {
    _recorder ??= AudioRecorder();
    return _recorder!.hasPermission();
  }

  @override
  Future<bool> start() async {
    if (_running) return true;
    _recorder ??= AudioRecorder();
    if (!await _recorder!.hasPermission()) return false;

    _buffer.clear();
    _detector = YinPitchDetector(sampleRate: analysisSampleRate.toDouble());
    final stream = await _recorder!.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: captureSampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );
    _running = true;
    _subscription = stream.listen(
      _onBytes,
      onError: (_) => _running = false,
      cancelOnError: false,
    );
    return true;
  }

  void _onBytes(Uint8List bytes) {
    if (!_running) return;
    for (var index = 0; index + 1 < bytes.length; index += 2) {
      final raw = bytes[index] | (bytes[index + 1] << 8);
      final signed = raw >= 0x8000 ? raw - 0x10000 : raw;
      _buffer.add(signed / 32768.0);
    }

    while (_buffer.length >= frameSize) {
      final frame = _buffer.sublist(0, frameSize);
      final downsampled = <double>[];
      for (var index = 0; index + 1 < frame.length; index += 2) {
        downsampled.add((frame[index] + frame[index + 1]) * 0.5);
      }
      final estimate = _detector!.detect(downsampled);
      _controller.add(
        PitchFrame(
          frequency: estimate.frequency,
          clarity: estimate.clarity,
          rms: estimate.rms,
          timestamp: DateTime.now(),
        ),
      );
      _buffer.removeRange(0, hopSize);
      if (_buffer.length > frameSize * 4) {
        _buffer.removeRange(0, _buffer.length - frameSize);
      }
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    await _subscription?.cancel();
    _subscription = null;
    _buffer.clear();
    try {
      await _recorder?.stop();
    } catch (_) {
      // The recorder may already be stopped or unavailable.
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    try {
      await _recorder?.dispose();
    } catch (_) {
      // Nothing else to release.
    }
    _recorder = null;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
