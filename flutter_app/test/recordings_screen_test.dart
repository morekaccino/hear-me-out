import 'dart:async';
import 'dart:convert';
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
import 'package:hear_me_out/core/media/take_bundle_exporter.dart';
import 'package:hear_me_out/core/media/take_export_cleaner.dart';
import 'package:hear_me_out/core/media/take_share_gateway.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
import 'package:hear_me_out/content/pieces/launch_pieces.dart';
import 'package:hear_me_out/features/recordings/recordings_screen.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/shared/widgets/duo_button.dart';
import 'package:hear_me_out/state/app_controller.dart';
import 'package:hear_me_out/state/providers.dart';
import 'package:hear_me_out/state/recording_controller.dart';

import 'support/fakes.dart';

class _Harness {
  _Harness({MediaStore? store, ProgressState? progress})
    : store = store ?? MemoryMediaStore(),
      progressStore = MemoryProgressStore(
        progress ??
            ProgressState.fresh(
              settings: const AppSettings(onboardingComplete: true),
            ),
      ) {
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
  final FakeTakeBundleExporter bundleExporter = FakeTakeBundleExporter();
  final FakeTakeShareGateway share = FakeTakeShareGateway();
  final FakeTakeExportCleaner exportCleaner = FakeTakeExportCleaner();
  final FakeRecordingTimerFactory timers = FakeRecordingTimerFactory();
  final FakeTakePlayer player = FakeTakePlayer();
  final MemoryRetentionStore retention = MemoryRetentionStore(optIn: true);
  final MemoryProgressStore progressStore;
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

ProgressState _progressWithPhraseEvidence() {
  final progress = ProgressState.fresh(
    settings: const AppSettings(onboardingComplete: true),
  );
  progress.recordPhraseAttempt(
    PhraseAttempt(
      phraseId: 'p1',
      outcome: AttemptOutcome.correct,
      now: DateTime.utc(2026, 11, 1, 10),
      accuracy: 0.9,
      tempoBpm: 68,
      targetTempoBpm: 72,
      pieceId: 'ode-to-joy',
      contentVersion: 1,
      bars: 4,
    ),
  );
  return progress;
}

class _FailingAppController extends AppController {
  @override
  Future<AppData> build() async => throw StateError('progress unavailable');
}

Widget _build(
  _Harness harness, {
  BackupExclusionResult backup = const BackupExclusionResult.failed('denied'),
  AppController Function()? appController,
}) {
  return _shell(
    harness,
    const RecordingsScreen(),
    backup,
    appController: appController,
  );
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

Widget _shell(
  _Harness harness,
  Widget home,
  BackupExclusionResult backup, {
  AppController Function()? appController,
}) {
  return ProviderScope(
    overrides: [
      recordingServiceProvider.overrideWithValue(AsyncData(harness.service)),
      mediaBackupStatusProvider.overrideWithValue(AsyncData(backup)),
      takePlayerProvider.overrideWithValue(harness.player),
      takeBundleExporterProvider.overrideWithValue(
        AsyncData(harness.bundleExporter),
      ),
      takeShareGatewayProvider.overrideWithValue(harness.share),
      takeExportCleanerProvider.overrideWithValue(
        AsyncData(harness.exportCleaner),
      ),
      if (appController != null)
        appControllerProvider.overrideWith(appController),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 7, 9, 15)),
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

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 240);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const ValueKey('recordings-list')),
    const Offset(0, 2000),
  );
  await tester.pumpAndSettle();
}

