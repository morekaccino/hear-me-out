import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/pcm_stream.dart';
import 'package:hear_me_out/core/audio/yin.dart';

void main() {
  const analysisRate = 22050;

  List<double> sine(
    double frequency,
    int sampleRate, {
    double seconds = 1,
    double amplitude = 0.5,
  }) {
    final length = (sampleRate * seconds).round();
    return [
      for (var index = 0; index < length; index++)
        amplitude * math.sin(2 * math.pi * frequency * index / sampleRate),
    ];
  }

  Uint8List pcm16(List<double> samples) {
    final bytes = Uint8List(samples.length * 2);
    final data = ByteData.sublistView(bytes);
    for (var index = 0; index < samples.length; index++) {
      final value = (samples[index].clamp(-1.0, 1.0) * 32767).round();
      data.setInt16(index * 2, value, Endian.little);
    }
    return bytes;
  }

  Uint8List interleaved(List<List<double>> channels) {
    final frames = channels.first.length;
    final bytes = Uint8List(frames * channels.length * 2);
    final data = ByteData.sublistView(bytes);
    var offset = 0;
    for (var frame = 0; frame < frames; frame++) {
      for (final channel in channels) {
        final value = (channel[frame].clamp(-1.0, 1.0) * 32767).round();
        data.setInt16(offset, value, Endian.little);
        offset += 2;
      }
    }
    return bytes;
  }

  List<double> decodeAll(
    Uint8List bytes, {
    int inputSampleRate = 48000,
    int channels = 1,
    int chunkSize = 0,
  }) {
    final decoder = Pcm16StreamDecoder(
      inputSampleRate: inputSampleRate,
      channels: channels,
      outputSampleRate: analysisRate,
    );
    final output = <double>[];
    if (chunkSize <= 0) {
      output.addAll(decoder.add(bytes));
    } else {
      for (var offset = 0; offset < bytes.length; offset += chunkSize) {
        final end = math.min(offset + chunkSize, bytes.length);
        output.addAll(decoder.add(bytes.sublist(offset, end)));
      }
    }
    output.addAll(decoder.flush());
    return output;
  }

  double detectedFrequency(List<double> samples) {
    final detector = YinPitchDetector(
      sampleRate: analysisRate.toDouble(),
      minFrequency: 70,
      maxFrequency: 1000,
    );
    return detector.detect(samples.sublist(4096, 8192)).frequency;
  }

  double centsError(double detected, double expected) {
    return 1200 * (math.log(detected / expected) / math.ln2);
  }

  void expectClose(List<double> actual, List<double> expected) {
    expect(actual.length, expected.length);
    for (var index = 0; index < expected.length; index++) {
      expect(
        actual[index],
        closeTo(expected[index], 1e-12),
        reason: 'at $index',
      );
    }
  }

  group('Pcm16StreamDecoder', () {
    test('44.1 kHz mono keeps a 440 Hz tone at 440 Hz', () {
      final decoded = decodeAll(
        pcm16(sine(440, 44100)),
        inputSampleRate: 44100,
      );
      final frequency = detectedFrequency(decoded);

      expect((frequency - 440).abs(), lessThan(1), reason: '$frequency Hz');
      expect(centsError(frequency, 440).abs(), lessThan(10));
    });

    test('48 kHz mono keeps a 440 Hz tone at 440 Hz, not 8.8% high', () {
      final decoded = decodeAll(pcm16(sine(440, 48000)));
      final frequency = detectedFrequency(decoded);

      expect((frequency - 440).abs(), lessThan(1), reason: '$frequency Hz');
      expect(centsError(frequency, 440).abs(), lessThan(10));
      expect(frequency, lessThan(441));
    });

    test('48 kHz harmonic guitar tone keeps its fundamental', () {
      const sampleRate = 48000;
      const frequency = 82.4069;
      final samples = <double>[];
      for (var index = 0; index < sampleRate; index++) {
        final time = index / sampleRate;
        var sample = 0.0;
        for (var harmonic = 1; harmonic <= 20; harmonic++) {
          sample +=
              math.sin(2 * math.pi * frequency * harmonic * time) / harmonic;
        }
        samples.add(sample * 0.2);
      }

      final decoded = decodeAll(pcm16(samples));
      final detected = detectedFrequency(decoded);

      expect(
        (detected - frequency).abs() / frequency,
        lessThan(0.01),
        reason: '$detected Hz',
      );
    });

    test('48 kHz stereo downmixes left-only, right-only, and identical', () {
      final left = sine(440, 48000);
      final right = sine(440, 48000);
      final silence = List<double>.filled(left.length, 0);

      for (final channels in [
        [left, silence],
        [silence, right],
        [left, right],
      ]) {
        final decoded = decodeAll(interleaved(channels), channels: 2);
        final frequency = detectedFrequency(decoded);
        expect((frequency - 440).abs(), lessThan(1), reason: '$frequency Hz');
      }
    });

    test('stereo channels are averaged, so opposite phases cancel', () {
      final left = sine(440, 48000);
      final right = left.map((sample) => -sample).toList();
      final decoded = decodeAll(interleaved([left, right]), channels: 2);

      final peak = decoded.fold<double>(0, (max, sample) {
        return math.max(max, sample.abs());
      });
      expect(peak, lessThan(0.001));
    });

    test('any channel count is averaged to mono', () {
      const frames = 2048;
      final channels = [
        List<double>.filled(frames, 0.2),
        List<double>.filled(frames, 0.4),
        List<double>.filled(frames, 0.6),
      ];
      final decoder = Pcm16StreamDecoder(
        inputSampleRate: 22050,
        channels: 3,
        outputSampleRate: 22050,
      );
      final decoded = [
        ...decoder.add(interleaved(channels)),
        ...decoder.flush(),
      ];

      expect(decoded, isNotEmpty);
      for (final sample in decoded) {
        expect(sample, closeTo(0.4, 0.0001));
      }
    });

    test('one-byte, three-byte, and random chunks match a single feed', () {
      final bytes = pcm16(sine(440, 48000, seconds: 0.25));
      final reference = decodeAll(bytes);

      expectClose(decodeAll(bytes, chunkSize: 1), reference);
      expectClose(decodeAll(bytes, chunkSize: 3), reference);

      final random = math.Random(7);
      final decoder = Pcm16StreamDecoder(
        inputSampleRate: 48000,
        channels: 1,
        outputSampleRate: analysisRate,
      );
      final chunked = <double>[];
      var offset = 0;
      while (offset < bytes.length) {
        final size = 1 + random.nextInt(17);
        final end = math.min(offset + size, bytes.length);
        chunked.addAll(decoder.add(bytes.sublist(offset, end)));
        offset = end;
      }
      chunked.addAll(decoder.flush());

      expectClose(chunked, reference);
    });

    test('stereo chunks may split a channel frame', () {
      final bytes = interleaved([
        sine(440, 48000, seconds: 0.1),
        sine(330, 48000, seconds: 0.1),
      ]);
      final reference = decodeAll(bytes, channels: 2);

      expectClose(decodeAll(bytes, channels: 2, chunkSize: 1), reference);
      expectClose(decodeAll(bytes, channels: 2, chunkSize: 3), reference);
    });

    test('an odd trailing byte is preserved across calls', () {
      final bytes = pcm16(sine(440, 48000, seconds: 0.1));
      final reference = decodeAll(bytes);

      final decoder = Pcm16StreamDecoder(
        inputSampleRate: 48000,
        channels: 1,
        outputSampleRate: analysisRate,
      );
      final output = <double>[];
      output.addAll(decoder.add(bytes.sublist(0, bytes.length - 1)));
      output.addAll(decoder.add(bytes.sublist(bytes.length - 1)));
      output.addAll(decoder.flush());

      expectClose(output, reference);
    });

    test('framesEmitted and outputSampleIndex only increase', () {
      final bytes = pcm16(sine(440, 48000, seconds: 0.25));
      final decoder = Pcm16StreamDecoder(
        inputSampleRate: 48000,
        channels: 1,
        outputSampleRate: analysisRate,
      );

      var expected = 0;
      for (var offset = 0; offset < bytes.length; offset += 37) {
        final end = math.min(offset + 37, bytes.length);
        final out = decoder.add(bytes.sublist(offset, end));
        expected += out.length;
        expect(decoder.framesEmitted, expected);
        expect(decoder.outputSampleIndex, expected);
      }
      final tail = decoder.flush();
      expected += tail.length;
      expect(decoder.framesEmitted, expected);
      expect(decoder.outputSampleIndex, expected);
      expect(decoder.flush(), isEmpty);
    });

    test('silence produces no voiced frames', () {
      final decoded = decodeAll(pcm16(List<double>.filled(48000, 0)));
      final detector = YinPitchDetector(sampleRate: analysisRate.toDouble());
      final estimate = detector.detect(decoded.sublist(4096, 8192));

      expect(estimate.voiced, isFalse);
      expect(estimate.frequency, 0);
    });

    test('flush emits buffered output once and never duplicates samples', () {
      final bytes = pcm16(sine(440, 48000, seconds: 0.25));
      final reference = decodeAll(bytes);

      final limited = Pcm16StreamDecoder(
        inputSampleRate: 48000,
        channels: 1,
        outputSampleRate: analysisRate,
        maxFrames: 100,
      );
      final output = <double>[];
      output.addAll(limited.add(bytes));
      expect(output, hasLength(100));
      output.addAll(limited.flush());
      expect(output, hasLength(reference.length));
      expect(limited.flush(), isEmpty);
      expectClose(output, reference);
    });
  });
}
