import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_recorder.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/audio/wav.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/media/before_after_share.dart';
import 'package:hear_me_out/core/media/media_store.dart';
import 'package:hear_me_out/core/media/recording_exporter.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/media/recording_index_store.dart';
import 'package:hear_me_out/core/media/recording_service.dart';
import 'package:hear_me_out/core/media/take_share_gateway.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
import 'package:hear_me_out/features/before_after/before_after_screen.dart';
import 'package:hear_me_out/shared/theme/app_theme.dart';
import 'package:hear_me_out/state/providers.dart';

import 'support/fakes.dart';

class _Harness {
  _Harness() {
    capture = FakePcmCapture(
      chunks: <Uint8List>[_toneBytes()],
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
  final FakeTakeShareGateway share = FakeTakeShareGateway();
  final MemoryRetentionStore retention = MemoryRetentionStore(optIn: true);
  final MemoryProgressStore progressStore = MemoryProgressStore(
    ProgressState.fresh(settings: const AppSettings(onboardingComplete: true)),
  );
  late final FakePcmCapture capture;
  late final RecordingService service;

  Future<void> seedTake({
    required String id,
    required DateTime createdAt,
    String? pieceId,
    String? phraseId,
  }) async {
    final bytes = _toneBytes();
    await store.put(
      bytes,
      mimeType: RecordingService.wavMimeType,
      id: id,
      pieceId: pieceId,
      phraseId: phraseId,
      durationMs: 1000,
    );
    indexStore.value = (indexStore.value ?? RecordingIndex.empty).add(
      RecordingTake(
        id: id,
        createdAt: createdAt,
        byteLength: bytes.length,
        durationMs: 1000,
        pieceId: pieceId,
        phraseId: phraseId,
      ),
    );
    await indexStore.save(indexStore.value!);
  }
}

Uint8List _toneBytes() {
  return encodeWavPcm16(
    WavData(
      sampleRate: 8000,
      channels: 1,
      samples: List<double>.filled(8000, 0.2),
    ),
  );
}

Widget _build(_Harness harness) {
  return ProviderScope(
    overrides: [
      recordingServiceProvider.overrideWithValue(AsyncData(harness.service)),
      recordingExporterProvider.overrideWithValue(AsyncData(harness.exporter)),
      takePlayerProvider.overrideWithValue(harness.player),
      takeShareGatewayProvider.overrideWithValue(harness.share),
      soundServiceProvider.overrideWithValue(FakeSoundService()),
      retentionStoreProvider.overrideWithValue(harness.retention),
      progressStoreProvider.overrideWithValue(harness.progressStore),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: BeforeAfterScreen(
        renderer: (_) async => Uint8List.fromList(<int>[1, 2, 3, 4]),
      ),
    ),
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

  testWidgets('shows the private card and one honest metric', (tester) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await harness.seedTake(
      id: 'a',
      createdAt: DateTime.utc(2026, 10, 1, 12),
      pieceId: 'greensleeves',
      phraseId: 'p1',
    );
    await harness.seedTake(
      id: 'b',
      createdAt: DateTime.utc(2026, 10, 13, 12),
      pieceId: 'greensleeves',
      phraseId: 'p1',
    );

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    expect(find.text('Before / after'), findsOneWidget);
    expect(find.text('Greensleeves'), findsOneWidget);
    expect(find.text('p1'), findsOneWidget);
    expect(find.text('12 days apart'), findsOneWidget);
    expect(find.textContaining('Private.'), findsOneWidget);
    expect(find.textContaining('export or share'), findsOneWidget);
    expect(find.textContaining('No score'), findsOneWidget);
    expect(find.textContaining('lesson'), findsNothing);
    expect(harness.exporter.requests, isEmpty);
    await harness.service.dispose();
  });

  testWidgets('export is explicit and writes a PNG', (tester) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await harness.seedTake(
      id: 'a',
      createdAt: DateTime.utc(2026, 10, 1, 12),
      pieceId: 'greensleeves',
    );
    await harness.seedTake(
      id: 'b',
      createdAt: DateTime.utc(2026, 10, 13, 12),
      pieceId: 'greensleeves',
    );

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();
    expect(harness.exporter.requests, isEmpty);

    await tester.ensureVisible(find.byKey(const ValueKey('before-after-export')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('before-after-export')));
    await tester.pumpAndSettle();

    expect(harness.exporter.requests, hasLength(1));
    expect(harness.exporter.requests.single.mimeType, 'image/png');
    expect(harness.exporter.requests.single.fileName, endsWith('.png'));
    expect(harness.exporter.requests.single.bytes, isNotEmpty);
    // Export saves the file only; it never opens the share sheet.
    expect(harness.share.sharedPaths, isEmpty);
    await harness.service.dispose();
  });

  testWidgets('share sends one PNG and the plain invitation', (tester) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await harness.seedTake(
      id: 'a',
      createdAt: DateTime.utc(2026, 10, 1, 12),
      pieceId: 'greensleeves',
    );
    await harness.seedTake(
      id: 'b',
      createdAt: DateTime.utc(2026, 10, 13, 12),
      pieceId: 'greensleeves',
    );

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();
    expect(harness.share.sharedPaths, isEmpty);

    await tester.ensureVisible(find.byKey(const ValueKey('before-after-share')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('before-after-share')));
    await tester.pumpAndSettle();

    expect(harness.exporter.requests, hasLength(1));
    expect(harness.exporter.requests.single.mimeType, 'image/png');
    expect(harness.share.sharedPaths, hasLength(1));
    expect(harness.share.sharedPaths.single, hasLength(1));
    expect(harness.share.sharedPaths.single.single, endsWith('.png'));
    expect(harness.share.texts.single, beforeAfterInviteText);
    expect(harness.share.subjects.single, isNotNull);
    expect(
      harness.retention.value.log.events
          .where((event) => event.name == RetentionEventName.cardShared),
      hasLength(1),
    );
    expect(find.text('Shared'), findsOneWidget);
    await harness.service.dispose();
  });

