import 'dart:math' as math;
import 'dart:typed_data';

import '../music/sound_spec.dart';

/// Renders a [SoundSpec] to a small mono PCM16 WAV.
///
/// The timbre is a plucked-string approximation: a short attack, a decaying
/// harmonic stack, and a little body resonance. It is deliberately simple so it
/// can run on every platform without bundled per-pitch assets.
Uint8List synthesizeWav(
  SoundSpec spec, {
  int sampleRate = 22050,
  double maxDurationSeconds = 8,
}) {
  if (spec.events.isEmpty) {
    return _wavFromSamples(Float32List(1), sampleRate);
  }

  final beatSeconds = 60 / spec.bpm;
  final totalSeconds = math.min(
    maxDurationSeconds,
    spec.lengthBeats * beatSeconds + 0.4,
  );
  final totalSamples = math.max(1, (totalSeconds * sampleRate).round());
  final samples = Float32List(totalSamples);

  for (final event in spec.events) {
    final startSeconds = event.startBeat * beatSeconds;
    final durationSeconds = event.durationBeats * beatSeconds;
    final startSample = (startSeconds * sampleRate).round();
    final length = (durationSeconds * sampleRate).round();
    final frequency = 440 * math.pow(2, (event.midi - 69) / 12).toDouble();
    _addPluck(
      samples,
      startSample,
      length,
      frequency,
      sampleRate,
      event.velocity,
    );
  }

  var peak = 0.0;
  for (final sample in samples) {
    final magnitude = sample.abs();
    if (magnitude > peak) peak = magnitude;
  }
  if (peak > 0.85) {
    final scale = 0.85 / peak;
    for (var index = 0; index < samples.length; index++) {
      samples[index] *= scale;
    }
  }

  return _wavFromSamples(samples, sampleRate);
}

void _addPluck(
  Float32List samples,
  int startSample,
  int length,
  double frequency,
  int sampleRate,
  double velocity,
) {
  if (startSample >= samples.length) return;
  final count = math.min(length, samples.length - startSample);
  final attackSamples = math.max(1, (0.006 * sampleRate).round());
  // Keep the decay long enough for low notes, short enough for fast passages.
  final decay = 0.28 + 0.12 * (220 / frequency).clamp(0.4, 1.6);
  const harmonics = [1.0, 0.45, 0.22, 0.1];
  const detune = [0.0, 0.0, 0.0015, -0.001];

  for (var index = 0; index < count; index++) {
    final t = index / sampleRate;
    final attack = index < attackSamples
        ? index / attackSamples
        : 1.0;
    final envelope = attack * math.exp(-t / decay);
    var value = 0.0;
    for (var harmonic = 0; harmonic < harmonics.length; harmonic++) {
      final partialFrequency =
          frequency * (harmonic + 1) * (1 + detune[harmonic]);
      value +=
          harmonics[harmonic] *
          math.sin(2 * math.pi * partialFrequency * t + harmonic * 0.7);
    }
    // A soft body resonance adds warmth without changing pitch.
    value += 0.08 * math.sin(2 * math.pi * frequency * 0.5 * t);
    samples[startSample + index] += value * envelope * velocity * 0.22;
  }
}

Uint8List _wavFromSamples(Float32List samples, int sampleRate) {
  final dataSize = samples.length * 2;
  final buffer = ByteData(44 + dataSize);
  var offset = 0;

  void writeString(String value) {
    for (final codeUnit in value.codeUnits) {
      buffer.setUint8(offset++, codeUnit);
    }
  }

  void writeUint32(int value) {
    buffer.setUint32(offset, value, Endian.little);
    offset += 4;
  }

  void writeUint16(int value) {
    buffer.setUint16(offset, value, Endian.little);
    offset += 2;
  }

  writeString('RIFF');
  writeUint32(36 + dataSize);
  writeString('WAVE');
  writeString('fmt ');
  writeUint32(16);
  writeUint16(1); // PCM
  writeUint16(1); // mono
  writeUint32(sampleRate);
  writeUint32(sampleRate * 2); // byte rate
  writeUint16(2); // block align
  writeUint16(16); // bits per sample
  writeString('data');
  writeUint32(dataSize);

  for (final sample in samples) {
    final clamped = sample.clamp(-1.0, 1.0);
    buffer.setInt16(offset, (clamped * 32767).round(), Endian.little);
    offset += 2;
  }

  return buffer.buffer.asUint8List();
}
