import 'dart:math' as math;
import 'dart:typed_data';

import 'wav.dart';

/// Values within this absolute tolerance of a gate are treated as inside the
/// gate so binary floating-point noise cannot flip a boundary decision.
const double _gateEpsilon = 1e-9;

bool _exceeds(double value, double limit) => value > limit + _gateEpsilon;

bool _below(double value, double limit) => value + _gateEpsilon < limit;

/// Pass/fail thresholds for timing and bleed calibration.
///
/// A device may only be used for scored timing when the loopback offset and
/// clock drift both stay within these limits. Bleed is gated separately by
/// [analyzeBleed].
class CalibrationGates {
  const CalibrationGates({
    this.maxOffsetMs = 10,
    this.maxDriftMsPer60s = 20,
    this.maxFalseOnsetsPerMinute = 1,
    this.maxRecallDrop = 0.05,
  }) : assert(maxOffsetMs >= 0, 'maxOffsetMs must not be negative'),
       assert(maxDriftMsPer60s >= 0, 'maxDriftMsPer60s must not be negative'),
       assert(
         maxFalseOnsetsPerMinute >= 0,
         'maxFalseOnsetsPerMinute must not be negative',
       ),
       assert(maxRecallDrop >= 0, 'maxRecallDrop must not be negative');

  /// Maximum absolute output-to-input offset for scored timing.
  final double maxOffsetMs;

  /// Maximum absolute clock drift, normalized to 60 seconds.
  final double maxDriftMsPer60s;

  /// Maximum energy onsets that are not explained by an expected note.
  final double maxFalseOnsetsPerMinute;

  /// Maximum allowed note-recall loss between speaker and headphone takes.
  final double maxRecallDrop;
}

/// Result of a loopback (reference click -> recording) calibration.
class CalibrationReport {
  const CalibrationReport({
    required this.offsetMs,
    required this.driftMsPer60s,
    required this.falseOnsetsPerMinute,
    required this.noteRecall,
    required this.timingUsable,
    required this.failures,
    this.offsetVerified = true,
    this.driftVerified = true,
    this.expectedOnsets = 0,
    this.matchedOnsets = 0,
    this.detectedOnsets = 0,
  });

  /// Offset at the start of the take. Positive means the recorded click
  /// arrives later than the reference.
  final double offsetMs;

  /// Change in offset per 60 seconds. Positive means the recording clock runs
  /// slower than the reference clock.
  final double driftMsPer60s;

  /// Recorded onsets that do not match an expected click, per minute.
  final double falseOnsetsPerMinute;

  /// Fraction of reference clicks that were detected in the recording.
  final double noteRecall;

  /// True only when offset, drift, and the measurement itself pass their
  /// gates. Bleed is a separate decision.
  final bool timingUsable;

  final List<String> failures;

  /// True when the first reference click was matched and the takes share a
  /// time origin. When false, [offsetMs] is diagnostic only.
  final bool offsetVerified;

  /// True when the offset is verified and at least two clicks were matched,
  /// so a drift line could be fitted. When false, [driftMsPer60s] is
  /// diagnostic only.
  final bool driftVerified;

  final int expectedOnsets;
  final int matchedOnsets;
  final int detectedOnsets;

  Map<String, dynamic> toJson() => {
    'offsetMs': offsetVerified ? _rounded(offsetMs, 3) : null,
    'driftMsPer60s': driftVerified ? _rounded(driftMsPer60s, 3) : null,
    'falseOnsetsPerMinute': _rounded(falseOnsetsPerMinute, 3),
    'noteRecall': _rounded(noteRecall, 4),
    'timingUsable': timingUsable,
    'offsetVerified': offsetVerified,
    'driftVerified': driftVerified,
    'failures': List<String>.from(failures),
    'expectedOnsets': expectedOnsets,
    'matchedOnsets': matchedOnsets,
    'detectedOnsets': detectedOnsets,
  };
}

/// Note-recall metrics for a single take.
class RecallReport {
  const RecallReport({
    required this.noteRecall,
    required this.falseOnsetsPerMinute,
    required this.meanLatencyMs,
    required this.recallUsable,
    required this.failures,
    required this.expectedOnsets,
    required this.detectedOnsets,
    required this.matchedOnsets,
  });

