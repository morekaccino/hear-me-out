import 'dart:math' as math;

import 'fft.dart';
import 'onset_detector.dart';
import 'yin.dart';

/// A pitched note isolated from a take.
class DetectedNote {
  const DetectedNote({
    required this.startSeconds,
    required this.durationSeconds,
    required this.midi,
    required this.cents,
    required this.confidence,
    required this.sampleIndex,
  });

  /// Attack time reported by the onset detector.
  final double startSeconds;

  /// Approximate sounding duration. Used for diagnostics, not scoring.
  final double durationSeconds;

  /// Nearest sounding MIDI note. 0 means "no reliable pitch".
  final int midi;

  /// Deviation from [midi] in cents, in the range -50..50.
  final double cents;

  /// 0..1. Values below 0.6 are indeterminate for scoring.
  final double confidence;

  final int sampleIndex;

  bool get isConfident => confidence >= 0.6;

  @override
  String toString() =>
      'DetectedNote(midi $midi, ${cents.toStringAsFixed(1)}c, '
      '${(confidence * 100).toStringAsFixed(0)}%, '
      '${startSeconds.toStringAsFixed(3)}s)';
}

/// Turns onsets into pitched note events.
///
/// The segmenter deliberately reuses [YinPitchDetector] instead of
/// reimplementing pitch detection. For each onset it analyzes two or three
/// short frames after the attack, takes the median pitch, and derives
/// confidence from YIN clarity plus frame agreement.
class NoteSegmenter {
  NoteSegmenter({
    required this.sampleRate,
    this.frameSize = 4096,
    this.hopSize = 2048,
    this.analysisSeconds = 0.12,
    this.minNoteGapSeconds = 0.06,
  });

  final double sampleRate;

  /// Upper bound for one YIN analysis window.
  final int frameSize;

  /// Preferred distance between analysis windows inside one note.
  final int hopSize;

  /// Length of one YIN analysis window, capped by [frameSize].
  final double analysisSeconds;

  /// Onsets closer than this are treated as one note.
  final double minNoteGapSeconds;

  List<DetectedNote> segment({
    required List<double> samples,
    required List<OnsetEvent> onsets,
  }) {
    if (samples.isEmpty || onsets.isEmpty || sampleRate <= 0) {
      return const [];
    }
    final sorted = [...onsets]
      ..sort((a, b) => a.sampleIndex.compareTo(b.sampleIndex));
    final merged = <OnsetEvent>[];
    for (final onset in sorted) {
      if (merged.isNotEmpty &&
          onset.timeSeconds - merged.last.timeSeconds < minNoteGapSeconds) {
        if (onset.strength > merged.last.strength) {
          merged[merged.length - 1] = onset;
        }
        continue;
      }
      merged.add(onset);
    }

    final detector = YinPitchDetector(sampleRate: sampleRate);
    final notes = <DetectedNote>[];
    for (var index = 0; index < merged.length; index++) {
      final onset = merged[index];
      final next = index + 1 < merged.length ? merged[index + 1] : null;
      final note = _analyze(
        samples: samples,
        onset: onset,
        next: next,
        detector: detector,
      );
      if (note != null) notes.add(note);
    }
    return notes;
  }

