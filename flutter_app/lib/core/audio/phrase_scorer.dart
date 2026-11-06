import '../learning/attempt_outcome.dart';
import 'alignment.dart';
import 'note_segmenter.dart';
import 'onset_detector.dart';

export '../learning/attempt_outcome.dart';

/// Per-target-note evidence.
class NoteResult {
  const NoteResult({
    required this.targetIndex,
    required this.outcome,
    required this.detectedMidi,
    required this.cents,
    required this.onsetErrorMs,
    required this.confidence,
    required this.octaveError,
    required this.inTune,
  });

  final int targetIndex;
  final AttemptOutcome outcome;

  /// Sounding MIDI reported by the segmenter, or null when nothing was heard.
  final int? detectedMidi;

  /// Intonation relative to the nearest semitone, in cents.
  final double? cents;

  /// Detected onset minus the fixed click-grid onset.
  final double? onsetErrorMs;

  /// Detection confidence, 0..1.
  final double confidence;

  /// True when the detected pitch is one or more octaves from the target.
  final bool octaveError;

  /// A correct pitch class within [PhraseScorer.intonationToleranceCents].
  final bool inTune;

  Map<String, dynamic> toJson() => {
        'targetIndex': targetIndex,
        'outcome': outcome.name,
        'detectedMidi': detectedMidi,
        'cents': _roundNullable(cents, 1),
        'onsetErrorMs': _roundNullable(onsetErrorMs, 1),
        'confidence': _round(confidence, 3),
        'octaveError': octaveError,
        'inTune': inTune,
      };
}

/// Whole-phrase evidence.
///
/// [outcome] is the tri-state verdict. `indeterminate` means "incomplete -
/// retry" and must never update mastery or spend a heart.
class PhraseResult {
  const PhraseResult({
    required this.outcome,
    required this.notes,
    required this.noteAccuracy,
    required this.medianCents,
    required this.meanOnsetErrorMs,
    required this.driftMsPerBar,
    required this.timingWithinTolerance,
    required this.complete,
    required this.timingIssue,
    required this.practicePass,
    required this.performanceReady,
    required this.extraNotes,
    required this.falseStart,
    required this.earlyStop,
    required this.timingToleranceMs,
    required this.intonationInTune,
  });

  final AttemptOutcome outcome;
  final List<NoteResult> notes;

  /// Correct / determinate target notes. Extra notes are reported separately.
  final double noteAccuracy;

  /// Median cents over correct target notes.
  final double? medianCents;

  /// Mean onset error over determinate target notes.
  final double? meanOnsetErrorMs;

  /// Least-squares onset-error slope, in milliseconds per bar.
  final double? driftMsPerBar;

  final bool timingWithinTolerance;

  /// Every target note produced determinate evidence, with no false start or
  /// early stop.
  final bool complete;

  /// "rushed", "dragged", or null when timing is acceptable.
  final String? timingIssue;

  /// At least 85% of determinate notes correct, timing acceptable, no extras,
  /// and no more than 20% indeterminate.
  final bool practicePass;

  /// 100% determinate correct, timing acceptable, complete, no extras, and
  /// median intonation within [PhraseScorer.intonationToleranceCents].
  final bool performanceReady;

  /// Confident detected notes that could not be aligned to a target.
  final int extraNotes;

  final bool falseStart;
  final bool earlyStop;

  /// The pedagogical onset tolerance used for this BPM.
  final double timingToleranceMs;

  /// Every correct note was within the intonation tolerance.
  final bool intonationInTune;

  Map<String, dynamic> toJson() => {
        'outcome': outcome.name,
        'notes': [for (final note in notes) note.toJson()],
        'noteAccuracy': _round(noteAccuracy, 4),
        'medianCents': _roundNullable(medianCents, 1),
        'meanOnsetErrorMs': _roundNullable(meanOnsetErrorMs, 1),
        'driftMsPerBar': _roundNullable(driftMsPerBar, 2),
        'timingWithinTolerance': timingWithinTolerance,
        'complete': complete,
        'timingIssue': timingIssue,
        'practicePass': practicePass,
        'performanceReady': performanceReady,
        'extraNotes': extraNotes,
        'falseStart': falseStart,
        'earlyStop': earlyStop,
        'timingToleranceMs': _round(timingToleranceMs, 1),
        'intonationInTune': intonationInTune,
      };
}

