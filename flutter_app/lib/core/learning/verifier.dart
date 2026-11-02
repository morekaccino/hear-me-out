import '../music/guitar.dart';
import '../music/note.dart';
import 'objective.dart';
import 'prompt.dart';

/// A learner's response to one prompt.
sealed class Answer {
  const Answer();
}

final class ChoiceAnswer extends Answer {
  const ChoiceAnswer(this.optionId);

  final String optionId;
}

enum PitchOutcome { correct, wrong, octave }

final class PitchAnswer extends Answer {
  const PitchAnswer({required this.outcome, this.cents, this.detected});

  final PitchOutcome outcome;
  final double? cents;
  final Note? detected;
}

/// A tap on a staff position, identified by its diatonic index.
final class StaffAnswer extends Answer {
  const StaffAnswer(this.diatonicIndex);

  final int diatonicIndex;
}

/// A tap on a string and fret.
final class FretAnswer extends Answer {
  const FretAnswer({required this.string, required this.fret});

  final int string;
  final int fret;
}

/// Taps recorded in beats from the start of the pulse.
final class RhythmAnswer extends Answer {
  const RhythmAnswer(this.tapsInBeats);

  final List<double> tapsInBeats;
}

class VerifyResult {
  const VerifyResult({
    required this.correct,
    this.octaveError = false,
    this.detail,
    this.evidenced = const <ObjectiveRef>[],
  });

  final bool correct;
  final bool octaveError;
  final String? detail;

  /// Objectives this answer is evidence for. Usually one; a played note can
  /// later credit both the note and its fretboard position.
  final List<ObjectiveRef> evidenced;
}

abstract interface class Verifier {
  VerifyResult verify(Answer answer, Prompt prompt);
}

class NoteChoiceVerifier implements Verifier {
  const NoteChoiceVerifier();

  @override
  VerifyResult verify(Answer answer, Prompt prompt) {
    if (prompt is! NotePrompt || answer is! ChoiceAnswer) {
      assert(false, 'NoteChoiceVerifier received ${prompt.runtimeType}');
      return const VerifyResult(correct: false);
    }
    return VerifyResult(
      correct: answer.optionId == prompt.note.id,
      evidenced: [prompt.objective],
    );
  }
}

class NotePitchVerifier implements Verifier {
  const NotePitchVerifier();

  @override
  VerifyResult verify(Answer answer, Prompt prompt) {
    if (prompt is! NotePrompt || answer is! PitchAnswer) {
      assert(false, 'NotePitchVerifier received ${prompt.runtimeType}');
      return const VerifyResult(correct: false);
    }
    final pitch = answer;
    return VerifyResult(
      correct: pitch.outcome == PitchOutcome.correct,
      octaveError: pitch.outcome == PitchOutcome.octave,
      evidenced: [prompt.objective],
    );
  }
}

class StaffTapVerifier implements Verifier {
  const StaffTapVerifier();

  @override
  VerifyResult verify(Answer answer, Prompt prompt) {
    if (prompt is! StaffTapPrompt || answer is! StaffAnswer) {
      return const VerifyResult(correct: false);
    }
    return VerifyResult(
      correct: answer.diatonicIndex == prompt.note.diatonicIndex,
      detail: '${prompt.note.display} sits at staff step '
          '${prompt.note.diatonicIndex}.',
      evidenced: [prompt.objective],
    );
  }
}

class FretTapVerifier implements Verifier {
  const FretTapVerifier();

  @override
  VerifyResult verify(Answer answer, Prompt prompt) {
    if (prompt is! FretTapPrompt || answer is! FretAnswer) {
      return const VerifyResult(correct: false);
    }
    final correct = Guitar.positionsFor(
      prompt.note,
      maxFret: prompt.maxFret,
    ).any(
      (position) =>
          position.string.number == answer.string && position.fret == answer.fret,
    );
    return VerifyResult(correct: correct, evidenced: [prompt.objective]);
  }
}

class ChoiceVerifier implements Verifier {
  const ChoiceVerifier();

  @override
  VerifyResult verify(Answer answer, Prompt prompt) {
    if (prompt is! ChoicePrompt || answer is! ChoiceAnswer) {
      return const VerifyResult(correct: false);
    }
    return VerifyResult(
      correct: answer.optionId == prompt.correctId,
      evidenced: [prompt.objective],
    );
  }
}

/// Grades taps against a pattern's onsets, ignoring small timing errors.
class RhythmVerifier implements Verifier {
  const RhythmVerifier({this.toleranceBeats = 0.28});

  final double toleranceBeats;

  @override
  VerifyResult verify(Answer answer, Prompt prompt) {
    if (prompt is! RhythmPrompt || answer is! RhythmAnswer) {
      return const VerifyResult(correct: false);
    }
    final expected = prompt.pattern.onsets;
    final taps = [...answer.tapsInBeats]..sort();

    if (taps.length != expected.length) {
      return VerifyResult(
        correct: false,
        detail: '${expected.length} taps expected, ${taps.length} heard.',
        evidenced: [prompt.objective],
      );
    }
    for (var index = 0; index < expected.length; index++) {
      if ((taps[index] - expected[index]).abs() > toleranceBeats) {
        return VerifyResult(
          correct: false,
          detail: 'One tap landed off the beat.',
          evidenced: [prompt.objective],
        );
      }
    }
    return VerifyResult(correct: true, evidenced: [prompt.objective]);
  }
}

/// Sends an answer to the verifier that matches its surface.
class PromptVerifier implements Verifier {
  const PromptVerifier();

  static const Verifier _choice = NoteChoiceVerifier();
  static const Verifier _pitch = NotePitchVerifier();
  static const Verifier _staff = StaffTapVerifier();
  static const Verifier _fret = FretTapVerifier();
  static const Verifier _option = ChoiceVerifier();
  static const Verifier _rhythm = RhythmVerifier();

  @override
  VerifyResult verify(Answer answer, Prompt prompt) {
    return switch (answer) {
      PitchAnswer() => _pitch.verify(answer, prompt),
      StaffAnswer() => _staff.verify(answer, prompt),
      FretAnswer() => _fret.verify(answer, prompt),
      RhythmAnswer() => _rhythm.verify(answer, prompt),
      ChoiceAnswer() => prompt is NotePrompt
          ? _choice.verify(answer, prompt)
          : _option.verify(answer, prompt),
    };
  }
}
