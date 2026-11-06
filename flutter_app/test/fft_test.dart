import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/fft.dart';

void main() {
  group('Fft', () {
    test('rejects sizes that are not a power of two', () {
      expect(() => Fft(0), throwsArgumentError);
      expect(() => Fft(1), throwsArgumentError);
      expect(() => Fft(6), throwsArgumentError);
      expect(() => Fft(1000), throwsArgumentError);
    });

    test('supports every size used by the phrase pipeline', () {
      for (final size in [256, 512, 1024, 2048]) {
        final real = Float64List(size)..[0] = 1;
        final imaginary = Float64List(size);
        Fft(size).forward(real, imaginary);
        for (var index = 0; index < size; index++) {
          expect(real[index], closeTo(1, 1e-9));
          expect(imaginary[index], closeTo(0, 1e-9));
        }
      }
    });

    test('an impulse has a flat spectrum', () {
      const size = 256;
      final real = Float64List(size)..[0] = 1;
      final imaginary = Float64List(size);
      Fft(size).forward(real, imaginary);
      for (var index = 0; index < size; index++) {
        final magnitude = math.sqrt(
          real[index] * real[index] + imaginary[index] * imaginary[index],
        );
        expect(magnitude, closeTo(1, 1e-9));
      }
    });

    test('a sine wave peaks in the expected bin', () {
      const size = 512;
      const bin = 17;
      final real = Float64List(size);
      final imaginary = Float64List(size);
      for (var index = 0; index < size; index++) {
        real[index] = math.sin(2 * math.pi * bin * index / size);
      }
      Fft(size).forward(real, imaginary);
      var peakBin = 0;
      var peak = 0.0;
      for (var index = 0; index < size ~/ 2; index++) {
        final magnitude = math.sqrt(
          real[index] * real[index] + imaginary[index] * imaginary[index],
        );
        if (magnitude > peak) {
          peak = magnitude;
          peakBin = index;
        }
      }
      expect(peakBin, bin);
      expect(peak, closeTo(size / 2, 1e-6));
    });

    test('forward and inverse round trip', () {
      const size = 1024;
      final random = math.Random(7);
      final original = Float64List(size);
      for (var index = 0; index < size; index++) {
        original[index] = random.nextDouble() * 2 - 1;
      }
      final real = Float64List.fromList(original);
      final imaginary = Float64List(size);
      final fft = Fft(size);
      fft.forward(real, imaginary);
      fft.inverse(real, imaginary);
      for (var index = 0; index < size; index++) {
        expect(real[index], closeTo(original[index], 1e-9));
        expect(imaginary[index], closeTo(0, 1e-9));
      }
    });

    test('Parseval energy is preserved', () {
      const size = 256;
      final random = math.Random(11);
      final samples = Float64List(size);
      var timeEnergy = 0.0;
      for (var index = 0; index < size; index++) {
        samples[index] = random.nextDouble() * 2 - 1;
        timeEnergy += samples[index] * samples[index];
      }
      final real = Float64List.fromList(samples);
      final imaginary = Float64List(size);
      Fft(size).forward(real, imaginary);
      var frequencyEnergy = 0.0;
      for (var index = 0; index < size; index++) {
        frequencyEnergy += real[index] * real[index] +
            imaginary[index] * imaginary[index];
      }
      expect(frequencyEnergy / size, closeTo(timeEnergy, 1e-9));
    });
  });

  group('magnitudeSpectrum', () {
    test('returns the non-negative half spectrum', () {
      final spectrum = magnitudeSpectrum(
        List<double>.filled(400, 0),
        fftSize: 512,
      );
      expect(spectrum.length, 257);
    });

    test('a sine wave dominates its bin', () {
      const sampleRate = 22050.0;
      const frequency = 440.0;
      const length = 1024;
      final samples = [
        for (var index = 0; index < length; index++)
          math.sin(2 * math.pi * frequency * index / sampleRate),
      ];
      final spectrum = magnitudeSpectrum(samples, fftSize: 1024);
      final expectedBin = (frequency * 1024 / sampleRate).round();
      var peakBin = 0;
      for (var index = 0; index < spectrum.length; index++) {
        if (spectrum[index] > spectrum[peakBin]) peakBin = index;
      }
      expect((peakBin - expectedBin).abs(), lessThanOrEqualTo(1));
      expect(spectrum[peakBin], greaterThan(50));
    });
  });
}