  /// Fraction of expected onsets detected in the take.
  final double noteRecall;

  /// Detected onsets that do not match an expected onset, per minute.
  final double falseOnsetsPerMinute;

  /// Mean (detected - expected) time for matched onsets. Positive means the
  /// detector found the note later than the manifest says.
  final double meanLatencyMs;

  final bool recallUsable;
  final List<String> failures;
  final int expectedOnsets;
  final int detectedOnsets;
  final int matchedOnsets;

  Map<String, dynamic> toJson() => {
    'noteRecall': _rounded(noteRecall, 4),
    'falseOnsetsPerMinute': _rounded(falseOnsetsPerMinute, 3),
    'meanLatencyMs': _rounded(meanLatencyMs, 3),
    'recallUsable': recallUsable,
    'failures': List<String>.from(failures),
    'expectedOnsets': expectedOnsets,
    'detectedOnsets': detectedOnsets,
    'matchedOnsets': matchedOnsets,
  };
}

/// Speaker-vs-headphone bleed comparison.
class BleedReport {
  const BleedReport({
    required this.speakerRecall,
    required this.headphoneRecall,
    required this.recallDrop,
    required this.speakerFalseOnsetsPerMinute,
    required this.headphonesRequired,
    required this.failures,
  });

  final double speakerRecall;
  final double headphoneRecall;

  /// Headphone recall minus speaker recall. A positive value means the
  /// speaker take lost notes.
  final double recallDrop;

  final double speakerFalseOnsetsPerMinute;

  /// True when the speaker take loses more than 5% recall or produces more
  /// than one unexplained onset per minute.
  final bool headphonesRequired;

  final List<String> failures;

  Map<String, dynamic> toJson() => {
    'speakerRecall': _rounded(speakerRecall, 4),
    'headphoneRecall': _rounded(headphoneRecall, 4),
    'recallDrop': _rounded(recallDrop, 4),
    'speakerFalseOnsetsPerMinute': _rounded(speakerFalseOnsetsPerMinute, 3),
    'headphonesRequired': headphonesRequired,
    'failures': List<String>.from(failures),
  };
}

