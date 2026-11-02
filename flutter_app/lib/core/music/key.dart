import 'note.dart';

/// A major or minor key, including its key signature and scale spelling.
///
/// Guitar music is written in treble clef, so the default octave is the written
/// octave used by the curriculum. Transposition to sounding pitch stays in
/// [Guitar].
class KeySignature {
  const KeySignature._({
    required this.tonic,
    required this.minor,
    required this.accidentals,
  });

  /// ASCII tonic spelling, such as `C`, `F#`, or `Bb`.
  final String tonic;

  final bool minor;

  /// Positive for sharps, negative for flats.
  final int accidentals;

  static const _majorAccidentals = <String, int>{
    'C': 0,
    'G': 1,
    'D': 2,
    'A': 3,
    'E': 4,
    'B': 5,
    'F#': 6,
    'C#': 7,
    'F': -1,
    'Bb': -2,
    'Eb': -3,
    'Ab': -4,
    'Db': -5,
    'Gb': -6,
    'Cb': -7,
  };

  static const _minorToRelativeMajor = <String, String>{
    'A': 'C',
    'E': 'G',
    'B': 'D',
    'F#': 'A',
    'C#': 'E',
    'G#': 'B',
    'D#': 'F#',
    'A#': 'C#',
    'D': 'F',
    'G': 'Bb',
    'C': 'Eb',
    'F': 'Ab',
    'Bb': 'Db',
    'Eb': 'Gb',
    'Ab': 'Cb',
  };

  factory KeySignature.major(String tonic) {
    final normalized = _normalizeTonic(tonic);
    final accidentals = _majorAccidentals[normalized];
    if (accidentals == null) {
      throw ArgumentError.value(tonic, 'tonic', 'Unknown major key');
    }
    return KeySignature._(
      tonic: normalized,
      minor: false,
      accidentals: accidentals,
    );
  }

  factory KeySignature.minor(String tonic) {
    final normalized = _normalizeTonic(tonic);
    final relativeMajor = _minorToRelativeMajor[normalized];
    if (relativeMajor == null) {
      throw ArgumentError.value(tonic, 'tonic', 'Unknown minor key');
    }
    return KeySignature._(
      tonic: normalized,
      minor: true,
      accidentals: _majorAccidentals[relativeMajor]!,
    );
  }

  factory KeySignature.of(String tonic, {bool minor = false}) =>
      minor ? KeySignature.minor(tonic) : KeySignature.major(tonic);

  String get relativeMajorTonic =>
      minor ? _minorToRelativeMajor[tonic]! : tonic;

  String get relativeMinorTonic {
    if (!minor) {
      final major = KeySignature.major(tonic);
      for (final entry in _minorToRelativeMajor.entries) {
        if (entry.value == major.tonic) return entry.key;
      }
    }
    return tonic;
  }

  bool get isFlat => accidentals < 0;

  /// The portable spelling used for display and storage, such as `F#` or `Bb`.
  String get id => minor ? '${tonic}m' : tonic;

  String get display => '$tonic ${minor ? 'minor' : 'major'}';

  /// How many sharps or flats the key signature shows.
  int get accidentalCount => accidentals.abs();

  /// The order in which accidentals appear on the staff.
  List<String> get accidentalOrder {
    if (accidentals > 0) {
      return const ['F#', 'C#', 'G#', 'D#', 'A#', 'E#', 'B#']
          .take(accidentals)
          .toList();
    }
    if (accidentals < 0) {
      return const ['Bb', 'Eb', 'Ab', 'Db', 'Gb', 'Cb', 'Fb']
          .take(-accidentals)
          .toList();
    }
    return const [];
  }

  /// Scale degrees in written octave [octave], spelled for this key.
  List<Note> scaleNotes({int octave = 4}) {
    final pattern = minor
        ? const [0, 2, 3, 5, 7, 8, 10, 12]
        : const [0, 2, 4, 5, 7, 9, 11, 12];
    final tonicNote = Note.parse('$tonic$octave');
    final tonicLetter = tonic[0];
    const letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final startLetter = letters.indexOf(tonicLetter);
    if (startLetter < 0) {
      throw ArgumentError.value(tonic, 'tonic', 'Invalid tonic letter');
    }

    return [
      for (var index = 0; index < pattern.length; index++)
        Note.spelledFromMidi(
          tonicNote.midi + pattern[index],
          letters[(startLetter + index) % 7],
        ),
    ];
  }

  /// A single scale degree (1-based, 1..8) in this key.
  Note degree(int degree, {int octave = 4}) {
    final notes = scaleNotes(octave: octave);
    final normalized = ((degree - 1) % 8) + 1;
    return notes[normalized - 1];
  }

  static String _normalizeTonic(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final letter = trimmed[0].toUpperCase();
    final rest = trimmed.substring(1);
    return '$letter$rest';
  }
}

/// The common major and minor keys used by the course.
const List<String> majorKeyTonals = [
  'C',
  'G',
  'D',
  'A',
  'E',
  'B',
  'F',
  'Bb',
  'Eb',
  'Ab',
  'Db',
];

const List<String> minorKeyTonals = [
  'A',
  'E',
  'B',
  'F#',
  'C#',
  'D',
  'G',
  'C',
  'F',
  'Bb',
  'Eb',
];
