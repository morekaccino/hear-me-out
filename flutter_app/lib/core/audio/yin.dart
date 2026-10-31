import 'dart:math' as math;

class PitchEstimate {
  const PitchEstimate({
    required this.frequency,
    required this.clarity,
    required this.rms,
    required this.voiced,
  });

  final double frequency;
  final double clarity;
  final double rms;
  final bool voiced;

  static const silent = PitchEstimate(
    frequency: 0,
    clarity: 0,
    rms: 0,
    voiced: false,
  );
}

/// YIN pitch detector (de Cheveigne & Kawahara, 2002).
///
/// Designed for a monophonic guitar signal. Use a window of about 90 ms and
/// sample rates around 22 kHz after decimation.
class YinPitchDetector {
  YinPitchDetector({
    required this.sampleRate,
    this.threshold = 0.15,
    this.minFrequency = 70,
    this.maxFrequency = 1000,
    this.minRms = 0.004,
  });

  final double sampleRate;
  final double threshold;
  final double minFrequency;
  final double maxFrequency;
  final double minRms;

  PitchEstimate detect(List<double> input) {
    if (input.length < 128) return PitchEstimate.silent;

    var mean = 0.0;
    for (final sample in input) {
      mean += sample;
    }
    mean /= input.length;

    var energy = 0.0;
    for (final sample in input) {
      final centered = sample - mean;
      energy += centered * centered;
    }
    final rms = math.sqrt(energy / input.length);
    if (rms < minRms) {
      return PitchEstimate(frequency: 0, clarity: 0, rms: rms, voiced: false);
    }

    final tauMin = math.max(2, (sampleRate / maxFrequency).floor());
    var tauMax = math.min(
      input.length ~/ 2,
      (sampleRate / minFrequency).ceil(),
    );
    if (tauMax <= tauMin + 2) return PitchEstimate.silent;

    final difference = List<double>.filled(tauMax + 1, 0);
    final integrationLength = input.length - tauMax;
    for (var tau = 1; tau <= tauMax; tau++) {
      var sum = 0.0;
      for (var index = 0; index < integrationLength; index++) {
        final delta = (input[index] - mean) - (input[index + tau] - mean);
        sum += delta * delta;
      }
      difference[tau] = sum;
    }

    final normalized = List<double>.filled(tauMax + 1, 1);
    var runningSum = 0.0;
    for (var tau = 1; tau <= tauMax; tau++) {
      runningSum += difference[tau];
      normalized[tau] = runningSum == 0
          ? 1
          : difference[tau] * tau / runningSum;
    }

    var chosenTau = -1;
    for (var tau = tauMin; tau <= tauMax; tau++) {
      if (normalized[tau] < threshold) {
        while (tau + 1 <= tauMax && normalized[tau + 1] < normalized[tau]) {
          tau++;
        }
        chosenTau = tau;
        break;
      }
    }

    if (chosenTau == -1) {
      var best = double.infinity;
      for (var tau = tauMin; tau <= tauMax; tau++) {
        if (normalized[tau] < best) {
          best = normalized[tau];
          chosenTau = tau;
        }
      }
      if (chosenTau == -1 || best > 0.35) {
        return PitchEstimate(frequency: 0, clarity: 0, rms: rms, voiced: false);
      }
    }

    var refinedTau = chosenTau.toDouble();
    if (chosenTau > tauMin && chosenTau < tauMax) {
      final before = normalized[chosenTau - 1];
      final center = normalized[chosenTau];
      final after = normalized[chosenTau + 1];
      final denominator = before - 2 * center + after;
      if (denominator.abs() > 1e-12) {
        refinedTau += 0.5 * (before - after) / denominator;
      }
    }

    final frequency = sampleRate / refinedTau;
    if (frequency < minFrequency || frequency > maxFrequency) {
      return PitchEstimate(frequency: 0, clarity: 0, rms: rms, voiced: false);
    }

    final clarity = (1 - normalized[chosenTau]).clamp(0.0, 1.0);
    return PitchEstimate(
      frequency: frequency,
      clarity: clarity,
      rms: rms,
      voiced: clarity >= 0.5,
    );
  }
}
