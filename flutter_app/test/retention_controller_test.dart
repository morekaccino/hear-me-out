import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/learning/prompt.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
import 'package:hear_me_out/state/app_controller.dart';
import 'package:hear_me_out/state/retention_controller.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith(MemoryRetentionStore store) {
    final container = ProviderContainer(
      overrides: [retentionStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  int count(MemoryRetentionStore store, RetentionEventName name) =>
      store.value.log.events.where((event) => event.name == name).length;

  Future<void> waitFor(bool Function() condition) async {
    for (var attempt = 0; attempt < 50 && !condition(); attempt++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(condition(), isTrue);
  }

  group('RetentionController', () {
    test('opt-in off records nothing and never saves', () async {
      final store = MemoryRetentionStore();
      final container = containerWith(store);
      await container.read(retentionControllerProvider.future);
      final controller = container.read(retentionControllerProvider.notifier);

      await controller.record(RetentionEventName.sessionStart);
      await controller.recordAppOpen();
      await controller.recordFirstNote();

      expect(store.value.log.events, isEmpty);
      expect(store.saveCount, 0);
      expect(
        container.read(retentionControllerProvider).requireValue.optIn,
        isFalse,
      );
    });

    test(
      'turning opt-in on persists and appOpen is once per local day',
      () async {
        final store = MemoryRetentionStore();
        final container = containerWith(store);
        await container.read(retentionControllerProvider.future);
        final controller = container.read(retentionControllerProvider.notifier);
        final day = DateTime(2026, 6, 1, 9);

        await controller.setOptIn(true, at: day);
        expect(store.value.optIn, isTrue);
        expect(store.value.log.installAt, day.toUtc());
        expect(count(store, RetentionEventName.appOpen), 1);

        await controller.recordAppOpen(at: day.add(const Duration(hours: 4)));
        expect(count(store, RetentionEventName.appOpen), 1);

        await controller.recordAppOpen(at: day.add(const Duration(days: 1)));
        expect(count(store, RetentionEventName.appOpen), 2);
      },
    );

    test(
      'turning opt-in off stops recording and erase clears events',
      () async {
        final store = MemoryRetentionStore(optIn: true);
        final container = containerWith(store);
        await container.read(retentionControllerProvider.future);
        final controller = container.read(retentionControllerProvider.notifier);
        await controller.record(RetentionEventName.sessionStart);
        await controller.record(RetentionEventName.sessionComplete);
        expect(store.value.log.events, hasLength(2));

        await controller.setOptIn(false);
        await controller.record(RetentionEventName.sessionStart);
        expect(store.value.log.events, hasLength(2));
        expect(store.value.optIn, isFalse);

        await controller.erase();
        expect(store.value.log.events, isEmpty);
        expect(store.value.optIn, isFalse);
        expect(store.value.log.installId, 'test-install');
        expect(
          container.read(retentionControllerProvider).requireValue.eventCount,
          0,
        );
      },
    );

    test('erase keeps opt-in and the install id', () async {
      final store = MemoryRetentionStore(
        optIn: true,
        installId: 'install-keep',
      );
      final container = containerWith(store);
      await container.read(retentionControllerProvider.future);
      final controller = container.read(retentionControllerProvider.notifier);
      await controller.recordAppOpen(at: DateTime(2026, 6, 4, 9));
      await controller.record(RetentionEventName.sessionStart);
      await controller.erase();

      expect(store.value.optIn, isTrue);
      expect(store.value.log.installId, 'install-keep');
      expect(store.value.log.installAt, isNotNull);
      expect(store.value.log.events, isEmpty);
    });

    test('onboarding events only record after opt-in and only once', () async {
      final store = MemoryRetentionStore();
      final container = containerWith(store);
      await container.read(retentionControllerProvider.future);
      final controller = container.read(retentionControllerProvider.notifier);

      await controller.recordOnboardingStart();
      await controller.recordOnboardingComplete();
      expect(store.value.log.events, isEmpty);

      await controller.setOptIn(true);
      await controller.recordOnboardingStart();
      await controller.recordOnboardingStart();
      await controller.recordOnboardingComplete();
      await controller.recordOnboardingComplete();

      expect(count(store, RetentionEventName.onboardingStart), 1);
      expect(count(store, RetentionEventName.onboardingComplete), 1);
    });

    test('firstNote emits once, not on every answer', () async {
      final store = MemoryRetentionStore(optIn: true);
      final container = containerWith(store);
      await container.read(retentionControllerProvider.future);
      final controller = container.read(retentionControllerProvider.notifier);
      final at = DateTime(2026, 6, 2, 10);

      await controller.recordFirstNote(at: at);
      await controller.recordFirstNote(at: at.add(const Duration(seconds: 5)));
      await controller.recordFirstNote(at: at.add(const Duration(seconds: 9)));

      expect(count(store, RetentionEventName.firstNote), 1);
    });

    test('concurrent hook writes do not lose events', () async {
      final store = MemoryRetentionStore(optIn: true);
      final container = containerWith(store);
      await container.read(retentionControllerProvider.future);
      final controller = container.read(retentionControllerProvider.notifier);
      final at = DateTime(2026, 6, 3, 9);

      await Future.wait([
        controller.recordAppOpen(at: at),
        controller.recordOnboardingStart(at: at),
        controller.recordFirstNote(at: at),
        controller.record(RetentionEventName.sessionStart, at: at),
      ]);

      expect(store.value.log.events, hasLength(4));
      expect(store.value.log.events.map((event) => event.name).toSet(), {
        RetentionEventName.appOpen,
        RetentionEventName.onboardingStart,
        RetentionEventName.firstNote,
        RetentionEventName.sessionStart,
      });
    });

    test(
      'firstPhrase and firstRecording are available and deduplicated',
      () async {
        final store = MemoryRetentionStore(optIn: true);
        final container = containerWith(store);
        await container.read(retentionControllerProvider.future);
        final controller = container.read(retentionControllerProvider.notifier);

        await controller.recordFirstPhrase();
        await controller.recordFirstPhrase();
        await controller.recordFirstRecording();
        await controller.recordFirstRecording();

        expect(count(store, RetentionEventName.firstPhrase), 1);
        expect(count(store, RetentionEventName.firstRecording), 1);
      },
    );
  });

  group('AppController retention hooks', () {
    test(
      'a session records start, complete, active day, and one firstNote',
      () async {
        final progressStore = MemoryProgressStore(
          ProgressState.fresh(
            settings: const AppSettings(
              onboardingComplete: true,
              answerMode: AnswerMode.name,
            ),
          ),
        );
        final retentionStore = MemoryRetentionStore(optIn: true);
        final container = ProviderContainer(
          overrides: [
            progressStoreProvider.overrideWithValue(progressStore),
            retentionStoreProvider.overrideWithValue(retentionStore),
          ],
        );
        addTearDown(container.dispose);

        await container.read(appControllerProvider.future);
        await waitFor(
          () => count(retentionStore, RetentionEventName.appOpen) == 1,
        );

        final controller = container.read(appControllerProvider.notifier);
        controller.startLesson('c3u1l1', micAvailable: false);
        await waitFor(
          () => count(retentionStore, RetentionEventName.sessionStart) == 1,
        );

        var noteAnswers = 0;
        var guard = 0;
        while (container.read(appControllerProvider).requireValue.run != null) {
          if (guard++ > 40) fail('the lesson did not finish');
          final run = container.read(appControllerProvider).requireValue.run!;
          final prompt = run.current;
          if (prompt.isScored) {
            if (prompt is NotePrompt) noteAnswers++;
            await controller.submitAnswer(correct: true);
          }
          await controller.nextExercise();
        }

        expect(noteAnswers, greaterThan(1));
        expect(
          container.read(appControllerProvider).requireValue.result,
          isNotNull,
        );
        await waitFor(
          () => count(retentionStore, RetentionEventName.sessionComplete) == 1,
        );
        await waitFor(
          () => count(retentionStore, RetentionEventName.dailyActive) == 1,
        );
        await waitFor(
          () => count(retentionStore, RetentionEventName.firstNote) == 1,
        );
        expect(count(retentionStore, RetentionEventName.sessionStart), 1);

        final exported = retentionStore.value.log.exportJson().toLowerCase();
        expect(exported, isNot(contains('audio')));
        expect(exported, isNot(contains('c3u1l1')));
      },
    );

    test('an opted-out session records nothing', () async {
      final progressStore = MemoryProgressStore(
        ProgressState.fresh(
          settings: const AppSettings(
            onboardingComplete: true,
            answerMode: AnswerMode.name,
          ),
        ),
      );
      final retentionStore = MemoryRetentionStore();
      final container = ProviderContainer(
        overrides: [
          progressStoreProvider.overrideWithValue(progressStore),
          retentionStoreProvider.overrideWithValue(retentionStore),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appControllerProvider.future);
      container
          .read(appControllerProvider.notifier)
          .startLesson('c3u1l1', micAvailable: false);
      await Future<void>.delayed(Duration.zero);

      expect(retentionStore.value.log.events, isEmpty);
      expect(retentionStore.saveCount, 0);
    });
  });
}
