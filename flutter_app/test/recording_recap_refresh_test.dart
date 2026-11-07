import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_recorder.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/media/media_store.dart';
import 'package:hear_me_out/core/media/recording_index_store.dart';
import 'package:hear_me_out/core/media/recording_service.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
import 'package:hear_me_out/features/today/today_controller.dart';
import 'package:hear_me_out/state/app_controller.dart';
import 'package:hear_me_out/state/providers.dart';
import 'package:hear_me_out/state/recording_controller.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a saved take refreshes the recap index and the performance-day cadence',
    () async {
      final now = DateTime(2026, 11, 6, 10);
      final progressStore = MemoryProgressStore(
        ProgressState(
          settings: const AppSettings(onboardingComplete: true),
          practiceSecondsByDay: {
            dayKey(DateTime(2026, 11, 6)): 300,
            dayKey(DateTime(2026, 11, 5)): 300,
            dayKey(DateTime(2026, 11, 3)): 300,
          },
        ),
      );
      final indexStore = MemoryRecordingIndexStore();
      final capture = FakePcmCapture(
        chunks: [pcm16Bytes(List<double>.filled(8000, 0.2))],
        config: const PcmCaptureConfig(sampleRate: 8000, channels: 1),
      );
      final timers = FakeRecordingTimerFactory();
      final service = RecordingService(
        store: MemoryMediaStore(),
        indexStore: indexStore,
        exporter: FakeRecordingExporter(),
        clock: () => DateTime.utc(2026, 11, 6, 12),
        recorderFactory: () => PhraseRecorder(
          capture: capture,
          requestedSampleRate: 8000,
          outputSampleRate: 8000,
        ),
        timerFactory: timers.call,
      );
      addTearDown(service.dispose);

      final container = ProviderContainer(
        overrides: [
          progressStoreProvider.overrideWithValue(progressStore),
          soundServiceProvider.overrideWithValue(FakeSoundService()),
          recordingServiceProvider.overrideWithValue(AsyncData(service)),
          recordingIndexStoreProvider.overrideWithValue(indexStore),
          retentionStoreProvider.overrideWithValue(MemoryRetentionStore()),
          reminderSchedulerProvider.overrideWithValue(FakeReminderScheduler()),
          todayClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);

      // Both read-only caches stay alive across the save, exactly as they do
      // when Today and Quests are mounted. That cross-tab lifetime is what made
      // the pre-save list stale.
      final recapSub = container.listen(recordingRecapTakesProvider, (_, _) {});
      addTearDown(recapSub.close);
      final controllerSub = container.listen(
        recordingControllerProvider,
        (_, _) {},
      );
      addTearDown(controllerSub.close);

      await container.read(appControllerProvider.future);
      expect(await container.read(recordingRecapTakesProvider.future), isEmpty);
      expect(container.read(todayPerformanceDayProvider), isTrue);

      final controller = container.read(recordingControllerProvider.notifier);
      await controller.startTake(pieceId: 'ode-to-joy');
      // Let the fake capture deliver its PCM chunk before stopping.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await controller.stopTake();
      await Future<void>.delayed(Duration.zero);

      final takes = await container.read(recordingRecapTakesProvider.future);
      expect(takes, hasLength(1));
      expect(takes.single.pieceId, 'ode-to-joy');
      // The real saved take counts toward the existing recording quest.
      expect(progressStore.value!.quests.recordingsMade, 1);
      // One take today closes the stage: the cadence sees the new take.
      expect(container.read(todayPerformanceDayProvider), isFalse);
    },
  );
}
