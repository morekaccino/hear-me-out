import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_recorder.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/media/media_store.dart';
import 'package:hear_me_out/core/media/recording_index_store.dart';
import 'package:hear_me_out/core/media/recording_service.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
import 'package:hear_me_out/state/providers.dart';
import 'package:hear_me_out/state/recording_controller.dart';

import 'support/fakes.dart';

Uint8List _tone() {
  final samples = <double>[for (var i = 0; i < 800; i++) 0.2];
  return pcm16Bytes(samples);
}

class _Harness {
  _Harness({bool reminderEnabled = true})
    : progressStore = MemoryProgressStore(
        ProgressState.fresh(
          settings: AppSettings(
            onboardingComplete: true,
            reminderEnabled: reminderEnabled,
          ),
        ),
      ) {
    capture = FakePcmCapture(
      chunks: <Uint8List>[_tone()],
      config: const PcmCaptureConfig(sampleRate: 8000, channels: 1),
    );
    service = RecordingService(
      store: store,
      indexStore: indexStore,
      exporter: exporter,
      clock: () => DateTime.utc(2026, 11, 7, 12),
      recorderFactory: () => PhraseRecorder(
        capture: capture,
        requestedSampleRate: 8000,
        outputSampleRate: 8000,
      ),
      timerFactory: timers.call,
    );
    scheduler = FakeReminderScheduler();
    container = ProviderContainer(
      overrides: [
        progressStoreProvider.overrideWithValue(progressStore),
        recordingServiceProvider.overrideWithValue(AsyncData(service)),
        reminderSchedulerProvider.overrideWithValue(scheduler),
        retentionStoreProvider.overrideWithValue(MemoryRetentionStore()),
      ],
    );
    addTearDown(container.dispose);
  }

  final MemoryProgressStore progressStore;
  final MediaStore store = MemoryMediaStore();
  final MemoryRecordingIndexStore indexStore = MemoryRecordingIndexStore();
  final FakeRecordingExporter exporter = FakeRecordingExporter();
  final FakeRecordingTimerFactory timers = FakeRecordingTimerFactory();
  late final FakePcmCapture capture;
  late final RecordingService service;
  late final FakeReminderScheduler scheduler;
  late final ProviderContainer container;

  Future<RecordingController> controller() async {
    final subscription = container.listen(
      recordingControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(recordingControllerProvider.notifier);
    await container.read(recordingControllerProvider.future);
    return controller;
  }

  Future<void> record(RecordingController controller, String pieceId) async {
    await controller.startTake(pieceId: pieceId);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await controller.stopTake();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the first take does not fire the before/after alert', () async {
    final harness = _Harness();
    final controller = await harness.controller();
    await harness.record(controller, 'twinkle');

    expect(harness.scheduler.beforeAfterPieceIds, isEmpty);
    await harness.service.dispose();
  });

  test('the second take fires it exactly once for that piece', () async {
    final harness = _Harness();
    final controller = await harness.controller();
    await harness.record(controller, 'twinkle');
    await harness.record(controller, 'twinkle');

    expect(harness.scheduler.beforeAfterPieceIds, <String>['twinkle']);
    await harness.service.dispose();
  });

  test('reminders off never fire it, even on the second take', () async {
    final harness = _Harness(reminderEnabled: false);
    final controller = await harness.controller();
    await harness.record(controller, 'twinkle');
    await harness.record(controller, 'twinkle');

    expect(harness.scheduler.beforeAfterPieceIds, isEmpty);
    await harness.service.dispose();
  });

  test('a different piece with one take does not fire it', () async {
    final harness = _Harness();
    final controller = await harness.controller();
    await harness.record(controller, 'twinkle');
    await harness.record(controller, 'ode');

    expect(harness.scheduler.beforeAfterPieceIds, isEmpty);
    await harness.service.dispose();
  });
}
