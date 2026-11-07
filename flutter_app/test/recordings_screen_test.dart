import 'dart:async';
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
import 'package:hear_me_out/content/pieces/launch_pieces.dart';
import 'package:hear_me_out/features/recordings/recordings_screen.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/providers.dart';
import 'package:hear_me_out/state/recording_controller.dart';

import 'support/fakes.dart';

class _Harness {
  _Harness({MediaStore? store}) : store = store ?? MemoryMediaStore() {
    capture = FakePcmCapture(
      chunks: <Uint8List>[_tone()],
      config: const PcmCaptureConfig(sampleRate: 8000, channels: 1),
    );
    service = RecordingService(
      store: this.store,
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

  final MediaStore store;
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

  Future<void> seedPieceTake(String id) async {
    await store.put(
      _toneBytes(),
      mimeType: RecordingService.wavMimeType,
      id: id,
      pieceId: 'ode-to-joy',
      phraseId: 'p1',
      durationMs: 1000,
    );
    final ref = (await store.list()).firstWhere((ref) => ref.id == id);
    indexStore.value = (indexStore.value ?? RecordingIndex.empty).add(
      RecordingTake.fromMediaRef(ref),
    );
    await indexStore.save(indexStore.value!);
  }
}

class _GatedMediaStore implements MediaStore {
  _GatedMediaStore(this.inner);

  final MemoryMediaStore inner;
  Completer<void>? nextPutGate;
  bool putWaiting = false;

  @override
  Future<MediaRef> put(
    Uint8List bytes, {
    required String mimeType,
    String? id,
    String? pieceId,
    String? phraseId,
    int? durationMs,
    double? score,
    int? analysisVersion,
  }) async {
    final gate = nextPutGate;
    if (gate != null) {
      nextPutGate = null;
      putWaiting = true;
      await gate.future;
      putWaiting = false;
    }
    return inner.put(
      bytes,
      mimeType: mimeType,
      id: id,
      pieceId: pieceId,
      phraseId: phraseId,
      durationMs: durationMs,
      score: score,
      analysisVersion: analysisVersion,
    );
  }

  @override
  Future<Uint8List?> get(String id) => inner.get(id);

  @override
  Future<void> delete(String id) => inner.delete(id);

  @override
  Future<List<MediaRef>> list() => inner.list();

  @override
  Future<int> usageBytes() => inner.usageBytes();

  @override
  Future<void> clear() => inner.clear();
}

Uint8List _toneBytes() {
  return pcm16Bytes(<double>[for (var i = 0; i < 8000; i++) 0.2]);
}

Uint8List _tone() => _toneBytes();

Widget _build(
  _Harness harness, {
  BackupExclusionResult backup = const BackupExclusionResult.failed('denied'),
}) {
  return _shell(harness, const RecordingsScreen(), backup);
}

Widget _buildNavigated(_Harness harness) {
  return _shell(
    harness,
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RecordingsScreen()),
            ),
            child: const Text('Open recordings'),
          ),
        ),
      ),
    ),
    const BackupExclusionResult.failed('denied'),
  );
}

