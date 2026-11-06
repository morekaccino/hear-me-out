import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/practice_session_factory.dart';
import 'package:hear_me_out/core/learning/lesson_run.dart';
import 'package:hear_me_out/core/learning/objective.dart';
import 'package:hear_me_out/core/learning/practice_session.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/prompt.dart';
import 'package:hear_me_out/core/learning/skill.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/music/note.dart';

void main() {
  const target = ObjectiveRef('note:E4', family: SkillFamily.noteReading);
  const learnedTarget = ObjectiveRef(
    'note:G4',
    family: SkillFamily.noteReading,
  );
  final start = DateTime(2026, 11, 6, 10);

  group('PracticeSession plan', () {
    test('5, 10, and 20 minute plans total their selected length', () {
      for (final length in PracticeSessionLength.values) {
        final session = PracticeSession(target: target, length: length);

        expect(
          session.totalDuration,
          Duration(minutes: length.minutes),
          reason: length.name,
        );
        expect(session.blocks, isNotEmpty);
        expect(
          session.blocks.fold(
            Duration.zero,
            (total, block) => total + block.budget,
          ),
          session.totalDuration,
        );
      }
    });

    test('5-minute plan follows the planned block order', () {
      final session = PracticeSession(target: target);

      expect(session.blocks.map((block) => block.role).toList(), [
        PracticeBlockRole.setup,
        PracticeBlockRole.technique,
        PracticeBlockRole.model,
        PracticeBlockRole.acquire,
        PracticeBlockRole.apply,
        PracticeBlockRole.reflect,
      ]);
      expect(session.blocks.first.isPreparation, isTrue);
      expect(session.blocks.first.countsInstrumentTime, isFalse);
    });

    test('10 and 20 minute plans add depth without a new session type', () {
      for (final length in [
        PracticeSessionLength.ten,
        PracticeSessionLength.twenty,
      ]) {
        final session = PracticeSession(target: target, length: length);

        expect(session.blocks.map((block) => block.role).toList(), [
          PracticeBlockRole.setup,
          PracticeBlockRole.technique,
          PracticeBlockRole.model,
          PracticeBlockRole.acquire,
          PracticeBlockRole.acquire,
          PracticeBlockRole.apply,
          PracticeBlockRole.reflect,
          PracticeBlockRole.maintenance,
        ], reason: length.name);
        expect(
          session.blocks.where(
            (block) => block.role == PracticeBlockRole.acquire,
          ),
          hasLength(2),
          reason: length.name,
        );
      }
    });

    test('the 5-minute plan leaves at least 3 minutes of guitar time', () {
      final session = PracticeSession(target: target);

      expect(
        session.instrumentTime,
        greaterThanOrEqualTo(const Duration(minutes: 3)),
      );
      expect(session.instrumentTime, const Duration(seconds: 210));
    });

    test('a maintenance day extends 5 minutes to 6 and adds the phrase', () {
      final standard = PracticeSession(target: target);
      final maintenance = PracticeSession(
        target: target,
        isMaintenanceDay: true,
        maintenanceTarget: learnedTarget,
      );

      expect(standard.totalDuration, const Duration(minutes: 5));
      expect(maintenance.totalDuration, const Duration(minutes: 6));
      expect(maintenance.blocks.length, standard.blocks.length + 1);

      final block = maintenance.blocks.last;
      expect(block.role, PracticeBlockRole.maintenance);
      expect(block.target, learnedTarget);
      expect(block.budget, const Duration(minutes: 1));
      expect(block.countsInstrumentTime, isTrue);
    });

    test('one target survives advancing every block', () {
      final session = PracticeSession(
        target: target,
        length: PracticeSessionLength.ten,
      );
      session.start(start);

      for (var index = 0; index < session.blocks.length; index++) {
        expect(session.target, target);
        expect(session.currentIndex, index);
        session.advance();
      }

      expect(session.isFinished, isTrue);
      expect(session.target, target);
      expect(session.stopPointReached, isTrue);
    });
  });

  group('PracticeSession clock', () {
    test('start, tick, pause, and resume use only the supplied clock', () {
      final session = PracticeSession(target: target);

      session.start(start);
      session.tick(start.add(const Duration(seconds: 10)));
      expect(session.elapsed, const Duration(seconds: 10));
      expect(session.instrumentElapsed, Duration.zero);

      session.pause(start.add(const Duration(seconds: 10)));
      session.tick(start.add(const Duration(seconds: 30)));
      expect(session.elapsed, const Duration(seconds: 10));
      expect(session.instrumentElapsed, Duration.zero);

      session.resume(start.add(const Duration(seconds: 30)));
      session.tick(start.add(const Duration(seconds: 40)));
      expect(session.elapsed, const Duration(seconds: 20));

      session.tick(start.add(const Duration(seconds: 60)));
      expect(session.elapsed, const Duration(seconds: 40));
      expect(session.instrumentElapsed, const Duration(seconds: 10));
    });

    test('many small ticks do not drift', () {
      final session = PracticeSession(target: target);
      session.start(start);

      for (var second = 1; second <= 100; second++) {
        session.tick(start.add(Duration(seconds: second)));
      }

      expect(session.elapsed, const Duration(seconds: 100));
      expect(session.instrumentElapsed, const Duration(seconds: 60));
      expect(session.currentIndex, 2);
      expect(session.currentBlockRemaining, const Duration(seconds: 20));
    });

    test('the stop point is reached when the full budget is used', () {
      final session = PracticeSession(target: target);
      session.start(start);
      session.tick(start.add(const Duration(minutes: 5)));

      expect(session.isFinished, isTrue);
      expect(session.stopPointReached, isTrue);
      expect(session.currentBlock, isNull);
      expect(session.progress, 1);
      expect(session.remaining, Duration.zero);
      expect(session.elapsed, const Duration(minutes: 5));
      expect(session.instrumentElapsed, const Duration(seconds: 210));

      session.tick(start.add(const Duration(minutes: 20)));
      expect(session.elapsed, const Duration(minutes: 5));
    });

    test('advancing past the last block is a clear manual stop point', () {
      final session = PracticeSession(target: target);
      session.start(start);

      while (!session.isFinished) {
        session.advance();
      }

      expect(session.isFinished, isTrue);
      expect(session.stopPointReached, isTrue);
      expect(session.remaining, Duration.zero);
      expect(session.progress, 1);
    });
  });

  group('content builder', () {
    ProgressState progressWithLearnedSkills() {
      final now = start;
      return ProgressState(
        skills: {
          'note:E4': SkillProgress(
            objectiveId: 'note:E4',
            family: SkillFamily.noteReading,
            reps: 2,
            correct: 1,
            incorrect: 1,
            dueAt: now.subtract(const Duration(minutes: 1)),
            lastSeenAt: now.subtract(const Duration(days: 2)),
          ),
          'note:G4': SkillProgress(
            objectiveId: 'note:G4',
            family: SkillFamily.noteReading,
            reps: 4,
            correct: 4,
            dueAt: now.add(const Duration(days: 7)),
            lastSeenAt: now.subtract(const Duration(days: 1)),
          ),
        },
      );
    }

    test('picks one due target and a learned maintenance target', () {
      final session = buildPracticeSession(
        progress: progressWithLearnedSkills(),
        now: start,
        isMaintenanceDay: true,
        random: Random(7),
      );

      expect(session.target.id, 'note:E4');
      expect(session.blocks.last.role, PracticeBlockRole.maintenance);
      expect(session.blocks.last.target.id, 'note:G4');
      expect(session.totalDuration, const Duration(minutes: 6));
    });

    test('is deterministic for a seeded random and fixed clock', () {
      final first = buildPracticeSession(
        progress: progressWithLearnedSkills(),
        now: start,
        length: PracticeSessionLength.ten,
        random: Random(42),
      );
      final second = buildPracticeSession(
        progress: progressWithLearnedSkills(),
        now: start,
        length: PracticeSessionLength.ten,
        random: Random(42),
      );

      expect(first.target.id, second.target.id);
      expect(
        first.blocks.map((block) => block.target.id).toList(),
        second.blocks.map((block) => block.target.id).toList(),
      );
    });

    test('a fresh profile still gets one non-empty target', () {
      final session = buildPracticeSession(
        progress: ProgressState.fresh(),
        now: start,
        random: Random(1),
      );

      expect(session.target.id, isNotEmpty);
      expect(session.target.family, SkillFamily.noteReading);
      expect(
        session.blocks
            .where((block) => block.role != PracticeBlockRole.maintenance)
            .every((block) => block.target == session.target),
        isTrue,
      );
    });
  });

  test('LessonRun keeps its lesson, lives, progress, and retry behavior', () {
    const lesson = LessonDefinition(
      id: 'test.lesson',
      unitId: 'test',
      title: 'Test lesson',
      newNotes: [],
      reviewNotes: [],
    );
    final prompt = NotePrompt(
      objective: target,
      templateId: 'note.ask',
      task: NoteTask.name,
      note: Note.parse('E4'),
    );
    final run = LessonRun(
      lesson: lesson,
      exercises: [prompt, prompt.retry()],
      isPractice: false,
    );

    expect(run.lives, livesPerLesson);
    expect(run.index, 0);
    expect(run.progress, 0);
    expect(run.stepLabel, 'Step 1 of 2');

    run.awaitingNext = true;
    expect(run.progress, 0.5);

    run.index = 1;
    run.awaitingNext = false;
    expect(run.progress, 0.5);

    run.correct = 2;
    expect(run.earnedXp, 15);
    expect(run.accuracy, 1);

    run.queueMistake(prompt);
    run.queueMistake(prompt.retry());
    expect(run.pendingMistakes, 1);
    expect(run.appendNextMistake(), isTrue);
    expect(run.exercises, hasLength(3));
  });
}
