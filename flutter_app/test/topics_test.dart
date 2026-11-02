import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/session_factory.dart';
import 'package:hear_me_out/core/learning/objective.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/prompt.dart';
import 'package:hear_me_out/core/learning/verifier.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/music/rhythm.dart';

void main() {
  final now = DateTime(2026, 11, 2, 9);

  List<Prompt> sessionFor(String id, {int seed = 1}) {
    return buildLessonSession(
      lesson: lessonById[id]!,
      progress: ProgressState.fresh(),
      now: now,
      micAvailable: false,
      mode: AnswerMode.name,
      random: Random(seed),
    );
  }

  test('a new note meets several question shapes, not one repeated', () {
    final prompts = sessionFor('c3u4l1');
    final shapes = <String>{};
    for (final prompt in prompts) {
      if (prompt.objective.id != 'note:F4') continue;
      shapes.add(prompt.templateId);
    }
    expect(shapes.length, greaterThanOrEqualTo(3));
    expect(shapes, contains('note.teach'));
    expect(shapes, contains('note.name'));
  });

  test('every note lesson keeps five exposures per new note', () {
    final prompts = sessionFor('c3u4l1');
    final exposures = <String, int>{};
    for (final prompt in prompts.where((prompt) => prompt.isNew)) {
      exposures[prompt.objective.id] =
          (exposures[prompt.objective.id] ?? 0) + 1;
    }
    expect(exposures['note:F4'], 5);
    expect(exposures['note:A4'], 5);
  });

  test('theory lessons ask questions from the theory family', () {
    final prompts = sessionFor('c3u8l1');
    final newPrompts = prompts.where((prompt) => prompt.isNew).toList();
    expect(newPrompts, isNotEmpty);
    expect(
      newPrompts.every(
        (prompt) => prompt.objective.family == SkillFamily.theory,
      ),
      isTrue,
    );
    expect(prompts.any((prompt) => prompt.isTeach), isTrue);
  });

  test('chord lessons render a diagram with the question', () {
    final prompts = sessionFor('c3u16l1');
    final questions = prompts.whereType<ChoicePrompt>().toList();
    expect(questions, isNotEmpty);
    final chordQuestions = questions.where((prompt) => prompt.chord != null);
    expect(chordQuestions.length, greaterThanOrEqualTo(4));
    expect(
      chordQuestions.every(
        (prompt) => prompt.options.any((o) => o.id == prompt.correctId),
      ),
      isTrue,
    );
  });

  test('rhythm lessons produce tap patterns', () {
    final prompts = buildLessonSession(
      lesson: const LessonDefinition(
        id: 'test.rhythm',
        unitId: 'test',
        title: 'Rhythm',
        newNotes: [],
        reviewNotes: [],
        teaches: ['rhythm:quarters', 'rhythm:halves'],
        exposures: 5,
        exerciseCount: 12,
      ),
      progress: ProgressState.fresh(),
      now: now,
      micAvailable: false,
      mode: AnswerMode.name,
      random: Random(3),
    );
    expect(prompts, isNotEmpty);
    expect(prompts.every((prompt) => prompt is RhythmPrompt), isTrue);
    for (final prompt in prompts.whereType<RhythmPrompt>()) {
      expect(prompt.pattern.onsets, isNotEmpty);
    }
  });

  test('staff placement accepts the right line and rejects its neighbour', () {
    const prompt = StaffTapPrompt(
      objective: ObjectiveRef('note:E4', family: SkillFamily.noteReading),
      templateId: 'note.place',
      note: Note('E', 4),
    );
    const verifier = StaffTapVerifier();
    expect(
      verifier.verify(
        StaffAnswer(Note('E', 4).diatonicIndex),
        prompt,
      ).correct,
      isTrue,
    );
    expect(
      verifier.verify(
        StaffAnswer(Note('F', 4).diatonicIndex),
        prompt,
      ).correct,
      isFalse,
    );
  });

  test('fret finding accepts any correct position', () {
    const prompt = FretTapPrompt(
      objective: ObjectiveRef('note:E4', family: SkillFamily.noteReading),
      templateId: 'note.fretboard',
      note: Note('E', 4),
      maxFret: 4,
    );
    const verifier = FretTapVerifier();
    // Written E4 sounds E3: D string fret 2 in first position.
    expect(
      verifier.verify(const FretAnswer(string: 4, fret: 2), prompt).correct,
      isTrue,
    );
    expect(
      verifier.verify(const FretAnswer(string: 5, fret: 2), prompt).correct,
      isFalse,
    );
  });

  test('rhythm grading accepts clean taps and rejects a missed beat', () {
    const prompt = RhythmPrompt(
      objective: ObjectiveRef('rhythm:quarters', family: SkillFamily.rhythm),
      templateId: 'rhythm.tap',
      pattern: fourQuarters,
      question: 'Tap the rhythm',
    );
    const verifier = RhythmVerifier();
    expect(
      verifier.verify(const RhythmAnswer([0, 1, 2, 3]), prompt).correct,
      isTrue,
    );
    expect(
      verifier.verify(const RhythmAnswer([0, 1, 2, 2.5]), prompt).correct,
      isFalse,
    );
    expect(
      verifier
          .verify(const RhythmAnswer([0, 1, 2]), prompt)
          .correct,
      isFalse,
    );
  });

  test('choice grading compares option ids', () {
    const prompt = ChoicePrompt(
      objective: ObjectiveRef('key:G', family: SkillFamily.theory),
      templateId: 'theory.ask',
      question: 'How many sharps does G major have?',
      options: [ChoiceOption('a', '0'), ChoiceOption('b', '1')],
      correctId: 'b',
    );
    const verifier = ChoiceVerifier();
    expect(verifier.verify(const ChoiceAnswer('b'), prompt).correct, isTrue);
    expect(verifier.verify(const ChoiceAnswer('a'), prompt).correct, isFalse);
  });
}
