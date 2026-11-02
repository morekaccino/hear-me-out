import 'note.dart';

/// Guitar music is written one octave above sounding pitch.
const int guitarWrittenToSoundingSemitones = -12;

class GuitarString {
  const GuitarString({
    required this.number,
    required this.label,
    required this.open,
  });

  /// 1 = high E, 6 = low E.
  final int number;
  final String label;

  /// Sounding pitch of the open string.
  final Note open;
}

/// Low to high, as printed on a tuner.
const List<GuitarString> standardTuning = [
  GuitarString(number: 6, label: 'Low E', open: Note('E', 2)),
  GuitarString(number: 5, label: 'A', open: Note('A', 2)),
  GuitarString(number: 4, label: 'D', open: Note('D', 3)),
  GuitarString(number: 3, label: 'G', open: Note('G', 3)),
  GuitarString(number: 2, label: 'B', open: Note('B', 3)),
  GuitarString(number: 1, label: 'High E', open: Note('E', 4)),
];

class GuitarPosition {
  const GuitarPosition({
    required this.string,
    required this.fret,
    required this.sounding,
  });

  final GuitarString string;
  final int fret;
  final Note sounding;

  String get label =>
      fret == 0 ? 'Open ${string.label}' : '${string.label} string, fret $fret';
}

class Guitar {
  const Guitar._();

  static int soundingMidiForWritten(Note written) =>
      written.midi + guitarWrittenToSoundingSemitones;

  static Note soundingNoteForWritten(Note written) =>
      Note.fromMidi(soundingMidiForWritten(written));

  static GuitarString? stringByNumber(int number) {
    for (final string in standardTuning) {
      if (string.number == number) return string;
    }
    return null;
  }

  /// Sounding pitch of [stringNumber] at [fret], where 0 is open.
  static Note soundingNoteAt(int stringNumber, int fret) {
    final string = stringByNumber(stringNumber);
    if (string == null || fret < 0) {
      throw ArgumentError('Invalid guitar position: string $stringNumber, fret $fret');
    }
    return Note.fromMidi(string.open.midi + fret);
  }

  /// Written pitch of [stringNumber] at [fret]. Guitar notation is written one
  /// octave above sounding pitch.
  static Note writtenNoteAt(int stringNumber, int fret) {
    final sounding = soundingNoteAt(stringNumber, fret);
    return Note.fromMidi(sounding.midi + 12);
  }

  static List<GuitarPosition> positionsFor(Note written, {int maxFret = 4}) {
    final soundingMidi = soundingMidiForWritten(written);
    final positions = <GuitarPosition>[];
    for (final string in standardTuning) {
      final fret = soundingMidi - string.open.midi;
      if (fret >= 0 && fret <= maxFret) {
        positions.add(
          GuitarPosition(
            string: string,
            fret: fret,
            sounding: Note.fromMidi(soundingMidi),
          ),
        );
      }
    }
    return positions;
  }

  /// The position a beginner should use: lowest fret, then lowest string.
  static GuitarPosition? bestPosition(Note written, {int maxFret = 4}) {
    final positions = positionsFor(written, maxFret: maxFret);
    if (positions.isEmpty) return null;
    positions.sort((a, b) {
      final fretCompare = a.fret.compareTo(b.fret);
      if (fretCompare != 0) return fretCompare;
      return b.string.number.compareTo(a.string.number);
    });
    return positions.first;
  }
}
