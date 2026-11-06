import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/lesson_run.dart';
import 'package:hear_me_out/core/music/curriculum.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/state/app_controller.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 11, 1, 12);

  group('Hearts', () {
    test('a fresh profile starts with five hearts and 500 gems', () {
      final state = ProgressState.fresh();
      expect(state.hearts, maxHearts);
      expect(state.gems, startingGems);
      expect(state.nextHeartAt, isNull);
    });

    test('losing a heart starts a four-hour refill timer', () {
      final state = ProgressState.fresh();
      expect(state.loseHeart(now), isTrue);
      expect(state.hearts, 4);
      expect(state.nextHeartAt, now.add(heartRegenInterval));
      state.refreshHearts(now.add(const Duration(hours: 3)));
      expect(state.hearts, 4);
      state.refreshHearts(now.add(const Duration(hours: 4)));
      expect(state.hearts, 5);
      expect(state.nextHeartAt, isNull);
    });

    test('hearts never go below zero', () {
      final state = ProgressState.fresh();
      for (var index = 0; index < maxHearts; index++) {
        expect(state.loseHeart(now), isTrue);
      }
      expect(state.hearts, 0);
      expect(state.loseHeart(now), isFalse);
    });

    test('a refill costs gems and fills all hearts', () {
      final state = ProgressState.fresh();
      state.loseHeart(now);
      state.loseHeart(now);
      expect(state.refillHearts(now), isTrue);
      expect(state.hearts, maxHearts);
      expect(state.gems, startingGems - heartRefillCost);
    });

    test('a refill is refused without enough gems', () {
      final state = ProgressState.fresh();
      state.gems = 0;
      state.loseHeart(now);
      expect(state.refillHearts(now), isFalse);
      expect(state.hearts, 4);
    });

    test('practice can restore one heart', () {
      final state = ProgressState.fresh();
      state.loseHeart(now);
      state.gainHeart(now);
      expect(state.hearts, maxHearts);
    });
  });

  group('Gems, freezes, and boosts', () {
    test('streak freezes cost gems and cap at two', () {
      final state = ProgressState.fresh();
      expect(state.buyStreakFreeze(), isTrue);
      expect(state.buyStreakFreeze(), isTrue);
      expect(state.streakFreezes, maxStreakFreezes);
      expect(state.buyStreakFreeze(), isFalse);
      expect(state.gems, startingGems - streakFreezeCost * 2);
    });

    test('a streak freeze protects one missed day', () {
      final state = ProgressState.fresh();
      final dayOne = DateTime(2026, 10, 30, 10);
      final dayThree = DateTime(2026, 11, 1, 10);
      state.completeLesson(
        lessonId: 'u1l1',
        accuracy: 1,
        earnedXp: 10,
        answered: 10,
        now: dayOne,
      );
      state.streakFreezes = 1;
      state.completeLesson(
        lessonId: 'u1l2',
        accuracy: 1,
        earnedXp: 10,
        answered: 10,
        now: dayThree,
      );
      expect(state.streak, 2);
      expect(state.streakFreezes, 0);
    });

    test('double XP doubles lesson and practice awards', () {
      final state = ProgressState.fresh();
      expect(state.buyXpBoost(now), isTrue);
      expect(state.xpMultiplierAt(now), 2);
      expect(state.xpMultiplierAt(now.add(const Duration(minutes: 16))), 1);
      expect(state.gems, startingGems - xpBoostCost);
    });
  });

  group('Chests', () {
    test('opening a chest awards gems once', () {
      final state = ProgressState.fresh();
      final chest = chestById['c3u1c1']!;
      expect(state.openChest(chest.id, chest.gems), isTrue);
      expect(state.gems, startingGems + chest.gems);
      expect(state.openedChests, contains(chest.id));
      expect(state.openChest(chest.id, chest.gems), isFalse);
      expect(state.gems, startingGems + chest.gems);
    });

    test('every unit has exactly one chest', () {
      for (final unit in curriculum) {
        expect(chestForUnit(unit.id), isNotNull, reason: unit.id);
      }
    });
  });

  group('Daily quests', () {
    test('correct answers advance the answer quest and can be claimed once', () {
      final state = ProgressState.fresh();
      final quest = dailyQuestDefinitions.firstWhere((q) => q.kind == 'correct');
      for (var index = 0; index < quest.target; index++) {
        state.recordAnswer(
          note: Note.parse('G4'),
          outcome: AttemptOutcome.correct,
          now: now,
        );
      }
      expect(state.questProgress(quest), quest.target);
      expect(state.claimQuest(quest, now), isTrue);
      expect(state.gems, startingGems + quest.rewardGems);
      expect(state.claimQuest(quest, now), isFalse);
    });

    test('a new day resets quest progress and claims', () {
      final state = ProgressState.fresh();
      final quest = dailyQuestDefinitions.firstWhere(
        (q) => q.kind == 'lessons',
      );
      state.completeLesson(
        lessonId: 'u1l1',
        accuracy: 1,
        earnedXp: 10,
        answered: 10,
        now: now,
      );
      expect(state.claimQuest(quest, now), isTrue);
      final tomorrow = now.add(const Duration(days: 1));
      state.refreshDaily(tomorrow);
      expect(state.questProgress(quest), 0);
      expect(state.isQuestClaimed(quest), isFalse);
    });
  });

  group('App mechanics', () {
    test('a chest opened through the controller is saved', () async {
      final store = MemoryProgressStore(ProgressState.fresh());
      final container = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      final notifier = container.read(appControllerProvider.notifier);
      expect(await notifier.openChest('c3u1c1'), isTrue);
      expect(store.value!.openedChests, contains('c3u1c1'));
      expect(store.value!.gems, startingGems + chestById['c3u1c1']!.gems);
    });

    test('a checkpoint does not spend hearts', () async {
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

      final before = container.read(appControllerProvider).requireValue.progress
          .hearts;
      final run = container
          .read(appControllerProvider)
          .requireValue
          .run!;
      expect(run.lesson.isReview, isTrue);
      await notifier.submitAnswer(correct: false);

      final after = container.read(appControllerProvider).requireValue;
      expect(after.progress.hearts, before);
      expect(after.run!.lives, before);
      expect(after.run!.lastCorrect, isFalse);
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
