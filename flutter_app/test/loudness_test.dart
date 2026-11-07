import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:hear_me_out/core/audio/loudness.dart';
import 'package:hear_me_out/core/audio/wav.dart';

Uint8List _tone({
  double amplitude = 0.2,
  int sampleRate = 8000,
  int seconds = 1,
}) {
  return encodeWavPcm16(
    WavData(
      sampleRate: sampleRate,
      channels: 1,
      samples: List<double>.filled(sampleRate * seconds, amplitude),
    ),
  );
}

void main() {
  test('a quiet take is boosted toward the target', () {
    final input = _tone(amplitude: 0.02);
    final before = measureWavLoudness(input);
    final output = normalizeWavLoudness(input);
    final after = measureWavLoudness(output);

    expect(after.rmsDbfs, closeTo(loudnessTargetRmsDbfs, 1.5));
    expect(after.rmsDbfs, greaterThan(before.rmsDbfs));
  });

  test('a loud take is attenuated toward the target', () {
    final input = _tone(amplitude: 0.8);
    final before = measureWavLoudness(input);
    final output = normalizeWavLoudness(input);
    final after = measureWavLoudness(output);

    expect(after.rmsDbfs, closeTo(loudnessTargetRmsDbfs, 1.5));
    expect(after.rmsDbfs, lessThan(before.rmsDbfs));
  });

  test('two different source levels end at the same loudness', () {
    final quiet = measureWavLoudness(
      normalizeWavLoudness(_tone(amplitude: 0.02)),
    );
    final loud = measureWavLoudness(
      normalizeWavLoudness(_tone(amplitude: 0.8)),
    );

    expect((quiet.rmsDbfs - loud.rmsDbfs).abs(), lessThan(1.5));
  });

  test('the gain cap is enforced', () {
    final quiet = measureWavLoudness(_tone(amplitude: 0.0006));
    final gain = loudnessGainDb(quiet);

    expect(gain, lessThanOrEqualTo(loudnessMaxGainDb));
    expect(gain, greaterThan(0));
  });

  test('a take below the silence threshold uses the peak target', () {
    expect(
      loudnessGainDb(const WavLoudness(rmsDbfs: -70, peakDbfs: -10)),
      closeTo(loudnessPeakTargetDbfs - -10, 0.001),
    );
    expect(
      loudnessGainDb(
        const WavLoudness(
          rmsDbfs: double.negativeInfinity,
          peakDbfs: double.negativeInfinity,
        ),
      ),
      0,
    );
  });

  test('the limiter prevents clipping at the sample ceiling', () {
    final samples = List<double>.filled(8000, 0.01);
    samples[4000] = 0.99;
    final input = encodeWavPcm16(
      WavData(sampleRate: 8000, channels: 1, samples: samples),
    );
    final output = normalizeWavLoudness(input);
    final decoded = parseWav(output);
    final peak = decoded.samples
        .map((sample) => sample.abs())
        .reduce(math.max);

    expect(peak, lessThanOrEqualTo(loudnessSampleCeiling + 0.001));
  });

  test('a silent take is returned unchanged', () {
    final input = encodeWavPcm16(
      WavData(
        sampleRate: 8000,
        channels: 1,
        samples: List<double>.filled(800, 0),
      ),
    );
    final output = normalizeWavLoudness(input);

    expect(measureWavLoudness(input).silent, isTrue);
    expect(output, same(input));
  });

  test('sample rate, channels, and duration are preserved', () {
    final samples = <double>[for (var i = 0; i < 44100 * 2; i++) 0.1];
    final input = encodeWavPcm16(
      WavData(sampleRate: 44100, channels: 2, samples: samples),
    );
    final output = normalizeWavLoudness(input);
    final decoded = parseWav(output);

    expect(decoded.sampleRate, 44100);
    expect(decoded.channels, 2);
    expect(decoded.duration, parseWav(input).duration);
  });

  test('normalization is deterministic', () {
    final input = _tone(amplitude: 0.15);

    expect(normalizeWavLoudness(input), normalizeWavLoudness(input));
  });

  test('malformed bytes throw a typed error', () {
    expect(
      () => normalizeWavLoudness(Uint8List.fromList(<int>[1, 2, 3])),
      throwsA(isA<LoudnessNormalizationException>()),
    );
    expect(
      () => measureWavLoudness(Uint8List.fromList(<int>[1, 2, 3])),
      throwsA(isA<LoudnessNormalizationException>()),
    );
  });
}