/// Measures output-to-input offset and clock drift by comparing a reference
/// click train with a recording of that train.
///
/// Algorithm (all deterministic, no wall clock):
/// 1. Each take is downmixed to mono by averaging channels.
/// 2. A 4 ms RMS envelope is sampled every 1 ms.
/// 3. Energy onsets are picked from local envelope maxima that clear an
///    adaptive threshold (10% of the peak or 3x the 20th percentile).
/// 4. The first reference click is aligned to recorded onsets in a bounded
///    0..2 s window. Candidate offsets are scored by how many reference
///    clicks they match and by their least-squares residual. The earliest
///    candidate wins a tie, so a shared time origin selects the true click
///    even when a periodic train has aliases.
/// 5. A take with an onset before the first reference click, or with no
///    candidate in the alignment window, is marked unverified instead of
///    being certified. This catches unaligned starts and missed first clicks.
/// 6. The line intercept at t = 0 is the offset; (slope - 1) * 60000 is drift
///    in ms per 60 s. Offset and drift are only usable when verified.
///
/// Positive offset means the recording is late. [timingUsable] is true only
/// when both measurements are verified, the offset and drift gates pass, and
/// drift was measurable from at least two clicks.
CalibrationReport analyzeLoopback({
  required WavData reference,
  required WavData recorded,
  CalibrationGates gates = const CalibrationGates(),
}) {
  _requireComparable(reference, recorded);
  final referenceMono = _downmix(reference);
  final recordedMono = _downmix(recorded);
  _requireSignal(referenceMono, 'reference');
  _requireSignal(recordedMono, 'recorded');

  final referenceEnvelope = _Envelope.of(referenceMono, reference.sampleRate);
  final recordedEnvelope = _Envelope.of(recordedMono, recorded.sampleRate);
  final referenceOnsets = _detectOnsets(referenceEnvelope);
  final recordedOnsets = _detectOnsets(recordedEnvelope);

  if (referenceOnsets.isEmpty) {
    throw ArgumentError(
      'The reference take has no detectable onsets. Generate a click train '
      'with clear attacks.',
    );
  }
  if (recordedOnsets.isEmpty) {
    throw ArgumentError(
      'The recorded take has no detectable onsets. Check the input gain and '
      'the microphone routing.',
    );
  }

  final alignment = _alignFirstClick(referenceOnsets, recordedOnsets);
  final candidate = _bestCandidate(
    referenceOnsets,
    recordedOnsets,
    alignment.coarseOffsetSeconds,
  );
  final fit = candidate.fit;

  final offsetMs = fit.interceptSeconds * 1000.0;
  final driftMsPer60s = (fit.slope - 1.0) * 60000.0;
  final firstReference = referenceOnsets.first;
  final offsetVerified =
      alignment.failures.isEmpty &&
      fit.pairs.length >= 2 &&
      _matchesFirstReference(fit, firstReference);
  final driftVerified = offsetVerified && fit.pairs.length >= 2;

  final matchedReference = <double>{};
  final usedRecorded = <int>{};
  for (final pair in fit.pairs) {
    matchedReference.add(pair.reference);
    usedRecorded.add(pair.recordedIndex);
  }
  final falseOnsets = recordedOnsets.length - usedRecorded.length;
  final recordedMinutes = recorded.duration.inMicroseconds / 60000000.0;
  final falseOnsetsPerMinute = recordedMinutes > 0
      ? falseOnsets / recordedMinutes
      : double.infinity;
  final noteRecall = matchedReference.length / referenceOnsets.length;

  final failures = <String>[];
  if (!offsetVerified) {
    if (alignment.failures.isNotEmpty) {
      failures.addAll(alignment.failures);
    } else if (!_matchesFirstReference(fit, firstReference)) {
      failures.add(
        'offset could not be verified: the first reference click was not '
        'matched in the recording',
      );
    } else {
      failures.add(
        'offset could not be verified: ${fit.pairs.length} reference '
        'click(s) matched, at least 2 are required',
      );
    }
  } else if (_exceeds(offsetMs.abs(), gates.maxOffsetMs)) {
    failures.add(
      'offset ${_format(offsetMs)} ms exceeds '
      '+/-${_format(gates.maxOffsetMs)} ms',
    );
  }
  if (!driftVerified) {
    if (!offsetVerified) {
      failures.add('drift cannot be verified because the offset is unverified');
    } else {
      failures.add(
        'drift cannot be verified: ${fit.pairs.length} reference click(s) '
        'matched, at least 2 are required',
      );
    }
  } else if (_exceeds(driftMsPer60s.abs(), gates.maxDriftMsPer60s)) {
    failures.add(
      'drift ${_format(driftMsPer60s)} ms/60s exceeds '
      '+/-${_format(gates.maxDriftMsPer60s)} ms/60s',
    );
  }

  return CalibrationReport(
    offsetMs: offsetMs,
    driftMsPer60s: driftMsPer60s,
    falseOnsetsPerMinute: falseOnsetsPerMinute,
    noteRecall: noteRecall,
    timingUsable: failures.isEmpty,
    failures: failures,
    offsetVerified: offsetVerified,
    driftVerified: driftVerified,
    expectedOnsets: referenceOnsets.length,
    matchedOnsets: matchedReference.length,
    detectedOnsets: recordedOnsets.length,
  );
}

