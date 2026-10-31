import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/yin.dart';

void main() {
  const sampleRate = 22050.0;
  const length = 2048;

  List<double> tone(
    double frequency, {
    bool harmonics = true,
    bool decay = false,
    double amplitude = 0.5,
  }) {
    final samples = <double>[];
    for (var index = 0; index < length; index++) {
      final time = index / sampleRate;
      var sample = sin(2 * pi * frequency * time);
      if (harmonics) {
        sample += 0.3 * sin(2 * pi * frequency * 2 * time);
        sample += 0.12 * sin(2 * pi * frequency * 3 * time);
      }
      if (decay) {
        sample *= exp(-4 * time);
      }
      samples.add(sample * amplitude);
    }
    return samples;
  }

  final detector = YinPitchDetector(
    sampleRate: sampleRate,
    minFrequency: 70,
    maxFrequency: 1000,
  );

  group('YIN detects guitar-range pitches', () {
    for (final entry in {
      'E2': 82.4069,
      'A2': 110.0,
      'D3': 146.832,
      'G3': 195.998,
      'B3': 246.942,
      'E4': 329.628,
      'F#4': 369.994,
      'Bb4': 466.164,
      'E5': 659.255,
    }.entries) {
      test('${entry.key} (${entry.value.toStringAsFixed(1)} Hz)', () {
        final estimate = detector.detect(tone(entry.value));
        expect(estimate.voiced, isTrue);
        expect(estimate.clarity, greaterThan(0.9));
        final error = (estimate.frequency - entry.value).abs() / entry.value;
        expect(error, lessThan(0.01), reason: 'detected ${estimate.frequency}');
      });
    }

    test('a decaying plucked note is still detected', () {
      final estimate = detector.detect(tone(196.0, decay: true));
      expect(estimate.voiced, isTrue);
      expect((estimate.frequency - 196.0).abs() / 196.0, lessThan(0.01));
    });

    test('A4 at 440 Hz is detected', () {
      final estimate = detector.detect(tone(440));
      expect(estimate.voiced, isTrue);
      expect((estimate.frequency - 440).abs(), lessThan(2));
    });
  });

  group('Silence and noise are rejected', () {
    test('digital silence is unvoiced', () {
      final estimate = detector.detect(List<double>.filled(length, 0));
      expect(estimate.voiced, isFalse);
      expect(estimate.frequency, 0);
    });

    test('white noise is unvoiced', () {
      final random = Random(42);
      final samples = [
        for (var index = 0; index < length; index++)
          (random.nextDouble() * 2 - 1) * 0.1,
      ];
      final estimate = detector.detect(samples);
      expect(estimate.voiced, isFalse);
    });

    test('a very quiet tone is gated out', () {
      final estimate = detector.detect(tone(440, amplitude: 0.001));
      expect(estimate.voiced, isFalse);
    });
  });
}