  DetectedNote? _analyze({
    required List<double> samples,
    required OnsetEvent onset,
    required OnsetEvent? next,
    required YinPitchDetector detector,
  }) {
    final windowSamples = math.min(
      frameSize,
      math.max(256, (analysisSeconds * sampleRate).round()),
    );
    final skipSamples = (0.012 * sampleRate).round();
    final start = onset.sampleIndex + skipSamples;
    if (start + 256 > samples.length) return null;

    final step = math.max(
      1,
      math.min(hopSize, math.max(1, windowSamples ~/ 2)),
    );
    final starts = <int>[];
    for (var offset = 0; offset < 3; offset++) {
      final frameStart = start + offset * step;
      if (frameStart + 256 > samples.length) break;
      if (next != null && frameStart + 256 > next.sampleIndex) break;
      starts.add(frameStart);
    }

    final estimates = <PitchEstimate>[];
    final frameStarts = <int>[];
    final frameLengths = <int>[];
    for (final frameStart in starts) {
      // Do not let a long analysis window bleed into the next note. Fast
      // passages get a shorter YIN window; 256 samples is still enough for
      // the guitar range at 22 kHz.
      final available = next == null
          ? samples.length - frameStart
          : math.min(
              samples.length - frameStart,
              next.sampleIndex - frameStart,
            );
      final length = math.min(windowSamples, available);
      if (length < 256) continue;
      final frame = samples.sublist(frameStart, frameStart + length);
      final estimate = detector.detect(frame);
      if (estimate.voiced) {
        estimates.add(estimate);
        frameStarts.add(frameStart);
        frameLengths.add(length);
      }
    }

    final duration = _durationFor(samples, onset, next);
    if (estimates.isEmpty) {
      return DetectedNote(
        startSeconds: onset.timeSeconds,
        durationSeconds: duration,
        midi: 0,
        cents: 0,
        confidence: 0,
        sampleIndex: onset.sampleIndex,
      );
    }

    final midiValues = estimates
        .map((estimate) => _frequencyToMidi(estimate.frequency))
        .toList()
      ..sort();
    final medianMidi = _medianSorted(midiValues);
    var frequency = _midiToFrequency(medianMidi);
    var confidenceMultiplier = 1.0;

    // Prefer a plausible fundamental when YIN has locked onto the second
    // harmonic. The check requires energy at the fundamental and at its third
    // harmonic, so a body resonance at half the true pitch cannot trigger it.
    final analysisStart = frameStarts.first;
    final corrected = _preferFundamental(
      frequency: frequency,
      samples: samples,
      start: analysisStart,
      length: frameLengths.first,
    );
    if (corrected != null) {
      frequency = corrected;
      confidenceMultiplier = 0.9;
    }

    final midiFloat = _frequencyToMidi(frequency);
    final midi = midiFloat.round();
    final cents = (midiFloat - midi) * 100;
    // Vibrato of +/-25 cents is a normal guitar technique, so allow up to a
    // semitone and a half of frame spread before agreement reaches zero.
    final spread = midiValues.last - midiValues.first;
    final agreement = (1 - spread / 1.5).clamp(0.0, 1.0);
    final clarity = _medianSorted(
      estimates.map((estimate) => estimate.clarity).toList()..sort(),
    );
    final frameFactor = estimates.length >= 2 ? 1.0 : 0.75;
    final confidence = (clarity *
            (0.6 + 0.4 * agreement) *
            frameFactor *
            confidenceMultiplier)
        .clamp(0.0, 1.0);

    return DetectedNote(
      startSeconds: onset.timeSeconds,
      durationSeconds: duration,
      midi: midi,
      cents: cents,
      confidence: confidence,
      sampleIndex: onset.sampleIndex,
    );
  }

  double _durationFor(
    List<double> samples,
    OnsetEvent onset,
    OnsetEvent? next,
  ) {
    if (next != null) {
      return math.max(0.06, next.timeSeconds - onset.timeSeconds);
    }
    final remaining = (samples.length - onset.sampleIndex) / sampleRate;
    return remaining.clamp(0.06, 0.5);
  }

  /// Returns the corrected frequency when [frequency] is an octave above a
  /// plausible fundamental, otherwise null.
  double? _preferFundamental({
    required double frequency,
    required List<double> samples,
    required int start,
    required int length,
  }) {
    final lower = frequency / 2;
    if (lower < 70 || lower > 1000) return null;
    if (length < 256 || start < 0 || start + length > samples.length) {
      return null;
    }
    final spectrum = magnitudeSpectrum(
      samples.sublist(start, start + length),
      applyWindow: true,
    );
    final fftSize = (spectrum.length - 1) * 2;
    final candidateMagnitude = _magnitudeAt(
      spectrum,
      frequency,
      sampleRate,
      fftSize,
    );
    final fundamentalMagnitude = _magnitudeAt(
      spectrum,
      lower,
      sampleRate,
      fftSize,
    );
    final thirdMagnitude = _magnitudeAt(
      spectrum,
      lower * 3,
      sampleRate,
      fftSize,
    );
    if (candidateMagnitude <= 0) return null;
    var peakMagnitude = 0.0;
    for (final value in spectrum) {
      if (value > peakMagnitude) peakMagnitude = value;
    }
    // Do not "correct" a pitch that has no energy at the reported frequency:
    // that is a missing fundamental, not a harmonic lock.
    if (candidateMagnitude < 0.05 * peakMagnitude) return null;
    if (fundamentalMagnitude < 0.15 * candidateMagnitude) return null;
    if (thirdMagnitude < 0.08 * candidateMagnitude) return null;
    return lower;
  }

  double _magnitudeAt(
    List<double> spectrum,
    double frequency,
    double sampleRate,
    int fftSize,
  ) {
    final bin = frequency * fftSize / sampleRate;
    final index = bin.round();
    if (index < 0 || index >= spectrum.length) return 0;
    var best = spectrum[index];
    if (index > 0 && spectrum[index - 1] > best) best = spectrum[index - 1];
    if (index + 1 < spectrum.length && spectrum[index + 1] > best) {
      best = spectrum[index + 1];
    }
    return best;
  }

  static double _frequencyToMidi(double frequency) =>
      69 + 12 * (math.log(frequency / 440) / math.ln2);

  static double _midiToFrequency(double midi) =>
      440 * math.pow(2, (midi - 69) / 12).toDouble();

  static double _medianSorted(List<double> sorted) {
    if (sorted.isEmpty) return 0;
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return 0.5 * (sorted[middle - 1] + sorted[middle]);
  }
}