/// Measures how many expected note onsets are found in [recorded].
///
/// [expectedOnsetSeconds] is the note-onset manifest for the phrase. A detected
/// onset matches when it falls within [matchWindowMs] of an expected onset.
/// Extra detections become false onsets normalized by the take duration.
RecallReport analyzeNoteRecall({
  required WavData recorded,
  required List<double> expectedOnsetSeconds,
  CalibrationGates gates = const CalibrationGates(),
  double matchWindowMs = 50,
}) {
  if (expectedOnsetSeconds.isEmpty) {
    throw ArgumentError.value(
      expectedOnsetSeconds,
      'expectedOnsetSeconds',
      'must not be empty',
    );
  }
  if (!matchWindowMs.isFinite || matchWindowMs <= 0) {
    throw ArgumentError.value(
      matchWindowMs,
      'matchWindowMs',
      'must be a positive number',
    );
  }
  final expected = List<double>.from(expectedOnsetSeconds);
  for (final onset in expected) {
    if (!onset.isFinite || onset < 0) {
      throw ArgumentError.value(
        onset,
        'expectedOnsetSeconds',
        'every onset must be finite and non-negative',
      );
    }
  }
  expected.sort();

  final mono = _downmix(recorded);
  _requireSignal(mono, 'recorded');
  final envelope = _Envelope.of(mono, recorded.sampleRate);
  final detected = _detectOnsets(envelope);
  if (detected.isEmpty) {
    throw ArgumentError(
      'The recorded take has no detectable onsets. Check the input gain and '
      'the microphone routing.',
    );
  }

  final windowSeconds = matchWindowMs / 1000.0;
  final usedDetected = <int>{};
  final latencies = <double>[];
  for (final onset in expected) {
    var bestIndex = -1;
    var bestDistance = double.infinity;
    for (var index = 0; index < detected.length; index++) {
      if (usedDetected.contains(index)) continue;
      final distance = (detected[index] - onset).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
    }
    if (bestIndex >= 0 && bestDistance <= windowSeconds) {
      usedDetected.add(bestIndex);
      latencies.add((detected[bestIndex] - onset) * 1000.0);
    }
  }

  final matched = usedDetected.length;
  final falseOnsets = detected.length - matched;
  final recordedMinutes = recorded.duration.inMicroseconds / 60000000.0;
  final falseOnsetsPerMinute = recordedMinutes > 0
      ? falseOnsets / recordedMinutes
      : double.infinity;
  final noteRecall = matched / expected.length;
  final meanLatencyMs = latencies.isEmpty
      ? 0.0
      : latencies.reduce((a, b) => a + b) / latencies.length;
  final minimumRecall = 1.0 - gates.maxRecallDrop;

  final failures = <String>[];
  if (_below(noteRecall, minimumRecall)) {
    failures.add(
      'note recall ${_format(noteRecall, 3)} is below the minimum '
      '${_format(minimumRecall, 3)}',
    );
  }
  if (_exceeds(falseOnsetsPerMinute, gates.maxFalseOnsetsPerMinute)) {
    failures.add(
      'false onsets ${_format(falseOnsetsPerMinute)} /min exceed '
      '${_format(gates.maxFalseOnsetsPerMinute)} /min',
    );
  }

  return RecallReport(
    noteRecall: noteRecall,
    falseOnsetsPerMinute: falseOnsetsPerMinute,
    meanLatencyMs: meanLatencyMs,
    recallUsable: failures.isEmpty,
    failures: failures,
    expectedOnsets: expected.length,
    detectedOnsets: detected.length,
    matchedOnsets: matched,
  );
}

/// Compares the same expected phrase recorded once with speaker click/backing
/// and once with wired headphones.
///
/// The headphone take is the reference condition. [headphonesRequired] is true
/// when speaker recall drops by more than [CalibrationGates.maxRecallDrop] or
/// the speaker take has more than
/// [CalibrationGates.maxFalseOnsetsPerMinute] unexplained onsets per minute.
BleedReport analyzeBleed({
  required WavData speaker,
  required WavData headphones,
  required List<double> expectedOnsetSeconds,
  CalibrationGates gates = const CalibrationGates(),
  double matchWindowMs = 50,
}) {
  final speakerReport = analyzeNoteRecall(
    recorded: speaker,
    expectedOnsetSeconds: expectedOnsetSeconds,
    gates: gates,
    matchWindowMs: matchWindowMs,
  );
  final headphoneReport = analyzeNoteRecall(
    recorded: headphones,
    expectedOnsetSeconds: expectedOnsetSeconds,
    gates: gates,
    matchWindowMs: matchWindowMs,
  );

  final recallDrop = headphoneReport.noteRecall - speakerReport.noteRecall;
  final failures = <String>[];
  if (_exceeds(recallDrop, gates.maxRecallDrop)) {
    failures.add(
      'speaker recall is ${_format(recallDrop, 4)} lower than headphones; '
      'limit is ${_format(gates.maxRecallDrop, 3)}',
    );
  }
  if (_exceeds(
    speakerReport.falseOnsetsPerMinute,
    gates.maxFalseOnsetsPerMinute,
  )) {
    failures.add(
      'speaker false onsets '
      '${_format(speakerReport.falseOnsetsPerMinute)} /min exceed '
      '${_format(gates.maxFalseOnsetsPerMinute)} /min',
    );
  }

  return BleedReport(
    speakerRecall: speakerReport.noteRecall,
    headphoneRecall: headphoneReport.noteRecall,
    recallDrop: recallDrop,
    speakerFalseOnsetsPerMinute: speakerReport.falseOnsetsPerMinute,
    headphonesRequired: failures.isNotEmpty,
    failures: failures,
  );
}

