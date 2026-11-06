import '../../core/music/piece.dart';
import '../../core/music/playability.dart';

/// The hand position a phrase is written in.
enum EtudePosition {
  /// Frets 0-3, with open strings available.
  first,

  /// Frets 2-5, with no open strings.
  second,
}

/// One phrase slot in a level's phrase plan.
class EtudePhrasePlan {
  const EtudePhrasePlan({required this.bars, required this.position});

  final int bars;
  final EtudePosition position;
}

/// A tonal key the generator may use.
///
/// The five keys match the T3.6 reviewed set: C, G, and D major plus A and E
/// minor. The generator does not invent key signatures or enharmonic spellings.
class EtudeKey {
  const EtudeKey({
    required this.name,
    required this.tonicPitchClass,
    required this.isMinor,
  });

  final String name;
  final int tonicPitchClass;
  final bool isMinor;

  /// Scale intervals above the tonic, in semitones.
  List<int> get scaleIntervals => isMinor
      ? const <int>[0, 2, 3, 5, 7, 8, 10]
      : const <int>[0, 2, 4, 5, 7, 9, 11];

  /// Pitch class of a zero-based scale degree. The degree wraps by octave.
  int degreePitchClass(int degree) {
    final index = degree % 7;
    return (tonicPitchClass + scaleIntervals[index]) % 12;
  }

  bool containsPitchClass(int pitchClass) {
    for (var index = 0; index < scaleIntervals.length; index++) {
      if (degreePitchClass(index) == pitchClass % 12) return true;
    }
    return false;
  }
}

/// The T3.6 level rubric expressed as generator parameters.
///
/// The table follows [`docs/SIGHT_READING_ETUDES.md`] section 2. Changing a
/// value here changes every generated candidate at that level, so a grammar
/// edit is a content decision and needs the same review as an authored etude.
class EtudeLevelSpec {
  const EtudeLevelSpec({
    required this.level,
    required this.stage,
    required this.tier,
    required this.phrasePlan,
    required this.tempoBpm,
    required this.allowedMeters,
    required this.allowedStrings,
    required this.minFret,
    required this.maxFret,
    required this.firstPositionLow,
    required this.firstPositionHigh,
    required this.secondPositionLow,
    required this.secondPositionHigh,
    required this.rhythmCells,
    required this.requiredRhythmCells,
    required this.requiresDottedRhythm,
    required this.requiresRest,
    required this.minAccidentals,
    required this.maxAccidentals,
    required this.maxIntervalSemitones,
    required this.registerRadiusSemitones,
    required this.registerTargets,
    required this.maxShifts,
    required this.maxStringSkip,
    required this.maxConsecutiveRepeatedNotes,
    required this.requiresOpenString,
    required this.allowedKeys,
  });

  final int level;

  /// V1 stage used in `authoring.stage`.
  final int stage;

  /// Content tier such as `foundation` or `returner`.
  final String tier;

  final List<EtudePhrasePlan> phrasePlan;
  final int tempoBpm;
  final List<TimeSignature> allowedMeters;

  /// Allowed string numbers, 1 = high E and 6 = low E.
  final List<int> allowedStrings;

  /// Inclusive fret envelope for the level.
  final int minFret;
  final int maxFret;

  /// First-position window, inclusive.
  final int firstPositionLow;
  final int firstPositionHigh;

  /// Second-position window, inclusive.
  final int secondPositionLow;
  final int secondPositionHigh;

  /// Durations the level may use, in quarter-note beats.
  final List<double> rhythmCells;

  /// Durations that must appear at least once in every candidate.
  final List<double> requiredRhythmCells;

  /// Whether a dotted value must appear.
  final bool requiresDottedRhythm;

  /// Whether a rest must appear.
  final bool requiresRest;

  /// Inclusive accidental count, counted as distinct written pitch classes
  /// outside the key signature.
  final int minAccidentals;
  final int maxAccidentals;

  /// Largest melodic interval inside a phrase, in semitones.
  final int maxIntervalSemitones;

  /// Half-width of the register window around the home tonic.
  final int registerRadiusSemitones;

  /// Sounding MIDI targets for the home tonic; one is chosen by seed.
  final List<int> registerTargets;

  /// Maximum number of phrase-level position changes.
  final int maxShifts;

  /// Maximum string jump between consecutive notes.
  final int maxStringSkip;

