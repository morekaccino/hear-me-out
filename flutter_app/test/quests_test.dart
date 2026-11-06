import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_scorer.dart';
import 'package:hear_me_out/core/learning/lesson_run.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/state/app_controller.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 11, 1, 12);

  const correctTake = PhraseResult(
    outcome: AttemptOutcome.correct,
    notes: [],
    noteAccuracy: 1,
    medianCents: 0,
    meanOnsetErrorMs: 0,
    driftMsPerBar: 0,
    timingWithinTolerance: true,
    complete: true,
    timingIssue: null,
    practicePass: true,
    performanceReady: true,
    extraNotes: 0,
    falseStart: false,
    earlyStop: false,
    timingToleranceMs: 80,
    intonationInTune: true,
  );

  PhraseAttempt phraseAttempt({
    required AttemptOutcome outcome,
    required DateTime at,
    String phraseId = 'twinkle.a',
    int bars = 2,
  }) =>
      PhraseAttempt(phraseId: phraseId, outcome: outcome, now: at, bars: bars);

  group('No currency economy', () {
    test('a fresh profile stores no hearts, gems, chests, or shop fields', () {
      final state = ProgressState.fresh();
      final json = state.toJson();
      for (final key in <String>[
        'hearts',
        'nextHeartAt',
        'streakFreezes',
        'gems',
        'xpBoostUntil',
        'openedChests',
        'claimedQuests',
        'questDay',
      ]) {
        expect(json.containsKey(key), isFalse, reason: key);
      }
      expect(state.quests.phrasesPracticed, 0);
      expect(state.quests.recordingsMade, 0);
      expect(state.quests.barsLearned, 0);
    });

    test('quests are musical and have no reward field', () {
      expect(
        questDefinitions.map((quest) => quest.title),
        containsAll(<String>[
          'Play 3 phrases',
          'Record a take',
          'Learn 4 bars',
        ]),
      );
      for (final quest in questDefinitions) {
        expect(quest.target, greaterThan(0));
        expect(quest.period, isA<QuestPeriod>());
      }
      expect(
        questDefinitions.where((q) => q.period == QuestPeriod.daily),
        hasLength(1),
      );
      expect(
        questDefinitions.where((q) => q.period == QuestPeriod.weekly),
        hasLength(2),
      );
    });

    test('the recording quest is honest while its producer is absent', () {
      final quest = questDefinitions.firstWhere((q) => q.kind == 'recordings');
      final state = ProgressState.fresh();
      expect(recordingFlowAvailable, isFalse);
      expect(quest.awaitingProducer, isTrue);
      expect(state.questProgress(quest), 0);
      expect(state.isQuestComplete(quest), isFalse);
    });
  });

  group('Musical quest counters', () {
    test('a determinate phrase increments the daily phrase quest', () {
      final state = ProgressState.fresh();
      state.recordPhraseAttempt(
        phraseAttempt(outcome: AttemptOutcome.correct, at: now),
      );
      final quest = questDefinitions.firstWhere((q) => q.kind == 'phrases');
      expect(state.quests.phrasesPracticed, 1);
      expect(state.questProgress(quest), 1);
    });

    test('an indeterminate phrase does not increment anything', () {
      final state = ProgressState.fresh();
      final before = state.toJson();
      state.recordPhraseAttempt(
        phraseAttempt(outcome: AttemptOutcome.indeterminate, at: now),
      );
      expect(state.toJson(), before);
      expect(state.quests.phrasesPracticed, 0);
      expect(state.quests.barsLearned, 0);
    });

    test('a correct take records each phrase bars once', () {
      final state = ProgressState.fresh();
      state.recordPhraseAttempt(
        phraseAttempt(outcome: AttemptOutcome.correct, at: now, bars: 4),
      );
      expect(state.quests.barsLearned, 4);
      expect(
        state.isQuestComplete(
          questDefinitions.firstWhere((q) => q.kind == 'bars'),
        ),
        isTrue,
      );

      // A second take of the same phrase must not add the same bars again.
      state.recordPhraseAttempt(
        phraseAttempt(
          outcome: AttemptOutcome.correct,
          at: now.add(const Duration(minutes: 5)),
          bars: 4,
        ),
      );
      expect(state.quests.barsLearned, 4);
      expect(state.quests.phrasesPracticed, 2);
    });

    test('an incorrect take neither adds bars nor claims them', () {
      final state = ProgressState.fresh();
      state.recordPhraseAttempt(
        phraseAttempt(outcome: AttemptOutcome.incorrect, at: now, bars: 4),
      );
      expect(state.quests.phrasesPracticed, 1);
      expect(state.quests.barsLearned, 0);
    });

    test('bars from different phrases add up', () {
      final state = ProgressState.fresh();
      state.recordPhraseAttempt(
        phraseAttempt(
          outcome: AttemptOutcome.correct,
          at: now,
          phraseId: 'twinkle.a',
          bars: 2,
        ),
      );
      state.recordPhraseAttempt(
        phraseAttempt(
          outcome: AttemptOutcome.correct,
          at: now,
          phraseId: 'twinkle.b',
          bars: 2,
        ),
      );
      expect(state.quests.barsLearned, 4);
    });

    test('recording is real only when the recording flow reports it', () {
      final state = ProgressState.fresh();
      final quest = questDefinitions.firstWhere((q) => q.kind == 'recordings');
      state.recordRecordingMade(now);
      expect(state.quests.recordingsMade, 1);
      expect(state.isQuestComplete(quest), isTrue);
    });
  });

  group('Quest resets', () {
    test('a new local day clears the daily phrase quest', () {
      final state = ProgressState.fresh();
      state.recordPhraseAttempt(
        phraseAttempt(outcome: AttemptOutcome.correct, at: now),
      );
      expect(state.quests.phrasesPracticed, 1);

      final tomorrow = now.add(const Duration(days: 1));
      state.refreshQuests(tomorrow);
      expect(state.quests.phrasesPracticed, 0);
      expect(state.quests.day, '2026-11-02');
    });

    test('a new week clears recordings and learned bars but not phrases', () {
      final state = ProgressState.fresh();
      state.recordPhraseAttempt(
        phraseAttempt(outcome: AttemptOutcome.correct, at: now, bars: 4),
      );
      state.recordRecordingMade(now);
      expect(state.quests.barsLearned, 4);
      expect(state.quests.recordingsMade, 1);

      // 2026-11-01 is a Sunday; the next day starts a new Monday week.
      final monday = DateTime(2026, 11, 2, 9);
      state.refreshQuests(monday);
      expect(state.quests.recordingsMade, 0);
      expect(state.quests.barsLearned, 0);
      expect(state.quests.phrasesPracticed, 0);
      expect(state.quests.week, '2026-11-02');
    });
  });

  group('Controller and storage', () {
    test(
      'a determinate controller take increments the phrase quest and saves',
      () async {
        final store = MemoryProgressStore(ProgressState.fresh());
        final container = ProviderContainer(
          overrides: [progressStoreProvider.overrideWithValue(store)],
        );
        addTearDown(container.dispose);
        await container.read(appControllerProvider.future);
        final notifier = container.read(appControllerProvider.notifier);

        final recorded = await notifier.recordPhraseResult(
          phraseId: 'twinkle.a',
          result: correctTake,
          tempoBpm: 60,
          now: now,
          bars: 2,
        );

        expect(recorded, isTrue);
        expect(store.value!.quests.phrasesPracticed, 1);
        expect(store.value!.quests.barsLearned, 2);
      },
    );

    test('an indeterminate controller take changes no quest counter', () async {
      final store = MemoryProgressStore(ProgressState.fresh());
      final container = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      final notifier = container.read(appControllerProvider.notifier);
      final before = store.value!.toJson();

      final recorded = await notifier.recordPhraseResult(
        phraseId: 'twinkle.a',
        result: const PhraseResult(
          outcome: AttemptOutcome.indeterminate,
          notes: [],
          noteAccuracy: 0,
          medianCents: null,
          meanOnsetErrorMs: null,
          driftMsPerBar: null,
          timingWithinTolerance: false,
          complete: false,
          timingIssue: null,
          practicePass: false,
          performanceReady: false,
          extraNotes: 0,
          falseStart: false,
          earlyStop: true,
          timingToleranceMs: 80,
          intonationInTune: false,
        ),
        tempoBpm: 60,
        now: now,
        bars: 2,
      );

      expect(recorded, isFalse);
      expect(store.value!.toJson(), before);
    });

    test('a recording reported by the controller is saved', () async {
      final store = MemoryProgressStore(ProgressState.fresh());
      final container = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      await container
          .read(appControllerProvider.notifier)
          .recordRecordingMade(now: now);
      expect(store.value!.quests.recordingsMade, 1);
    });
  });

  group('Lesson flow without a resource', () {
    test('a checkpoint wrong answer only lowers its score', () async {
      final store = MemoryProgressStore(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      final notifier = container.read(appControllerProvider.notifier);
      notifier.startLesson('c3u1l6', micAvailable: false);

      final run = container.read(appControllerProvider).requireValue.run!;
      expect(run.lesson.isReview, isTrue);
      await notifier.submitAnswer(correct: false);

      final after = container.read(appControllerProvider).requireValue;
      expect(after.run!.lastCorrect, isFalse);
      expect(after.run!.wrong, 1);
      expect(after.progress.xp, 0);
    });

    test('a passing jump test unlocks the earlier section', () async {
      final store = MemoryProgressStore(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      final notifier = container.read(appControllerProvider.notifier);
      notifier.startJumpTest(sectionId: 'c3s2', micAvailable: false);

      var run = container.read(appControllerProvider).requireValue.run!;
      expect(run.isJumpTest, isTrue);
      expect(run.exercises, hasLength(reviewExercisesPerLesson));

      while (container.read(appControllerProvider).requireValue.run != null) {
        run = container.read(appControllerProvider).requireValue.run!;
        await notifier.submitAnswer(correct: true);
        await notifier.nextExercise();
      }

      final data = container.read(appControllerProvider).requireValue;
      expect(data.result, isNotNull);
      expect(data.result!.passed, isTrue);
      for (final lesson in sections.first.units.expand((u) => u.lessons)) {
        expect(
          data.progress.completedLessons,
          contains(lesson.id),
          reason: lesson.id,
        );
      }
    });
  });
}
