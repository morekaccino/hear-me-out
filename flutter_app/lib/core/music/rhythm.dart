/// One note in a rhythm, measured in beats from the start of the bar.
class RhythmCell {
  const RhythmCell({required this.start, required this.duration});

  final double start;
  final double duration;

  bool get isRest => duration <= 0;
}

/// A short rhythm to count, tap, or strum.
class RhythmPattern {
  const RhythmPattern({
    required this.id,
    required this.label,
    required this.beats,
    required this.cells,
  });

  final String id;
  final String label;

  /// Beats in the bar: 4 for 4/4, 3 for 3/4.
  final int beats;

  final List<RhythmCell> cells;

  List<double> get onsets => [for (final cell in cells) cell.start];

  bool get isEmpty => cells.isEmpty;
}

const RhythmPattern fourQuarters = RhythmPattern(
  id: 'quarters',
  label: 'Four quarter notes',
  beats: 4,
  cells: [
    RhythmCell(start: 0, duration: 1),
    RhythmCell(start: 1, duration: 1),
    RhythmCell(start: 2, duration: 1),
    RhythmCell(start: 3, duration: 1),
  ],
);

const RhythmPattern twoHalves = RhythmPattern(
  id: 'halves',
  label: 'Two half notes',
  beats: 4,
  cells: [
    RhythmCell(start: 0, duration: 2),
    RhythmCell(start: 2, duration: 2),
  ],
);

const RhythmPattern quarterTwoHalves = RhythmPattern(
  id: 'quarter-half-quarter',
  label: 'Quarter, half, quarter',
  beats: 4,
  cells: [
    RhythmCell(start: 0, duration: 1),
    RhythmCell(start: 1, duration: 2),
    RhythmCell(start: 3, duration: 1),
  ],
);

const RhythmPattern eighthPairs = RhythmPattern(
  id: 'eighths',
  label: 'Eight eighth notes',
  beats: 4,
  cells: [
    RhythmCell(start: 0, duration: 0.5),
    RhythmCell(start: 0.5, duration: 0.5),
    RhythmCell(start: 1, duration: 0.5),
    RhythmCell(start: 1.5, duration: 0.5),
    RhythmCell(start: 2, duration: 0.5),
    RhythmCell(start: 2.5, duration: 0.5),
    RhythmCell(start: 3, duration: 0.5),
    RhythmCell(start: 3.5, duration: 0.5),
  ],
);

const RhythmPattern restOnThree = RhythmPattern(
  id: 'rest-three',
  label: 'Quarter, quarter, rest, quarter',
  beats: 4,
  cells: [
    RhythmCell(start: 0, duration: 1),
    RhythmCell(start: 1, duration: 1),
    RhythmCell(start: 2, duration: 0),
    RhythmCell(start: 3, duration: 1),
  ],
);

const RhythmPattern waltz = RhythmPattern(
  id: 'waltz',
  label: 'Three quarter notes',
  beats: 3,
  cells: [
    RhythmCell(start: 0, duration: 1),
    RhythmCell(start: 1, duration: 1),
    RhythmCell(start: 2, duration: 1),
  ],
);

const RhythmPattern waltzHalfQuarter = RhythmPattern(
  id: 'waltz-half-quarter',
  label: 'Half, then quarter',
  beats: 3,
  cells: [
    RhythmCell(start: 0, duration: 2),
    RhythmCell(start: 2, duration: 1),
  ],
);

const RhythmPattern downUpStrum = RhythmPattern(
  id: 'down-up',
  label: 'Down, up, down, up',
  beats: 4,
  cells: [
    RhythmCell(start: 0, duration: 0.5),
    RhythmCell(start: 0.5, duration: 0.5),
    RhythmCell(start: 1, duration: 0.5),
    RhythmCell(start: 1.5, duration: 0.5),
    RhythmCell(start: 2, duration: 0.5),
    RhythmCell(start: 2.5, duration: 0.5),
    RhythmCell(start: 3, duration: 0.5),
    RhythmCell(start: 3.5, duration: 0.5),
  ],
);

