import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_recorder.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/audio/wav.dart';
import 'package:hear_me_out/core/media/media_store.dart';
import 'package:hear_me_out/core/media/recording_encoder.dart';
import 'package:hear_me_out/core/media/recording_index.dart';
import 'package:hear_me_out/core/media/recording_index_store.dart';
import 'package:hear_me_out/core/media/recording_service.dart';

import 'support/fakes.dart';

class _Harness {
  _Harness({
    bool permission = true,
    int sampleRate = 8000,
    List<Uint8List>? chunks,
    int takeLimit = 20,
    int byteLimit = RecordingService.defaultByteLimit,
    RecordingEncoder? encoder,
  }) : store = MemoryMediaStore(),
       indexStore = MemoryRecordingIndexStore(),
       exporter = FakeRecordingExporter(),
       timers = FakeRecordingTimerFactory() {
    capture = FakePcmCapture(
      permission: permission,
      chunks: chunks ?? <Uint8List>[_tone(sampleRate, seconds: 0.1)],
      config: PcmCaptureConfig(sampleRate: sampleRate, channels: 1),
    );
    service = RecordingService(
      store: store,
      indexStore: indexStore,
      exporter: exporter,
      clock: _nextTime,
      recorderFactory: () => PhraseRecorder(
        capture: capture,
        requestedSampleRate: sampleRate,
        outputSampleRate: sampleRate,
      ),
      encoder: encoder ?? const WavRecordingEncoder(),
      timerFactory: timers.call,
      takeLimit: takeLimit,
      byteLimit: byteLimit,
    );
  }

  final MemoryMediaStore store;
  final MemoryRecordingIndexStore indexStore;
  final FakeRecordingExporter exporter;
  final FakeRecordingTimerFactory timers;
  late final FakePcmCapture capture;
  late final RecordingService service;

  DateTime _now = DateTime.utc(2026, 1, 1, 12);

  DateTime _nextTime() {
    final value = _now;
    _now = _now.add(const Duration(seconds: 1));
    return value;
  }

  Future<RecordingStopResult> record({
    String? pieceId,
    String? phraseId,
  }) async {
    final start = await service.start(pieceId: pieceId, phraseId: phraseId);
    expect(start.started, isTrue, reason: 'start failed: ${start.failure}');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return service.stop();
  }
}

Uint8List _tone(int sampleRate, {double seconds = 0.1}) {
  final samples = <double>[
    for (var index = 0; index < (sampleRate * seconds).round(); index++) 0.2,
  ];
  return pcm16Bytes(samples);
}

class _FixedEncoder implements RecordingEncoder {
  @override
  String get mimeType => 'audio/x-test';

  @override
  String get fileExtension => 'test';

  @override
  Uint8List encode(List<double> samples, {required int sampleRate}) =>
      Uint8List.fromList(<int>[1, 2, 3, 4]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'permission denied returns a typed failure and starts no capture',
    () async {
      final harness = _Harness(permission: false);

      final result = await harness.service.start();

      expect(result.started, isFalse);
      expect(result.failure!.kind, RecordingFailureKind.permissionDenied);
      expect(harness.capture.startCalls, 0);
      expect(await harness.store.list(), isEmpty);
      await harness.service.dispose();
    },
  );

  test(
    'the 60-second timer auto-stops, truncates, and marks the take capped',
    () async {
      final harness = _Harness(
        sampleRate: 8000,
        chunks: <Uint8List>[_tone(8000, seconds: 61)],
      );

      final started = await harness.service.start();
      expect(started.started, isTrue);
      await Future<void>.delayed(Duration.zero);

      final timer = harness.timers.timers.single;
      expect(timer.duration, const Duration(seconds: 60));
      final autoStop = harness.service.autoStopResults.first;
      timer.fire();
      final result = await autoStop;

      expect(result.saved, isTrue);
      expect(result.capped, isTrue);
      expect(result.take!.durationMs, 60000);
      expect(result.take!.capped, isTrue);
      final bytes = await harness.store.get(result.take!.id);
      expect(bytes, isNotNull);
      expect(parseWav(bytes!).duration, const Duration(seconds: 60));
      expect(harness.service.isRecording, isFalse);
      await harness.service.dispose();
    },
  );

