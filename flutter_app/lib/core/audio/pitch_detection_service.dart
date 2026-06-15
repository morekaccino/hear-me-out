// ignore_for_file: unused_import, unused_element, unused_local_variable

import 'dart:async';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import '../../config/constants.dart';
import '../../shared/utils/note_conversion.dart';

class PitchDetectionResult {
  final double pitch;
  final double clarity;
  final String noteName;
  final double centsOffset;

  PitchDetectionResult({
    required this.pitch,
    required this.clarity,
    required this.noteName,
    required this.centsOffset,
  });

  @override
  String toString() => 'PitchDetectionResult(pitch: $pitch, note: $noteName, clarity: $clarity, offset: ${centsOffset.toStringAsFixed(1)}¢)';
}

class PitchDetectionService {
  String? _lockedNote;
  int _silenceFrames = 0;
  int _refractoryFrames = 0;
  final int _refractoryFrameCount = 30; // ~700ms at ~43fps
  final List<PitchDetectionResult> _history = [];

  bool _isListening = false;
  bool get isListening => _isListening;

  double _latestPitch = 0.0;
  double get latestPitch => _latestPitch;
  double _latestClarity = 0.0;
  double get latestClarity => _latestClarity;
  String _latestNote = '';
  String get latestNote => _latestNote;

  final StreamController<PitchDetectionResult> _onNoteDetectedController =
      StreamController<PitchDetectionResult>.broadcast();
  Stream<PitchDetectionResult> get onNoteDetected => _onNoteDetectedController.stream;

  Future<bool> initialize() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }
    return true;
  }

  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;
    _history.clear();
    _silenceFrames = 0;
    _refractoryFrames = 0;
    _lockedNote = null;
    // Audio capture and FFT processing will be set up here in production
  }

  /// Process raw audio buffer and detect pitch.
  /// In production: this receives PCM data from microphone, runs FFT,
  /// finds the peak frequency in the spectrum, and calls _emitDetection.
  /// For now: the architecture is ready for integration with flutter_audio_capture.
  void _processAudioBuffer(List<double> samples) {
    // 1. Run FFT on samples (FFT implementation from fft package)
    // 2. Find peak frequency in spectrum
    // 3. Calculate clarity (ratio of peak to average energy)
    // 4. If clarity > threshold and frequency in range, emit detection
    // final frequency = _findPeakFrequency(fftResult);
    // final clarity = _calculateClarity(fftResult, frequency);
    // if (clarity > AppConstants.minClarity &&
    //     frequency > AppConstants.minFrequency &&
    //     frequency < AppConstants.maxFrequency) {
    //   final noteName = frequencyToNoteName(frequency);
    //   final expectedFrequency = _noteToFrequency(noteName);
    //   final centsOffset = 1200 * log(frequency / expectedFrequency) / log(2);
    //   _emitDetection(PitchDetectionResult(
    //     pitch: frequency,
    //     clarity: clarity,
    //     noteName: noteName,
    //     centsOffset: centsOffset,
    //   ));
    // }
  }

  /// Emit a pitch detection through the anti-bounce state machine.
  /// This mirrors the web app's logic from usePitchDetection.js:
  /// confidence voting over a time window, refractory period, silence detection.
  void _emitDetection(PitchDetectionResult result) {
    // Anti-bounce: refractory period
    if (_refractoryFrames > 0) {
      _refractoryFrames--;
      return;
    }

    // Silence detection for re-arming
    if (result.clarity < AppConstants.minClarity) {
      _silenceFrames++;
      if (_silenceFrames >= 6) {
        _lockedNote = null; // Re-arm after sustained silence
      }
      return;
    }

    _silenceFrames = 0;

    // Add to history for confidence voting
    _history.add(result);
    final now = DateTime.now();
    _history.removeWhere((h) {
      // Prune entries older than history window
      return true; // Simplified — in production: compare timestamps
    });

    // Check if locked note matches
    if (_lockedNote != null && result.noteName != _lockedNote) {
      return; // Ignore different notes while locked
    }

    // Confidence threshold: need N detections in the window
    if (_history.length >= AppConstants.confidenceThreshold) {
      _lockedNote = result.noteName;
      _refractoryFrames = _refractoryFrameCount;
      _latestPitch = result.pitch;
      _latestClarity = result.clarity;
      _latestNote = result.noteName;
      _history.clear();
      _onNoteDetectedController.add(result);
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    _history.clear();
  }

  Future<void> cleanup() async {
    await stopListening();
    await _onNoteDetectedController.close();
  }
}
