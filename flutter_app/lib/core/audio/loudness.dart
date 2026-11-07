import 'dart:math' as math;
import 'dart:typed_data';

import 'wav.dart';

/// Target RMS level for an A/B comparison, in dBFS.
const double loudnessTargetRmsDbfs = -20;

/// Below this RMS level a take is treated as very quiet and peak-normalized
/// instead of RMS-normalized. True silence is never boosted.
const double loudnessSilenceThresholdDbfs = -60;

/// Peak target used when a take is below [loudnessSilenceThresholdDbfs].
const double loudnessPeakTargetDbfs = -1;

/// The most boost a comparison applies.
const double loudnessMaxGainDb = 18;

/// The most attenuation a comparison applies.
const double loudnessMaxAttenuationDb = -24;

/// Samples are clamped to this absolute value after gain so a boost cannot
/// hard-clip the PCM16 output.
const double loudnessSampleCeiling = 0.98;

/// Measured level of a WAV take.
class WavLoudness {
  const WavLoudness({required this.rmsDbfs, required this.peakDbfs});

  /// Root-mean-square level across every interleaved sample, in dBFS.
  final double rmsDbfs;

  /// Highest absolute sample, in dBFS.
  final double peakDbfs;

  /// True when every sample is exactly zero.
  bool get silent => peakDbfs == double.negativeInfinity;
}

/// A WAV that could not be read or normalized.
///
/// Expected failures are typed so the UI can show "This take could not be
/// normalized." instead of a raw parser exception.
class LoudnessNormalizationException implements Exception {
  const LoudnessNormalizationException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'LoudnessNormalizationException: $message';
}

/// Measures [bytes] as interleaved PCM16. Throws
/// [LoudnessNormalizationException] for bytes that are not a supported WAV.
WavLoudness measureWavLoudness(Uint8List bytes) {
  final WavData data;
  try {
    data = parseWav(bytes);
  } on FormatException catch (error) {
    throw LoudnessNormalizationException(
      'This take could not be normalized.',
      cause: error,
    );
  }
  return _measure(data.samples);
}

/// The gain that normalization applies to [loudness], capped to the allowed
/// boost and attenuation. A silent take gets no gain.
double loudnessGainDb(WavLoudness loudness) {
  if (loudness.silent) return 0;
  final target = loudness.rmsDbfs < loudnessSilenceThresholdDbfs
      ? loudnessPeakTargetDbfs - loudness.peakDbfs
      : loudnessTargetRmsDbfs - loudness.rmsDbfs;
  return target
      .clamp(loudnessMaxAttenuationDb, loudnessMaxGainDb)
      .toDouble();
}

/// Returns a new PCM16 WAV with matched loudness.
///
/// The input is never modified. The output keeps the input sample rate,
/// channel count, and frame count. A silent take is returned unchanged. Bytes
/// that are not a supported WAV throw [LoudnessNormalizationException] so the
/// caller cannot play raw input as a fallback.
Uint8List normalizeWavLoudness(Uint8List bytes) {
  final WavData data;
  try {
    data = parseWav(bytes);
  } on FormatException catch (error) {
    throw LoudnessNormalizationException(
      'This take could not be normalized.',
      cause: error,
    );
  }

  final loudness = _measure(data.samples);
  if (loudness.silent) return bytes;

  final gain = math.pow(10, loudnessGainDb(loudness) / 20).toDouble();
  final samples = Float64List(data.samples.length);
  for (var index = 0; index < data.samples.length; index++) {
    // Apply the gain, then clamp each sample to the ceiling. This is the
    // literal safety rule: a boost can leave the body at the target while a
    // transient peak is limited instead of hard-clipping the PCM16 output.
    samples[index] = (data.samples[index] * gain)
        .clamp(-loudnessSampleCeiling, loudnessSampleCeiling)
        .toDouble();
  }

  return encodeWavPcm16(
    WavData(
      sampleRate: data.sampleRate,
      channels: data.channels,
      samples: samples,
    ),
  );
}

WavLoudness _measure(List<double> samples) {
  if (samples.isEmpty) {
    return const WavLoudness(
      rmsDbfs: double.negativeInfinity,
      peakDbfs: double.negativeInfinity,
    );
  }

  var sumSquares = 0.0;
  var peak = 0.0;
  for (final sample in samples) {
    final magnitude = sample.abs();
    if (magnitude > peak) peak = magnitude;
    sumSquares += sample * sample;
  }

  final rms = math.sqrt(sumSquares / samples.length);
  return WavLoudness(
    rmsDbfs: rms <= 0 ? double.negativeInfinity : 20 * math.log(rms) / math.ln10,
    peakDbfs: peak <= 0
        ? double.negativeInfinity
        : 20 * math.log(peak) / math.ln10,
  );
}
