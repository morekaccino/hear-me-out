import 'note.dart';

/// The scale families used by the course.
enum ScaleMode {
  major,
  naturalMinor,
  harmonicMinor,
  melodicMinor,
  majorPentatonic,
  minorPentatonic,
  blues,
  ionian,
  dorian,
  phrygian,
  lydian,
  mixolydian,
  aeolian,
  locrian;

  String get label => switch (this) {
    ScaleMode.major => 'major',
    ScaleMode.naturalMinor => 'natural minor',
    ScaleMode.harmonicMinor => 'harmonic minor',
    ScaleMode.melodicMinor => 'melodic minor',
    ScaleMode.majorPentatonic => 'major pentatonic',
    ScaleMode.minorPentatonic => 'minor pentatonic',
    ScaleMode.blues => 'blues',
    ScaleMode.ionian => 'Ionian',
    ScaleMode.dorian => 'Dorian',
    ScaleMode.phrygian => 'Phrygian',
    ScaleMode.lydian => 'Lydian',
    ScaleMode.mixolydian => 'Mixolydian',
    ScaleMode.aeolian => 'Aeolian',
    ScaleMode.locrian => 'Locrian',
  };

  bool get isSevenNote => switch (this) {
    ScaleMode.majorPentatonic ||
    ScaleMode.minorPentatonic ||
    ScaleMode.blues => false,
    _ => true,
  };
}

/// A scale rooted on a written note.
class Scale {
  const Scale({required this.root, required this.mode});

  final Note root;
  final ScaleMode mode;

  static const _patterns = <ScaleMode, List<int>>{
    ScaleMode.major: [0, 2, 4, 5, 7, 9, 11, 12],
    ScaleMode.ionian: [0, 2, 4, 5, 7, 9, 11, 12],
    ScaleMode.naturalMinor: [0, 2, 3, 5, 7, 8, 10, 12],
    ScaleMode.aeolian: [0, 2, 3, 5, 7, 8, 10, 12],
    ScaleMode.harmonicMinor: [0, 2, 3, 5, 7, 8, 11, 12],
    ScaleMode.melodicMinor: [0, 2, 3, 5, 7, 9, 11, 12],
    ScaleMode.dorian: [0, 2, 3, 5, 7, 9, 10, 12],
    ScaleMode.phrygian: [0, 1, 3, 5, 7, 8, 10, 12],
    ScaleMode.lydian: [0, 2, 4, 6, 7, 9, 11, 12],
    ScaleMode.mixolydian: [0, 2, 4, 5, 7, 9, 10, 12],
    ScaleMode.locrian: [0, 1, 3, 5, 6, 8, 10, 12],
    ScaleMode.majorPentatonic: [0, 2, 4, 7, 9, 12],
    ScaleMode.minorPentatonic: [0, 3, 5, 7, 10, 12],
    ScaleMode.blues: [0, 3, 5, 6, 7, 10, 12],
  };

  List<int> get semitones => _patterns[mode]!;

  /// The pitch classes of the scale, spelled from the root.
  List<Note> get notes {
    const letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final start = letters.indexOf(root.letter);
    final pattern = semitones;
    final sevenNote = mode.isSevenNote;
    return [
      for (var index = 0; index < pattern.length; index++)
        sevenNote
            ? Note.spelledFromMidi(
                root.midi + pattern[index],
                letters[(start + index) % 7],
              )
            : Note.fromMidi(
                root.midi + pattern[index],
                preferFlats:
                    mode == ScaleMode.blues ||
                    root.accidental == Accidental.flat,
              ),
    ];
  }

  /// The 1-based scale degree, with octave wrapping.
  Note degree(int degreeNumber) {
    final pattern = semitones;
    final normalized = (degreeNumber - 1) % (pattern.length - 1);
    return notes[normalized];
  }

  /// Scale degrees as semitone offsets from the root.
  List<int> get degreeSemitones => semitones;

  String get id => '${root.pitchClass}:${mode.name}';

  String get display => '${root.pitchClass} ${mode.label}';
}

/// The modes of the major scale, in order.
const List<ScaleMode> churchModes = [
  ScaleMode.ionian,
  ScaleMode.dorian,
  ScaleMode.phrygian,
  ScaleMode.lydian,
  ScaleMode.mixolydian,
  ScaleMode.aeolian,
  ScaleMode.locrian,
];
