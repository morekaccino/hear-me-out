import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/session_factory.dart';
import 'package:hear_me_out/core/learning/lesson_run.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/prompt.dart';
import 'package:hear_me_out/core/learning/session_shape.dart';
import 'package:hear_me_out/core/learning/session_validator.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/music/note.dart';

void main() {
  final now = DateTime(2026, 10, 31, 10);
  final e4 = Note.parse('E4');
  final f4 = Note.parse('F4');
  final g4 = Note.parse('G4');
  final a4 = Note.parse('A4');

  LessonDefinition noteLesson({
    String id = 'test.notes',
    List<Note> newNotes = const [],
    List<Note> reviewNotes = const [],
    bool isReview = false,
    int exerciseCount = 10,
  }) => LessonDefinition(
    id: id,
    unitId: 'test',
    title: id,
    newNotes: newNotes,
    reviewNotes: reviewNotes,
    exposures: 5,
    isReview: isReview,
    exerciseCount: exerciseCount,
  );

  final discover = noteLesson(
    newNotes: [e4, f4],
  );
  final later = noteLesson(
    id: 'test.later',
    newNotes: [g4, a4],
    reviewNotes: [e4, f4],
    exerciseCount: 14,
  );
  final checkpoint = noteLesson(
    id: 'test.checkpoint',
    reviewNotes: [e4, f4, g4, a4, Note.parse('C5'), Note.parse('D5')],
    isReview: true,
    exerciseCount: reviewExercisesPerLesson,
  );

  List<Prompt> sessionOf(
    LessonDefinition lesson, {
    ProgressState? progress,
    bool mic = true,
    AnswerMode mode = AnswerMode.mixed,
    int seed = 1,
  }) {
    return buildLessonSession(
      lesson: lesson,
      progress: progress ?? ProgressState.fresh(),
      now: now,
      micAvailable: mic,
      mode: mode,
      random: Random(seed),
    );
  }

  List<NotePrompt> notePromptsOf(
    LessonDefinition lesson, {
    ProgressState? progress,
    bool mic = true,
    AnswerMode mode = AnswerMode.mixed,
    int seed = 1,
  }) {
    return sessionOf(
      lesson,
      progress: progress,
      mic: mic,
      mode: mode,
      seed: seed,
    ).whereType<NotePrompt>().toList();
  }

  test('a two-note lesson gets five exposures per new note', () {
    final prompts = sessionOf(discover);
    expect(prompts, hasLength(10));
    final counts = <String, int>{};
    for (final prompt in prompts.where((prompt) => prompt.isNew)) {
      counts[prompt.objective.id] = (counts[prompt.objective.id] ?? 0) + 1;
    }
    expect(counts['note:E4'], 5);
    expect(counts['note:F4'], 5);
  });

  test('every new note is taught before it is tested', () {
    final exercises = notePromptsOf(discover);
    for (final note in [e4, f4]) {
      final first = exercises.indexWhere((p) => p.note.id == note.id);
      expect(exercises[first].isTeach, isTrue, reason: note.id);
      final firstQuestion = exercises.indexWhere(
        (p) => p.note.id == note.id && p.isScored,
      );
      expect(firstQuestion, greaterThan(first), reason: note.id);
    }
  });

  test('a teach card is informational and never scored', () {
    final teach = notePromptsOf(discover).firstWhere((p) => p.isTeach);
    expect(teach.isScored, isFalse);
    expect(teach.choices, isEmpty);
  });

  test('a note still learning keeps its exposures after an early exit', () {
    final progress = ProgressState.fresh();
    progress.recordAnswer(note: e4, outcome: AttemptOutcome.correct, now: now);
    final exercises = sessionOf(discover, progress: progress, mic: false);
    expect(
      exercises.where((p) => p.objective.id == 'note:E4' && p.isNew),
      hasLength(5),
    );
  });

  test('no two adjacent exercises use the same objective', () {
    final prompts = sessionOf(discover, seed: 2);
    for (var index = 1; index < prompts.length; index++) {
      expect(
        prompts[index].objective.id,
        isNot(prompts[index - 1].objective.id),
      );
    }
  });

  test('mixed mode teaches, asks names, then plays', () {
    final exercises = notePromptsOf(discover, seed: 3);
    final firstE4 = exercises.firstWhere((p) => p.note.id == 'E4');
    expect(firstE4.isTeach, isTrue);
    final firstQuestion = exercises.firstWhere(
      (p) => p.note.id == 'E4' && p.isScored,
    );
    expect(firstQuestion.task, NoteTask.name);
    expect(firstQuestion.isGuided, isTrue);
    expect(
      exercises.where((exercise) => exercise.isPlay).length,
      greaterThanOrEqualTo(3),
    );
  });

  test('without mic permission every scored exercise is naming', () {
    final exercises = notePromptsOf(discover, mic: false, seed: 4);
    expect(
      exercises
          .where((exercise) => exercise.isScored)
          .every((exercise) => exercise.task == NoteTask.name),
      isTrue,
    );
  });

  test('name mode never produces play exercises', () {
    final exercises = notePromptsOf(discover, mode: AnswerMode.name, seed: 5);
    expect(exercises.every((exercise) => !exercise.isPlay), isTrue);
  });

  test('play mode uses the microphone for every scored exercise', () {
    final exercises = notePromptsOf(discover, mode: AnswerMode.play, seed: 6);
    expect(
      exercises
          .where((exercise) => exercise.isScored)
          .every((exercise) => exercise.isPlay),
      isTrue,
    );
  });

  test('scored naming exercises offer distinct choices including the answer', () {
    final exercises = notePromptsOf(
      discover,
      mic: false,
      mode: AnswerMode.name,
      seed: 7,
    );
    for (final exercise in exercises.where((p) => p.isScored)) {
      expect(exercise.choices.length, greaterThanOrEqualTo(3));
      expect(
        exercise.choices.map((note) => note.id).toSet(),
        hasLength(exercise.choices.length),
      );
      expect(
        exercise.choices.any((note) => note.id == exercise.note.id),
        isTrue,
      );
    }
  });

  test('guided attempts offer three options including the answer', () {
    final exercises = notePromptsOf(discover, mic: false, seed: 7);
    final guided = exercises.firstWhere((p) => p.isGuided);
    expect(guided.choices, hasLength(3));
    expect(guided.choices.any((note) => note.id == guided.note.id), isTrue);
  });

  test('natural notes get natural-only answer choices', () {
    final choices = answerChoices(Note.parse('C5'), random: Random(12));
    expect(
      choices.every((note) => note.accidental == Accidental.natural),
      isTrue,
    );
  });

  test('accidental notes can include their natural neighbors', () {
    final choices = answerChoices(Note.parse('F#4'), random: Random(13));
    expect(choices.any((note) => note.id == 'F4'), isTrue);
  });

  test('a later lesson mixes new notes with earlier notes', () {
    final progress = ProgressState.fresh();
    for (final note in [e4, f4]) {
      progress.recordAnswer(note: note, outcome: AttemptOutcome.correct, now: now);
    }
    final exercises = notePromptsOf(
      later,
      progress: progress,
      mic: false,
      mode: AnswerMode.name,
      seed: 8,
    );
    final ids = exercises.map((exercise) => exercise.note.id).toSet();
    expect(ids, containsAll(['G4', 'A4', 'E4', 'F4']));
  });

  test('builder is deterministic for a seeded random source', () {
    List<String> build() => notePromptsOf(later, seed: 9)
        .map((exercise) => '${exercise.note.id}:${exercise.task.name}')
        .toList();
    expect(build(), build());
  });

  test('practice uses learned notes and avoids empty sessions', () {
    final progress = ProgressState.fresh();
    progress.recordAnswer(note: g4, outcome: AttemptOutcome.correct, now: now);
    progress.recordAnswer(note: a4, outcome: AttemptOutcome.correct, now: now);
    final exercises = buildPracticeExercises(
      kind: 'all',
      progress: progress,
      now: now,
      micAvailable: true,
      mode: AnswerMode.mixed,
      random: Random(10),
    );
    expect(exercises, hasLength(exercisesPerLesson));
    expect(
      exercises.every(
        (prompt) => ['note:G4', 'note:A4'].contains(prompt.objective.id),
      ),
      isTrue,
    );
    expect(
      exercises.where((prompt) => prompt.usesMicrophone).length,
      greaterThanOrEqualTo(3),
    );
  });

  test('practice on a fresh profile falls back to real notes', () {
    final exercises = buildPracticeExercises(
      kind: 'due',
      progress: ProgressState.fresh(),
      now: now,
      micAvailable: false,
      mode: AnswerMode.mixed,
      random: Random(11),
    );
    expect(exercises, hasLength(exercisesPerLesson));
    expect(
      exercises.every((prompt) => prompt.objective.id.startsWith('note:')),
      isTrue,
    );
  });

  test('review lessons use the checkpoint length and skip teach cards', () {
    final exercises = sessionOf(
      checkpoint,
      mic: false,
      mode: AnswerMode.name,
      seed: 24,
    );
    expect(
      exercises.length,
      inInclusiveRange(8, reviewExercisesPerLesson),
    );
    expect(exercises.every((exercise) => !exercise.isNew), isTrue);
    expect(exercises.every((exercise) => !exercise.isTeach), isTrue);
  });

  test('a later note lesson reserves review slots for earlier notes', () {
    final progress = ProgressState.fresh();
    progress.recordAnswer(note: e4, outcome: AttemptOutcome.correct, now: now);
    progress.recordAnswer(note: f4, outcome: AttemptOutcome.correct, now: now);
    final prompts = sessionOf(
      later,
      progress: progress,
      mic: false,
      mode: AnswerMode.name,
      seed: 21,
    );
    final review = prompts.where((prompt) => !prompt.isNew).toList();
    expect(review, hasLength(4));
    expect(
      review.every(
        (prompt) => ['note:E4', 'note:F4'].contains(prompt.objective.id),
      ),
      isTrue,
    );
  });

  test('same notes are spaced apart inside a lesson', () {
    final prompts = sessionOf(
      later,
      progress: ProgressState.fresh(),
      mic: false,
      mode: AnswerMode.name,
      seed: 22,
    );
    for (var index = 2; index < prompts.length; index++) {
      expect(
        prompts[index].objective.id,
        isNot(prompts[index - 2].objective.id),
        reason: 'exercise $index',
      );
    }
  });

  test('the validator accepts a well-formed note lesson', () {
    final prompts = sessionOf(discover);
    final shape = SessionShape.standard(
      total: prompts.length,
      newObjectives: 2,
      exposures: discover.exposures,
    );
    expect(const SessionValidator().violations(prompts, shape: shape), isEmpty);
  });

  test('mistakes are queued for an end-of-lesson retry', () {
    final exercises = notePromptsOf(
      discover,
      mic: false,
      mode: AnswerMode.name,
      seed: 23,
    );
    final run = LessonRun(
      lesson: discover,
      exercises: exercises,
      isPractice: false,
    );
    final missed = exercises.firstWhere((prompt) => prompt.isScored);
    run.queueMistake(missed);
    run.queueMistake(missed);
    expect(run.pendingMistakes, 1);
    expect(run.appendNextMistake(), isTrue);
    expect(run.pendingMistakes, 0);
    final appended = run.exercises.last as NotePrompt;
    expect(appended.note.id, missed.note.id);
    expect(appended.isNew, isFalse);
    expect(run.appendNextMistake(), isFalse);
  });

  test('teach cards are never queued as mistakes', () {
    final exercises = notePromptsOf(
      discover,
      mic: false,
      mode: AnswerMode.name,
      seed: 23,
    );
    final run = LessonRun(
      lesson: discover,
      exercises: exercises,
      isPractice: false,
    );
    run.queueMistake(exercises.firstWhere((prompt) => prompt.isTeach));
    expect(run.pendingMistakes, 0);
  });

  test('retrying a teach card cannot produce a malformed prompt', () {
    final teach = notePromptsOf(discover).firstWhere((p) => p.isTeach);
    final retried = teach.retry();
    expect(retried.isTeach, isTrue);
    expect(retried.isScored, isFalse);
  });
}
