import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/pieces/launch_pieces.dart';
import 'package:hear_me_out/content/pieces/phrase_objectives.dart';
import 'package:hear_me_out/core/audio/loudness.dart';
import 'package:hear_me_out/core/audio/phrase_recorder.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/audio/wav.dart';
import 'package:hear_me_out/core/learning/progress.dart';
import 'package:hear_me_out/core/media/media_store.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/media/recording_index_store.dart';
import 'package:hear_me_out/core/media/recording_service.dart';
import 'package:hear_me_out/core/music/note_event.dart';
import 'package:hear_me_out/core/music/phrase.dart';
import 'package:hear_me_out/core/music/piece.dart';
import 'package:hear_me_out/core/storage/progress_store.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
import 'package:hear_me_out/features/recordings/compare_takes_screen.dart';
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
    double amplitude = 0.2,
    String? pieceId,
    String? phraseId,
    Uint8List? bytes,
  }) async {
    final audio = bytes ?? _toneBytes(amplitude: amplitude);
    await store.put(
      audio,
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
        byteLength: audio.length,
        durationMs: 1000,
        pieceId: pieceId,
        phraseId: phraseId,
      ),
    );
    await indexStore.save(indexStore.value!);
  }
}

Uint8List _toneBytes({double amplitude = 0.2}) {
  return encodeWavPcm16(
    WavData(
      sampleRate: 8000,
      channels: 1,
      samples: List<double>.filled(8000, amplitude),
    ),
  );
}

Widget _build(_Harness harness, {PhraseObjectiveRegistry? registry}) {
  return ProviderScope(
    overrides: [
      recordingServiceProvider.overrideWithValue(AsyncData(harness.service)),
      takePlayerProvider.overrideWithValue(harness.player),
      soundServiceProvider.overrideWithValue(FakeSoundService()),
      retentionStoreProvider.overrideWithValue(harness.retention),
      progressStoreProvider.overrideWithValue(harness.progressStore),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: CompareTakesScreen(registry: registry),
    ),
  );
}

void _useSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

PhraseObjectiveRegistry _registryWithTempo() {
  final registry = PhraseObjectiveRegistry();
  const phrase = Phrase(
    id: 'p1',
    bars: 1,
    timeSignature: TimeSignature(4, 4),
    events: <NoteEvent>[],
    targetTempoBpm: 72,
  );
  registry.registerPhrase(
    piece: launchPieces.first.piece,
    phrase: phrase,
    stage: 1,
  );
  return registry;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the pair with date, length, and tempo', (tester) async {
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

    await tester.pumpWidget(_build(harness, registry: _registryWithTempo()));
    await tester.pumpAndSettle();

    expect(find.text('Compare takes'), findsOneWidget);
    expect(find.text('TAKE A'), findsOneWidget);
    expect(find.text('TAKE B'), findsOneWidget);
    expect(find.text('Target 72 BPM'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('compare-length-left')), findsOneWidget);
    expect(find.byKey(const ValueKey('compare-date-left')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });

  testWidgets('playing both sides applies the same loudness', (tester) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await harness.seedTake(
      id: 'a',
      createdAt: DateTime.utc(2026, 10, 1, 12),
      amplitude: 0.02,
      pieceId: 'greensleeves',
    );
    await harness.seedTake(
      id: 'b',
      createdAt: DateTime.utc(2026, 10, 13, 12),
      amplitude: 0.8,
      pieceId: 'greensleeves',
    );
    final quietBytes = await harness.store.get('a');
    final loudBytes = await harness.store.get('b');

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('compare-play-left')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compare-play-right')));
    await tester.pumpAndSettle();

    expect(harness.player.played, hasLength(2));
    final left = measureWavLoudness(harness.player.played[0]).rmsDbfs;
    final right = measureWavLoudness(harness.player.played[1]).rmsDbfs;
    expect(left, closeTo(loudnessTargetRmsDbfs, 1.5));
    expect(right, closeTo(loudnessTargetRmsDbfs, 1.5));
    expect((left - right).abs(), lessThan(1.5));

    final quietSource = measureWavLoudness(quietBytes!).rmsDbfs;
    final loudSource = measureWavLoudness(loudBytes!).rmsDbfs;
    expect(quietSource, lessThan(loudSource));
    expect(left, greaterThan(quietSource));
    expect(right, lessThan(loudSource));
    expect(harness.player.played[0], isNot(quietBytes));
    expect(harness.player.played[1], isNot(loudBytes));

    // Comparison playback reads the take; it never rewrites the stored media.
    expect(await harness.store.get('a'), quietBytes);
    expect(await harness.store.get('b'), loudBytes);
    await harness.service.dispose();
  });

  testWidgets('a malformed take shows a typed error and plays nothing', (
    tester,
  ) async {
    _useSize(tester, const Size(390, 844));
    final harness = _Harness();
    await harness.seedTake(
      id: 'a',
      createdAt: DateTime.utc(2026, 10, 1, 12),
      pieceId: 'greensleeves',
      bytes: Uint8List.fromList(<int>[1, 2, 3, 4, 5]),
    );
    await harness.seedTake(
      id: 'b',
      createdAt: DateTime.utc(2026, 10, 13, 12),
      pieceId: 'greensleeves',
    );

    await tester.pumpWidget(_build(harness));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('compare-play-left')));
    await tester.pumpAndSettle();

    expect(find.text('This take could not be normalized.'), findsWidgets);
    expect(harness.player.played, isEmpty);
    await harness.service.dispose();
  });

  testWidgets('export and delete act on a take', (tester) async {
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

    await tester.tap(find.byKey(const ValueKey('compare-export-left')));
    await tester.pumpAndSettle();
    expect(harness.exporter.requests, hasLength(1));
    expect(harness.exporter.requests.single.mimeType, 'audio/wav');

    await tester.tap(find.byKey(const ValueKey('compare-delete-right')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(await harness.store.get('b'), isNull);
    expect(
      harness.indexStore.value!.takes.map((take) => take.id),
      isNot(contains('b')),
    );
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

    expect(find.text('At least two takes are needed'), findsOneWidget);
    await harness.service.dispose();
  });

  testWidgets('fits a 1200px viewport side by side', (tester) async {
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

    expect(find.text('Compare takes'), findsOneWidget);
    expect(find.text('TAKE A'), findsOneWidget);
    expect(find.text('TAKE B'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await harness.service.dispose();
  });
}