  test(
    'a second start while live is busy and opens no second capture',
    () async {
      final harness = _Harness();
      final first = await harness.service.start();
      expect(first.started, isTrue);

      final second = await harness.service.start();
      expect(second.started, isFalse);
      expect(second.failure!.kind, RecordingFailureKind.busy);
      expect(harness.capture.startCalls, 1);

      await Future<void>.delayed(Duration.zero);
      final result = await harness.service.stop();
      expect(result.saved, isTrue);
      await harness.service.dispose();
    },
  );

  test(
    'a full global quota returns a typed failure before opening the mic',
    () async {
      final harness = _Harness();
      var index = RecordingIndex.empty;
      for (var i = 0; i < RecordingService.defaultTakeLimit; i++) {
        final ref = await harness.store.put(
          Uint8List.fromList(<int>[1, 2, 3]),
          mimeType: RecordingService.wavMimeType,
          id: 'take-$i',
          durationMs: 1000,
        );
        index = index.add(RecordingTake.fromMediaRef(ref));
      }
      await harness.indexStore.save(index);

      final result = await harness.service.start();

      expect(result.started, isFalse);
      expect(result.failure!.kind, RecordingFailureKind.quota);
      expect(result.failure!.message, contains('Delete one'));
      expect(harness.capture.startCalls, 0);
      await harness.service.dispose();
    },
  );

  test('the byte cap is a typed quota failure', () async {
    final harness = _Harness(byteLimit: 100);

    final start = await harness.service.start();
    expect(start.started, isTrue);
    await Future<void>.delayed(Duration.zero);
    final result = await harness.service.stop();

    expect(result.saved, isFalse);
    expect(result.failure!.kind, RecordingFailureKind.quota);
    expect(await harness.store.list(), isEmpty);
    await harness.service.dispose();
  });

  test(
    'a store failure preserves existing takes and indexes nothing new',
    () async {
      final store = ToggleMediaStore();
      final indexStore = MemoryRecordingIndexStore();
      final exporter = FakeRecordingExporter();
      final capture = FakePcmCapture(
        chunks: <Uint8List>[_tone(8000)],
        config: const PcmCaptureConfig(sampleRate: 8000, channels: 1),
      );
      final service = RecordingService(
        store: store,
        indexStore: indexStore,
        exporter: exporter,
        clock: DateTime.now,
        recorderFactory: () => PhraseRecorder(
          capture: capture,
          requestedSampleRate: 8000,
          outputSampleRate: 8000,
        ),
      );

      final firstStart = await service.start();
      expect(firstStart.started, isTrue);
      await Future<void>.delayed(Duration.zero);
      final first = await service.stop();
      expect(first.saved, isTrue);
      final firstBytes = await store.get(first.take!.id);
      expect(firstBytes, isNotNull);

      store.failPuts = true;
      final secondStart = await service.start();
      expect(secondStart.started, isTrue);
      await Future<void>.delayed(Duration.zero);
      final second = await service.stop();

      expect(second.saved, isFalse);
      expect(second.failure!.kind, RecordingFailureKind.storage);
      expect(await store.list(), hasLength(1));
      expect(await store.get(first.take!.id), firstBytes);
      expect((await service.listTakes()).single.id, first.take!.id);
      await service.dispose();
    },
  );

  test('delete one and clear all update the store and the index', () async {
    final harness = _Harness();
    final first = await harness.record();
    final second = await harness.record();
    expect(await harness.store.list(), hasLength(2));

    final deleteFailure = await harness.service.deleteTake(first.take!.id);
    expect(deleteFailure, isNull);
    expect(await harness.store.get(first.take!.id), isNull);
    expect((await harness.service.listTakes()).single.id, second.take!.id);

    final clearFailure = await harness.service.clearAll();
    expect(clearFailure, isNull);
    expect(await harness.store.list(), isEmpty);
    expect(await harness.service.listTakes(), isEmpty);
    await harness.service.dispose();
  });