/// Scores a short phrase against a fixed click grid.
///
/// Timing is always measured against [TargetNote.onsetSeconds], never against
/// a warped alignment path. DTW is used only to decide which detected note
/// belongs to which target.
class PhraseScorer {
  PhraseScorer({
    required this.sampleRate,
    this.intonationToleranceCents = 30,
  });

  final double sampleRate;
  final int intonationToleranceCents;

  /// Pedagogical onset tolerance: +/-80 ms at 60 BPM, +/-50 ms at 90 BPM,
  /// linear outside that range and clamped to [40, 100] ms.
  static double timingToleranceForBpm(double bpm) {
    if (!bpm.isFinite || bpm <= 0) {
      throw ArgumentError.value(bpm, 'bpm', 'must be positive');
    }
    return (140 - bpm).clamp(40.0, 100.0);
  }

  /// Runs the full audio pipeline and scores [target].
  ///
  /// [countInSeconds] is a silent pre-roll. A detected attack before it is
  /// reported as a false start and is removed from note scoring. Do not pass a
  /// click track that is present in the recording; clicks would be scored as
  /// attacks.
  ///
  /// [beatsPerBar] is passed to [scoreDetections], where it is used to derive
  /// bars only when the caller left every [TargetNote.bar] at zero.
  PhraseResult score({
    required List<double> samples,
    required List<TargetNote> target,
    required double bpm,
    int beatsPerBar = 4,
    double? countInSeconds,
  }) {
    if (bpm <= 0) {
      throw ArgumentError.value(bpm, 'bpm', 'must be positive');
    }
    if (beatsPerBar <= 0) {
      throw ArgumentError.value(
        beatsPerBar,
        'beatsPerBar',
        'must be positive',
      );
    }
    final onsets = OnsetDetector(sampleRate: sampleRate).detect(samples);
    final detected = NoteSegmenter(sampleRate: sampleRate).segment(
      samples: samples,
      onsets: onsets,
    );

    var falseStart = false;
    var scorable = detected;
    if (countInSeconds != null && countInSeconds > 0) {
      // A first note a few milliseconds early is normal playing, not a false
      // start. Only a clear attack well inside the count-in counts.
      final guard = countInSeconds - 0.05;
      falseStart = onsets.any((onset) => onset.timeSeconds < guard);
      // A false start is incomplete, not a failed note. Do not let the early
      // attack consume a target or count as an extra.
      scorable = [
        for (final note in detected)
          if (note.startSeconds >= guard) note,
      ];
    }

    return scoreDetections(
      target: target,
      detected: scorable,
      bpm: bpm,
      beatsPerBar: beatsPerBar,
      falseStart: falseStart,
    );
  }

