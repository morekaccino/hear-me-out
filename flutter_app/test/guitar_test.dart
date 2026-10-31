import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/music/guitar.dart';
import 'package:hear_me_out/core/music/note.dart';

void main() {
  group('Guitar transposition', () {
    test('written C4 sounds as C3', () {
      final written = Note.parse('C4');
      final sounding = Guitar.soundingNoteForWritten(written);
      expect(sounding.id, 'C3');
      expect(Guitar.soundingMidiForWritten(written), 48);
    });

    test('open high E written as E5 sounds as E4', () {
      final written = Note.parse('E5');
      expect(Guitar.soundingNoteForWritten(written).id, 'E4');
    });
  });

  group('Standard tuning positions', () {
    void expectPosition(String written, String label, int fret) {
      final position = Guitar.bestPosition(Note.parse(written));
      expect(
        position,
        isNotNull,
        reason: '$written should have a first-position fingering',
      );
      expect(position!.string.label, label, reason: written);
      expect(position.fret, fret, reason: written);
    }

    test('open strings map to their written octave', () {
      expectPosition('E3', 'Low E', 0);
      expectPosition('A3', 'A', 0);
      expectPosition('D4', 'D', 0);
      expectPosition('G4', 'G', 0);
      expectPosition('B4', 'B', 0);
      expectPosition('E5', 'High E', 0);
    });

    test('first-position low-string notes', () {
      expectPosition('F3', 'Low E', 1);
      expectPosition('G3', 'Low E', 3);
      expectPosition('B3', 'A', 2);
    });

    test('first-position middle-string notes', () {
      expectPosition('C4', 'A', 3);
      expectPosition('E4', 'D', 2);
      expectPosition('F4', 'D', 3);
      expectPosition('A4', 'G', 2);
    });

    test('first-position high-string notes', () {
      expectPosition('C5', 'B', 1);
      expectPosition('D5', 'B', 3);
      expectPosition('F5', 'High E', 1);
    });

    test('accidental notes use the correct fret', () {
      expectPosition('F#4', 'D', 4);
      expectPosition('C#5', 'B', 2);
      expectPosition('Bb4', 'G', 3);
    });

    test('positions respect the max fret limit', () {
      final positions = Guitar.positionsFor(Note.parse('C4'), maxFret: 2);
      expect(positions, isEmpty);
    });

    test('label reads naturally for open and fretted notes', () {
      expect(Guitar.bestPosition(Note.parse('D4'))!.label, 'Open D');
      expect(Guitar.bestPosition(Note.parse('C4'))!.label, 'A string, fret 3');
    });
  });
}
