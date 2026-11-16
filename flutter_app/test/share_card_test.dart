import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_recorder.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/audio/wav.dart';
import 'package:hear_me_out/core/media/before_after_share.dart';
import 'package:hear_me_out/core/media/media_store.dart';
import 'package:hear_me_out/core/media/recording_index_store.dart';
import 'package:hear_me_out/core/media/recording_service.dart';
import 'package:hear_me_out/core/media/take_share_gateway.dart';
import 'package:hear_me_out/core/retention/retention_event.dart';
import 'package:hear_me_out/core/storage/retention_store.dart';
import 'package:hear_me_out/state/providers.dart';
import 'package:hear_me_out/state/recording_controller.dart';

import 'support/fakes.dart';

class _Harness {
  _Harness({bool optIn = true})
    : retention = MemoryRetentionStore(optIn: optIn) {
    capture = FakePcmCapture(
      chunks: <Uint8List>[_toneBytes()],
      config: const PcmCaptureConfig(sampleRate: 8000, channels: 1),
    );
    service = RecordingService(
      store: store,
      indexStore: indexStore,
      exporter: exporter,
      clock: () => DateTime.utc(2026, 11, 16, 12),
      recorderFactory: () => PhraseRecorder(
        capture: capture,
        requestedSampleRate: 8000,
        outputSampleRate: 8000,
      ),
      timerFactory: timers.call,
    );
    container = ProviderContainer(
      overrides: [
        recordingServiceProvider.overrideWithValue(AsyncData(service)),
        recordingExporterProvider.overrideWithValue(AsyncData(exporter)),
        takeShareGatewayProvider.overrideWithValue(share),
        retentionStoreProvider.overrideWithValue(retention),
      ],
    );
    addTearDown(container.dispose);
  }

  final MemoryMediaStore store = MemoryMediaStore();
  final MemoryRecordingIndexStore indexStore = MemoryRecordingIndexStore();
  final FakeRecordingExporter exporter = FakeRecordingExporter();
  final FakeRecordingTimerFactory timers = FakeRecordingTimerFactory();
  final FakeTakeShareGateway share = FakeTakeShareGateway();
  final MemoryRetentionStore retention;
  late final FakePcmCapture capture;
  late final RecordingService service;
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

  int cardSharedCount() => retention.value.log.events
      .where((event) => event.name == RetentionEventName.cardShared)
      .length;
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the invitation is pinned and makes no score or ranking claim', () {
    expect(
      beforeAfterInviteText,
      'I practice guitar with Hear Me Out. If you want to read music and play '
      'guitar too, here is my progress card.',
    );
    final lower = beforeAfterInviteText.toLowerCase();
    for (final banned in <String>[
      'score',
      'percent',
      '%',
      'rank',
      'leaderboard',
      'better',
      'best',
      'worse',
      'worst',
      'compare',
      'comparison',
      'beat',
      'streak',
      'http',
    ]) {
      expect(lower, isNot(contains(banned)), reason: 'contains "$banned"');
    }
  });

  test('a successful share records one card_shared event', () async {
    final harness = _Harness();
    final controller = await harness.controller();

    final outcome = await controller.shareBeforeAfterCard(
      path: '/exports/card.png',
      fileName: 'card.png',
    );

    expect(outcome.status, CardShareStatus.shared);
    expect(harness.share.sharedPaths, <List<String>>[
      <String>['/exports/card.png'],
    ]);
    expect(harness.share.texts.single, beforeAfterInviteText);
    expect(harness.share.subjects.single, beforeAfterShareSubject);
    expect(outcome.message, isNot(contains('/exports')));
    expect(harness.cardSharedCount(), 1);
    await harness.service.dispose();
  });

  test('cancelled, unavailable, and failed shares record nothing', () async {
    final harness = _Harness();
    final controller = await harness.controller();

    harness.share.result = const TakeShareResult(TakeShareStatus.cancelled);
    final cancelled = await controller.shareBeforeAfterCard(
      path: '/exports/card.png',
      fileName: 'card.png',
    );
    expect(cancelled.status, CardShareStatus.cancelled);
    expect(cancelled.message, 'Card saved as card.png. Share cancelled.');
    expect(cancelled.message, isNot(contains('/exports')));
    expect(harness.cardSharedCount(), 0);

    for (final status in <TakeShareStatus>[
      TakeShareStatus.unavailable,
      TakeShareStatus.failed,
    ]) {
      harness.share.result = TakeShareResult(status);
      final outcome = await controller.shareBeforeAfterCard(
        path: '/exports/card.png',
        fileName: 'card.png',
      );
      expect(outcome.status, CardShareStatus.exported);
      expect(outcome.message, contains('card.png'));
      expect(outcome.message, isNot(contains('/exports')));
      expect(harness.cardSharedCount(), 0, reason: 'status $status');
    }

    await harness.service.dispose();
  });

  test('a gateway that throws keeps the file and records nothing', () async {
    final harness = _Harness();
    final controller = await harness.controller();
    harness.share.failWith = StateError('gateway exploded');

    final outcome = await controller.shareBeforeAfterCard(
      path: '/exports/card.png',
      fileName: 'card.png',
    );

    expect(outcome.status, CardShareStatus.exported);
    expect(
      outcome.message,
      'Card saved as card.png. The share sheet could not open.',
    );
    expect(outcome.message, isNot(contains('/exports')));
    expect(harness.cardSharedCount(), 0);
    await harness.service.dispose();
  });

  test('every successful share adds exactly one event', () async {
    final harness = _Harness();
    final controller = await harness.controller();

    await controller.shareBeforeAfterCard(
      path: '/exports/card.png',
      fileName: 'card.png',
    );
    await controller.shareBeforeAfterCard(
      path: '/exports/card.png',
      fileName: 'card.png',
    );

    expect(harness.cardSharedCount(), 2);
    await harness.service.dispose();
  });

  test('a download-only result never calls the share sheet', () async {
    final harness = _Harness();
    final controller = await harness.controller();

    final outcome = await controller.shareBeforeAfterCard(
      path: null,
      fileName: 'card.png',
    );

    expect(outcome.status, CardShareStatus.exported);
    expect(outcome.message, contains('Downloaded card.png'));
    expect(harness.share.sharedPaths, isEmpty);
    expect(harness.cardSharedCount(), 0);
    await harness.service.dispose();
  });

  test('a successful share records nothing when the log is opted out', () async {
    final harness = _Harness(optIn: false);
    final controller = await harness.controller();

    final outcome = await controller.shareBeforeAfterCard(
      path: '/exports/card.png',
      fileName: 'card.png',
    );

    expect(outcome.status, CardShareStatus.shared);
    expect(harness.cardSharedCount(), 0);
    await harness.service.dispose();
  });
}
