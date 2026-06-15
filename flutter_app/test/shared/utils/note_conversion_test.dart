import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/shared/utils/note_conversion.dart';

void main() {
  group('NoteConversion', () {
    group('frequencyToMidi', () {
      test('A4 (440 Hz) returns MIDI 69', () {
        expect(frequencyToMidi(440.0), 69);
      });

      test('C4 (261.63 Hz) returns MIDI 60', () {
        expect(frequencyToMidi(261.63), closeTo(60, 1));
      });

      test('E2 (82.41 Hz) returns MIDI 40', () {
        expect(frequencyToMidi(82.41), closeTo(40, 1));
      });
    });

    group('midiToNoteName', () {
      test('MIDI 69 returns A4', () {
        expect(midiToNoteName(69), 'A4');
      });

      test('MIDI 60 returns C4', () {
        expect(midiToNoteName(60), 'C4');
      });

      test('MIDI 40 returns E2', () {
        expect(midiToNoteName(40), 'E2');
      });
    });

    group('frequencyToNoteName', () {
      test('440 Hz returns A4', () {
        expect(frequencyToNoteName(440.0), 'A4');
      });
    });

    group('shiftNoteOctave', () {
      test('shifts A4 up one octave to A5', () {
        expect(shiftNoteOctave('A4', 1), 'A5');
      });

      test('shifts C4 down two octaves to C2', () {
        expect(shiftNoteOctave('C4', -2), 'C2');
      });
    });
  });
}