  /// Scores already-segmented notes. This is the deterministic core used by
  /// [score]; exposing it lets callers and the null-model tests skip audio
  /// analysis without changing any scoring rule.
  ///
  /// [beatsPerBar] is only used when every [TargetNote.bar] is zero, in which
  /// case bars are derived from the fixed onset grid. Otherwise the caller's
  /// bar values win.
  PhraseResult scoreDetections({
    required List<TargetNote> target,
    required List<DetectedNote> detected,
    required double bpm,
    int beatsPerBar = 4,
    bool falseStart = false,
  }) {
    if (bpm <= 0) {
      throw ArgumentError.value(bpm, 'bpm', 'must be positive');
    }
    if (beatsPerBar <= 0) {
      throw ArgumentError.value(
        beatsPerBar,
        'beatsPerBar',
        'must be positive',
      );
    }
    final tolerance = timingToleranceForBpm(bpm);
    if (target.isEmpty) {
      return PhraseResult(
        outcome: AttemptOutcome.indeterminate,
        notes: const [],
        noteAccuracy: 0,
        medianCents: null,
        meanOnsetErrorMs: null,
        driftMsPerBar: null,
        timingWithinTolerance: true,
        complete: false,
        timingIssue: null,
        practicePass: false,
        performanceReady: false,
        extraNotes: 0,
        falseStart: falseStart,
        earlyStop: false,
        timingToleranceMs: tolerance,
        intonationInTune: false,
      );
    }

    final alignment = alignNotes(target: target, detected: detected);
    final matchedDetected = <int>{};
    final notes = <NoteResult>[];
    final timingPoints = <_TimingPoint>[];
    var determinate = 0;
    var correct = 0;
    var wrong = 0;
    var indeterminate = 0;

    // If every caller-supplied bar is zero, derive bars from the click grid
    // so drift still works for a multi-bar phrase.
    final deriveBars = target.every((note) => note.bar == 0);
    final barSeconds = beatsPerBar * 60 / bpm;
    final firstOnset = target.first.onsetSeconds;
    int barFor(TargetNote note) {
      if (!deriveBars) return note.bar;
      return ((note.onsetSeconds - firstOnset) / barSeconds).floor();
    }

    for (var position = 0; position < target.length; position++) {
      final targetNote = target[position];
      final match = alignment[position];
      if (match.detectedIndex == null) {
        notes.add(
          NoteResult(
            targetIndex: targetNote.index,
            outcome: AttemptOutcome.indeterminate,
            detectedMidi: null,
            cents: null,
            onsetErrorMs: null,
            confidence: 0,
            octaveError: false,
            inTune: false,
          ),
        );
        indeterminate++;
        continue;
      }

      final detectedIndex = match.detectedIndex!;
      matchedDetected.add(detectedIndex);
      final detectedNote = detected[detectedIndex];
      final onsetErrorMs =
          (detectedNote.startSeconds - targetNote.onsetSeconds) * 1000;
      final interval = (detectedNote.midi - targetNote.midi).abs();
      final octaveError = interval > 0 && interval % 12 == 0;

      if (detectedNote.confidence < DetectedNote.determinateConfidence) {
        notes.add(
          NoteResult(
            targetIndex: targetNote.index,
            outcome: AttemptOutcome.indeterminate,
            detectedMidi:
                detectedNote.midi > 0 ? detectedNote.midi : null,
            cents: detectedNote.midi > 0 ? detectedNote.cents : null,
            onsetErrorMs: onsetErrorMs,
            confidence: detectedNote.confidence,
            octaveError: octaveError,
            inTune: false,
          ),
        );
        indeterminate++;
        continue;
      }

      final pitchMatch = interval == 0;
      final inTune =
          pitchMatch && detectedNote.cents.abs() <= intonationToleranceCents;
      notes.add(
        NoteResult(
          targetIndex: targetNote.index,
          outcome:
              pitchMatch ? AttemptOutcome.correct : AttemptOutcome.incorrect,
          detectedMidi: detectedNote.midi,
          cents: detectedNote.cents,
          onsetErrorMs: onsetErrorMs,
          confidence: detectedNote.confidence,
          octaveError: octaveError,
          inTune: inTune,
        ),
      );
      determinate++;
      if (pitchMatch) {
        correct++;
      } else {
        wrong++;
      }
      timingPoints.add(
        _TimingPoint(bar: barFor(targetNote), errorMs: onsetErrorMs),
      );
    }

    final extraNotes = [
      for (var index = 0; index < detected.length; index++)
        if (!matchedDetected.contains(index) &&
            detected[index].confidence >= DetectedNote.determinateConfidence)
          index,
    ].length;

    // A quarter-second guard keeps a deliberately rushed take (80 ms early)
    // from being mistaken for an early stop. A real stop leaves at least one
    // beat of silence before the last target.
    double? lastDetected;
    for (final note in detected) {
      if (lastDetected == null || note.startSeconds > lastDetected) {
        lastDetected = note.startSeconds;
      }
    }
    final earlyStop = lastDetected != null &&
        lastDetected < target.last.onsetSeconds - 0.25;

    final drift = _drift(timingPoints);
    // Half a millisecond of guard absorbs onset-refinement bias so a take
    // sitting exactly on the documented boundary is outside tolerance.
    final withinTolerance = timingPoints.every(
      (point) => point.errorMs.abs() < tolerance - 0.5,
    );
    final driftWithinTolerance = drift == null ||
        drift.slope.abs() < tolerance - 0.5;
    final timingWithinTolerance = withinTolerance && driftWithinTolerance;
    final meanOnsetErrorMs = timingPoints.isEmpty
        ? null
        : timingPoints.fold<double>(0, (sum, point) => sum + point.errorMs) /
            timingPoints.length;
    final worstErrorMs = timingPoints.isEmpty
        ? null
        : timingPoints
            .reduce(
              (worst, point) =>
                  point.errorMs.abs() > worst.errorMs.abs() ? point : worst,
            )
            .errorMs;
    final timingIssue = timingWithinTolerance
        ? null
        : _timingIssue(
            drift: drift,
            driftFailed: !driftWithinTolerance,
            meanErrorMs: meanOnsetErrorMs,
            worstErrorMs: worstErrorMs,
          );

    final correctCents = [
      for (final note in notes)
        if (note.outcome == AttemptOutcome.correct && note.cents != null)
          note.cents!,
    ]..sort();
    final medianCents =
        correctCents.isEmpty ? null : _medianSorted(correctCents);
    final noteAccuracy = determinate == 0 ? 0.0 : correct / determinate;
    final indeterminateFraction = indeterminate / target.length;
    final complete =
        indeterminate == 0 && !falseStart && !earlyStop;
    final intonationInTune =
        correctCents.isNotEmpty && correctCents.every(
          (cents) => cents.abs() <= intonationToleranceCents,
        );

    AttemptOutcome outcome;
    if (!complete) {
      // Any indeterminate note, false start, or early stop makes the take
      // incomplete. An incomplete take is a retry, never a failure, even when
      // another note was confidently wrong. The 20% indeterminate limit below
      // remains only as a practice-pass signal.
      outcome = AttemptOutcome.indeterminate;
    } else if (wrong > 0 || extraNotes > 0) {
      outcome = AttemptOutcome.incorrect;
    } else if (!timingWithinTolerance) {
      outcome = AttemptOutcome.incorrect;
    } else {
      outcome = AttemptOutcome.correct;
    }

    final practicePass = timingWithinTolerance &&
        extraNotes == 0 &&
        !falseStart &&
        !earlyStop &&
        determinate > 0 &&
        noteAccuracy >= 0.85 &&
        indeterminateFraction <= 0.20;
    final performanceReady = complete &&
        extraNotes == 0 &&
        determinate == target.length &&
        correct == target.length &&
        medianCents != null &&
        medianCents.abs() <= intonationToleranceCents &&
        timingWithinTolerance;

    return PhraseResult(
      outcome: outcome,
      notes: notes,
      noteAccuracy: noteAccuracy,
      medianCents: medianCents,
      meanOnsetErrorMs: meanOnsetErrorMs,
      driftMsPerBar: drift?.slope,
      timingWithinTolerance: timingWithinTolerance,
      complete: complete,
      timingIssue: timingIssue,
      practicePass: practicePass,
      performanceReady: performanceReady,
      extraNotes: extraNotes,
      falseStart: falseStart,
      earlyStop: earlyStop,
      timingToleranceMs: tolerance,
      intonationInTune: intonationInTune,
    );
  }

