import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/session_factory.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/prompt.dart';
import 'package:hear_me_out/core/learning/lesson_run.dart';
import 'package:hear_me_out/core/learning/session_shape.dart';
import 'package:hear_me_out/core/learning/session_validator.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/music/note.dart';

void main() {
  final now = DateTime(2026, 10, 31, 10);

  List<Prompt> session(
    String id, {
    ProgressState? progress,
    bool mic = true,
    AnswerMode mode = AnswerMode.mixed,
    int seed = 1,
  }) {
    return buildLessonSession(
      lesson: lessonById[id]!,
      progress: progress ?? ProgressState.fresh(),
      now: now,
      micAvailable: mic,
      mode: mode,
      random: Random(seed),
    );
  }

  List<NotePrompt> lesson(
    String id, {
    ProgressState? progress,
    bool mic = true,
    AnswerMode mode = AnswerMode.mixed,
    int seed = 1,
  }) {
    return session(
      id,
      progress: progress,
      mic: mic,
      mode: mode,
      seed: seed,
    ).whereType<NotePrompt>().toList();
  }

  test(
    'a two-note lesson is shorter so no note is asked six times',
    () {
      final prompts = session('u1l1');
      expect(prompts, hasLength(8));

      final newCounts = <String, int>{};
      for (final prompt in prompts.where((prompt) => prompt.isNew)) {
        newCounts[prompt.objective.id] =
            (newCounts[prompt.objective.id] ?? 0) + 1;
      }
      expect(newCounts['note:E4'], newNoteExposures);
      expect(newCounts['note:F4'], newNoteExposures);
    },
  );

  test('every new note is taught before it is tested', () {
    final exercises = lesson('u1l1');
    for (final id in ['E4', 'F4']) {
      final first = exercises.indexWhere((prompt) => prompt.note.id == id);
      expect(exercises[first].isTeach, isTrue, reason: id);
      final firstQuestion = exercises.indexWhere(
        (prompt) => prompt.note.id == id && prompt.isScored,
      );
      expect(firstQuestion, greaterThan(first), reason: id);
    }
  });

  test('a teach card is informational and never scored', () {
    final teach = lesson('u1l1').firstWhere((prompt) => prompt.isTeach);
    expect(teach.isScored, isFalse);
    expect(teach.choices, isEmpty);
  });

  test(
    'a note still learning keeps its teaching exposures after an early exit',
    () {
      final progress = ProgressState.fresh();
      progress.recordAnswer(
        note: Note.parse('E4'),
        correctAnswer: true,
        now: now,
      );
      final exercises = session('u1l1', progress: progress, mic: false);
      expect(
        exercises.where(
          (prompt) => prompt.objective.id == 'note:E4' && prompt.isNew,
        ),
        hasLength(newNoteExposures),
      );
    },
  );

  test('no two adjacent exercises use the same objective', () {
    final prompts = session('u1l1', seed: 2);
    for (var index = 1; index < prompts.length; index++) {
      expect(
        prompts[index].objective.id,
        isNot(prompts[index - 1].objective.id),
      );
    }
  });

  test('mixed mode teaches, then asks names, then plays', () {
    final exercises = lesson('u1l1', seed: 3);

    final firstE4 = exercises.firstWhere((prompt) => prompt.note.id == 'E4');
    expect(firstE4.isTeach, isTrue);

    final firstE4Question = exercises.firstWhere(
      (prompt) => prompt.note.id == 'E4' && prompt.isScored,
    );
    expect(firstE4Question.task, NoteTask.name);
    expect(firstE4Question.isGuided, isTrue);

    expect(
      exercises.where((exercise) => exercise.isPlay).length,
      greaterThanOrEqualTo(3),
    );
  });

  test('without mic permission every scored exercise is a naming exercise', () {
    final exercises = lesson('u1l1', mic: false, seed: 4);
    expect(
      exercises
          .where((exercise) => exercise.isScored)
          .every((exercise) => exercise.task == NoteTask.name),
      isTrue,
    );
  });

  test('name mode never produces play exercises', () {
    final exercises = lesson('u1l1', mode: AnswerMode.name, seed: 5);
    expect(exercises.every((exercise) => !exercise.isPlay), isTrue);
  });

  test('play mode uses the microphone for every scored exercise', () {
    final exercises = lesson('u1l1', mode: AnswerMode.play, seed: 6);
    expect(
      exercises
          .where((exercise) => exercise.isScored)
          .every((exercise) => exercise.isPlay),
      isTrue,
    );
  });

  test('scored naming exercises offer distinct choices including the answer', () {
    final exercises = lesson(
      'u1l1',
      mic: false,
      mode: AnswerMode.name,
      seed: 7,
    );
    for (final exercise in exercises.where((prompt) => prompt.isScored)) {
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

  test('guided attempts offer fewer, more distant options', () {
    final exercises = lesson('u1l1', mic: false, seed: 7);
    final guided = exercises.firstWhere((prompt) => prompt.isGuided);
    expect(guided.choices, hasLength(3));
    expect(guided.choices.any((note) => note.id == guided.note.id), isTrue);

    final distance = guided.choices
        .where((note) => note.id != guided.note.id)
        .map((note) => (note.diatonicIndex - guided.note.diatonicIndex).abs())
        .reduce((a, b) => a > b ? a : b);
    expect(distance, greaterThanOrEqualTo(2));
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

  test('a later lesson mixes its new notes with earlier notes', () {
    final progress = ProgressState.fresh();
    for (final note in [Note.parse('E4'), Note.parse('F4')]) {
      progress.recordAnswer(note: note, correctAnswer: true, now: now);
    }
    final exercises = lesson(
      'u1l2',
      progress: progress,
      mic: false,
      mode: AnswerMode.name,
      seed: 8,
    );
    final ids = exercises.map((exercise) => exercise.note.id).toSet();
    expect(ids, containsAll(['E4', 'F4', 'G4', 'A4']));
  });

  test('builder is deterministic for a seeded random source', () {
    List<String> build() => lesson('u1l4', seed: 9)
        .map((exercise) => '${exercise.note.id}:${exercise.task.name}')
        .toList();

    expect(build(), build());
  });

  test('practice uses learned notes and avoids silent empty sessions', () {
    final progress = ProgressState.fresh();
    progress.recordAnswer(
      note: Note.parse('G4'),
      correctAnswer: true,
      now: now,
    );
    progress.recordAnswer(
      note: Note.parse('A4'),
      correctAnswer: true,
      now: now,
    );
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

  test('every lesson builds a valid session', () {
    for (var index = 0; index < allLessons.length; index++) {
      final definition = allLessons[index];
      final prompts = buildLessonSession(
        lesson: definition,
        progress: ProgressState.fresh(),
        now: now,
        micAvailable: true,
        mode: AnswerMode.mixed,
        random: Random(100 + index),
      );
      final expectedLength = definition.isReview
          ? reviewExercisesPerLesson
          : exercisesPerLesson;
      expect(
        prompts.length,
        lessThanOrEqualTo(expectedLength),
        reason: definition.id,
      );
      expect(prompts.length, greaterThanOrEqualTo(8), reason: definition.id);

      final shape = SessionShape.standard(
        total: prompts.length,
        newObjectives:
            definition.newNotes.length.clamp(0, 2) + definition.teaches.length,
        exposures: definition.exposures,
      );
      expect(
        const SessionValidator().violations(prompts, shape: shape),
        isEmpty,
        reason: definition.id,
      );

      for (var exercise = 1; exercise < prompts.length; exercise++) {
        expect(
          prompts[exercise].objective.id,
          isNot(prompts[exercise - 1].objective.id),
          reason: definition.id,
        );
      }
      for (final prompt in prompts.whereType<NotePrompt>()) {
        if (!prompt.isScored) continue;
        expect(
          prompt.choices.any((choice) => choice.id == prompt.note.id),
          isTrue,
          reason: definition.id,
        );
      }
    }
  });

  test('a later lesson reserves review slots for earlier notes', () {
    final progress = ProgressState.fresh();
    progress.recordAnswer(
      note: Note.parse('E4'),
      correctAnswer: true,
      now: now,
    );
    progress.recordAnswer(
      note: Note.parse('F4'),
      correctAnswer: true,
      now: now,
    );
    final prompts = session(
      'u1l2',
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
    final progress = ProgressState.fresh();
    for (final note in [
      Note.parse('E4'),
      Note.parse('F4'),
      Note.parse('G4'),
      Note.parse('A4'),
    ]) {
      progress.recordAnswer(note: note, correctAnswer: true, now: now);
    }
    final prompts = session(
      'u1l3',
      progress: progress,
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

  test('mistakes are queued for an end-of-lesson retry', () {
    final exercises = lesson('u1l1', mic: false, mode: AnswerMode.name, seed: 23);
    final run = LessonRun(
      lesson: lessonById['u1l1']!,
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
    final exercises = lesson('u1l1', mic: false, mode: AnswerMode.name, seed: 23);
    final run = LessonRun(
      lesson: lessonById['u1l1']!,
      exercises: exercises,
      isPractice: false,
    );
    run.queueMistake(exercises.firstWhere((prompt) => prompt.isTeach));
    expect(run.pendingMistakes, 0);
  });

  test('retrying a teach card cannot produce a malformed prompt', () {
    final teach = lesson('u1l1').firstWhere((prompt) => prompt.isTeach);
    final retried = teach.retry();
    expect(retried.isTeach, isTrue);
    expect(retried.isScored, isFalse);
  });

  test('review lessons use the longer checkpoint length', () {
    final exercises = session(
      'u1l5',
      mic: false,
      mode: AnswerMode.name,
      seed: 24,
    );
    expect(exercises, hasLength(reviewExercisesPerLesson));
    expect(exercises.every((exercise) => !exercise.isNew), isTrue);
    expect(exercises.every((exercise) => !exercise.isTeach), isTrue);
  });

  test('practice falls back to lesson one notes on a fresh profile', () {
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
      exercises.every(
        (prompt) => ['note:E4', 'note:F4'].contains(prompt.objective.id),
      ),
      isTrue,
    );
  });
}