void _requireComparable(WavData reference, WavData recorded) {
  if (reference.sampleRate != recorded.sampleRate) {
    throw ArgumentError(
      'Sample rates differ (reference ${reference.sampleRate} Hz, recorded '
      '${recorded.sampleRate} Hz). Export both takes at the same rate.',
    );
  }
}

void _requireSignal(Float64List samples, String name) {
  if (samples.length < 4) {
    throw ArgumentError('The $name take is too short to analyze.');
  }
  var peak = 0.0;
  for (final sample in samples) {
    final magnitude = sample.abs();
    if (magnitude > peak) peak = magnitude;
  }
  if (peak < 1e-5) {
    throw ArgumentError(
      'The $name take is silent. Check the routing and input gain.',
    );
  }
}

Float64List _downmix(WavData data) {
  final frames = data.frameCount;
  final mono = Float64List(frames);
  if (data.channels == 1) {
    for (var frame = 0; frame < frames; frame++) {
      mono[frame] = data.samples[frame];
    }
    return mono;
  }
  for (var frame = 0; frame < frames; frame++) {
    var sum = 0.0;
    final base = frame * data.channels;
    for (var channel = 0; channel < data.channels; channel++) {
      sum += data.samples[base + channel];
    }
    mono[frame] = sum / data.channels;
  }
  return mono;
}

/// RMS envelope with a 4 ms window and a 1 ms hop.
class _Envelope {
  const _Envelope({
    required this.values,
    required this.hopSamples,
    required this.windowSamples,
    required this.sampleRate,
  });

  factory _Envelope.of(Float64List samples, int sampleRate) {
    final hop = math.max(1, (sampleRate * 0.001).round());
    final window = math.max(1, hop * 4);
    if (samples.length < window) {
      return _Envelope(
        values: Float64List(0),
        hopSamples: hop,
        windowSamples: window,
        sampleRate: sampleRate,
      );
    }
    final count = ((samples.length - window) ~/ hop) + 1;
    final values = Float64List(count);
    for (var index = 0; index < count; index++) {
      final start = index * hop;
      final end = start + window;
      var energy = 0.0;
      for (var sample = start; sample < end; sample++) {
        final value = samples[sample];
        energy += value * value;
      }
      values[index] = math.sqrt(energy / window);
    }
    return _Envelope(
      values: values,
      hopSamples: hop,
      windowSamples: window,
      sampleRate: sampleRate,
    );
  }

  final Float64List values;
  final int hopSamples;
  final int windowSamples;
  final int sampleRate;

  double timeAt(int index) {
    return (index * hopSamples + windowSamples / 2.0) / sampleRate;
  }

  double get frameSeconds => hopSamples / sampleRate;
}

class _Onset {
  const _Onset(this.seconds, this.strength);

  final double seconds;
  final double strength;
}

