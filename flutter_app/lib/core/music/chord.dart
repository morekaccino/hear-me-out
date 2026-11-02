import 'interval.dart';
import 'key.dart';
import 'note.dart';

/// The chord qualities used by the course.
enum ChordQuality {
  major,
  minor,
  diminished,
  augmented,
  major7,
  minor7,
  dominant7,
  halfDiminished7,
  diminished7,
  major6,
  minor6,
  sus2,
  sus4,
  add9,
  major9,
  dominant9;

  String get label => switch (this) {
    ChordQuality.major => 'major',
    ChordQuality.minor => 'minor',
    ChordQuality.diminished => 'diminished',
    ChordQuality.augmented => 'augmented',
    ChordQuality.major7 => 'major seventh',
    ChordQuality.minor7 => 'minor seventh',
    ChordQuality.dominant7 => 'dominant seventh',
    ChordQuality.halfDiminished7 => 'half-diminished seventh',
    ChordQuality.diminished7 => 'diminished seventh',
    ChordQuality.major6 => 'major sixth',
    ChordQuality.minor6 => 'minor sixth',
    ChordQuality.sus2 => 'suspended second',
    ChordQuality.sus4 => 'suspended fourth',
    ChordQuality.add9 => 'added ninth',
    ChordQuality.major9 => 'major ninth',
    ChordQuality.dominant9 => 'dominant ninth',
  };

  String get suffix => switch (this) {
    ChordQuality.major => '',
    ChordQuality.minor => 'm',
    ChordQuality.diminished => 'dim',
    ChordQuality.augmented => 'aug',
    ChordQuality.major7 => 'maj7',
    ChordQuality.minor7 => 'm7',
    ChordQuality.dominant7 => '7',
    ChordQuality.halfDiminished7 => 'm7b5',
    ChordQuality.diminished7 => 'dim7',
    ChordQuality.major6 => '6',
    ChordQuality.minor6 => 'm6',
    ChordQuality.sus2 => 'sus2',
    ChordQuality.sus4 => 'sus4',
    ChordQuality.add9 => 'add9',
    ChordQuality.major9 => 'maj9',
    ChordQuality.dominant9 => '9',
  };

  /// Semitones above the root.
  List<int> get intervals => switch (this) {
    ChordQuality.major => const [0, 4, 7],
    ChordQuality.minor => const [0, 3, 7],
    ChordQuality.diminished => const [0, 3, 6],
    ChordQuality.augmented => const [0, 4, 8],
    ChordQuality.major7 => const [0, 4, 7, 11],
    ChordQuality.minor7 => const [0, 3, 7, 10],
    ChordQuality.dominant7 => const [0, 4, 7, 10],
    ChordQuality.halfDiminished7 => const [0, 3, 6, 10],
    ChordQuality.diminished7 => const [0, 3, 6, 9],
    ChordQuality.major6 => const [0, 4, 7, 9],
    ChordQuality.minor6 => const [0, 3, 7, 9],
    ChordQuality.sus2 => const [0, 2, 7],
    ChordQuality.sus4 => const [0, 5, 7],
    ChordQuality.add9 => const [0, 4, 7, 14],
    ChordQuality.major9 => const [0, 4, 7, 11, 14],
    ChordQuality.dominant9 => const [0, 4, 7, 10, 14],
  };

  bool get isTriad => intervals.length == 3;

  bool get isSeventh => intervals.length >= 4 && intervals[3] < 12;
}

/// A chord symbol such as `C`, `Am`, `G7`, or `Fmaj7`.
class ChordSymbol {
  const ChordSymbol({
    required this.root,
    required this.quality,
    this.bass,
  });

  final Note root;
  final ChordQuality quality;

  /// Optional slash-chord bass note.
  final Note? bass;

  String get symbol {
    final rootName = root.pitchClass;
    final base = '$rootName${quality.suffix}';
    return bass == null ? base : '$base/${bass!.pitchClass}';
  }

  String get display => symbol;

  List<Note> get notes {
    const letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final start = letters.indexOf(root.letter);
    return [
      for (var index = 0; index < quality.intervals.length; index++)
        _spell(root.midi + quality.intervals[index], start + index),
    ];
  }

  List<String> get noteNames => [for (final note in notes) note.pitchClass];

  /// The chord tones as scale-degree labels relative to the root.
  List<String> get toneLabels {
    final labels = <String>[];
    for (var index = 0; index < quality.intervals.length; index++) {
      final interval = quality.intervals[index];
      labels.add(
        switch (index) {
          0 => 'root',
          1 => switch (interval % 12) {
            2 => '2',
            3 => 'b3',
            4 => '3',
            5 => '4',
            _ => '$interval',
          },
          2 => switch (interval % 12) {
            6 => 'b5',
            7 => '5',
            8 => '#5',
            _ => '$interval',
          },
          3 => switch (interval % 12) {
            9 => '6',
            10 => 'b7',
            11 => '7',
            _ => '$interval',
          },
          4 => '9',
          _ => '$interval',
        },
      );
    }
    return labels;
  }

