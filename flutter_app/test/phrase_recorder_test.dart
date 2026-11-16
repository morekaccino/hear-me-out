import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_recorder.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/audio/yin.dart';

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

/// Duplicates a tone into the left channel and leaves the right silent.
Uint8List stereoBytes(int sampleRate, {double seconds = 0.5}) {
  final mono = silentTake(sampleRate, seconds);
  addTone(
    mono,
    sampleRate,
    startSeconds: 0.02,
    durationSeconds: seconds - 0.04,
    midi: 69,
  );
  final buffer = ByteData(mono.length * 4);
  var offset = 0;
  for (final sample in mono) {
    buffer.setInt16(
      offset,
      (sample.clamp(-1.0, 1.0) * 32767).round(),
      Endian.little,
    );
    buffer.setInt16(offset + 2, 0, Endian.little);
    offset += 4;
  }
  return buffer.buffer.asUint8List();
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
      'uses the effective stereo 48 kHz format and downmixes to mono',
      () async {
        final capture = FakePcmCapture(
          chunks: [stereoBytes(48000)],
          config: const PcmCaptureConfig(sampleRate: 48000, channels: 2),
        );
        final recorder = PhraseRecorder(capture: capture);

        expect(await recorder.start(), isTrue);
        await Future<void>.delayed(Duration.zero);
        final take = await recorder.stop();

        expect(take.sourceSampleRate, 48000);
        expect(take.sourceChannels, 2);
        expect(take.sampleRate, PhraseRecorder.analysisSampleRate);
        expect(take.durationSeconds, closeTo(0.5, 0.02));

        // The fixture is left-only. A mono downmix must carry that signal, and
        // resampling must keep it at 440 Hz rather than silence or a shifted
        // pitch.
        final estimate = YinPitchDetector(
          sampleRate: take.sampleRate.toDouble(),
        ).detect(take.samples.sublist(0, 8192));
        expect(estimate.rms, greaterThan(0.005));
        expect(estimate.voiced, isTrue);
        expect(estimate.frequency, closeTo(440, 5));
        await recorder.dispose();
      },
    );

    test(
      'take length comes from the sample clock, not elapsed wall time',
      () async {
        final capture = FakePcmCapture(
          chunks: [toneBytes(48000, seconds: 0.25)],
          config: const PcmCaptureConfig(sampleRate: 48000, channels: 1),
        );
        final recorder = PhraseRecorder(capture: capture);

        expect(await recorder.start(), isTrue);
        await Future<void>.delayed(const Duration(milliseconds: 40));
        final take = await recorder.stop();

        // The fixture holds 0.25 s of samples. A wall-clock stopwatch would
        // also add the 40 ms wait and land at 0.29 s, outside the tolerance.
        expect(take.durationSeconds, closeTo(0.25, 0.02));
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

    test('falls back to 44.1 kHz when 48 kHz startup fails', () async {
      final capture = FakePcmCapture(
        failSampleRates: {48000},
        chunks: [toneBytes(44100)],
        config: const PcmCaptureConfig(sampleRate: 44100, channels: 1),
      );
      final recorder = PhraseRecorder(capture: capture);

      expect(await recorder.start(), isTrue);
      expect(capture.startAttempts, [48000, 44100]);
      // The failed 48 kHz attempt is stopped before the retry.
      expect(capture.stopCalls, 1);

      await Future<void>.delayed(Duration.zero);
      final take = await recorder.stop();
      expect(take.sourceSampleRate, 44100);
      expect(take.sampleRate, PhraseRecorder.analysisSampleRate);
      expect(take.durationSeconds, closeTo(1.0, 0.02));
      expect(capture.stopCalls, 2);
      await recorder.dispose();
    });

    test('ignores a format correction after the first sample', () async {
      final capture = FakePcmCapture(
        chunks: [toneBytes(48000, seconds: 0.25)],
        config: const PcmCaptureConfig(sampleRate: 48000, channels: 1),
      );
      final recorder = PhraseRecorder(capture: capture);

      expect(await recorder.start(), isTrue);
      await Future<void>.delayed(Duration.zero);
      capture.changeConfig(
        const PcmCaptureConfig(sampleRate: 44100, channels: 1),
      );
      await Future<void>.delayed(Duration.zero);

      final take = await recorder.stop();
      expect(take.sourceSampleRate, 48000);
      expect(take.durationSeconds, closeTo(0.25, 0.02));
      await recorder.dispose();
    });

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
