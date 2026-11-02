/// An open chord shape a beginner can read from a diagram.
class ChordShape {
  const ChordShape({
    required this.id,
    required this.name,
    required this.frets,
  });

  final String id;

  /// Display name, such as `G` or `E minor`.
  final String name;

  /// Fret per string, low E to high E. 0 is open, null is muted.
  final List<int?> frets;

  int get highestFret =>
      frets.whereType<int>().fold(0, (best, fret) => fret > best ? fret : best);
}

const List<ChordShape> chordShapes = [
  ChordShape(id: 'G', name: 'G', frets: [3, 2, 0, 0, 0, 3]),
  ChordShape(id: 'C', name: 'C', frets: [null, 3, 2, 0, 1, 0]),
  ChordShape(id: 'D', name: 'D', frets: [null, null, 0, 2, 3, 2]),
  ChordShape(id: 'A', name: 'A', frets: [null, 0, 2, 2, 2, 0]),
  ChordShape(id: 'E', name: 'E', frets: [0, 2, 2, 1, 0, 0]),
  ChordShape(id: 'Am', name: 'A minor', frets: [null, 0, 2, 2, 1, 0]),
  ChordShape(id: 'Em', name: 'E minor', frets: [0, 2, 2, 0, 0, 0]),
  ChordShape(id: 'Dm', name: 'D minor', frets: [null, null, 0, 2, 3, 1]),
];

final Map<String, ChordShape> chordById = {
  for (final chord in chordShapes) chord.id: chord,
};
