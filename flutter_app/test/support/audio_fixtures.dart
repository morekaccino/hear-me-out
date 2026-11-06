import 'dart:math' as math;

/// Test-only synthetic take builder.
///
/// Everything is generated in memory so the DSP tests have known ground truth
/// without committing audio fixtures.

double midiToFrequency(int midi, {double cents = 0}) =>
    440 * math.pow(2, (midi - 69 + cents / 100) / 12).toDouble();

List<double> silentTake(int sampleRate, double seconds) =>
    List<double>.filled((sampleRate * seconds).round(), 0);

void addTone(
  List<double> samples,
  int sampleRate, {
  required double startSeconds,
  required double durationSeconds,
  required int midi,
  double cents = 0,
  double amplitude = 0.4,
  List<double> harmonics = const [1.0, 0.45, 0.22, 0.1],
  double attackSeconds = 0.005,
  double decaySeconds = 0.4,
  double vibratoCents = 0,
  double vibratoHz = 5,
  double noise = 0,
  int seed = 1,
}) {
  final start = (startSeconds * sampleRate).round();
  final count = (durationSeconds * sampleRate).round();
  final attack = math.max(1, (attackSeconds * sampleRate).round());
  final release = math.max(1, (0.02 * sampleRate).round());
  final frequency = midiToFrequency(midi, cents: cents);
  final random = math.Random(seed);
  for (var index = 0; index < count; index++) {
    final target = start + index;
    if (target >= samples.length) break;
    final time = index / sampleRate;
    var envelope =
        (index < attack ? index / attack : 1.0) * math.exp(-time / decaySeconds);
    final remaining = count - index;
    if (remaining < release) {
      envelope *= remaining / release;
    }
    final modulation = vibratoCents == 0
        ? 0.0
        : vibratoCents * math.sin(2 * math.pi * vibratoHz * time);
    final shifted = frequency * math.pow(2, modulation / 1200);
    var value = 0.0;
    for (var harmonic = 0; harmonic < harmonics.length; harmonic++) {
      value += harmonics[harmonic] *
          math.sin(2 * math.pi * shifted * (harmonic + 1) * time);
    }
    if (noise > 0) {
      value += (random.nextDouble() * 2 - 1) * noise;
    }
    samples[target] += value * envelope * amplitude * 0.22;
  }
}

void addClick(
  List<double> samples,
  int sampleRate, {
  required double startSeconds,
  double amplitude = 0.5,
  int seed = 1,
}) {
  final start = (startSeconds * sampleRate).round();
  final count = math.max(1, (0.008 * sampleRate).round());
  final random = math.Random(seed + start);
  for (var index = 0; index < count; index++) {
    final target = start + index;
    if (target >= samples.length) break;
    final envelope = math.exp(-index / (0.002 * sampleRate));
    samples[target] +=
        (random.nextDouble() * 2 - 1) * amplitude * envelope;
  }
}

void addWhiteNoise(
  List<double> samples, {
  required double amplitude,
  int seed = 1,
}) {
  final random = math.Random(seed);
  for (var index = 0; index < samples.length; index++) {
    samples[index] += (random.nextDouble() * 2 - 1) * amplitude;
  }
}
