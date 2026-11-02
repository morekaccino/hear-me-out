import 'chord.dart';
import 'key.dart';

/// A short harmonic progression in a key.
class Progression {
  const Progression({
    required this.key,
    required this.chords,
    required this.romanNumerals,
    this.name,
  });

  final KeySignature key;
  final List<ChordSymbol> chords;
  final List<String> romanNumerals;
  final String? name;

  String get display => romanNumerals.join('–');

  String get chordSymbols => chords.map((chord) => chord.symbol).join('–');

  String get id => '${key.id}:${romanNumerals.join('-')}';

  /// Builds a diatonic progression from 1-based scale degrees.
  factory Progression.diatonic(
    KeySignature key,
    List<int> degrees, {
    String? name,
  }) {
    final triads = diatonicTriads(key);
    final chords = <ChordSymbol>[];
    final romans = <String>[];
    for (final degree in degrees) {
      final normalized = ((degree - 1) % 7) + 1;
      final triad = triads[normalized - 1];
      chords.add(triad.chord);
      romans.add(triad.romanNumeral);
    }
    return Progression(
      key: key,
      chords: chords,
      romanNumerals: romans,
      name: name,
    );
  }
}

/// Common cadence types.
enum CadenceType {
  authentic,
  half,
  plagal,
  deceptive;

  String get label => switch (this) {
    CadenceType.authentic => 'authentic',
    CadenceType.half => 'half',
    CadenceType.plagal => 'plagal',
    CadenceType.deceptive => 'deceptive',
  };
}

/// The cadence formed by the last two chords, when it is one of the common
/// four types.
CadenceType? cadenceFor(Progression progression) {
  if (progression.romanNumerals.length < 2) return null;
  final last = progression.romanNumerals.last;
  final previous = progression.romanNumerals[
      progression.romanNumerals.length - 2];
  if (last == 'I' && previous == 'V') return CadenceType.authentic;
  if (last == 'I' && previous == 'IV') return CadenceType.plagal;
  if (last == 'vi' && previous == 'V') return CadenceType.deceptive;
  if (last == 'V') return CadenceType.half;
  return null;
}

/// The 12-bar blues progression in a major key, using dominant sevenths.
Progression twelveBarBlues(KeySignature key) {
  final triads = majorDiatonicTriads(key);
  final one = ChordSymbol(
    root: triads[0].chord.root,
    quality: ChordQuality.dominant7,
  );
  final four = ChordSymbol(
    root: triads[3].chord.root,
    quality: ChordQuality.dominant7,
  );
  final five = ChordSymbol(
    root: triads[4].chord.root,
    quality: ChordQuality.dominant7,
  );
  final romans = <String>[
    'I7', 'I7', 'I7', 'I7',
    'IV7', 'IV7', 'I7', 'I7',
    'V7', 'IV7', 'I7', 'V7',
  ];
  final chords = <ChordSymbol>[
    one, one, one, one,
    four, four, one, one,
    five, four, one, five,
  ];
  return Progression(
    key: key,
    chords: chords,
    romanNumerals: romans,
    name: '12-bar blues',
  );
}

/// A I–V–vi–IV progression in a major key.
Progression popProgression(KeySignature key) =>
    Progression.diatonic(key, const [1, 5, 6, 4], name: 'I–V–vi–IV');

/// A ii–V–I progression in a major key.
Progression jazzCadence(KeySignature key) =>
    Progression.diatonic(key, const [2, 5, 1], name: 'ii–V–I');