List<double> _detectOnsets(_Envelope envelope) {
  final values = envelope.values;
  if (values.isEmpty) return const <double>[];

  var peak = 0.0;
  for (final value in values) {
    if (value > peak) peak = value;
  }
  if (peak < 1e-7) return const <double>[];

  final sorted = List<double>.from(values)..sort();
  final noiseFloor = sorted[(sorted.length * 0.2).floor()];
  var threshold = math.max(peak * 0.10, noiseFloor * 3.0);
  threshold = math.min(threshold, peak * 0.60);
  if (threshold <= 0) threshold = peak * 0.10;

  final minimumGapFrames = math.max(1, (0.040 / envelope.frameSeconds).round());
  final onsets = <_Onset>[];
  var lastPeakIndex = -minimumGapFrames;
  for (var index = 1; index + 1 < values.length; index++) {
    final value = values[index];
    if (value < threshold) continue;
    if (value < values[index - 1] || value < values[index + 1]) continue;
    if (index - lastPeakIndex < minimumGapFrames) continue;

    var shift = 0.0;
    final before = values[index - 1];
    final after = values[index + 1];
    final denominator = before - 2.0 * value + after;
    if (denominator.abs() > 1e-12) {
      shift = 0.5 * (before - after) / denominator;
      shift = shift.clamp(-0.5, 0.5);
    }
    onsets.add(
      _Onset(envelope.timeAt(index) + shift * envelope.frameSeconds, value),
    );
    lastPeakIndex = index;
  }
  return [for (final onset in onsets) onset.seconds];
}

const double _maxAlignmentLatencySeconds = 2.0;
const double _alignmentToleranceSeconds = 0.050;
const int _maxAlignmentCandidates = 8;

class _Alignment {
  const _Alignment({required this.coarseOffsetSeconds, required this.failures});

  final double coarseOffsetSeconds;
  final List<String> failures;
}

class _CandidateFit {
  const _CandidateFit({
    required this.fit,
    required this.offsetSeconds,
    required this.matched,
    required this.residualSeconds,
  });

  final _Fit fit;
  final double offsetSeconds;
  final int matched;
  final double residualSeconds;
}

/// Checks that the takes share a time origin and that the first reference
/// click has a recorded candidate within the plausible latency window.
_Alignment _alignFirstClick(
  List<double> referenceOnsets,
  List<double> recordedOnsets,
) {
  final firstReference = referenceOnsets.first;
  final early = <double>[
    for (final onset in recordedOnsets)
      if (onset < firstReference - _alignmentToleranceSeconds) onset,
  ];
  if (early.isNotEmpty) {
    final earlyMs = (firstReference - early.first) * 1000.0;
    return _Alignment(
      coarseOffsetSeconds: 0.0,
      failures: [
        'the recording has an onset ${_format(earlyMs)} ms before the first '
            'reference click; start playback and recording together so both '
            'takes share sample zero',
      ],
    );
  }

  for (final onset in recordedOnsets) {
    final offset = onset - firstReference;
    if (offset >= -_alignmentToleranceSeconds &&
        offset <= _maxAlignmentLatencySeconds) {
      return _Alignment(
        coarseOffsetSeconds: offset,
        failures: const <String>[],
      );
    }
  }

  return const _Alignment(
    coarseOffsetSeconds: 0.0,
    failures: <String>[
      'could not align the first reference click; the recording may start '
          'after it, or the input may be silent',
    ],
  );
}

/// Scores candidate alignments by matched clicks, then fit residual, then
/// the earliest offset. Anchoring to the first reference click prevents a
/// periodic train from selecting a negative alias such as -10 ms for a
/// 490 ms delay.
_CandidateFit _bestCandidate(
  List<double> referenceOnsets,
  List<double> recordedOnsets,
  double fallbackOffset,
) {
  final firstReference = referenceOnsets.first;
  final candidates = <double>[];
  for (final onset in recordedOnsets) {
    final offset = onset - firstReference;
    if (offset < -_alignmentToleranceSeconds) continue;
    if (offset > _maxAlignmentLatencySeconds) break;
    candidates.add(offset);
    if (candidates.length >= _maxAlignmentCandidates) break;
  }

  _CandidateFit? best;
  for (final candidate in candidates) {
    final fit = _fitOnsets(referenceOnsets, recordedOnsets, candidate);
    final current = _CandidateFit(
      fit: fit,
      offsetSeconds: candidate,
      matched: fit.pairs.length,
      residualSeconds: _residualSeconds(fit),
    );
    if (best == null || _isBetterCandidate(current, best)) {
      best = current;
    }
  }

  if (best != null) return best;

  final fit = _fitOnsets(referenceOnsets, recordedOnsets, fallbackOffset);
  return _CandidateFit(
    fit: fit,
    offsetSeconds: fallbackOffset,
    matched: fit.pairs.length,
    residualSeconds: _residualSeconds(fit),
  );
}

