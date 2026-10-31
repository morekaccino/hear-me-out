import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/session_builder.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/music/note.dart';

void main() {
  final now = DateTime(2026, 10, 31, 10);

  test(
    'the first lesson is ten exercises with three new exposures per note',
    () {
      final progress = ProgressState.fresh();
      final exercises = buildLessonExercises(
        lesson: lessonById['u1l1']!,
        progress: progress,
        now: now,
        micAvailable: true,
        mode: AnswerMode.mixed,
        random: Random(1),
      );

      expect(exercises, hasLength(exercisesPerLesson));
      final newCounts = <String, int>{};
      for (final exercise in exercises.where((exercise) => exercise.isNew)) {
        newCounts[exercise.note.id] = (newCounts[exercise.note.id] ?? 0) + 1;
      }
      expect(newCounts['E4'], 3);
      expect(newCounts['F4'], 3);
    },
  );

  test(
    'a note still learning keeps its teaching exposures after an early exit',
    () {
      final progress = ProgressState.fresh();
      progress.recordAnswer(
        note: Note.parse('E4'),
        correctAnswer: true,
        now: now,
      );
      final exercises = buildLessonExercises(
        lesson: lessonById['u1l1']!,
        progress: progress,
        now: now,
        micAvailable: false,
        mode: AnswerMode.name,
        random: Random(14),
      );
      expect(
        exercises.where(
          (exercise) => exercise.note.id == 'E4' && exercise.isNew,
        ),
        hasLength(3),
      );
    },
  );

  test('no two adjacent exercises use the same note', () {
    final progress = ProgressState.fresh();
    final exercises = buildLessonExercises(
      lesson: lessonById['u1l1']!,
      progress: progress,
      now: now,
      micAvailable: true,
      mode: AnswerMode.mixed,
      random: Random(2),
    );
    for (var index = 1; index < exercises.length; index++) {
      expect(exercises[index].note.id, isNot(exercises[index - 1].note.id));
    }
  });

  test(
    'mixed mode starts new notes with their names and includes play work',
    () {
      final progress = ProgressState.fresh();
      final exercises = buildLessonExercises(
        lesson: lessonById['u1l1']!,
        progress: progress,
        now: now,
        micAvailable: true,
        mode: AnswerMode.mixed,
        random: Random(3),
      );
      final firstE4 = exercises.firstWhere(
        (exercise) => exercise.note.id == 'E4' && exercise.newExposure == 0,
      );
      final firstF4 = exercises.firstWhere(
        (exercise) => exercise.note.id == 'F4' && exercise.newExposure == 0,
      );
      expect(firstE4.mode, AnswerMode.name);
      expect(firstF4.mode, AnswerMode.name);
      expect(
        exercises.where((exercise) => exercise.mode == AnswerMode.play).length,
        greaterThanOrEqualTo(3),
      );
    },
  );

  test('without mic permission every exercise is a naming exercise', () {
    final exercises = buildLessonExercises(
      lesson: lessonById['u1l1']!,
      progress: ProgressState.fresh(),
      now: now,
      micAvailable: false,
      mode: AnswerMode.mixed,
      random: Random(4),
    );
    expect(
      exercises.every((exercise) => exercise.mode == AnswerMode.name),
      isTrue,
    );
  });

  test('name mode never produces play exercises', () {
    final exercises = buildLessonExercises(
      lesson: lessonById['u1l1']!,
      progress: ProgressState.fresh(),
      now: now,
      micAvailable: true,
      mode: AnswerMode.name,
      random: Random(5),
    );
    expect(
      exercises.every((exercise) => exercise.mode == AnswerMode.name),
      isTrue,
    );
  });

  test('play mode uses the microphone for every exercise', () {
    final exercises = buildLessonExercises(
      lesson: lessonById['u1l1']!,
      progress: ProgressState.fresh(),
      now: now,
      micAvailable: true,
      mode: AnswerMode.play,
      random: Random(6),
    );
    expect(
      exercises.every((exercise) => exercise.mode == AnswerMode.play),
      isTrue,
    );
  });

  test(
    'every naming exercise has four distinct choices including the answer',
    () {
      final exercises = buildLessonExercises(
        lesson: lessonById['u1l1']!,
        progress: ProgressState.fresh(),
        now: now,
        micAvailable: false,
        mode: AnswerMode.name,
        random: Random(7),
      );
      for (final exercise in exercises) {
        expect(exercise.choices, hasLength(4));
        expect(exercise.choices.map((note) => note.id).toSet(), hasLength(4));
        expect(
          exercise.choices.any((note) => note.id == exercise.note.id),
          isTrue,
        );
      }
    },
  );

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
    final exercises = buildLessonExercises(
      lesson: lessonById['u1l2']!,
      progress: progress,
      now: now,
      micAvailable: false,
      mode: AnswerMode.name,
      random: Random(8),
    );
    final ids = exercises.map((exercise) => exercise.note.id).toSet();
    expect(ids, containsAll(['E4', 'F4', 'G4', 'A4']));
  });

  test('builder is deterministic for a seeded random source', () {
    List<String> build() => buildLessonExercises(
      lesson: lessonById['u1l4']!,
      progress: ProgressState.fresh(),
      now: now,
      micAvailable: true,
      mode: AnswerMode.mixed,
      random: Random(9),
    ).map((exercise) => '${exercise.note.id}:${exercise.mode.name}').toList();

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
      exercises.every((exercise) => ['G4', 'A4'].contains(exercise.note.id)),
      isTrue,
    );
    expect(
      exercises.where((exercise) => exercise.mode == AnswerMode.play).length,
      greaterThanOrEqualTo(3),
    );
  });

  test('every lesson builds a valid ten-exercise session', () {
    for (var index = 0; index < allLessons.length; index++) {
      final lesson = allLessons[index];
      final exercises = buildLessonExercises(
        lesson: lesson,
        progress: ProgressState.fresh(),
        now: now,
        micAvailable: true,
        mode: AnswerMode.mixed,
        random: Random(100 + index),
      );
      expect(exercises, hasLength(exercisesPerLesson), reason: lesson.id);
      for (var exercise = 1; exercise < exercises.length; exercise++) {
        expect(
          exercises[exercise].note.id,
          isNot(exercises[exercise - 1].note.id),
          reason: lesson.id,
        );
      }
      for (final exercise in exercises) {
        expect(exercise.choices, hasLength(4), reason: lesson.id);
        expect(
          exercise.choices.any((choice) => choice.id == exercise.note.id),
          isTrue,
          reason: lesson.id,
        );
        if (exercise.isNew && exercise.newExposure == 0) {
          expect(exercise.mode, AnswerMode.name, reason: lesson.id);
        }
      }
      final newCounts = <String, int>{};
      for (final exercise in exercises.where((exercise) => exercise.isNew)) {
        newCounts[exercise.note.id] = (newCounts[exercise.note.id] ?? 0) + 1;
      }
      for (final note in lesson.newNotes) {
        if (newCounts.containsKey(note.id)) {
          expect(newCounts[note.id], 3, reason: '${lesson.id} ${note.id}');
        }
      }
    }
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
      exercises.every((exercise) => ['E4', 'F4'].contains(exercise.note.id)),
      isTrue,
    );
  });
}
