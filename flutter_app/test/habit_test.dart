import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/app.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/storage/onboarding_store.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/features/lesson/lesson_screen.dart';
import 'package:hear_me_out/state/app_controller.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Weekly goal', () {
    test('defaults to 30 minutes and zero progress on a fresh profile', () {
      final state = ProgressState.fresh();
      final now = DateTime(2026, 11, 6, 12);
      expect(state.settings.weeklyGoalMinutes, 30);
      expect(state.weeklyPracticeMinutes(now), 0);
      expect(state.weeklyGoalProgress(now), 0);
      expect(state.weeklyPracticeGoalRemaining(now), 30);
    });

    test('uses only measured session seconds in the rolling seven days', () {
      final state = ProgressState.fresh();
      final now = DateTime(2026, 11, 6, 12);
      state.recordPracticeSeconds(300, now);
      state.recordPracticeSeconds(
        120,
        DateTime(2026, 11, 5, 12),
      );
      // Eight days ago is outside the window and must not count.
      state.recordPracticeSeconds(
        900,
        DateTime(2026, 10, 29, 12),
      );

      expect(state.weeklyPracticeMinutes(now), 7);
      expect(state.weeklyPracticeSeconds(now), 420);
      expect(state.activePracticeDays(now, days: 7), 2);
      expect(state.activePracticeDays(now), 3);
      expect(state.weeklyGoalProgress(now), closeTo(7 / 30, 1e-9));
      expect(state.weeklyPracticeGoalRemaining(now), 23);
    });

    test('the setting changes and persists', () {
      final state = ProgressState.fresh(
        settings: const AppSettings(weeklyGoalMinutes: 60),
      );
      final restored = ProgressState.fromJson(state.toJson());
      expect(restored.settings.weeklyGoalMinutes, 60);
      expect(restored.settings.weeklyGoalMinutes, isNot(30));
    });

    test('XP is not the habit goal', () {
      final state = ProgressState.fresh();
      final now = DateTime(2026, 11, 6, 12);
      state.addXp(500, now);
      expect(state.xp, 500);
      expect(state.weeklyPracticeMinutes(now), 0);
      expect(state.settings.toJson().containsKey('dailyGoalXp'), isFalse);
    });

    test('a fresh profile stores no heart fields', () {
      final json = ProgressState.fresh().toJson();
      expect(json.containsKey('hearts'), isFalse);
      expect(json.containsKey('nextHeartAt'), isFalse);
      expect(json.containsKey('streakFreezes'), isFalse);
      expect(json.containsKey('lastCompletedDay'), isFalse);
      expect(json['practiceSecondsByDay'], isEmpty);
    });
  });

  group('Optional streak', () {
    test('is off by default and does not advance', () {
      final state = ProgressState.fresh();
      final now = DateTime(2026, 11, 6, 12);
      state.recordPracticeEffort(
        now: now,
        instrumentTime: const Duration(minutes: 20),
      );
      expect(state.settings.streakEnabled, isFalse);
      expect(state.effectiveStreakAt(now), 0);
      expect(state.streak, 0);
      expect(state.lastPracticeDay, isNull);
      expect(state.weeklyPracticeMinutes(now), 20);
    });

    test('a disabled streak can be enabled and then counts effective days', () {
      final state = ProgressState.fresh(
        settings: const AppSettings(streakEnabled: true),
      );
      final dayOne = DateTime(2026, 11, 6, 12);
      final dayTwo = DateTime(2026, 11, 7, 12);

      state.recordPracticeEffort(
        now: dayOne,
        instrumentTime: const Duration(minutes: 2),
      );
      expect(state.effectiveStreakAt(dayOne), 0);

      state.recordPracticeEffort(
        now: dayOne,
        instrumentTime: const Duration(minutes: 1),
      );
      expect(state.effectiveStreakAt(dayOne), 1);

      state.recordPracticeEffort(
        now: dayOne,
        instrumentTime: const Duration(minutes: 10),
      );
      expect(state.effectiveStreakAt(dayOne), 1);
      expect(state.weeklyPracticeMinutes(dayOne), 13);

      state.recordPracticeEffort(
        now: dayTwo,
        instrumentTime: const Duration(minutes: 3),
      );
      expect(state.effectiveStreakAt(dayTwo), 2);
      expect(state.bestStreak, 2);
    });

    test('a missed day resets quietly and the next practice starts at one', () {
      final state = ProgressState.fresh(
        settings: const AppSettings(streakEnabled: true),
      );
      final dayOne = DateTime(2026, 11, 6, 12);
      final dayFour = DateTime(2026, 11, 9, 12);

      state.recordPracticeEffort(
        now: dayOne,
        instrumentTime: const Duration(minutes: 5),
      );
      expect(state.effectiveStreakAt(dayOne), 1);
      expect(state.effectiveStreakAt(dayFour), 0);
      expect(state.streak, 1);
      expect(state.bestStreak, 1);

      state.recordPracticeEffort(
        now: dayFour,
        instrumentTime: const Duration(minutes: 5),
      );
      expect(state.effectiveStreakAt(dayFour), 1);
      expect(state.lastPracticeDay, '2026-11-09');
    });

    test('one recorded take counts without inventing guitar minutes', () {
      final state = ProgressState.fresh(
        settings: const AppSettings(streakEnabled: true),
      );
      final now = DateTime(2026, 11, 6, 12);
      state.recordPracticeEffort(now: now, recordedTake: true);
      expect(state.effectiveStreakAt(now), 1);
      expect(state.weeklyPracticeMinutes(now), 0);
      expect(state.practiceSecondsByDay, isEmpty);
    });
  });

  group('Local measurement', () {
    test('completion and return use real sessions and practice days', () {
      final state = ProgressState.fresh();
      final now = DateTime(2026, 11, 6, 12);
      state.completeLesson(
        lessonId: 'c3u2l1',
        accuracy: 1,
        earnedXp: 10,
        answered: 10,
        now: now,
      );
      state.recordFailedSession(
        lessonId: 'c3u2l2',
        accuracy: 0.4,
        answered: 10,
        now: now,
      );
      state.recordPracticeSeconds(600, now);
      state.recordPracticeSeconds(300, DateTime(2026, 11, 4, 12));

      expect(state.sessionCompletionRate, 0.5);
      expect(state.returnRate(now), closeTo(2 / 14, 1e-9));
      expect(state.activePracticeDays(now), 2);
    });
  });

  group('Controller habit loop', () {
    test('a lesson with many wrong answers finishes and stays repeatable', () async {
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
      notifier.startLesson('c3u2l1', micAvailable: false);

      var guard = 0;
      while (container.read(appControllerProvider).requireValue.result == null &&
          guard < 40) {
        guard++;
        await notifier.submitAnswer(correct: false);
        await notifier.nextExercise();
      }

      final data = container.read(appControllerProvider).requireValue;
      expect(data.result, isNotNull);
      expect(data.result!.passed, isFalse);
      expect(data.progress.isLessonCompleted('c3u2l1'), isFalse);
      expect(data.progress.toJson().containsKey('hearts'), isFalse);
      expect(data.progress.toJson().containsKey('streakFreezes'), isFalse);
      expect(store.value!.toJson().containsKey('hearts'), isFalse);

      notifier.startLesson('c3u2l1', micAvailable: false);
      expect(container.read(appControllerProvider).requireValue.run, isNotNull);
      expect(container.read(appControllerProvider).requireValue.run!.index, 0);
    });

    test('weekly minutes come from measured session time', () async {
      var now = DateTime(2026, 11, 6, 12);
      final store = MemoryProgressStore(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
            streakEnabled: true,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          progressStoreProvider.overrideWithValue(store),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      final notifier = container.read(appControllerProvider.notifier);
      notifier.startLesson('c3u2l1', micAvailable: false);
      now = now.add(const Duration(minutes: 5));

      var guard = 0;
      while (container.read(appControllerProvider).requireValue.result == null &&
          guard < 40) {
        guard++;
        await notifier.submitAnswer(correct: true);
        await notifier.nextExercise();
      }

      final data = container.read(appControllerProvider).requireValue;
      expect(data.result, isNotNull);
      expect(data.result!.passed, isTrue);
      expect(data.result!.weeklyMinutes, 5);
      expect(data.result!.streakEnabled, isTrue);
      expect(data.progress.weeklyPracticeMinutes(now), 5);
      expect(data.progress.effectiveStreakAt(now), 1);
      expect(store.value!.weeklyPracticeMinutes(now), 5);
    });

    test('practice is always available and completion does not add a life', () async {
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

      notifier.startPractice(kind: 'all', micAvailable: false);
      final run = container.read(appControllerProvider).requireValue.run!;
      expect(run.isPractice, isTrue);
      expect(run.exercises, isNotEmpty);
      expect(
        container.read(appControllerProvider).requireValue.progress.toJson()
            .containsKey('hearts'),
        isFalse,
      );
    });
  });

  group('No heart UI', () {
    testWidgets('path, practice, profile, and shop contain no hearts', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = MemoryProgressStore(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
          ),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressStoreProvider.overrideWithValue(store),
            onboardingStoreProvider.overrideWithValue(FakeOnboardingStore()),
            audioEngineProvider.overrideWithValue(FakeAudioEngine()),
            pitchSourceFactoryProvider.overrideWithValue(
              FakePitchSourceFactory(permission: false).call,
            ),
            soundServiceProvider.overrideWithValue(FakeSoundService()),
          ],
          child: const HearMeOutApp(),
        ),
      );
      await tester.pumpAndSettle();

      void expectNoHearts() {
        expect(find.byIcon(Icons.favorite_rounded), findsNothing);
        expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
        expect(
          find.textContaining(
            RegExp('heart', caseSensitive: false),
            findRichText: true,
          ),
          findsNothing,
        );
        expect(find.text('Out of hearts'), findsNothing);
      }

      expectNoHearts();
      expect(find.text('0 / 30 min this week'), findsOneWidget);

      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();
      expectNoHearts();
      expect(find.text('This week'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expectNoHearts();
      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(find.text('Weekly goal'), findsOneWidget);
      expect(find.text('Practice streak'), findsOneWidget);
      expect(find.text('Hearts'), findsNothing);

      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();
      expectNoHearts();
      expect(find.text('Double XP'), findsOneWidget);
      expect(find.text('Refill hearts'), findsNothing);
    });

    testWidgets('settings persist the weekly goal and opt-in streak', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = MemoryProgressStore(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
          ),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressStoreProvider.overrideWithValue(store),
            onboardingStoreProvider.overrideWithValue(FakeOnboardingStore()),
            audioEngineProvider.overrideWithValue(FakeAudioEngine()),
            pitchSourceFactoryProvider.overrideWithValue(
              FakePitchSourceFactory(permission: false).call,
            ),
            soundServiceProvider.overrideWithValue(FakeSoundService()),
          ],
          child: const HearMeOutApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(find.text('30 min'), findsOneWidget);

      await tester.tap(find.text('30 min'));
      await tester.pumpAndSettle();
      expect(store.value!.settings.weeklyGoalMinutes, 45);

      final streakSwitch = find.byType(Switch).first;
      await tester.tap(streakSwitch);
      await tester.pumpAndSettle();
      expect(store.value!.settings.streakEnabled, isTrue);
    });

    testWidgets('a failed lesson shows a neutral result with no heart copy', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = MemoryProgressStore(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          progressStoreProvider.overrideWithValue(store),
          pitchSourceFactoryProvider.overrideWithValue(
            FakePitchSourceFactory(permission: false).call,
          ),
          audioEngineProvider.overrideWithValue(FakeAudioEngine()),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(appControllerProvider.future);
      final notifier = container.read(appControllerProvider.notifier);
      notifier.startLesson('c3u2l1', micAvailable: false);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LessonScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
      expect(
        find.textContaining(RegExp('heart', caseSensitive: false)),
        findsNothing,
      );

      var guard = 0;
      while (container.read(appControllerProvider).requireValue.result == null &&
          guard < 40) {
        guard++;
        final run = container.read(appControllerProvider).requireValue.run!;
        if (run.current.isTeach) {
          await tester.tap(find.text('GOT IT'));
          await tester.pumpAndSettle();
          continue;
        }
        await notifier.submitAnswer(correct: false);
        await tester.pumpAndSettle();
        final finish = find.text('FINISH');
        await tester.tap(
          finish.evaluate().isNotEmpty ? finish : find.text('CONTINUE'),
        );
        await tester.pumpAndSettle();
      }

      expect(find.text('Not passed yet'), findsOneWidget);
      expect(find.text('Out of hearts'), findsNothing);
      expect(find.text('REFILL & RETRY'), findsNothing);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.text('TRY AGAIN'), findsOneWidget);
    });
  });
}
