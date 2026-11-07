import 'recording_index.dart';

/// True when [takes] contains at least two takes for one piece.
///
/// This is the recordings-screen entry condition. A free take has no piece, so
/// it does not open the comparison from the list.
bool hasComparablePiecePair(List<RecordingTake> takes) {
  final counts = <String, int>{};
  for (final take in takes) {
    final pieceId = take.pieceId;
    if (pieceId == null) continue;
    counts[pieceId] = (counts[pieceId] ?? 0) + 1;
  }
  return counts.values.any((count) => count >= 2);
}

/// The default A and B takes for [takes].
///
/// The pair is the oldest and newest take for the earliest piece that has two
/// takes. When a piece has a phrase with two takes, that phrase wins so the
/// learner compares the same musical material. With no comparably grouped
/// takes, the oldest and newest take overall are used.
TakeComparisonPair? defaultTakeComparisonPair(List<RecordingTake> takes) {
  if (takes.length < 2) return null;
  final ordered = List<RecordingTake>.of(takes)..sort(_byCreatedAt);

  final pieceGroups = <String, List<RecordingTake>>{};
  for (final take in ordered) {
    final pieceId = take.pieceId;
    if (pieceId == null) continue;
    pieceGroups.putIfAbsent(pieceId, () => <RecordingTake>[]).add(take);
  }

  for (final group in pieceGroups.values) {
    if (group.length < 2) continue;
    final phraseGroups = <String, List<RecordingTake>>{};
    for (final take in group) {
      final phraseId = take.phraseId;
      if (phraseId == null) continue;
      phraseGroups.putIfAbsent(phraseId, () => <RecordingTake>[]).add(take);
    }
    for (final phraseGroup in phraseGroups.values) {
      if (phraseGroup.length < 2) continue;
      return TakeComparisonPair(
        left: phraseGroup.first,
        right: phraseGroup.last,
      );
    }
    return TakeComparisonPair(left: group.first, right: group.last);
  }

  return TakeComparisonPair(left: ordered.first, right: ordered.last);
}

int _byCreatedAt(RecordingTake a, RecordingTake b) {
  final byTime = a.createdAt.compareTo(b.createdAt);
  return byTime != 0 ? byTime : a.id.compareTo(b.id);
}

/// The two takes on the comparison surface.
class TakeComparisonPair {
  const TakeComparisonPair({required this.left, required this.right});

  final RecordingTake left;
  final RecordingTake right;
}
