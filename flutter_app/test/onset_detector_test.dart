import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/onset_detector.dart';

import 'support/audio_fixtures.dart';

const sampleRate = 22050.0;

void main() {
  late OnsetDetector detector;

  setUp(() {
    detector = OnsetDetector(sampleRate: sampleRate);
  });

  group('OnsetDetector', () {
    test('empty and short buffers produce no onsets', () {
      expect(detector.detect(const []), isEmpty);
      expect(detector.detect(List<double>.filled(100, 0)), isEmpty);
    });

    test('digital silence produces no onsets', () {
      expect(detector.detect(silentTake(22050, 2)), isEmpty);
    });

    test('a 60 BPM click train is detected on the beat', () {
      final samples = silentTake(22050, 6);
      for (var index = 0; index < 5; index++) {
        addClick(samples, 22050, startSeconds: 0.5 + index, seed: index);
      }
      final onsets = detector.detect(samples);
      expect(onsets.length, 5);
      for (var index = 0; index < onsets.length; index++) {
        expect(
          onsets[index].timeSeconds,
          closeTo(0.5 + index, 0.015),
          reason: 'onset $index',
        );
        expect(onsets[index].strength, greaterThan(0.4));
        expect(
          onsets[index].timeSeconds,
          closeTo(
            onsets[index].sampleIndex / sampleRate,
            1e-12,
          ),
        );
      }
    });

    test('a 90 BPM click train is detected on the beat', () {
      final samples = silentTake(22050, 5);
      final beat = 60 / 90;
      for (var index = 0; index < 5; index++) {
        addClick(samples, 22050, startSeconds: 0.5 + index * beat, seed: index);
      }
      final onsets = detector.detect(samples);
      expect(onsets.length, 5);
      for (var index = 0; index < onsets.length; index++) {
        expect(
          onsets[index].timeSeconds,
          closeTo(0.5 + index * beat, 0.015),
          reason: 'onset $index',
        );
      }
    });

    test('two attacks 50 ms apart merge because 50 ms is the minimum gap', () {
      // Documented limit: on the default 11.6 ms hop, a 50 ms separation is
      // below `minGapSeconds` and is reported as one onset. Faster passage
      // work needs a smaller minimum gap.
      final samples = silentTake(22050, 2);
      addTone(
        samples,
        22050,
        startSeconds: 0.5,
        durationSeconds: 0.4,
        midi: 69,
        attackSeconds: 0.003,
      );
      addTone(
        samples,
        22050,
        startSeconds: 0.55,
        durationSeconds: 0.4,
        midi: 76,
        attackSeconds: 0.003,
      );
      final onsets = detector.detect(samples);
      expect(onsets.length, 1);
    });

    test('a quiet take still produces onsets', () {
      final samples = silentTake(22050, 4);
      for (var index = 0; index < 4; index++) {
        addTone(
          samples,
          22050,
          startSeconds: 0.5 + index,
          durationSeconds: 0.5,
          midi: 60 + index * 2,
          amplitude: 0.06,
          attackSeconds: 0.003,
        );
      }
      final onsets = detector.detect(samples);
      expect(onsets.length, 4);
      for (var index = 0; index < onsets.length; index++) {
        expect(onsets[index].timeSeconds, closeTo(0.5 + index, 0.015));
      }
    });

    test('steady white noise produces no onsets', () {
      final samples = silentTake(22050, 3);
      addWhiteNoise(samples, amplitude: 0.1, seed: 42);
      expect(detector.detect(samples), isEmpty);
    });

    test('a soft attack is detected', () {
      final samples = silentTake(22050, 3);
      addTone(
        samples,
        22050,
        startSeconds: 0.5,
        durationSeconds: 1,
        midi: 55,
        attackSeconds: 0.12,
      );
      final onsets = detector.detect(samples);
      expect(onsets.length, 1);
      expect(onsets.first.timeSeconds, closeTo(0.5, 0.03));
    });

    test('a body thump is reported with low strength', () {
      final samples = silentTake(22050, 2);
      addTone(
        samples,
        22050,
        startSeconds: 0.5,
        durationSeconds: 0.3,
        midi: 35,
        amplitude: 0.6,
        harmonics: const [1.0],
        attackSeconds: 0.002,
        decaySeconds: 0.08,
      );
      final onsets = detector.detect(samples);
      expect(onsets.length, 1);
      expect(onsets.first.strength, lessThan(0.3));
    });

    test('note releases do not create phantom onsets', () {
      final samples = silentTake(22050, 6);
      for (var index = 0; index < 5; index++) {
        addTone(
          samples,
          22050,
          startSeconds: 0.5 + index,
          durationSeconds: 0.8,
          midi: 64 + index,
        );
      }
      final onsets = detector.detect(samples);
      expect(onsets.length, 5);
      for (var index = 0; index < onsets.length; index++) {
        expect(onsets[index].timeSeconds, closeTo(0.5 + index, 0.015));
      }
    });

    test('a vibrato note keeps a single attack', () {
      final samples = silentTake(22050, 2);
      addTone(
        samples,
        22050,
        startSeconds: 0.5,
        durationSeconds: 1,
        midi: 64,
        vibratoCents: 25,
      );
      final onsets = detector.detect(samples);
      expect(onsets.length, 1);
      expect(onsets.first.timeSeconds, closeTo(0.5, 0.02));
    });

    test('30 seconds of 22.05 kHz audio analyzes in well under 2 seconds', () {
      final samples = silentTake(22050, 30);
      for (var index = 0; index < 40; index++) {
        addClick(samples, 22050, startSeconds: 0.5 + index * 0.7, seed: index);
      }
      final stopwatch = Stopwatch()..start();
      final onsets = detector.detect(samples);
      stopwatch.stop();
      expect(onsets.length, 40);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'analyzed 30 s in ${stopwatch.elapsedMilliseconds} ms',
      );
    });
  });
}