  static String? _timingIssue({
    required _Drift? drift,
    required bool driftFailed,
    required double? meanErrorMs,
    required double? worstErrorMs,
  }) {
    double? value;
    if (driftFailed && drift != null) {
      value = drift.slope;
    } else if (meanErrorMs != null && meanErrorMs.abs() >= 1) {
      value = meanErrorMs;
    } else {
      value = worstErrorMs;
    }
    if (value == null || value.abs() < 1e-9) return null;
    return value < 0 ? 'rushed' : 'dragged';
  }

  static _Drift? _drift(List<_TimingPoint> points) {
    if (points.length < 2) return null;
    final bars = points.map((point) => point.bar).toSet();
    if (bars.length < 2) return null;
    final meanBar =
        points.fold<double>(0, (sum, point) => sum + point.bar) /
            points.length;
    final meanError =
        points.fold<double>(0, (sum, point) => sum + point.errorMs) /
            points.length;
    var covariance = 0.0;
    var variance = 0.0;
    for (final point in points) {
      final barDelta = point.bar - meanBar;
      covariance += barDelta * (point.errorMs - meanError);
      variance += barDelta * barDelta;
    }
    if (variance == 0) return null;
    return _Drift(slope: covariance / variance);
  }

  static double _medianSorted(List<double> sorted) {
    if (sorted.isEmpty) return 0;
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return 0.5 * (sorted[middle - 1] + sorted[middle]);
  }
}

class _TimingPoint {
  const _TimingPoint({required this.bar, required this.errorMs});
  final int bar;
  final double errorMs;
}

class _Drift {
  const _Drift({required this.slope});
  final double slope;
}

double _round(double value, int digits) =>
    double.parse(value.toStringAsFixed(digits));

double? _roundNullable(double? value, int digits) =>
    value == null ? null : _round(value, digits);
