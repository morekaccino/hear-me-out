import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/synth.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/music/sound_spec.dart';

void main() {
  group('WAV synth', () {
    test('produces a valid PCM WAV header', () {
      final bytes = synthesizeWav(
        SoundSpec.note(Note.parse('A4')),
        sampleRate: 22050,
      );
      expect(bytes.length, greaterThan(44));
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(bytes.sublist(12, 16)), 'fmt ');
      expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');
      final data = ByteData.sublistView(bytes);
      expect(data.getUint32(24, Endian.little), 22050);
      expect(data.getUint16(22, Endian.little), 1);
      expect(data.getUint16(34, Endian.little), 16);
    });

    test('renders a longer file for a progression', () {
      final note = synthesizeWav(SoundSpec.note(Note.parse('C4')));
      final chord = synthesizeWav(
        SoundSpec.progression([
          [Note.parse('C4'), Note.parse('E4'), Note.parse('G4')],
          [Note.parse('F4'), Note.parse('A4'), Note.parse('C5')],
        ]),
      );
      expect(chord.length, greaterThan(note.length));
    });

    test('does not clip', () {
      final bytes = synthesizeWav(
        SoundSpec.chord([
          Note.parse('C3'),
          Note.parse('E3'),
          Note.parse('G3'),
          Note.parse('C4'),
          Note.parse('E4'),
          Note.parse('G4'),
        ]),
      );
      final data = ByteData.sublistView(bytes);
      var peak = 0;
      for (var offset = 44; offset < bytes.length; offset += 2) {
        final sample = data.getInt16(offset, Endian.little).abs();
        if (sample > peak) peak = sample;
      }
      expect(peak, lessThanOrEqualTo(32767));
      expect(peak, greaterThan(1000));
    });
  });
}