  test('export sends the stored bytes and never mutates the take', () async {
    final harness = _Harness();
    final saved = await harness.record();
    final id = saved.take!.id;
    final beforeBytes = await harness.store.get(id);
    final beforeRefs = await harness.store.list();
    final beforeIndex = harness.indexStore.value;

    final outcome = await harness.service.exportTake(id);

    expect(outcome.exported, isTrue);
    expect(outcome.result!.fileName, 'recording-$id.wav');
    final request = harness.exporter.requests.single;
    expect(request.bytes, beforeBytes);
    expect(request.mimeType, RecordingService.wavMimeType);
    expect(await harness.store.get(id), beforeBytes);
    expect(await harness.store.list(), beforeRefs);
    expect(harness.indexStore.value, beforeIndex);
    await harness.service.dispose();
  });

  test(
    'the encoder seam controls stored bytes, mime type, and export name',
    () async {
      final harness = _Harness(encoder: _FixedEncoder());
      final saved = await harness.record();
      final id = saved.take!.id;
      final ref = (await harness.store.list()).single;

      expect(ref.mimeType, 'audio/x-test');
      expect(await harness.store.get(id), <int>[1, 2, 3, 4]);

      final outcome = await harness.service.exportTake(id);
      expect(outcome.result!.fileName, 'recording-$id.test');
      expect(harness.exporter.requests.single.mimeType, 'audio/x-test');
      await harness.service.dispose();
    },
  );

  test(
    'first and last take per piece are kept and a middle take is deleted',
    () async {
      final harness = _Harness();
      final first = await harness.record(pieceId: 'ode-to-joy');
      final middle = await harness.record(pieceId: 'ode-to-joy');
      final last = await harness.record(pieceId: 'ode-to-joy');

      final takes = await harness.service.listTakes();
      expect(
        takes.map((take) => take.id),
        containsAll(<String>[first.take!.id, last.take!.id]),
      );
      expect(takes.map((take) => take.id), isNot(contains(middle.take!.id)));
      expect(takes, hasLength(2));
      expect(await harness.store.get(middle.take!.id), isNull);
      expect(await harness.store.get(first.take!.id), isNotNull);
      expect(await harness.store.get(last.take!.id), isNotNull);
      await harness.service.dispose();
    },
  );

  test(
    'reconcile deletes unreferenced blobs and drops missing entries',
    () async {
      final harness = _Harness();
      final saved = await harness.record();
      final keptId = saved.take!.id;

      await harness.store.put(
        Uint8List.fromList(<int>[9, 9, 9]),
        mimeType: RecordingService.wavMimeType,
        id: 'orphan-blob',
        durationMs: 100,
      );

      final first = await harness.service.reconcile();

      expect(first.deletedOrphans, 1);
      expect(await harness.store.get('orphan-blob'), isNull);
      expect(await harness.store.get(keptId), isNotNull);
      expect((await harness.service.listTakes()).single.id, keptId);

      await harness.store.delete(keptId);
      final second = await harness.service.reconcile();

      expect(second.removedIndexEntries, 1);
      expect(await harness.service.listTakes(), isEmpty);
      await harness.service.dispose();
    },
  );

  test(
    'an unreadable index is rebuilt from existing blobs instead of deleted',
    () async {
      final store = MemoryMediaStore();
      final indexStore = MemoryRecordingIndexStore();
      final capture = FakePcmCapture(
        chunks: <Uint8List>[_tone(8000)],
        config: const PcmCaptureConfig(sampleRate: 8000, channels: 1),
      );
      final service = RecordingService(
        store: store,
        indexStore: indexStore,
        exporter: FakeRecordingExporter(),
        clock: DateTime.now,
        recorderFactory: () => PhraseRecorder(
          capture: capture,
          requestedSampleRate: 8000,
          outputSampleRate: 8000,
        ),
      );
      await store.put(
        Uint8List.fromList(<int>[1, 2, 3]),
        mimeType: RecordingService.wavMimeType,
        id: 'existing',
        durationMs: 100,
      );

      final report = await service.reconcile();

      expect(report.adoptedBlobs, 1);
      expect(await store.get('existing'), isNotNull);
      expect((await service.listTakes()).single.id, 'existing');
      await service.dispose();
    },
  );
}
