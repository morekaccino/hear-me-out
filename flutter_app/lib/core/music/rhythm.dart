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

const List<RhythmPattern> rhythmPatterns = [
  fourQuarters,
  twoHalves,
  quarterTwoHalves,
  eighthPairs,
  restOnThree,
  waltz,
  waltzHalfQuarter,
  downUpStrum,
];