  testWidgets('web keeps the download-only share path', (tester) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    harness.exporter.webDownload = true;
    await harness.seedTake(
      id: 'a',
      createdAt: DateTime.utc(2026, 10, 1, 12),
      pieceId: 'greensleeves',
    );
    await harness.seedTake(
      id: 'b',
      createdAt: DateTime.utc(2026, 10, 13, 12),
      pieceId: 'greensleeves',
    );

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('before-after-share')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('before-after-share')));
    await tester.pumpAndSettle();

    expect(harness.exporter.requests, hasLength(1));
    expect(harness.share.sharedPaths, isEmpty);
    expect(find.text('Card saved'), findsOneWidget);
    expect(find.textContaining('downloads folder'), findsOneWidget);
    expect(
      harness.retention.value.log.events
          .where((event) => event.name == RetentionEventName.cardShared),
      isEmpty,
    );
    await harness.service.dispose();
  });

  testWidgets('a cancelled share says Share cancelled, not Card saved', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    harness.share.result = const TakeShareResult(TakeShareStatus.cancelled);
    await harness.seedTake(
      id: 'a',
      createdAt: DateTime.utc(2026, 10, 1, 12),
      pieceId: 'greensleeves',
    );
    await harness.seedTake(
      id: 'b',
      createdAt: DateTime.utc(2026, 10, 13, 12),
      pieceId: 'greensleeves',
    );

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('before-after-share')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('before-after-share')));
    await tester.pumpAndSettle();

    expect(find.text('Share cancelled'), findsOneWidget);
    expect(find.textContaining('Card saved as'), findsOneWidget);
    expect(find.text('Card saved'), findsNothing);
    expect(
      harness.retention.value.log.events
          .where((event) => event.name == RetentionEventName.cardShared),
      isEmpty,
    );
    await harness.service.dispose();
  });

  testWidgets('a gateway that throws keeps the card and records nothing', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    harness.share.failWith = StateError('gateway exploded');
    await harness.seedTake(
      id: 'a',
      createdAt: DateTime.utc(2026, 10, 1, 12),
      pieceId: 'greensleeves',
    );
    await harness.seedTake(
      id: 'b',
      createdAt: DateTime.utc(2026, 10, 13, 12),
      pieceId: 'greensleeves',
    );

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('before-after-share')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('before-after-share')));
    await tester.pumpAndSettle();

    expect(find.text('Card saved'), findsOneWidget);
    expect(find.textContaining('share sheet could not open'), findsOneWidget);
    expect(find.text('Could not share'), findsNothing);
    expect(
      harness.retention.value.log.events
          .where((event) => event.name == RetentionEventName.cardShared),
      isEmpty,
    );
    await harness.service.dispose();
  });

  testWidgets('a share write failure says Could not share', (tester) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    harness.exporter.failWith = const RecordingExportException(
      'Could not write the card.',
    );
    await harness.seedTake(
      id: 'a',
      createdAt: DateTime.utc(2026, 10, 1, 12),
      pieceId: 'greensleeves',
    );
    await harness.seedTake(
      id: 'b',
      createdAt: DateTime.utc(2026, 10, 13, 12),
      pieceId: 'greensleeves',
    );

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('before-after-share')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('before-after-share')));
    await tester.pumpAndSettle();

    expect(find.text('Could not share'), findsOneWidget);
    expect(find.text('Could not export'), findsNothing);
    expect(find.text('Could not write the card.'), findsOneWidget);
    await harness.service.dispose();
  });

  testWidgets('one take shows an honest empty state', (tester) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await harness.seedTake(
      id: 'a',
      createdAt: DateTime.utc(2026, 10, 1, 12),
      pieceId: 'greensleeves',
    );

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    expect(find.text('No before/after yet'), findsOneWidget);
    expect(harness.exporter.requests, isEmpty);
    await harness.service.dispose();
  });

  testWidgets('fits a 1200px viewport', (tester) async {
    _useSize(tester, const Size(1200, 900));
    final harness = _Harness();
    await harness.seedTake(
      id: 'a',
      createdAt: DateTime.utc(2026, 10, 1, 12),
      pieceId: 'greensleeves',
    );
    await harness.seedTake(
      id: 'b',
      createdAt: DateTime.utc(2026, 10, 13, 12),
      pieceId: 'greensleeves',
    );

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    expect(find.text('Before / after'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });
}
