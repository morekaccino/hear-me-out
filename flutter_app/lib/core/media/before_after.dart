import 'recording_index.dart';
import 'take_comparison.dart';

/// The data one private before/after card shows.
///
/// The card is a pair of real takes, not a score. It names the piece and phrase,
/// the date range, and how many days separate the takes. A pair with fewer than
/// two takes is not a card.
class BeforeAfterCardData {
  const BeforeAfterCardData({
    required this.pieceId,
    required this.pieceTitle,
    required this.phraseId,
    required this.takeCount,
    required this.first,
    required this.last,
    required this.daysApart,
  });

  final String pieceId;
  final String pieceTitle;
  final String? phraseId;
  final int takeCount;
  final RecordingTake first;
  final RecordingTake last;
  final int daysApart;

  String get phraseLabel {
    final phrase = phraseId;
    if (phrase == null || phrase.trim().isEmpty) return 'Whole piece';
    return phrase;
  }

  String get metricLabel => daysApart == 0
      ? 'Both takes from the same day'
      : '$daysApart ${daysApart == 1 ? 'day' : 'days'} apart';
}

/// Selects the card for the most recent comparable piece/phrase.
///
/// The selection uses [defaultTakeComparisonPair] so the card and the A/B screen
/// agree on the pair. The card needs at least two takes in that piece/phrase
/// group; otherwise it returns null instead of inventing a before/after.
BeforeAfterCardData? buildBeforeAfterCard({
  required Iterable<RecordingTake> takes,
  Map<String, String> pieceTitles = const <String, String>{},
}) {
  final all = List<RecordingTake>.of(takes);
  final pair = defaultTakeComparisonPair(all);
  if (pair == null) return null;

  final pieceId = pair.left.pieceId;
  if (pieceId == null || pieceId.trim().isEmpty) return null;
  final phraseId = pair.left.phraseId;

  final group = all
      .where(
        (take) =>
            take.pieceId == pieceId &&
            (phraseId == null || take.phraseId == phraseId),
      )
      .toList()
    ..sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  if (group.length < 2) return null;

  final first = group.first;
  final last = group.last;
  return BeforeAfterCardData(
    pieceId: pieceId,
    pieceTitle: pieceTitles[pieceId] ?? pieceId,
    phraseId: phraseId,
    takeCount: group.length,
    first: first,
    last: last,
    daysApart: _daysApart(first.createdAt, last.createdAt),
  );
}

int _daysApart(DateTime a, DateTime b) {
  final first = a.toLocal();
  final last = b.toLocal();
  final firstDay = DateTime(first.year, first.month, first.day);
  final lastDay = DateTime(last.year, last.month, last.day);
  return lastDay.difference(firstDay).inDays.abs();
}
