import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_recorder.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';

import 'support/audio_fixtures.dart';
import 'support/fakes.dart';

Uint8List toneBytes(int sampleRate, {double seconds = 1.0}) {
  final samples = silentTake(sampleRate, seconds);
  addTone(
    samples,
    sampleRate,
    startSeconds: 0.05,
    durationSeconds: seconds - 0.1,
    midi: 69,
  );
  return pcm16Bytes(samples);
}

void main() {
  group('PhraseRecorder', () {
    test('collects, resamples, flushes, and stops exactly once', () async {
      final capture = FakePcmCapture(
        chunks: [toneBytes(48000)],
        config: const PcmCaptureConfig(sampleRate: 48000, channels: 1),
      );
      final recorder = PhraseRecorder(capture: capture);

      expect(await recorder.start(), isTrue);
      expect(recorder.isRecording, isTrue);
      await Future<void>.delayed(Duration.zero);

      final take = await recorder.stop();
      expect(take.sampleRate, PhraseRecorder.analysisSampleRate);
      expect(take.sourceSampleRate, 48000);
      expect(take.sourceChannels, 1);
      expect(take.samples, isNotEmpty);
      expect(take.durationSeconds, closeTo(1.0, 0.02));
      expect(recorder.isRecording, isFalse);
      expect(recorder.sampleCount, 0);
      expect(capture.startCalls, 1);
      expect(capture.stopCalls, 1);

      final second = await recorder.stop();
      expect(second.samples, isEmpty);
      expect(capture.stopCalls, 1);

      await recorder.dispose();
      expect(capture.disposeCalls, 1);
      await recorder.dispose();
      expect(capture.disposeCalls, 1);
    });

    test(
      'a second start while running does not open a second capture',
      () async {
        final capture = FakePcmCapture(
          chunks: [toneBytes(48000, seconds: 0.5)],
          config: const PcmCaptureConfig(sampleRate: 48000, channels: 1),
        );
        final recorder = PhraseRecorder(capture: capture);

        expect(await recorder.start(), isTrue);
        expect(await recorder.start(), isTrue);
        expect(capture.startCalls, 1);
        await Future<void>.delayed(Duration.zero);

        final first = await recorder.stop();
        expect(first.samples, isNotEmpty);

        expect(await recorder.start(), isTrue);
        expect(capture.startCalls, 2);
        await Future<void>.delayed(Duration.zero);
        final second = await recorder.stop();
        expect(second.samples, isNotEmpty);
        expect(capture.stopCalls, 2);

        await recorder.dispose();
      },
    );

    test(
      'uses the effective 44.1 kHz format when the platform reports it',
      () async {
        final capture = FakePcmCapture(
          chunks: [toneBytes(44100)],
          config: const PcmCaptureConfig(sampleRate: 44100, channels: 1),
        );
        final recorder = PhraseRecorder(capture: capture);

        expect(await recorder.start(), isTrue);
        await Future<void>.delayed(Duration.zero);
        final take = await recorder.stop();

        expect(take.sourceSampleRate, 44100);
        expect(take.sampleRate, PhraseRecorder.analysisSampleRate);
        expect(take.durationSeconds, closeTo(1.0, 0.02));
        await recorder.dispose();
      },
    );

    test(
      'denied permission starts no capture and records no samples',
      () async {
        final capture = FakePcmCapture(permission: false);
        final recorder = PhraseRecorder(capture: capture);

        expect(await recorder.start(), isFalse);
        expect(recorder.isRecording, isFalse);
        expect(capture.startCalls, 0);
        expect(recorder.sampleCount, 0);
        await recorder.dispose();
      },
    );

    test('dispose stops an active take', () async {
      final capture = FakePcmCapture(
        chunks: [toneBytes(48000, seconds: 0.5)],
        config: const PcmCaptureConfig(sampleRate: 48000, channels: 1),
      );
      final recorder = PhraseRecorder(capture: capture);

      expect(await recorder.start(), isTrue);
      await Future<void>.delayed(Duration.zero);
      await recorder.dispose();

      expect(recorder.isRecording, isFalse);
      expect(capture.stopCalls, 1);
      expect(capture.disposeCalls, 1);
    });
  });
}