  /// Longest allowed run of the same written pitch.
  final int maxConsecutiveRepeatedNotes;

  /// Whether the level must use an open string.
  final bool requiresOpenString;

  final List<EtudeKey> allowedKeys;

  int get totalBars =>
      phrasePlan.fold<int>(0, (sum, phrase) => sum + phrase.bars);

  /// The limits the playability validator applies to a candidate at this level.
  PlayabilityLimits get playabilityLimits {
    final strings = allowedStrings.toList()..sort();
    return PlayabilityLimits(
      minString: strings.first,
      maxString: strings.last,
      minFret: minFret,
      maxFret: maxFret,
      minWrittenMidi: 52,
      maxWrittenMidi: 88,
      maxStretch: 4,
      maxStringSkip: maxStringSkip,
      maxShifts: maxShifts,
      maxShiftDistance: 7,
      requireOpenString: requiresOpenString,
      maxConsecutiveRepeatedNotes: maxConsecutiveRepeatedNotes,
      allowedDurations: rhythmCells,
      requireTonicCadence: true,
      maxCadenceApproachSemitones: 2,
    );
  }

  /// Returns the level grammar, or throws [ArgumentError] for an invalid level.
  static EtudeLevelSpec forLevel(int level) {
    final spec = _levels[level];
    if (spec == null) {
      throw ArgumentError.value(
        level,
        'level',
        'Etude levels are 1-5; level $level has no grammar.',
      );
    }
    return spec;
  }

  /// All five level grammars in order.
  static List<EtudeLevelSpec> get all => <EtudeLevelSpec>[
    for (var level = 1; level <= 5; level++) forLevel(level),
  ];

  static const List<EtudeKey> _keys = <EtudeKey>[
    EtudeKey(name: 'C major', tonicPitchClass: 0, isMinor: false),
    EtudeKey(name: 'G major', tonicPitchClass: 7, isMinor: false),
    EtudeKey(name: 'D major', tonicPitchClass: 2, isMinor: false),
    EtudeKey(name: 'A minor', tonicPitchClass: 9, isMinor: true),
    EtudeKey(name: 'E minor', tonicPitchClass: 4, isMinor: true),
  ];

  static const TimeSignature _fourFour = TimeSignature(4, 4);
  static const TimeSignature _threeFour = TimeSignature(3, 4);

