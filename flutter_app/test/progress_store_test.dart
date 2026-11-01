import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/session_builder.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/state/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Progress serialization', () {
    test('all progress fields survive a JSON round trip', () {
      final progress = ProgressState.fresh(
        settings: const AppSettings(
          onboardingComplete: true,
          answerMode: AnswerMode.play,
          toleranceCents: 40,
          soundEffects: false,
          dailyGoalXp: 30,
        ),
      );
      final now = DateTime(2026, 10, 31, 10);
      progress.recordAnswer(
        note: Note.parse('G4'),
        correctAnswer: true,
        now: now,
        absCents: 8,
      );
      progress.completeLesson(
        lessonId: 'u1l1',
        accuracy: 0.9,
        earnedXp: 10,
        answered: 10,
        now: now,
      );

      final restored = ProgressState.fromJson(progress.toJson());
      expect(restored.settings.onboardingComplete, isTrue);
      expect(restored.settings.answerMode, AnswerMode.play);
      expect(restored.settings.toleranceCents, 40);
      expect(restored.settings.soundEffects, isFalse);
      expect(restored.notes['G4']!.correct, 1);
      expect(restored.notes['G4']!.averageAbsCents, 8);
      expect(restored.completedLessons, contains('u1l1'));
      expect(restored.bestLessonAccuracy['u1l1'], 0.9);
      expect(restored.recentSessions.single.lessonId, 'u1l1');
      expect(restored.gems, progress.gems);
      expect(restored.hearts, progress.hearts);
      expect(restored.daily.correct, 1);
      expect(restored.daily.lessons, 1);
    });

    test('export and import preserve progress', () {
      final progress = ProgressState.fresh();
      progress.addXp(25, DateTime(2026, 10, 31));
      final restored = importProgress(exportProgress(progress));
      expect(restored, isNotNull);
      expect(restored!.xp, 25);
    });

    test('old lesson ids migrate to the sectioned curriculum', () {
      final restored = ProgressState.fromJson({
        'schemaVersion': 1,
        'curriculumVersion': 1,
        'completedLessons': ['u1l1', 'u2l1', 'u2l2', 'u3l1', 'u4l1'],
        'bestLessonAccuracy': {'u2l1': 0.8, 'u2l2': 0.9, 'u3l1': 0.7},
      });
      expect(restored.curriculumVersion, ProgressState.currentCurriculumVersion);
      expect(
        restored.completedLessons,
        containsAll(['u1l1', 'u3l1', 'u4l1', 'u6l1']),
      );
      expect(restored.completedLessons, isNot(contains('u2l1')));
      expect(restored.bestLessonAccuracy['u3l1'], 0.9);
    });

    test('backups accept known schema versions and reject the rest', () {
      expect(importProgress('not json'), isNull);
      expect(importProgress('{"schemaVersion": 1}'), isNotNull);
      expect(importProgress('{"hello": "world"}'), isNull);
      expect(importProgress('{"schemaVersion": 2}'), isNotNull);
      expect(importProgress('{"schemaVersion": 3}'), isNull);
      expect(importProgress('{"schemaVersion": 0}'), isNull);
    });
  });

  group('SharedPreferencesProgressStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves and reloads progress', () async {
      final store = SharedPreferencesProgressStore();
      final progress = ProgressState.fresh(
        settings: const AppSettings(onboardingComplete: true),
      );
      progress.recordAnswer(
        note: Note.parse('A4'),
        correctAnswer: true,
        now: DateTime(2026, 10, 31),
      );
      await store.save(progress);

      final reloaded = await SharedPreferencesProgressStore().load();
      expect(reloaded, isNotNull);
      expect(reloaded!.notes['A4']!.correct, 1);
      expect(reloaded.settings.onboardingComplete, isTrue);
    });

    test('corrupt storage falls back to null instead of crashing', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesProgressStore.storageKey: '{broken json',
      });
      final reloaded = await SharedPreferencesProgressStore().load();
      expect(reloaded, isNull);
    });

    test('clear removes saved progress', () async {
      final store = SharedPreferencesProgressStore();
      await store.save(ProgressState.fresh());
      await store.clear();
      expect(await store.load(), isNull);
    });
  });

  group('AppController', () {
    test('onboarding settings are saved', () async {
      final store = MemoryProgressStore();
      final container = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      await container
          .read(appControllerProvider.notifier)
          .completeOnboarding(const AppSettings(dailyGoalXp: 30));
      expect(store.value!.settings.onboardingComplete, isTrue);
      expect(store.value!.settings.dailyGoalXp, 30);
    });

    test('a full lesson completes, awards XP, and persists', () async {
      final store = MemoryProgressStore();
      final container = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      await container
          .read(appControllerProvider.notifier)
          .completeOnboarding(const AppSettings(answerMode: AnswerMode.name));

      final notifier = container.read(appControllerProvider.notifier);
      notifier.startLesson('u1l1', micAvailable: false);

      for (var index = 0; index < exercisesPerLesson; index++) {
        final run = container.read(appControllerProvider).requireValue.run!;
        expect(run.current.mode, AnswerMode.name);
        await notifier.submitAnswer(correct: true);
        await notifier.nextExercise();
      }

      final data = container.read(appControllerProvider).requireValue;
      expect(data.result, isNotNull);
      expect(data.result!.passed, isTrue);
      expect(data.result!.xp, 15);
      expect(data.result!.answered, exercisesPerLesson);
      expect(data.progress.isLessonCompleted('u1l1'), isTrue);
      expect(data.progress.xp, 15);
      expect(data.progress.streak, 1);

      expect(store.value!.isLessonCompleted('u1l1'), isTrue);
      expect(store.value!.xp, 15);
    });

    test('progress survives a simulated app restart', () async {
      final store = MemoryProgressStore();
      final first = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(first.dispose);
      await first.read(appControllerProvider.future);
      await first
          .read(appControllerProvider.notifier)
          .completeOnboarding(const AppSettings(answerMode: AnswerMode.name));
      final notifier = first.read(appControllerProvider.notifier);
      notifier.startLesson('u1l1', micAvailable: false);
      for (var index = 0; index < exercisesPerLesson; index++) {
        await notifier.submitAnswer(correct: true);
        await notifier.nextExercise();
      }

      final second = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(second.dispose);
      final reloaded = await second.read(appControllerProvider.future);
      expect(reloaded.progress.isLessonCompleted('u1l1'), isTrue);
      expect(reloaded.progress.xp, 15);
      expect(reloaded.progress.streak, 1);
    });

    test('a missed note comes back at the end of the lesson', () async {
      final store = MemoryProgressStore();
      final container = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      await container
          .read(appControllerProvider.notifier)
          .completeOnboarding(const AppSettings(answerMode: AnswerMode.name));
      final notifier = container.read(appControllerProvider.notifier);
      notifier.startLesson('u1l1', micAvailable: false);

      final missed = container.read(appControllerProvider).requireValue.run!.current.note;
      await notifier.submitAnswer(correct: false);
      await notifier.nextExercise();
      for (var index = 1; index < exercisesPerLesson; index++) {
        await notifier.submitAnswer(correct: true);
        await notifier.nextExercise();
      }

      final beforeRetry = container.read(appControllerProvider).requireValue;
      expect(beforeRetry.result, isNull);
      final retryRun = beforeRetry.run!;
      expect(retryRun.isReviewingMistakes, isTrue);
      expect(retryRun.current.note.id, missed.id);

      await notifier.submitAnswer(correct: true);
      await notifier.nextExercise();
      final data = container.read(appControllerProvider).requireValue;
      expect(data.result, isNotNull);
      expect(data.result!.passed, isTrue);
      expect(data.result!.answered, exercisesPerLesson + 1);
    });

    test('a failed lesson does not unlock the next one', () async {
      final store = MemoryProgressStore();
      final container = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      await container
          .read(appControllerProvider.notifier)
          .completeOnboarding(const AppSettings(answerMode: AnswerMode.name));
      final notifier = container.read(appControllerProvider.notifier);
      notifier.startLesson('u1l1', micAvailable: false);
      for (var index = 0; index < livesPerLesson; index++) {
        await notifier.submitAnswer(correct: false);
        await notifier.nextExercise();
      }
      final data = container.read(appControllerProvider).requireValue;
      expect(data.result, isNotNull);
      expect(data.result!.passed, isFalse);
      expect(data.progress.isLessonCompleted('u1l1'), isFalse);
      expect(data.progress.xp, 0);
    });

    test('practice never spends lives and completes with XP', () async {
      final store = MemoryProgressStore();
      final container = ProviderContainer(
        overrides: [progressStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      await container
          .read(appControllerProvider.notifier)
          .completeOnboarding(const AppSettings(answerMode: AnswerMode.name));

      final notifier = container.read(appControllerProvider.notifier);
      notifier.startPractice(kind: 'all', micAvailable: false);
      for (var index = 0; index < 3; index++) {
        await notifier.submitAnswer(correct: false);
        await notifier.nextExercise();
      }

      final run = container.read(appControllerProvider).requireValue.run!;
      expect(run.lives, livesPerLesson);
      expect(run.index, 3);
      expect(run.isFinished, isFalse);

      for (var index = 3; index < exercisesPerLesson; index++) {
        await notifier.submitAnswer(correct: true);
        await notifier.nextExercise();
      }

      for (var index = 0; index < maxMistakeRetries; index++) {
        final remaining = container.read(appControllerProvider).requireValue.run;
        if (remaining == null) break;
        await notifier.submitAnswer(correct: true);
        await notifier.nextExercise();
      }

      final data = container.read(appControllerProvider).requireValue;
      expect(data.result, isNotNull);
      expect(data.result!.passed, isTrue);
      expect(data.result!.xp, 5);
      expect(data.progress.xp, 5);
      expect(store.value!.xp, 5);
    });
  });
}
