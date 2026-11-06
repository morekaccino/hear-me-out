import '../music/note.dart';
import 'phrase_prompt.dart';
import 'phrase_scorer.dart';

/// The single actionable correction shown after a phrase take.
///
/// [worstBar] is a one-based piece bar. It is null when the take is incomplete
/// or the evidence is not confident enough to name a bar. Callers must not
/// invent bar or beat feedback when it is null.
class PhraseVerification {
  const PhraseVerification({
    required this.outcome,
    required this.noteAccuracy,
    required this.timingWithinTolerance,
    required this.complete,
    required this.worstBar,
    required this.confidence,
    required this.practicePass,
    required this.performanceReady,
    required this.correction,
    required this.result,
  });

  final AttemptOutcome outcome;
  final double noteAccuracy;
  final bool timingWithinTolerance;
  final bool complete;
  final int? worstBar;
  final double confidence;
  final bool practicePass;
  final bool performanceReady;

  /// Exactly one sentence the learner can act on.
  final String correction;

  /// Raw scorer evidence, kept for progress recording and diagnostics.
  final PhraseResult result;

  /// A complete, determinate take is the only take that may update progress.
  /// An incomplete or indeterminate take is a retry (T2.3 contract).
  bool get updatesProgress =>
      complete && outcome != AttemptOutcome.indeterminate;
}

/// Turns audio or scorer evidence into a typed phrase verdict and one
/// correction.
///
/// The verifier never reads the wall clock. Alignment is owned by
/// [PhraseScorer], which measures timing against the fixed click grid.
class PhraseVerifier {
  const PhraseVerifier({this.confidenceThreshold = 0.7})
    : assert(
        confidenceThreshold >= 0 && confidenceThreshold <= 1,
        'confidenceThreshold must be in 0..1',
      );

  /// Below this mean note confidence, the app withholds bar and beat detail.
  final double confidenceThreshold;

  PhraseVerification verify({
    required PhrasePlayPrompt prompt,
    required List<double> samples,
    required int sampleRate,
  }) {
    if (sampleRate <= 0) {
      throw ArgumentError.value(sampleRate, 'sampleRate', 'must be positive');
    }
    final result =
        PhraseScorer(
          sampleRate: sampleRate.toDouble(),
          intonationToleranceCents: prompt.intonationToleranceCents,
        ).score(
          samples: samples,
          target: prompt.targetNotes,
          bpm: prompt.bpm.toDouble(),
          beatsPerBar: prompt.beatsPerBar.round(),
          countInSeconds: prompt.countInSeconds,
        );
    return fromResult(prompt: prompt, result: result);
  }

  PhraseVerification fromResult({
    required PhrasePlayPrompt prompt,
    required PhraseResult result,
  }) {
    final confidence = _confidence(result);
    final confident = confidence >= confidenceThreshold;
    final worstBar = confident ? _worstBar(result, prompt) : null;
    final correction = _correction(
      prompt: prompt,
      result: result,
      confident: confident,
      worstBar: worstBar,
    );

    return PhraseVerification(
      outcome: result.outcome,
      noteAccuracy: result.noteAccuracy,
      timingWithinTolerance: result.timingWithinTolerance,
      complete: result.complete,
      worstBar: worstBar,
      confidence: confidence,
      practicePass: result.practicePass,
      performanceReady: result.performanceReady,
      correction: correction,
      result: result,
    );
  }

  double _confidence(PhraseResult result) {
    if (result.notes.isEmpty) return 0;
    var sum = 0.0;
    for (final note in result.notes) {
      sum += note.confidence.clamp(0.0, 1.0);
    }
    return sum / result.notes.length;
  }

