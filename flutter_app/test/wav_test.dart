import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/wav.dart';

void main() {
  Uint8List bytesWith(List<int> values) => Uint8List.fromList(values);

  Uint8List validWav() {
    return encodeWavPcm16(
      WavData(sampleRate: 44100, channels: 1, samples: [0.0, 0.25, -0.25]),
    );
  }

  group('WAV codec', () {
    test('roundtrips mono PCM16 at 44.1 kHz', () {
      final source = WavData(
        sampleRate: 44100,
        channels: 1,
        samples: [-1.0, -0.5, -0.125, 0.0, 0.125, 0.5, 1.0],
      );

      final decoded = parseWav(encodeWavPcm16(source));

      expect(decoded.sampleRate, 44100);
      expect(decoded.channels, 1);
      expect(decoded.samples.length, source.samples.length);
      for (var index = 0; index < source.samples.length; index++) {
        expect(decoded.samples[index], closeTo(source.samples[index], 1e-4));
      }
      expect(decoded.duration, const Duration(microseconds: 159));
    });

    test('roundtrips stereo PCM16 at 48 kHz and keeps channel order', () {
      final source = WavData(
        sampleRate: 48000,
        channels: 2,
        samples: [0.1, -0.1, 0.2, -0.2, 0.75, -0.75],
      );

      final decoded = parseWav(encodeWavPcm16(source));

      expect(decoded.sampleRate, 48000);
      expect(decoded.channels, 2);
      expect(decoded.frameCount, 3);
      expect(decoded.samples[0], closeTo(0.1, 1e-4));
      expect(decoded.samples[1], closeTo(-0.1, 1e-4));
      expect(decoded.samples[4], closeTo(0.75, 1e-4));
      expect(decoded.samples[5], closeTo(-0.75, 1e-4));
      expect(decoded.duration, const Duration(microseconds: 63));
    });

    test('roundtrips empty data', () {
      final source = WavData(
        sampleRate: 22050,
        channels: 2,
        samples: const <double>[],
      );

      final encoded = encodeWavPcm16(source);
      final decoded = parseWav(encoded);

      expect(encoded.length, 44);
      expect(decoded.sampleRate, 22050);
      expect(decoded.channels, 2);
      expect(decoded.samples, isEmpty);
      expect(decoded.frameCount, 0);
      expect(decoded.duration, Duration.zero);
    });

    test('clamps out-of-range samples on encode', () {
      final decoded = parseWav(
        encodeWavPcm16(
          WavData(sampleRate: 44100, channels: 1, samples: [2.0, -2.0]),
        ),
      );

      expect(decoded.samples[0], closeTo(1.0, 1e-4));
      expect(decoded.samples[1], closeTo(-1.0, 1e-4));
    });

    test('skips unknown chunks before the data chunk', () {
      final base = validWav();
      // Insert a 6-byte LIST chunk after the fmt chunk.
      final listChunk = <int>[
        ...'LIST'.codeUnits,
        6,
        0,
        0,
        0,
        ...'abcd'.codeUnits,
        0,
        0,
      ];
      final combined = BytesBuilder()
        ..add(base.sublist(0, 36))
        ..add(Uint8List.fromList(listChunk))
        ..add(base.sublist(36));
      final bytes = combined.toBytes();
      final view = ByteData.sublistView(bytes);
      view.setUint32(4, bytes.length - 8, Endian.little);

      final decoded = parseWav(bytes);

      expect(decoded.samples.length, 3);
    });

    test('rejects a truncated header', () {
      expect(
        () => parseWav(bytesWith(List<int>.filled(10, 0))),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-RIFF container', () {
      final bytes = validWav();
      bytes.setRange(0, 4, 'RIFX'.codeUnits);
      expect(
        () => parseWav(bytes),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('RIFF'),
          ),
        ),
      );
    });

    test('rejects a non-WAVE form type', () {
      final bytes = validWav();
      bytes.setRange(8, 12, 'AVI '.codeUnits);
      expect(
        () => parseWav(bytes),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('WAVE'),
          ),
        ),
      );
    });

    test('rejects a non-PCM format tag', () {
      final bytes = validWav();
      ByteData.sublistView(bytes).setUint16(20, 3, Endian.little);
      expect(
        () => parseWav(bytes),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('only PCM'),
          ),
        ),
      );
    });

    test('rejects a non-16-bit depth', () {
      final bytes = validWav();
      ByteData.sublistView(bytes).setUint16(34, 24, Endian.little);
      expect(
        () => parseWav(bytes),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('16-bit'),
          ),
        ),
      );
    });

    test('rejects a data chunk larger than the file', () {
      final bytes = validWav();
      ByteData.sublistView(bytes).setUint32(40, 4096, Endian.little);
      expect(
        () => parseWav(bytes),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Truncated'),
          ),
        ),
      );
    });

    test('rejects an odd data length', () {
      final bytes = validWav();
      ByteData.sublistView(bytes).setUint32(40, 1, Endian.little);
      expect(() => parseWav(bytes), throwsA(isA<FormatException>()));
    });

    test('rejects a short fmt chunk', () {
      final bytes = validWav();
      ByteData.sublistView(bytes).setUint32(16, 8, Endian.little);
      expect(
        () => parseWav(bytes),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('fmt chunk'),
          ),
        ),
      );
    });

    test('rejects a file without a data chunk', () {
      final base = validWav();
      final bytes = base.sublist(0, 36);
      ByteData.sublistView(bytes).setUint32(4, 28, Endian.little);
      expect(
        () => parseWav(bytes),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('data chunk'),
          ),
        ),
      );
    });

    test('rejects a block alignment that does not match the channels', () {
      final bytes = validWav();
      ByteData.sublistView(bytes).setUint16(32, 4, Endian.little);
      expect(
        () => parseWav(bytes),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('block alignment'),
          ),
        ),
      );
    });
  });
}
