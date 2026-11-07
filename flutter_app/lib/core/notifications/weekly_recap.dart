import '../learning/progress.dart';
import '../media/recording_index.dart';

/// One honest before/after pair for a piece with at least two takes.
class BeforeAfterRecap {
  const BeforeAfterRecap({
    required this.pieceId,
    required this.pieceTitle,
    required this.before,
    required this.after,
    required this.takeCount,
  });

  final String pieceId;
  final String pieceTitle;
  final RecordingTake before;
  final RecordingTake after;
  final int takeCount;
}

/// Real numbers for the Quests recap card.
///
/// Minutes come from [ProgressState.weeklyPracticeSeconds]; phrases come from
/// the weekly quest counter. Recordings are takes whose local creation day is
/// in the same rolling seven-day window. Nothing is estimated.
class WeeklyRecap {
  const WeeklyRecap({
    required this.minutes,
    required this.phrases,
    required this.recordings,
    this.beforeAfter,
  });

  final int minutes;
  final int phrases;
  final int recordings;
  final BeforeAfterRecap? beforeAfter;

  bool get hasBeforeAfter => beforeAfter != null;
}

/// Builds the recap from stored progress and the recording index.
///
/// [pieceTitles] lets the caller show a real piece title instead of an id. A
/// missing title falls back to the id; the recap never invents a name.
WeeklyRecap buildWeeklyRecap({
  required ProgressState progress,
  required Iterable<RecordingTake> takes,
  required DateTime now,
  Map<String, String> pieceTitles = const <String, String>{},
}) {
  final start = DateTime(now.year, now.month, now.day - 6);
  final endExclusive = DateTime(now.year, now.month, now.day + 1);

  final ordered = List<RecordingTake>.of(takes)
    ..sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });

  var recordings = 0;
  final byPiece = <String, List<RecordingTake>>{};
  for (final take in ordered) {
    final local = take.createdAt.toLocal();
    if (!local.isBefore(start) && local.isBefore(endExclusive)) {
      recordings++;
    }
    final pieceId = take.pieceId;
    if (pieceId == null || pieceId.trim().isEmpty) continue;
    byPiece.putIfAbsent(pieceId, () => <RecordingTake>[]).add(take);
  }

  // Prefer the piece practised most recently, so the row reflects the
  // before/after the learner just made. Ties fall back to the piece id.
  BeforeAfterRecap? beforeAfter;
  for (final entry in byPiece.entries) {
    final pieceTakes = entry.value;
    if (pieceTakes.length < 2) continue;
    final candidate = BeforeAfterRecap(
      pieceId: entry.key,
      pieceTitle: pieceTitles[entry.key] ?? entry.key,
      before: pieceTakes.first,
      after: pieceTakes.last,
      takeCount: pieceTakes.length,
    );
    final current = beforeAfter;
    if (current == null ||
        candidate.after.createdAt.isAfter(current.after.createdAt) ||
        (candidate.after.createdAt == current.after.createdAt &&
            candidate.pieceId.compareTo(current.pieceId) < 0)) {
      beforeAfter = candidate;
    }
  }

  return WeeklyRecap(
    minutes: progress.weeklyPracticeMinutes(now),
    phrases: progress.quests.phrasesPracticed,
    recordings: recordings,
    beforeAfter: beforeAfter,
  );
}