const RhythmPattern sixEight = RhythmPattern(
  id: 'six-eight',
  label: 'Six eighth notes',
  beats: 6,
  cells: [
    RhythmCell(start: 0, duration: 0.5),
    RhythmCell(start: 0.5, duration: 0.5),
    RhythmCell(start: 1, duration: 0.5),
    RhythmCell(start: 1.5, duration: 0.5),
    RhythmCell(start: 2, duration: 0.5),
    RhythmCell(start: 2.5, duration: 0.5),
    RhythmCell(start: 3, duration: 0.5),
    RhythmCell(start: 3.5, duration: 0.5),
    RhythmCell(start: 4, duration: 0.5),
    RhythmCell(start: 4.5, duration: 0.5),
    RhythmCell(start: 5, duration: 0.5),
    RhythmCell(start: 5.5, duration: 0.5),
  ],
);

const RhythmPattern sevenEight = RhythmPattern(
  id: 'seven-eight',
  label: 'Seven beats',
  beats: 7,
  cells: [
    RhythmCell(start: 0, duration: 1),
    RhythmCell(start: 1, duration: 1),
    RhythmCell(start: 2, duration: 1),
    RhythmCell(start: 3, duration: 1),
    RhythmCell(start: 4, duration: 1),
    RhythmCell(start: 5, duration: 1),
    RhythmCell(start: 6, duration: 1),
  ],
);

const RhythmPattern fiveFour = RhythmPattern(
  id: 'five-four',
  label: 'Five beats',
  beats: 5,
  cells: [
    RhythmCell(start: 0, duration: 1),
    RhythmCell(start: 1, duration: 1),
    RhythmCell(start: 2, duration: 1),
    RhythmCell(start: 3, duration: 1),
    RhythmCell(start: 4, duration: 1),
  ],
);

const RhythmPattern syncopatedOffbeat = RhythmPattern(
  id: 'syncopated-offbeat',
  label: 'Offbeat accents',
  beats: 4,
  cells: [
    RhythmCell(start: 0, duration: 0.5),
    RhythmCell(start: 1, duration: 0.5),
    RhythmCell(start: 1.5, duration: 0.5),
    RhythmCell(start: 2.5, duration: 0.5),
    RhythmCell(start: 3, duration: 0.5),
    RhythmCell(start: 3.5, duration: 0.5),
  ],
);

const RhythmPattern bluesShuffle = RhythmPattern(
  id: 'blues-shuffle',
  label: 'Blues shuffle',
  beats: 4,
  cells: [
    RhythmCell(start: 0, duration: 0.66),
    RhythmCell(start: 0.66, duration: 0.34),
    RhythmCell(start: 1, duration: 0.66),
    RhythmCell(start: 1.66, duration: 0.34),
    RhythmCell(start: 2, duration: 0.66),
    RhythmCell(start: 2.66, duration: 0.34),
    RhythmCell(start: 3, duration: 0.66),
    RhythmCell(start: 3.66, duration: 0.34),
  ],
);

const RhythmPattern fingerstyleRoll = RhythmPattern(
  id: 'fingerstyle-roll',
  label: 'Fingerstyle roll',
  beats: 4,
  cells: [
    RhythmCell(start: 0, duration: 0.5),
    RhythmCell(start: 0.5, duration: 0.5),
    RhythmCell(start: 1, duration: 0.5),
    RhythmCell(start: 1.5, duration: 0.5),
    RhythmCell(start: 2, duration: 0.5),
    RhythmCell(start: 2.5, duration: 0.5),
    RhythmCell(start: 3, duration: 0.5),
    RhythmCell(start: 3.5, duration: 0.5),
  ],
);

const List<RhythmPattern> rhythmPatterns = [
  fourQuarters,
  twoHalves,
  quarterTwoHalves,
  eighthPairs,
  restOnThree,
  waltz,
  waltzHalfQuarter,
  downUpStrum,
  sixEight,
  sevenEight,
  fiveFour,
  syncopatedOffbeat,
  bluesShuffle,
  fingerstyleRoll,
];