  @override
  String toString() => symbol;

  @override
  bool operator ==(Object other) =>
      other is ChordSymbol &&
      other.root.samePitchAs(root) &&
      other.quality == quality &&
      other.bass?.midi == bass?.midi;

  @override
  int get hashCode => Object.hash(root.midi % 12, quality, bass?.midi);
}

Note _spell(int midi, int letterIndex) {
  const letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  final letter = letters[letterIndex % 7];
  return Note.spelledFromMidi(midi, letter);
}

/// A diatonic chord inside a key, with its roman numeral and function.
class DiatonicChord {
  const DiatonicChord({
    required this.degree,
    required this.chord,
    required this.romanNumeral,
    required this.function,
  });

  /// 1-based scale degree.
  final int degree;
  final ChordSymbol chord;
  final String romanNumeral;

  /// Tonic, predominant, or dominant.
  final String function;
}

/// The seven diatonic triads of a major key.
List<DiatonicChord> majorDiatonicTriads(KeySignature key, {int octave = 4}) {
  assert(!key.minor, 'majorDiatonicTriads expects a major key');
  final scale = key.scaleNotes(octave: octave);
  const qualities = [
    ChordQuality.major,
    ChordQuality.minor,
    ChordQuality.minor,
    ChordQuality.major,
    ChordQuality.major,
    ChordQuality.minor,
    ChordQuality.diminished,
  ];
  const romans = ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°'];
  const functions = [
    'tonic',
    'predominant',
    'tonic',
    'predominant',
    'dominant',
    'tonic',
    'dominant',
  ];
  return [
    for (var index = 0; index < 7; index++)
      DiatonicChord(
        degree: index + 1,
        chord: ChordSymbol(root: scale[index], quality: qualities[index]),
        romanNumeral: romans[index],
        function: functions[index],
      ),
  ];
}

/// The seven diatonic triads of a natural minor key.
List<DiatonicChord> naturalMinorDiatonicTriads(
  KeySignature key, {
  int octave = 4,
}) {
  assert(key.minor, 'naturalMinorDiatonicTriads expects a minor key');
  final scale = key.scaleNotes(octave: octave);
  const qualities = [
    ChordQuality.minor,
    ChordQuality.diminished,
    ChordQuality.major,
    ChordQuality.minor,
    ChordQuality.minor,
    ChordQuality.major,
    ChordQuality.major,
  ];
  const romans = ['i', 'ii°', 'III', 'iv', 'v', 'VI', 'VII'];
  const functions = [
    'tonic',
    'predominant',
    'tonic',
    'predominant',
    'dominant',
    'predominant',
    'dominant',
  ];
  return [
    for (var index = 0; index < 7; index++)
      DiatonicChord(
        degree: index + 1,
        chord: ChordSymbol(root: scale[index], quality: qualities[index]),
        romanNumeral: romans[index],
        function: functions[index],
      ),
  ];
}

List<DiatonicChord> diatonicTriads(KeySignature key, {int octave = 4}) =>
    key.minor
    ? naturalMinorDiatonicTriads(key, octave: octave)
    : majorDiatonicTriads(key, octave: octave);

/// Builds a chord from a root pitch class and quality.
ChordSymbol chordFrom(String root, ChordQuality quality, {String? bass}) {
  return ChordSymbol(
    root: Note.parse('${root}4'),
    quality: quality,
    bass: bass == null ? null : Note.parse('${bass}4'),
  );
}

/// The interval between two notes, described by semitones and diatonic size.
Interval intervalBetween(Note lower, Note upper) {
  final semitones = upper.midi - lower.midi;
  final number = upper.diatonicIndex - lower.diatonicIndex + 1;
  final normalizedNumber = number <= 0 ? number + 7 : number;
  final quality = _qualityFor(semitones.abs(), normalizedNumber);
  return Interval(
    semitones: semitones.abs(),
    number: normalizedNumber,
    quality: quality,
  );
}

IntervalQuality _qualityFor(int semitones, int number) {
  final simpleNumber = ((number - 1) % 7) + 1;
  final expectedMajor = Interval.majorSemitonesForNumber(simpleNumber);
  final difference = semitones - expectedMajor;
  if (isPerfectIntervalNumber(simpleNumber)) {
    return switch (difference) {
      0 => IntervalQuality.perfect,
      1 => IntervalQuality.augmented,
      -1 => IntervalQuality.diminished,
      _ => difference > 0
          ? IntervalQuality.augmented
          : IntervalQuality.diminished,
    };
  }
  return switch (difference) {
    0 => IntervalQuality.major,
    -1 => IntervalQuality.minor,
    -2 => IntervalQuality.diminished,
    1 => IntervalQuality.augmented,
    _ => difference > 0 ? IntervalQuality.augmented : IntervalQuality.minor,
  };
}
