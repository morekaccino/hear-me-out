import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/music/guitar.dart';
import 'package:hear_me_out/core/music/note.dart';

void main() {
  final g4 = Note.parse('G4');

  group('Note scheduling', () {
    test('a first correct answer moves to box 1 and waits ten minutes', () {
      final state = ProgressState.fresh();
      final now = DateTime(2026, 10, 31, 10);
      state.recordAnswer(
        note: g4,
        outcome: AttemptOutcome.correct,
        now: now,
        absCents: 12,
      );
      final note = state.progressFor(g4)!;
      expect(note.box, 1);
      expect(note.dueAt, now.add(const Duration(minutes: 10)));
      expect(note.correct, 1);
      expect(note.correctDays, contains('2026-10-31'));
      expect(note.averageAbsCents, 12);
    });

    test('a wrong answer drops two boxes and requeues in one minute', () {
      final now = DateTime(2026, 10, 31, 10);
      final note = NoteProgress(box: 4, correct: 5);
      note.recordAnswer(correctAnswer: false, now: now);
      expect(note.box, 2);
      expect(note.dueAt, now.add(const Duration(minutes: 1)));
      expect(note.incorrect, 1);
      expect(note.streak, 0);
    });

    test('a wrong answer never drops below box zero', () {
      final note = NoteProgress(box: 1);
      note.recordAnswer(correctAnswer: false, now: DateTime(2026, 10, 31));
      expect(note.box, 0);
    });

    test('box five is the maximum', () {
      final note = NoteProgress(box: 5);
      note.recordAnswer(correctAnswer: true, now: DateTime(2026, 10, 31));
      expect(note.box, 5);
    });

    test('mastery needs five correct answers across two days', () {
      final state = ProgressState.fresh();
      final dayOne = DateTime(2026, 10, 30, 10);
      final dayTwo = DateTime(2026, 10, 31, 10);
      for (var index = 0; index < 4; index++) {
        state.recordAnswer(
          note: g4,
          outcome: AttemptOutcome.correct,
          now: dayOne,
        );
      }
      expect(state.progressFor(g4)!.box, 4);
      expect(state.progressFor(g4)!.mastered, isFalse);

      state.recordAnswer(
        note: g4,
        outcome: AttemptOutcome.correct,
        now: dayTwo,
      );
      expect(state.progressFor(g4)!.box, 5);
      expect(state.progressFor(g4)!.mastered, isTrue);
      expect(state.masteredCount, 1);
    });

    test(
      'one day is not enough for mastery even with many correct answers',
      () {
        final state = ProgressState.fresh();
        final day = DateTime(2026, 10, 30, 10);
        for (var index = 0; index < 10; index++) {
          state.recordAnswer(
            note: g4,
            outcome: AttemptOutcome.correct,
            now: day,
          );
        }
        expect(state.progressFor(g4)!.mastered, isFalse);
      },
    );
  });

  group('XP, streak and completion', () {
    test('XP accumulates and resets the daily counter on a new day', () {
      final state = ProgressState.fresh();
      final dayOne = DateTime(2026, 10, 30, 10);
      final dayTwo = DateTime(2026, 10, 31, 10);
      state.addXp(10, dayOne);
      state.addXp(5, dayOne);
      expect(state.xp, 15);
      expect(state.xpToday, 15);
      state.addXp(10, dayTwo);
      expect(state.xp, 25);
      expect(state.xpToday, 10);
    });

    test('completing a lesson unlocks it and awards XP', () {
      final state = ProgressState.fresh();
      final now = DateTime(2026, 10, 31, 10);
      state.completeLesson(
        lessonId: 'u1l1',
        accuracy: 1,
        earnedXp: 15,
        answered: 10,
        now: now,
      );
      expect(state.isLessonCompleted('u1l1'), isTrue);
      expect(state.xp, 15);
      expect(state.streak, 1);
      expect(state.lastCompletedDay, '2026-10-31');
      expect(state.bestLessonAccuracy['u1l1'], 1);
      expect(state.recentSessions, hasLength(1));
    });

    test('streak counts once per day and continues the next day', () {
      final state = ProgressState.fresh();
      final dayOne = DateTime(2026, 10, 30, 10);
      final dayTwo = DateTime(2026, 10, 31, 10);
      final dayFour = DateTime(2026, 11, 2, 10);

      state.completeLesson(
        lessonId: 'u1l1',
        accuracy: 1,
        earnedXp: 10,
        answered: 10,
        now: dayOne,
      );
      state.completeLesson(
        lessonId: 'u1l2',
        accuracy: 1,
        earnedXp: 10,
        answered: 10,
        now: dayOne.add(const Duration(hours: 2)),
      );
      expect(state.streak, 1);

      state.completeLesson(
        lessonId: 'u1l3',
        accuracy: 1,
        earnedXp: 10,
        answered: 10,
        now: dayTwo,
      );
      expect(state.streak, 2);
      expect(state.bestStreak, 2);

      state.completeLesson(
        lessonId: 'u1l4',
        accuracy: 1,
        earnedXp: 10,
        answered: 10,
        now: dayFour,
      );
      expect(state.streak, 1);
      expect(state.bestStreak, 2);
    });

    test('a broken streak reads as zero until the next completed lesson', () {
      final state = ProgressState.fresh();
      state.completeLesson(
        lessonId: 'u1l1',
        accuracy: 1,
        earnedXp: 10,
        answered: 10,
        now: DateTime(2026, 10, 20, 10),
      );
      expect(state.effectiveStreakAt(DateTime(2026, 10, 21, 10)), 1);
      expect(state.effectiveStreakAt(DateTime(2026, 10, 23, 10)), 0);
    });

    test('a failed session is recorded but does not unlock the lesson', () {
      final state = ProgressState.fresh();
      state.recordFailedSession(
        lessonId: 'u1l1',
        accuracy: 0.4,
        answered: 4,
        now: DateTime(2026, 10, 31),
      );
      expect(state.isLessonCompleted('u1l1'), isFalse);
      expect(state.recentSessions.single.passed, isFalse);
      expect(state.xp, 0);
    });
  });

  group('Due and weak notes', () {
    test('due notes are ordered by their due time', () {
      final now = DateTime(2026, 10, 31, 12);
      final state = ProgressState.fresh();
      state.notes['G4'] = NoteProgress(
        dueAt: now.subtract(const Duration(days: 2)),
      );
      state.notes['E4'] = NoteProgress(
        dueAt: now.subtract(const Duration(hours: 1)),
      );
      state.notes['C5'] = NoteProgress(dueAt: now.add(const Duration(days: 1)));
      final due = state.dueNotes(now);
      expect(due.map((note) => note.id), ['G4', 'E4']);
    });

    test('weak notes require at least two attempts and low accuracy', () {
      final state = ProgressState.fresh();
      state.notes['G4'] = NoteProgress(correct: 1, incorrect: 3);
      state.notes['E4'] = NoteProgress(correct: 4, incorrect: 0);
      state.notes['C5'] = NoteProgress(correct: 0, incorrect: 1);
      final weak = state.weakNotes();
      expect(weak.map((note) => note.id), ['G4']);
    });
  });

  group('Curriculum integrity', () {
    test('every lesson id is unique', () {
      expect(
        allLessons.map((lesson) => lesson.id).toSet(),
        hasLength(allLessons.length),
      );
    });

    test('every unit is contiguous in the path', () {
      for (final unit in curriculum) {
        expect(unit.lessons, isNotEmpty);
        for (final lesson in unit.lessons) {
          expect(lesson.unitId, unit.id);
        }
      }
    });

    test('sections contain every unit exactly once', () {
      final sectionUnits = [
        for (final section in sections) ...section.units,
      ];
      expect(sectionUnits, curriculum);
      expect(curriculum, hasLength(40));
      expect(allLessons, hasLength(240));
    });

    test('every unit has six lessons and ends with a checkpoint', () {
      for (final unit in curriculum) {
        expect(unit.focus, isNotEmpty);
        expect(unit.lessons, hasLength(6), reason: unit.id);
        expect(unit.lessons.last.isReview, isTrue, reason: unit.id);
        expect(
          unit.lessons.where((lesson) => lesson.isReview),
          hasLength(1),
          reason: unit.id,
        );
      }
    });

    test('every curriculum note is playable within fifteen frets', () {
      for (final lesson in allLessons) {
        for (final note in [...lesson.newNotes, ...lesson.reviewNotes]) {
          expect(Note.tryParse(note.id), isNotNull);
          expect(
            Guitar.positionsFor(note, maxFret: 15),
            isNotEmpty,
            reason: note.id,
          );
        }
      }
    });
  });
}