bool _isBetterCandidate(_CandidateFit candidate, _CandidateFit current) {
  if (candidate.matched != current.matched) {
    return candidate.matched > current.matched;
  }
  if ((candidate.residualSeconds - current.residualSeconds).abs() > 1e-9) {
    return candidate.residualSeconds < current.residualSeconds;
  }
  return candidate.offsetSeconds < current.offsetSeconds;
}

double _residualSeconds(_Fit fit) {
  if (fit.pairs.isEmpty) return double.infinity;
  var sum = 0.0;
  for (final pair in fit.pairs) {
    final predicted = fit.interceptSeconds + fit.slope * pair.reference;
    sum += (pair.recorded - predicted).abs();
  }
  return sum / fit.pairs.length;
}

bool _matchesFirstReference(_Fit fit, double firstReference) {
  for (final pair in fit.pairs) {
    if ((pair.reference - firstReference).abs() < 1e-9) return true;
  }
  return false;
}

class _Pair {
  const _Pair(this.reference, this.recorded, this.recordedIndex);

  final double reference;
  final double recorded;
  final int recordedIndex;
}

class _Fit {
  const _Fit({
    required this.interceptSeconds,
    required this.slope,
    required this.pairs,
  });

  final double interceptSeconds;
  final double slope;
  final List<_Pair> pairs;
}

_Fit _fitOnsets(
  List<double> referenceOnsets,
  List<double> recordedOnsets,
  double coarseOffset,
) {
  const matchWindowSeconds = 0.050;
  var intercept = coarseOffset;
  var slope = 1.0;
  var pairs = <_Pair>[];

  for (var pass = 0; pass < 3; pass++) {
    final used = <int>{};
    final nextPairs = <_Pair>[];
    for (final reference in referenceOnsets) {
      final predicted = intercept + slope * reference;
      var bestIndex = -1;
      var bestDistance = double.infinity;
      for (var index = 0; index < recordedOnsets.length; index++) {
        if (used.contains(index)) continue;
        final distance = (recordedOnsets[index] - predicted).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          bestIndex = index;
        }
      }
      if (bestIndex >= 0 && bestDistance <= matchWindowSeconds) {
        used.add(bestIndex);
        nextPairs.add(_Pair(reference, recordedOnsets[bestIndex], bestIndex));
      }
    }
    pairs = nextPairs;
    if (pairs.length >= 2) {
      final fit = _leastSquares(pairs);
      intercept = fit.$1;
      slope = fit.$2;
    } else if (pairs.length == 1) {
      intercept = pairs.first.recorded - pairs.first.reference;
      slope = 1.0;
    } else {
      intercept = coarseOffset;
      slope = 1.0;
    }
  }

  return _Fit(interceptSeconds: intercept, slope: slope, pairs: pairs);
}

/// Returns (intercept, slope) for recorded = intercept + slope * reference.
(double, double) _leastSquares(List<_Pair> pairs) {
  var sumX = 0.0;
  var sumY = 0.0;
  var sumXX = 0.0;
  var sumXY = 0.0;
  for (final pair in pairs) {
    sumX += pair.reference;
    sumY += pair.recorded;
    sumXX += pair.reference * pair.reference;
    sumXY += pair.reference * pair.recorded;
  }
  final count = pairs.length.toDouble();
  final denominator = count * sumXX - sumX * sumX;
  if (denominator.abs() < 1e-12) {
    return (sumY / count - sumX / count, 1.0);
  }
  final slope = (count * sumXY - sumX * sumY) / denominator;
  final intercept = (sumY - slope * sumX) / count;
  return (intercept, slope);
}

double _rounded(double value, int digits) {
  if (!value.isFinite) return value;
  final factor = math.pow(10, digits).toDouble();
  final rounded = (value * factor).roundToDouble() / factor;
  return rounded == 0 ? 0.0 : rounded;
}

String _format(double value, [int digits = 2]) {
  if (!value.isFinite) return value.toString();
  return value.toStringAsFixed(digits);
}
