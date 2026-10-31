import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/music/note.dart';

void main() {
  group('Note parsing and MIDI', () {
    test('C4 is MIDI 60', () {
      expect(Note.parse('C4').midi, 60);
    });

    test('A4 is MIDI 69', () {
      expect(Note.parse('A4').midi, 69);
    });

    test('sharps and flats resolve to the right MIDI notes', () {
      expect(Note.parse('C#4').midi, 61);
      expect(Note.parse('Db4').midi, 61);
      expect(Note.parse('Bb4').midi, 70);
      expect(Note.parse('E2').midi, 40);
    });

    test('a parsed note keeps its spelling', () {
      expect(Note.parse('F#4').id, 'F#4');
      expect(Note.parse('Bb4').id, 'Bb4');
      expect(Note.parse('F#4').display, 'F\u266F4');
      expect(Note.parse('Bb4').display, 'B\u266D4');
    });

    test('C sharp and D flat are the same pitch but different spellings', () {
      expect(Note.parse('C#4').samePitchAs(Note.parse('Db4')), isTrue);
      expect(Note.parse('C#4'), isNot(equals(Note.parse('Db4'))));
    });

    test(
      'fromMidi returns sharp spellings by default and flats on request',
      () {
        expect(Note.fromMidi(61).id, 'C#4');
        expect(Note.fromMidi(70).id, 'A#4');
        expect(Note.fromMidi(70, preferFlats: true).id, 'Bb4');
      },
    );

    test('transposition can preserve a flat spelling', () {
      expect(Note.parse('A#3').transposed(12, preferFlats: true).id, 'Bb4');
      expect(Note.parse('A#3').transposed(12).id, 'A#4');
    });

    test('invalid note strings are rejected', () {
      expect(Note.tryParse('H4'), isNull);
      expect(Note.tryParse('C'), isNull);
      expect(Note.tryParse('C#'), isNull);
      expect(() => Note.parse('nope'), throwsFormatException);
    });
  });

  group('Staff positions', () {
    test('C4 is one diatonic step below E4', () {
      expect(Note.parse('C4').diatonicIndex, 28);
      expect(Note.parse('E4').diatonicIndex, 30);
    });

    test('an octave adds seven staff steps', () {
      expect(
        Note.parse('C5').diatonicIndex - Note.parse('C4').diatonicIndex,
        7,
      );
    });

    test('accidentals do not move the staff position', () {
      expect(Note.parse('F#4').diatonicIndex, Note.parse('F4').diatonicIndex);
      expect(Note.parse('Bb4').diatonicIndex, Note.parse('B4').diatonicIndex);
    });
  });

  group('Frequency and cents conversions', () {
    test('A4 at 440 Hz is MIDI 69', () {
      expect(frequencyToMidi(440), closeTo(69, 0.0001));
    });

    test('C4 at 261.63 Hz is MIDI 60', () {
      expect(frequencyToMidi(261.63), closeTo(60, 0.01));
    });

    test('E2 at 82.41 Hz is MIDI 40', () {
      expect(frequencyToMidi(82.41), closeTo(40, 0.02));
    });

    test('MIDI 69 is 440 Hz and MIDI 60 is about 261.63 Hz', () {
      expect(midiToFrequency(69), closeTo(440, 0.0001));
      expect(midiToFrequency(60), closeTo(261.63, 0.01));
    });

    test('cents are measured from the nearest note', () {
      expect(centsFromMidi(60.4), closeTo(40, 0.0001));
      expect(centsFromMidi(59.75), closeTo(-25, 0.0001));
    });

    test('a different tuning reference shifts the result', () {
      expect(frequencyToMidi(432, a4: 432), closeTo(69, 0.0001));
      expect(frequencyToMidi(440, a4: 432), greaterThan(69));
    });
  });

  test('dayKey formats a local calendar day', () {
    expect(dayKey(DateTime(2026, 1, 2, 23, 59)), '2026-01-02');
  });
}