  static const Map<int, EtudeLevelSpec> _levels = <int, EtudeLevelSpec>{
    1: EtudeLevelSpec(
      level: 1,
      stage: 1,
      tier: 'foundation',
      phrasePlan: <EtudePhrasePlan>[
        EtudePhrasePlan(bars: 4, position: EtudePosition.first),
      ],
      tempoBpm: 60,
      allowedMeters: <TimeSignature>[_fourFour],
      allowedStrings: <int>[1, 2, 3],
      minFret: 0,
      maxFret: 3,
      firstPositionLow: 0,
      firstPositionHigh: 3,
      secondPositionLow: 2,
      secondPositionHigh: 5,
      rhythmCells: <double>[2.0, 1.0],
      requiredRhythmCells: <double>[1.0, 2.0],
      requiresDottedRhythm: false,
      requiresRest: false,
      minAccidentals: 0,
      maxAccidentals: 0,
      maxIntervalSemitones: 2,
      registerRadiusSemitones: 9,
      registerTargets: <int>[62],
      maxShifts: 0,
      maxStringSkip: 2,
      maxConsecutiveRepeatedNotes: 2,
      requiresOpenString: true,
      allowedKeys: _keys,
    ),
    2: EtudeLevelSpec(
      level: 2,
      stage: 2,
      tier: 'foundation',
      phrasePlan: <EtudePhrasePlan>[
        EtudePhrasePlan(bars: 4, position: EtudePosition.first),
        EtudePhrasePlan(bars: 4, position: EtudePosition.first),
      ],
      tempoBpm: 66,
      allowedMeters: <TimeSignature>[_fourFour, _threeFour],
      allowedStrings: <int>[1, 2, 3],
      minFret: 0,
      maxFret: 5,
      firstPositionLow: 0,
      firstPositionHigh: 3,
      secondPositionLow: 2,
      secondPositionHigh: 5,
      rhythmCells: <double>[1.0, 0.5],
      requiredRhythmCells: <double>[0.5, 1.0],
      requiresDottedRhythm: false,
      requiresRest: false,
      minAccidentals: 0,
      maxAccidentals: 1,
      maxIntervalSemitones: 4,
      registerRadiusSemitones: 9,
      registerTargets: <int>[60],
      maxShifts: 0,
      maxStringSkip: 2,
      maxConsecutiveRepeatedNotes: 2,
      requiresOpenString: true,
      allowedKeys: _keys,
    ),
    3: EtudeLevelSpec(
      level: 3,
      stage: 3,
      tier: 'foundation',
      phrasePlan: <EtudePhrasePlan>[
        EtudePhrasePlan(bars: 4, position: EtudePosition.first),
        EtudePhrasePlan(bars: 4, position: EtudePosition.first),
        EtudePhrasePlan(bars: 4, position: EtudePosition.first),
      ],
      tempoBpm: 72,
      allowedMeters: <TimeSignature>[_fourFour, _threeFour],
      allowedStrings: <int>[1, 2, 3, 4, 5, 6],
      minFret: 0,
      maxFret: 5,
      firstPositionLow: 0,
      firstPositionHigh: 3,
      secondPositionLow: 2,
      secondPositionHigh: 5,
      rhythmCells: <double>[1.0, 0.5, 1.5, 3.0],
      requiredRhythmCells: <double>[0.5, 1.0],
      requiresDottedRhythm: true,
      requiresRest: false,
      minAccidentals: 1,
      maxAccidentals: 1,
      maxIntervalSemitones: 5,
      registerRadiusSemitones: 12,
      registerTargets: <int>[48, 60],
      maxShifts: 0,
      maxStringSkip: 3,
      maxConsecutiveRepeatedNotes: 2,
      requiresOpenString: true,
      allowedKeys: _keys,
    ),
    4: EtudeLevelSpec(
      level: 4,
      stage: 5,
      tier: 'returner',
      phrasePlan: <EtudePhrasePlan>[
        EtudePhrasePlan(bars: 4, position: EtudePosition.first),
        EtudePhrasePlan(bars: 4, position: EtudePosition.second),
        EtudePhrasePlan(bars: 4, position: EtudePosition.first),
      ],
      tempoBpm: 76,
      allowedMeters: <TimeSignature>[_fourFour, _threeFour],
      allowedStrings: <int>[1, 2, 3, 4],
      minFret: 0,
      maxFret: 5,
      firstPositionLow: 0,
      firstPositionHigh: 3,
      secondPositionLow: 2,
      secondPositionHigh: 5,
      rhythmCells: <double>[1.0, 0.5],
      requiredRhythmCells: <double>[0.5, 1.0],
      requiresDottedRhythm: false,
      requiresRest: false,
      minAccidentals: 0,
      maxAccidentals: 0,
      maxIntervalSemitones: 4,
      registerRadiusSemitones: 9,
      registerTargets: <int>[60],
      maxShifts: 2,
      maxStringSkip: 3,
      maxConsecutiveRepeatedNotes: 2,
      requiresOpenString: false,
      allowedKeys: _keys,
    ),
    5: EtudeLevelSpec(
      level: 5,
      stage: 9,
      tier: 'returner',
      phrasePlan: <EtudePhrasePlan>[
        EtudePhrasePlan(bars: 2, position: EtudePosition.first),
        EtudePhrasePlan(bars: 2, position: EtudePosition.second),
      ],
      tempoBpm: 70,
      allowedMeters: <TimeSignature>[_fourFour, _threeFour],
      allowedStrings: <int>[1, 2, 3, 4, 5, 6],
      minFret: 0,
      maxFret: 5,
      firstPositionLow: 0,
      firstPositionHigh: 3,
      secondPositionLow: 2,
      secondPositionHigh: 5,
      rhythmCells: <double>[1.0, 0.5],
      requiredRhythmCells: <double>[0.5, 1.0],
      requiresDottedRhythm: false,
      requiresRest: true,
      minAccidentals: 0,
      maxAccidentals: 0,
      maxIntervalSemitones: 5,
      registerRadiusSemitones: 12,
      registerTargets: <int>[60],
      maxShifts: 1,
      maxStringSkip: 3,
      maxConsecutiveRepeatedNotes: 2,
      requiresOpenString: false,
      allowedKeys: _keys,
    ),
  };
}
