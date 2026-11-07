import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_recorder.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/audio/wav.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/media/media_store.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/media/recording_index_store.dart';
import 'package:hear_me_out/core/media/recording_service.dart';
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