  int? _worstBar(PhraseResult result, PhrasePlayPrompt prompt) {
    if (!result.complete || result.outcome == AttemptOutcome.indeterminate) {
      return null;
    }

    final wrongByBar = <int, List<NoteResult>>{};
    for (final note in result.notes) {
      if (note.outcome != AttemptOutcome.incorrect) continue;
      final target = prompt.targetForIndex(note.targetIndex);
      if (target == null) continue;
      wrongByBar.putIfAbsent(target.bar, () => <NoteResult>[]).add(note);
    }
    if (wrongByBar.isNotEmpty) {
      final bars = wrongByBar.entries.toList()
        ..sort((a, b) {
          final byCount = b.value.length.compareTo(a.value.length);
          if (byCount != 0) return byCount;
          final byConfidence = _maxConfidence(b.value)
              .compareTo(_maxConfidence(a.value));
          if (byConfidence != 0) return byConfidence;
          return a.key.compareTo(b.key);
        });
      return bars.first.key + 1;
    }

    if (!result.timingWithinTolerance) {
      NoteResult? worst;
      var worstError = -1.0;
      for (final note in result.notes) {
        final error = note.onsetErrorMs;
        if (error == null) continue;
        final magnitude = error.abs();
        if (magnitude > worstError) {
          worstError = magnitude;
          worst = note;
        }
      }
      if (worst != null) {
        final target = prompt.targetForIndex(worst.targetIndex);
        if (target != null) return target.bar + 1;
      }
    }

    return null;
  }

  double _maxConfidence(List<NoteResult> notes) {
    var max = 0.0;
    for (final note in notes) {
      if (note.confidence > max) max = note.confidence;
    }
    return max;
  }

  String _correction({
    required PhrasePlayPrompt prompt,
    required PhraseResult result,
    required bool confident,
    required int? worstBar,
  }) {
    if (!result.complete || result.outcome == AttemptOutcome.indeterminate) {
      return 'Could not hear the whole phrase — try again.';
    }

    if (!confident) {
      return 'Not quite. Play it once more and listen for the bar that slipped.';
    }

    final wrong = _worstWrongNote(result, prompt);
    if (wrong != null) {
      final bar = worstBar ?? wrong.target.displayBar;
      final expected = wrong.target.writtenNote.display;
      final actual = _soundingDisplay(
        wrong.note.detectedMidi,
        preferFlats: wrong.target.writtenNote.accidental == Accidental.flat,
      );
      return 'Bar $bar: $expected came out $actual';
    }

    if (result.extraNotes > 0) {
      return 'Extra notes slipped in. Play only the written notes and leave space.';
    }

    if (!result.timingWithinTolerance) {
      final issue = result.timingIssue ?? 'rushed';
      final advice = issue == 'dragged'
          ? 'Keep the pulse moving.'
          : 'Slow down and keep the pulse.';
      if (worstBar == null) {
        return '${_capitalize(issue)}. $advice';
      }
      return 'Bar $worstBar $issue. $advice';
    }

    if (!result.intonationInTune) {
      return 'Clean take. Keep this tempo and center each note.';
    }
    return 'Clean take. Keep this tempo and add the next bar.';
  }

  ({PhrasePlayTarget target, NoteResult note})? _worstWrongNote(
    PhraseResult result,
    PhrasePlayPrompt prompt,
  ) {
    final bars = <int, List<NoteResult>>{};
    for (final note in result.notes) {
      if (note.outcome != AttemptOutcome.incorrect) continue;
      final target = prompt.targetForIndex(note.targetIndex);
      if (target == null) continue;
      bars.putIfAbsent(target.bar, () => <NoteResult>[]).add(note);
    }
    if (bars.isEmpty) return null;

    final candidates = bars.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.length.compareTo(a.value.length);
        if (byCount != 0) return byCount;
        final byConfidence = _maxConfidence(b.value)
            .compareTo(_maxConfidence(a.value));
        if (byConfidence != 0) return byConfidence;
        return a.key.compareTo(b.key);
      });
    final chosen = candidates.first.value.toList()
      ..sort((a, b) {
        final byConfidence = b.confidence.compareTo(a.confidence);
        if (byConfidence != 0) return byConfidence;
        return a.targetIndex.compareTo(b.targetIndex);
      });
    final note = chosen.first;
    final target = prompt.targetForIndex(note.targetIndex);
    if (target == null) return null;
    return (target: target, note: note);
  }

  String _soundingDisplay(int? soundingMidi, {required bool preferFlats}) {
    if (soundingMidi == null) return 'a different note';
    // Guitar notation is written an octave above sounding pitch.
    final written = Note.fromMidi(soundingMidi + 12, preferFlats: preferFlats);
    return written.display;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
