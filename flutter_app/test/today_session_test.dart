import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/pieces/phrase_objectives.dart';
import 'package:hear_me_out/core/audio/phrase_scorer.dart';
import 'package:hear_me_out/core/audio/scored_take_gate.dart';
import 'package:hear_me_out/core/learning/note_objective.dart';
import 'package:hear_me_out/core/learning/practice_session.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/skill.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/features/today/today_content.dart';
import 'package:hear_me_out/features/today/today_controller.dart';
import 'package:hear_me_out/state/app_controller.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';
import 'support/phrase_fixtures.dart';

void main() {
  final noteTarget = noteObjective(Note.parse('E4'));

  PhraseResult phraseResult({
    AttemptOutcome outcome = AttemptOutcome.correct,
    bool complete = true,
    double accuracy = 1,
  }) {
    return PhraseResult(
      outcome: outcome,
      notes: const [],
      noteAccuracy: accuracy,
      medianCents: 0,
      meanOnsetErrorMs: 0,
      driftMsPerBar: 0,
      timingWithinTolerance: true,
      complete: complete,
      timingIssue: null,
      practicePass: true,
      performanceReady: true,
      extraNotes: 0,
      falseStart: false,
      earlyStop: false,
      timingToleranceMs: 80,
      intonationInTune: true,
    );
  }

  MemoryProgressStore freshStore() => MemoryProgressStore(
    ProgressState.fresh(settings: const AppSettings(onboardingComplete: true)),
  );

  MemoryProgressStore storeWithLearnedSkills(DateTime now) {
    return MemoryProgressStore(
      ProgressState(
        settings: const AppSettings(onboardingComplete: true),
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
      ),
    );
  }

  Future<ProviderContainer> makeContainer({
    required MemoryProgressStore store,
    DateTime Function()? clock,
    bool performanceDay = false,
    ScoredTakeGate gate = const ScoredTakeGate(),
    PhraseObjectiveRegistry? registry,
  }) async {
    final container = ProviderContainer(
      overrides: [
        progressStoreProvider.overrideWithValue(store),
        soundServiceProvider.overrideWithValue(FakeSoundService()),
        todayClockProvider.overrideWithValue(
          clock ?? () => DateTime(2026, 11, 6, 10),
        ),
        todayPerformanceDayProvider.overrideWithValue(performanceDay),
        todayScoredTakeGateProvider.overrideWithValue(gate),
        todayPhraseRegistryProvider.overrideWithValue(
          registry ?? PhraseObjectiveRegistry(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(appControllerProvider.future);
    return container;
  }

  group('Today plan', () {
    test('5, 10, and 20 minute plans total the selected length', () async {
      final container = await makeContainer(store: freshStore());
      final controller = container.read(todayControllerProvider.notifier);

      expect(
        container.read(todayControllerProvider).session.length,
        PracticeSessionLength.five,
      );

      for (final length in PracticeSessionLength.values) {
        controller.setLength(length);
        final session = container.read(todayControllerProvider).session;
        expect(session.length, length);
        expect(session.totalDuration, length.duration);
        expect(
          session.blocks.fold(
            Duration.zero,
            (total, block) => total + block.budget,
          ),
          length.duration,
        );
      }
    });

    test('the 5-minute plan shows at least 3 minutes of guitar time', () async {
      final container = await makeContainer(store: freshStore());
      final session = container.read(todayControllerProvider).session;

      expect(session.instrumentTime, const Duration(seconds: 210));
      expect(
        session.instrumentTime,
        greaterThanOrEqualTo(const Duration(minutes: 3)),
      );
      expect(
        session.blocks
            .where((block) => block.countsInstrumentTime)
            .fold(Duration.zero, (total, block) => total + block.budget),
        session.instrumentTime,
      );
    });

    test('changing length keeps the one target', () async {
      final container = await makeContainer(store: freshStore());
      final controller = container.read(todayControllerProvider.notifier);
      final target = container.read(todayControllerProvider).session.target;

      controller.setLength(PracticeSessionLength.twenty);

      final session = container.read(todayControllerProvider).session;
      expect(session.target, target);
      expect(
        session.blocks.every((block) => block.target == session.target),
        isTrue,
      );
    });

    test(
      'a maintenance day adds the learned phrase and reaches 6 minutes',
      () async {
        final now = DateTime(2026, 11, 6, 10);
        final container = await makeContainer(
          store: storeWithLearnedSkills(now),
          clock: () => now,
        );
        final controller = container.read(todayControllerProvider.notifier);
        final before = container.read(todayControllerProvider).session;

        expect(before.totalDuration, const Duration(minutes: 5));
        expect(before.maintenanceTarget, isNotNull);

        controller.setMaintenanceDay(true);

        final session = container.read(todayControllerProvider).session;
        expect(session.totalDuration, const Duration(minutes: 6));
        expect(session.blocks.last.role, PracticeBlockRole.maintenance);
        expect(session.blocks.last.target, session.maintenanceTarget);
        expect(session.instrumentTime, const Duration(minutes: 4, seconds: 30));
      },
    );

    test(
      'a maintenance day without a learned target stays 5 minutes',
      () async {
        final container = await makeContainer(store: freshStore());
        final controller = container.read(todayControllerProvider.notifier);

        controller.setMaintenanceDay(true);

        final session = container.read(todayControllerProvider).session;
        expect(session.maintenanceTarget, isNull);
        expect(session.totalDuration, const Duration(minutes: 5));
        expect(session.isMaintenanceDay, isFalse);
      },
    );
  });

  group('Today clock', () {
    test(
      'start, tick, pause, and resume use only the supplied clock',
      () async {
        final start = DateTime(2026, 11, 6, 10);
        var now = start;
        final container = await makeContainer(
          store: freshStore(),
          clock: () => now,
        );
        final controller = container.read(todayControllerProvider.notifier);

        controller.start();
        now = start.add(const Duration(seconds: 10));
        controller.tick();
        expect(
          container.read(todayControllerProvider).session.elapsed,
          const Duration(seconds: 10),
        );
        expect(
          container.read(todayControllerProvider).session.instrumentElapsed,
          Duration.zero,
        );

        controller.pause();
        now = start.add(const Duration(seconds: 40));
        controller.tick();
        expect(
          container.read(todayControllerProvider).session.elapsed,
          const Duration(seconds: 10),
        );

        controller.resume();
        now = start.add(const Duration(seconds: 50));
        controller.tick();
        expect(
          container.read(todayControllerProvider).session.elapsed,
          const Duration(seconds: 20),
        );
      },
    );

    test('pausing across the stop point records completion once', () async {
      final start = DateTime(2026, 11, 6, 10);
      var now = start;
      final store = freshStore();
      final container = await makeContainer(store: store, clock: () => now);
      final controller = container.read(todayControllerProvider.notifier);

      controller.start();
      now = start.add(const Duration(seconds: 299));
      controller.tick();
      expect(
        container.read(todayControllerProvider).session.isFinished,
        isFalse,
      );

      now = start.add(const Duration(seconds: 301));
      controller.pause();
      await Future<void>.delayed(Duration.zero);

      final state = container.read(todayControllerProvider);
      expect(state.session.isFinished, isTrue);
      expect(state.session.stopPointReached, isTrue);
      expect(state.completedRecorded, isTrue);
      expect(store.value!.daily.practice, 1);
      expect(store.value!.practiceSecondsByDay[dayKey(start)], 210);
    });

    test('many small ticks do not drift', () async {
      final start = DateTime(2026, 11, 6, 10);
      var now = start;
      final container = await makeContainer(
        store: freshStore(),
        clock: () => now,
      );
      final controller = container.read(todayControllerProvider.notifier);

      controller.start();
      for (var second = 1; second <= 100; second++) {
        now = start.add(Duration(seconds: second));
        controller.tick();
      }

      final session = container.read(todayControllerProvider).session;
      expect(session.elapsed, const Duration(seconds: 100));
      expect(session.instrumentElapsed, const Duration(seconds: 60));
      expect(session.currentIndex, 2);
      expect(session.currentBlockRemaining, const Duration(seconds: 20));
    });

    test('the stop point is clear and early end is safe', () async {
      final start = DateTime(2026, 11, 6, 10);
      var now = start;
      final store = freshStore();
      final container = await makeContainer(store: store, clock: () => now);
      final controller = container.read(todayControllerProvider.notifier);

      controller.start();
      now = start.add(const Duration(seconds: 90));
      controller.tick();
      await Future<void>.delayed(Duration.zero);

      controller.finishEarly();
      await Future<void>.delayed(Duration.zero);

      final state = container.read(todayControllerProvider);
      expect(state.session.isFinished, isTrue);
      expect(state.session.stopPointReached, isTrue);
      expect(state.earlyEnded, isTrue);
      expect(state.completedRecorded, isTrue);
      expect(state.session.instrumentElapsed, const Duration(seconds: 60));
      expect(store.value!.daily.practice, 1);

      controller.finishEarly();
      await Future<void>.delayed(Duration.zero);
      expect(store.value!.daily.practice, 1);
    });

    test('a paused session never counts the paused interval', () async {
      final start = DateTime(2026, 11, 6, 10);
      var now = start;
      final container = await makeContainer(
        store: freshStore(),
        clock: () => now,
      );
      final controller = container.read(todayControllerProvider.notifier);

      controller.start();
      controller.pause();
      now = start.add(const Duration(minutes: 2));
      controller.tick();
      controller.resume();
      now = start.add(const Duration(minutes: 2, seconds: 35));
      controller.tick();

      final session = container.read(todayControllerProvider).session;
      expect(session.elapsed, const Duration(seconds: 35));
      expect(session.instrumentElapsed, const Duration(seconds: 5));
    });
  });

  group('Today content', () {
    test('a note target has one synth preview and one read-along note', () {
      final registry = PhraseObjectiveRegistry();
      final view = resolveTodayTarget(noteTarget, registry);
      final preview = todaySynthPreview(noteTarget, registry);

      expect(view.title, 'E4');
      expect(view.note, isNotNull);
      expect(view.detail, contains('D string, fret 2'));
      expect(preview, isNotNull);
      expect(preview!.events, hasLength(1));
      expect(preview.events.single.midi, 52); // sounding E4
      expect(preview.label, contains('Synth preview'));
    });

    test(
      'a registered phrase target previews the phrase, not a human take',
      () {
        final registry = PhraseObjectiveRegistry()
          ..registerScore(loadCorpusScore('foundation/ode-to-joy.json'));
        final target = registry.resolvePhrase('ode-to-joy-p1');
        expect(target, isNotNull);

        final view = resolveTodayTarget(target!, registry);
        final preview = todaySynthPreview(target, registry);

        expect(view.hasPhrase, isTrue);
        expect(view.title, 'Theme, first half');
        expect(view.detail, contains('72 BPM'));
        expect(preview, isNotNull);
        expect(preview!.events.length, greaterThan(1));
        expect(preview.label, 'Theme, first half');
      },
    );
  });

  group('Today phrase evidence', () {
    test('a determinate gate-open take records phrase progress', () async {
      final store = freshStore();
      final container = await makeContainer(
        store: store,
        performanceDay: true,
        gate: const ScoredTakeGate(headphonesConfirmed: true),
      );
      final controller = container.read(todayControllerProvider.notifier);

      final saved = await controller.savePhraseResult(
        phraseId: 'ode-to-joy-p1',
        result: phraseResult(),
        tempoBpm: 72,
        pieceId: 'ode-to-joy',
        contentVersion: 1,
        correction: 'Bar 1: play F♯5 cleanly.',
      );

      expect(saved, isTrue);
      final state = container.read(todayControllerProvider);
      expect(state.lastTakeSaved, isTrue);
      expect(state.lastCorrection, 'Bar 1: play F♯5 cleanly.');
      final phrase = store.value!.phraseProgressFor('ode-to-joy-p1');
      expect(phrase, isNotNull);
      expect(phrase!.reps, 1);
      expect(phrase.correct, 1);
    });

    test('a gate-open non-performance day stays practice only', () async {
      final store = freshStore();
      final container = await makeContainer(
        store: store,
        gate: const ScoredTakeGate(headphonesConfirmed: true),
      );
      final controller = container.read(todayControllerProvider.notifier);

      final saved = await controller.savePhraseResult(
        phraseId: 'ode-to-joy-p1',
        result: phraseResult(),
        tempoBpm: 72,
        pieceId: 'ode-to-joy',
        contentVersion: 1,
      );

      expect(saved, isFalse);
      expect(container.read(todayControllerProvider).lastTakeSaved, isFalse);
      expect(store.value!.phraseProgressFor('ode-to-joy-p1'), isNull);
    });

    test('a gate-closed take is practice only and records nothing', () async {
      final store = freshStore();
      final container = await makeContainer(store: store);
      final controller = container.read(todayControllerProvider.notifier);

      final saved = await controller.savePhraseResult(
        phraseId: 'ode-to-joy-p1',
        result: phraseResult(),
        tempoBpm: 72,
        pieceId: 'ode-to-joy',
        contentVersion: 1,
      );

      expect(saved, isFalse);
      expect(container.read(todayControllerProvider).lastTakeSaved, isFalse);
      expect(store.value!.phraseProgressFor('ode-to-joy-p1'), isNull);
    });

    test(
      'an indeterminate take records nothing even with the gate open',
      () async {
        final store = freshStore();
        final container = await makeContainer(
          store: store,
          performanceDay: true,
          gate: const ScoredTakeGate(headphonesConfirmed: true),
        );
        final controller = container.read(todayControllerProvider.notifier);

        final saved = await controller.savePhraseResult(
          phraseId: 'ode-to-joy-p1',
          result: phraseResult(outcome: AttemptOutcome.indeterminate),
          tempoBpm: 72,
          pieceId: 'ode-to-joy',
          contentVersion: 1,
        );

        expect(saved, isFalse);
        expect(store.value!.phraseProgressFor('ode-to-joy-p1'), isNull);
      },
    );

    test(
      'an incomplete take records nothing even with the gate open',
      () async {
        final store = freshStore();
        final container = await makeContainer(
          store: store,
          performanceDay: true,
          gate: const ScoredTakeGate(headphonesConfirmed: true),
        );
        final controller = container.read(todayControllerProvider.notifier);

        final saved = await controller.savePhraseResult(
          phraseId: 'ode-to-joy-p1',
          result: phraseResult(complete: false),
          tempoBpm: 72,
          pieceId: 'ode-to-joy',
          contentVersion: 1,
        );

        expect(saved, isFalse);
        expect(store.value!.phraseProgressFor('ode-to-joy-p1'), isNull);
      },
    );
  });

  test(
    'the performance-day opt-in is off unless a caller asks for it',
    () async {
      final container = await makeContainer(store: freshStore());
      expect(container.read(todayControllerProvider).performanceDay, isFalse);

      final other = await makeContainer(
        store: freshStore(),
        performanceDay: true,
      );
      expect(other.read(todayControllerProvider).performanceDay, isTrue);
    },
  );
}
