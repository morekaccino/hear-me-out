import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_recorder.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/media/backup_exclusion.dart';
import 'package:hear_me_out/core/media/media_store.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/media/recording_index_store.dart';
import 'package:hear_me_out/core/media/recording_service.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
import 'package:hear_me_out/features/recordings/recordings_screen.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

class _Harness {
  _Harness() {
    capture = FakePcmCapture(
      chunks: <Uint8List>[_tone()],
      config: const PcmCaptureConfig(sampleRate: 8000, channels: 1),
    );
    service = RecordingService(
      store: store,
      indexStore: indexStore,
      exporter: exporter,
      clock: () => DateTime.utc(2026, 11, 6, 12),
      recorderFactory: () => PhraseRecorder(
        capture: capture,
        requestedSampleRate: 8000,
        outputSampleRate: 8000,
      ),
      timerFactory: timers.call,
    );
  }

  final MemoryMediaStore store = MemoryMediaStore();
  final MemoryRecordingIndexStore indexStore = MemoryRecordingIndexStore();
  final FakeRecordingExporter exporter = FakeRecordingExporter();
  final FakeRecordingTimerFactory timers = FakeRecordingTimerFactory();
  final FakeTakePlayer player = FakeTakePlayer();
  final MemoryRetentionStore retention = MemoryRetentionStore(optIn: true);
  final MemoryProgressStore progressStore = MemoryProgressStore(
    ProgressState.fresh(settings: const AppSettings(onboardingComplete: true)),
  );
  late final FakePcmCapture capture;
  late final RecordingService service;

  Future<void> seedTake(String id) async {
    await store.put(
      _toneBytes(),
      mimeType: RecordingService.wavMimeType,
      id: id,
      durationMs: 1000,
    );
    final ref = (await store.list()).firstWhere((ref) => ref.id == id);
    indexStore.value = (indexStore.value ?? RecordingIndex.empty).add(
      RecordingTake.fromMediaRef(ref),
    );
    await indexStore.save(indexStore.value!);
  }
}

Uint8List _toneBytes() {
  return pcm16Bytes(<double>[for (var i = 0; i < 8000; i++) 0.2]);
}

Uint8List _tone() => _toneBytes();

Widget _build(
  _Harness harness, {
  BackupExclusionResult backup = const BackupExclusionResult.failed('denied'),
}) {
  return ProviderScope(
    overrides: [
      recordingServiceProvider.overrideWithValue(AsyncData(harness.service)),
      mediaBackupStatusProvider.overrideWithValue(AsyncData(backup)),
      takePlayerProvider.overrideWithValue(harness.player),
      soundServiceProvider.overrideWithValue(FakeSoundService()),
      retentionStoreProvider.overrideWithValue(harness.retention),
      progressStoreProvider.overrideWithValue(harness.progressStore),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const RecordingsScreen()),
  );
}

void _useSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty state fits 390x844 and never claims backup exclusion', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    expect(find.text('Recordings'), findsOneWidget);
    expect(find.text('No takes yet'), findsOneWidget);
    expect(find.text('RECORD'), findsOneWidget);
    expect(find.textContaining('could not confirm'), findsOneWidget);
    expect(
      find.textContaining('excluded from cloud backup by default'),
      findsNothing,
    );
    expect(find.textContaining('XP'), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('fits a 1200px viewport without overflow', (tester) async {
    _useSize(tester, const Size(1200, 900));
    final harness = _Harness();
    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    expect(find.text('Recordings'), findsOneWidget);
    expect(find.text('RECORD'), findsOneWidget);
    expect(find.text('Local storage'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('record and stop saves a take and shows confirmed privacy copy', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await tester.pumpWidget(
      _build(harness, backup: const BackupExclusionResult.excluded()),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('excluded from cloud backup by default'),
      findsOneWidget,
    );
    expect(find.textContaining('could not confirm'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('record-button')));
    await tester.pump();
    await tester.pump();
    expect(find.text('STOP'), findsOneWidget);
    // Let the fake capture deliver its PCM chunk before stopping.
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const ValueKey('record-button')));
    await tester.pumpAndSettle();

    expect(find.text('Free take'), findsOneWidget);
    expect(find.text('0:01'), findsOneWidget);
    expect(find.byKey(const ValueKey('recording-usage-count')), findsOneWidget);
    expect(find.text('1 / 20 takes'), findsOneWidget);
    expect(find.text('Take saved on this device.'), findsOneWidget);
    expect(await harness.store.list(), hasLength(1));
    expect(
      harness.retention.value.log.hasEvent(RetentionEventName.firstRecording),
      isTrue,
    );
    expect(harness.progressStore.value!.quests.recordingsMade, 1);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('play, export, and delete use the stored take without mutation', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    const id = 'take-1';
    await harness.seedTake(id);
    final beforeBytes = await harness.store.get(id);

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('play-take-$id')),
      160,
    );
    await tester.tap(find.byKey(const ValueKey('play-take-$id')));
    await tester.pumpAndSettle();
    expect(harness.player.played, hasLength(1));
    expect(harness.player.played.single, beforeBytes);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('export-take-$id')),
      160,
    );
    await tester.tap(find.byKey(const ValueKey('export-take-$id')));
    await tester.pumpAndSettle();
    expect(harness.exporter.requests, hasLength(1));
    expect(harness.exporter.requests.single.bytes, beforeBytes);
    expect(harness.exporter.requests.single.fileName, 'recording-$id.wav');
    expect(await harness.store.get(id), beforeBytes);
    expect(await harness.store.list(), hasLength(1));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('delete-take-$id')),
      160,
    );
    await tester.tap(find.byKey(const ValueKey('delete-take-$id')));
    await tester.pumpAndSettle();
    expect(await harness.store.list(), isEmpty);
    expect(find.text('No takes yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('a full quota shows a clear failure and a delete action', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    for (var i = 0; i < RecordingService.defaultTakeLimit; i++) {
      await harness.seedTake('take-$i');
    }

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();
    expect(find.text('20 of 20 takes stored'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('record-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('You can keep 20 takes'), findsOneWidget);
    expect(find.byKey(const ValueKey('quota-delete-action')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('quota-delete-action')));
    await tester.pumpAndSettle();
    expect(find.text('Delete a take'), findsOneWidget);

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(await harness.store.list(), hasLength(19));
    expect(find.text('19 of 20 takes stored'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('clear all asks for confirmation before deleting', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await harness.seedTake('take-1');

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();
    expect(find.text('Free take'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('recordings-list')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clear-all-recordings')));
    await tester.pumpAndSettle();
    expect(find.text('Clear all takes?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await harness.store.list(), hasLength(1));

    await tester.tap(find.byKey(const ValueKey('clear-all-recordings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    expect(await harness.store.list(), isEmpty);
    expect(find.text('No takes yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('the 60-second auto-stop updates the screen and marks the take', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('record-button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    harness.timers.timers.single.fire();
    await tester.pumpAndSettle();

    expect(find.text('Take saved at the 60-second limit.'), findsOneWidget);
    expect(find.text('STOP'), findsNothing);
    expect(find.text('RECORD'), findsOneWidget);
    expect(find.text('Stopped at 60 s'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });
}