Widget _shell(_Harness harness, Widget home, BackupExclusionResult backup) {
  return ProviderScope(
    overrides: [
      recordingServiceProvider.overrideWithValue(AsyncData(harness.service)),
      mediaBackupStatusProvider.overrideWithValue(AsyncData(backup)),
      takePlayerProvider.overrideWithValue(harness.player),
      soundServiceProvider.overrideWithValue(FakeSoundService()),
      retentionStoreProvider.overrideWithValue(harness.retention),
      progressStoreProvider.overrideWithValue(harness.progressStore),
    ],
    child: MaterialApp(theme: AppTheme.light, home: home),
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

    expect(find.text('Free take'), findsWidgets);
    expect(find.text('0:01'), findsOneWidget);
    expect(find.text('1 of 20 takes stored'), findsOneWidget);
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
    expect(find.text('Free take'), findsWidgets);

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

  testWidgets('leaving the screen stops and discards a live take', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await tester.pumpWidget(_buildNavigated(harness));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open recordings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('record-button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(harness.service.isRecording, isTrue);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Open recordings'), findsOneWidget);
    expect(harness.service.isRecording, isFalse);
    expect(harness.capture.stopCalls, greaterThanOrEqualTo(1));
    expect(await harness.store.list(), isEmpty);

    // The recorder is free again, so Practice can open its tuner or start a
    // new take without a second capture.
    final restart = await harness.service.start();
    expect(restart.started, isTrue);
    expect(harness.capture.startCalls, 2);
    await tester.pump(const Duration(milliseconds: 100));
    await harness.service.cancel();
    await harness.service.dispose();
  });

  testWidgets('a selected piece makes per-piece retention reachable', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    final piece = launchPieces.first.piece;
    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recording-piece')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(piece.title).last);
    await tester.pumpAndSettle();

    Future<void> recordOnce() async {
      await tester.tap(find.byKey(const ValueKey('record-button')));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('record-button')));
      await tester.pumpAndSettle();
    }

    await recordOnce();
    await recordOnce();
    await recordOnce();

    final takes = await harness.service.listTakes();
    expect(takes, hasLength(2));
    expect(takes.every((take) => take.pieceId == piece.id), isTrue);
    expect(await harness.store.list(), hasLength(2));
    expect(find.text(piece.title), findsWidgets);
    expect(find.text('2 of 20 takes stored'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('a comparison entry opens with two takes for one piece', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await harness.seedPieceTake('take-1');
    await harness.seedPieceTake('take-2');

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('compare-takes-card')),
    );
    expect(find.byKey(const ValueKey('compare-takes-open')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('compare-takes-open')));
    await tester.pumpAndSettle();

    expect(find.text('Compare takes'), findsOneWidget);
    expect(find.byKey(const ValueKey('compare-left-take')), findsOneWidget);
    expect(find.byKey(const ValueKey('compare-right-take')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('a single piece take has no comparison entry', (tester) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await harness.seedPieceTake('take-1');

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('compare-takes-card')), findsNothing);
    expect(find.byKey(const ValueKey('compare-takes-open')), findsNothing);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('popping during save keeps the take and its retention set', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final inner = MemoryMediaStore(clock: () => DateTime.utc(2026, 1, 1));
    final gated = _GatedMediaStore(inner);
    final harness = _Harness(store: gated);
    final first = await gated.put(
      _toneBytes(),
      mimeType: RecordingService.wavMimeType,
      id: 'first',
      pieceId: 'ode-to-joy',
      phraseId: 'p1',
      durationMs: 1000,
    );
    final previousLast = await gated.put(
      _toneBytes(),
      mimeType: RecordingService.wavMimeType,
      id: 'last-before',
      pieceId: 'ode-to-joy',
      phraseId: 'p1',
      durationMs: 1000,
    );
    harness.indexStore.value = RecordingIndex(<RecordingTake>[
      RecordingTake.fromMediaRef(first),
      RecordingTake.fromMediaRef(previousLast),
    ]);
    await harness.indexStore.save(harness.indexStore.value!);

    await tester.pumpWidget(_buildNavigated(harness));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open recordings'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(RecordingsScreen)),
    );
    final controller = container.read(recordingControllerProvider.notifier);
    await controller.startTake(pieceId: 'ode-to-joy', phraseId: 'p1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(harness.service.isRecording, isTrue);

    final gate = Completer<void>();
    gated.nextPutGate = gate;
    await tester.tap(find.byKey(const ValueKey('record-button')));
    for (var attempt = 0; attempt < 20 && !gated.putWaiting; attempt++) {
      await tester.pump();
    }
    expect(gated.putWaiting, isTrue);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open recordings'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();

    final takes = await harness.service.listTakes();
    expect(takes, hasLength(2));
    final saved = takes.firstWhere((take) => take.id != 'first');
    expect(saved.pieceId, 'ode-to-joy');
    expect(saved.phraseId, 'p1');
    expect(takes.map((take) => take.id), contains('first'));
    expect(takes.map((take) => take.id), isNot(contains('last-before')));
    expect(await harness.store.list(), hasLength(2));
    expect(harness.service.isRecording, isFalse);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });
}