/// Opens the export header sheet and confirms the export.
Future<void> _tapExport(WidgetTester tester, String id) async {
  await _reveal(tester, find.byKey(ValueKey('export-take-$id')));
  await tester.tap(find.byKey(ValueKey('export-take-$id')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('export-confirm')), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('export-confirm')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a new success notice resets the neutral export flag', () {
    const state = RecordingScreenState(
      takes: <RecordingTake>[],
      usageBytes: 0,
      takeLimit: 20,
      byteLimit: 200,
      notice: 'Export saved. Share cancelled.',
      noticeNeutral: true,
    );

    final next = state.copyWith(notice: 'Take saved on this device.');

    expect(next.notice, 'Take saved on this device.');
    expect(next.noticeNeutral, isFalse);
  });

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

    final savedId = (await harness.service.listTakes()).single.id;
    await _reveal(tester, find.byKey(ValueKey('take-$savedId')));
    expect(find.text('Free take'), findsWidgets);
    expect(find.text('0:01'), findsOneWidget);
    await _scrollToTop(tester);
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

  testWidgets('a launch piece can be preselected and a save reports back', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    final piece = launchPieces.first.piece;
    var savedCallbacks = 0;
    await tester.pumpWidget(
      _shell(
        harness,
        RecordingsScreen(
          initialPieceId: piece.id,
          onTakeSaved: () => savedCallbacks++,
        ),
        const BackupExclusionResult.failed('denied'),
      ),
    );
    await tester.pumpAndSettle();

    // The preselected launch piece is the dropdown value, so the take is
    // linked without another choice.
    expect(find.text(piece.title), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('record-button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('record-button')));
    await tester.pumpAndSettle();

    expect(savedCallbacks, 1);
    final takes = await harness.service.listTakes();
    expect(takes, hasLength(1));
    expect(takes.single.pieceId, piece.id);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('an unknown preselected piece falls back to a free take', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await tester.pumpWidget(
      _shell(
        harness,
        const RecordingsScreen(initialPieceId: 'not-a-launch-piece'),
        const BackupExclusionResult.failed('denied'),
      ),
    );
    await tester.pumpAndSettle();

    // The invalid value is dropped rather than asserted into the dropdown.
    expect(find.text('Free take'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('record-button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('record-button')));
    await tester.pumpAndSettle();

    final takes = await harness.service.listTakes();
    expect(takes, hasLength(1));
    expect(takes.single.pieceId, isNull);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('a single-take entry disables record after the first save', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await tester.pumpWidget(
      _shell(
        harness,
        const RecordingsScreen(singleTake: true),
        const BackupExclusionResult.failed('denied'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('record-button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('record-button')));
    await tester.pumpAndSettle();

    expect(find.text('TAKE SAVED'), findsOneWidget);
    expect(find.text('Take saved. Listen back below.'), findsOneWidget);
    expect(find.text('Record a few bars, then listen back.'), findsNothing);
    // The real save still counts toward the existing recording quest.
    expect(harness.progressStore.value!.quests.recordingsMade, 1);

    // The one-take entry cannot start a second take.
    await tester.tap(find.byKey(const ValueKey('record-button')));
    await tester.pumpAndSettle();
    expect(harness.capture.startCalls, 1);
    expect(await harness.service.listTakes(), hasLength(1));
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('play, bundle export, and delete use the stored take without mutation', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    const id = 'take-1';
    await harness.seedTake(id);
    final beforeBytes = await harness.store.get(id);

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    await _reveal(tester, find.byKey(ValueKey('play-take-$id')));
    await tester.tap(find.byKey(ValueKey('play-take-$id')));
    await tester.pumpAndSettle();
    expect(harness.player.played, hasLength(1));
    expect(harness.player.played.single, beforeBytes);

    await _tapExport(tester, id);

    expect(harness.bundleExporter.requests, hasLength(1));
    final request = harness.bundleExporter.requests.single;
    expect(request.takeId, id);
    expect(request.files.map((file) => file.fileName), <String>[
      '$id.wav',
      '$id.json',
      '$id.pdf',
    ]);
    expect(request.files.first.bytes, beforeBytes);
    expect(
      String.fromCharCodes(request.files.last.bytes.take(4)),
      '%PDF',
    );
    final json =
        jsonDecode(utf8.decode(request.files[1].bytes)) as Map<String, dynamic>;
    expect(json['takeId'], id);
    expect(json['exportedAt'], '2026-11-07T09:15:00.000Z');
    expect(json['evidence'], isNull);

    expect(harness.share.sharedPaths, hasLength(1));
    expect(harness.share.sharedPaths.single, <String>[
      '/exports/$id.wav',
      '/exports/$id.json',
      '/exports/$id.pdf',
    ]);
    expect(
      find.text('Shared. Nothing is uploaded by the app.'),
      findsWidgets,
    );
    await _scrollToTop(tester);
    final notice = tester.widget<Text>(
      find.byKey(const ValueKey('recording-notice')),
    );
    expect(notice.data, contains('Shared'));
    expect(
      find.byKey(const ValueKey('recording-notice-success')),
      findsOneWidget,
    );
    expect(await harness.store.get(id), beforeBytes);
    expect(await harness.store.list(), hasLength(1));

    await _reveal(tester, find.byKey(ValueKey('delete-take-$id')));
    await tester.tap(find.byKey(ValueKey('delete-take-$id')));
    await tester.pumpAndSettle();
    expect(await harness.store.list(), isEmpty);
    expect(find.text('No takes yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('a bundle failure shows a typed message, not an exception', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    const id = 'take-1';
    await harness.seedTake(id);
    harness.bundleExporter.failWith = const TakeBundleExportException(
      'Could not write the export bundle.',
    );

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();
    await _tapExport(tester, id);

    expect(find.text('Could not write the export bundle.'), findsWidgets);
    await _scrollToTop(tester);
    final message = tester.widget<Text>(
      find.byKey(const ValueKey('recording-failure-message')),
    );
    expect(message.data, 'Could not write the export bundle.');
    expect(harness.share.sharedPaths, isEmpty);
    expect(await harness.store.list(), hasLength(1));
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('a phrase take includes real stored evidence in the summary', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness(progress: _progressWithPhraseEvidence());
    const id = 'take-1';
    await harness.seedPieceTake(id);

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();
    await _tapExport(tester, id);

    final request = harness.bundleExporter.requests.single;
    final json =
        jsonDecode(utf8.decode(request.files[1].bytes)) as Map<String, dynamic>;
    expect(json['piece'], <String, Object?>{
      'title': 'Ode to Joy',
      'composer': 'Ludwig van Beethoven',
      'stage': 2,
    });
    expect(json['phraseId'], 'p1');
    final evidence = json['evidence']! as Map<String, dynamic>;
    expect(evidence['attempts'], 1);
    expect(evidence['bestAccuracy'], 0.9);
    expect(evidence['bestTempoBpm'], 68);
    expect(evidence['performanceDays'], 1);
    expect(evidence['masteryDays'], 0);
    expect(evidence['contentVersion'], 1);
    expect(
      String.fromCharCodes(request.files.last.bytes.take(4)),
      '%PDF',
    );
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('a phrase take with no stored record says there is no evidence', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    const id = 'take-1';
    await harness.seedPieceTake(id);

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();
    await _tapExport(tester, id);

    final request = harness.bundleExporter.requests.single;
    final json =
        jsonDecode(utf8.decode(request.files[1].bytes)) as Map<String, dynamic>;
    expect(json['piece'], isNotNull);
    expect(json['phraseId'], 'p1');
    expect(json['evidence'], isNull);
    expect(json.containsKey('score'), isFalse);
    expect(json.containsKey('grade'), isFalse);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('a cancelled share keeps the exported files and says so', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    const id = 'take-1';
    await harness.seedTake(id);
    harness.share.result = const TakeShareResult(TakeShareStatus.cancelled);

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();
    await _tapExport(tester, id);

    expect(harness.bundleExporter.requests, hasLength(1));
    expect(find.textContaining('Share cancelled'), findsWidgets);
    await _scrollToTop(tester);
    expect(
      find.byKey(const ValueKey('recording-notice-neutral')),
      findsOneWidget,
    );
    final notice = tester.widget<Text>(
      find.byKey(const ValueKey('recording-notice')),
    );
    expect(notice.data, contains('Share cancelled'));
    expect(notice.data, contains('/exports/$id.wav'));
    expect(harness.share.sharedPaths, hasLength(1));
    expect(await harness.store.list(), hasLength(1));
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('a web-style download reports the three files without a share', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    const id = 'take-1';
    await harness.seedTake(id);
    harness.bundleExporter.webDownload = true;

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();
    await _tapExport(tester, id);

    expect(find.textContaining('Downloaded 3 files'), findsWidgets);
    await _scrollToTop(tester);
    final notice = tester.widget<Text>(
      find.byKey(const ValueKey('recording-notice')),
    );
    expect(notice.data, contains('Downloaded 3 files'));
    expect(notice.data, contains('Nothing is uploaded'));
    expect(harness.share.sharedPaths, isEmpty);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('the export header is shown before the share sheet', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    const id = 'take-1';
    await harness.seedTake(id);

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();
    await _reveal(tester, find.byKey(ValueKey('export-take-$id')));
    await tester.tap(find.byKey(ValueKey('export-take-$id')));
    await tester.pumpAndSettle();

    expect(find.text('WHAT THIS FILE CONTAINS'), findsOneWidget);
    expect(find.text('WHO IT IS FOR'), findsOneWidget);
    expect(find.text('KEEPING AND DELETING IT'), findsOneWidget);
    expect(find.textContaining('90 days'), findsOneWidget);
    expect(find.textContaining('Clear exported files'), findsOneWidget);
    expect(find.text('Nothing is uploaded by the app.'), findsOneWidget);

    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(harness.bundleExporter.requests, isEmpty);
    expect(harness.share.sharedPaths, isEmpty);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('the export action is disabled while an export is in flight', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    const id = 'take-1';
    await harness.seedTake(id);
    final gate = Completer<void>();
    harness.bundleExporter.gate = gate;

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();
    await _reveal(tester, find.byKey(ValueKey('export-take-$id')));
    await tester.tap(find.byKey(ValueKey('export-take-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('EXPORTING…'), findsOneWidget);
    final button = tester.widget<OutlineDuoButton>(
      find.byKey(ValueKey('export-take-$id')),
    );
    expect(button.onPressed, isNull);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('EXPORT FOR TEACHER'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('a progress read failure is exported as evidence unavailable', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    const id = 'take-1';
    await harness.seedPieceTake(id);

    await tester.pumpWidget(
      _build(harness, appController: _FailingAppController.new),
    );
    await tester.pumpAndSettle();
    await _tapExport(tester, id);

    final request = harness.bundleExporter.requests.single;
    final json =
        jsonDecode(utf8.decode(request.files[1].bytes)) as Map<String, dynamic>;
    expect(json['phraseId'], 'p1');
    expect(json['evidenceStatus'], 'unavailable');
    expect(json['evidence'], isNull);
    expect(json.containsKey('score'), isFalse);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('clear exports deletes the app copies after confirmation', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await harness.seedTake('take-1');

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    await _reveal(tester, find.byKey(const ValueKey('clear-exports')));
    await tester.tap(find.byKey(const ValueKey('clear-exports')));
    await tester.pumpAndSettle();
    expect(find.text('Clear exported files?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(harness.exportCleaner.calls, 0);

    await tester.tap(find.byKey(const ValueKey('clear-exports')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear exports'));
    await tester.pumpAndSettle();

    expect(harness.exportCleaner.calls, 1);
    expect(find.text('Cleared 3 exported files.'), findsWidgets);
    expect(await harness.store.list(), hasLength(1));
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('clear exports is hidden when the platform has no app folder', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    harness.exportCleaner.isSupported = false;

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('clear-exports')), findsNothing);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('a clear-exports failure is typed and the stored take remains', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await harness.seedTake('take-1');
    harness.exportCleaner.result = const TakeExportClearResult(
      failure: TakeExportClearFailure(
        'Could not clear every exported file. Some copies may remain.',
      ),
    );

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();
    await _reveal(tester, find.byKey(const ValueKey('clear-exports')));
    await tester.tap(find.byKey(const ValueKey('clear-exports')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear exports'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not clear every exported file. Some copies may remain.'),
      findsWidgets,
    );
    expect(await harness.store.list(), hasLength(1));
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

    await _reveal(tester, find.byKey(const ValueKey('clear-all-recordings')));
    await tester.tap(find.byKey(const ValueKey('clear-all-recordings')));
    await tester.pumpAndSettle();
    expect(find.text('Clear all takes?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await harness.store.list(), hasLength(1));

    await _reveal(tester, find.byKey(const ValueKey('clear-all-recordings')));
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
    final savedId = (await harness.service.listTakes()).single.id;
    await _reveal(tester, find.byKey(ValueKey('take-$savedId')));
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
