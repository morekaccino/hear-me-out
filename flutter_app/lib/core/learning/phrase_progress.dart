/// Persisted performance progress for one phrase.
///
/// This is a storage shape only. The scheduler that updates it lives with the
/// phrase-session work (T2.3/T2.5). A phrase is identified by [Phrase.id].
class PhraseProgress {
  PhraseProgress({
    required this.phraseId,
    this.stabilityDays = 0,
    this.difficulty = 0,
    this.dueAt,
    this.reps = 0,
    this.lapses = 0,
    this.correct = 0,
    this.incorrect = 0,
    Set<String>? correctDays,
    Set<String>? performanceDays,
    this.firstPerformanceDay,
    this.lastPerformanceAt,
    this.bestTempoBpm,
    this.bestAccuracy,
  }) : correctDays = correctDays ?? <String>{},
       performanceDays = performanceDays ?? <String>{};

  final String phraseId;
  double stabilityDays;
  double difficulty;
  DateTime? dueAt;
  int reps;
  int lapses;
  int correct;
  int incorrect;

  /// Local `yyyy-MM-dd` keys on which the phrase was answered correctly.
  final Set<String> correctDays;

  /// Local `yyyy-MM-dd` keys with a counted performance.
  final Set<String> performanceDays;

  /// The first counted performance day. Stored explicitly so the seven-day
  /// mastery window survives even if the day set is pruned later.
  String? firstPerformanceDay;

  DateTime? lastPerformanceAt;
  int? bestTempoBpm;

  /// Best accuracy as a fraction in `[0, 1]`.
  double? bestAccuracy;

  int get attempts => correct + incorrect;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  /// The latest counted performance day, or null when there is none.
  String? get lastPerformanceDay {
    if (performanceDays.isEmpty) return null;
    final days = performanceDays.toList()..sort();
    return days.last;
  }

  /// Days between the first and last counted performance day.
  int get performanceSpanDays {
    if (performanceDays.length < 2) return 0;
    final days = performanceDays.toList()..sort();
    final first = _tryParseDay(firstPerformanceDay ?? days.first);
    final last = _tryParseDay(days.last);
    if (first == null || last == null) return 0;
    return last.difference(first).inDays;
  }

  /// Performance mastery: four spaced reps, five correct answers on two days,
  /// at least three performance days, and a seven-day performance window.
  bool get mastered =>
      reps >= 4 &&
      correct >= 5 &&
      correctDays.length >= 2 &&
      performanceDays.length >= 3 &&
      performanceSpanDays >= 7;

  PhraseProgress copy() => PhraseProgress(
    phraseId: phraseId,
    stabilityDays: stabilityDays,
    difficulty: difficulty,
    dueAt: dueAt,
    reps: reps,
    lapses: lapses,
    correct: correct,
    incorrect: incorrect,
    correctDays: {...correctDays},
    performanceDays: {...performanceDays},
    firstPerformanceDay: firstPerformanceDay,
    lastPerformanceAt: lastPerformanceAt,
    bestTempoBpm: bestTempoBpm,
    bestAccuracy: bestAccuracy,
  );

  Map<String, dynamic> toJson() => {
    'phraseId': phraseId,
    'stabilityDays': stabilityDays,
    'difficulty': difficulty,
    'dueAt': dueAt?.toIso8601String(),
    'reps': reps,
    'lapses': lapses,
    'correct': correct,
    'incorrect': incorrect,
    'correctDays': correctDays.toList()..sort(),
    'performanceDays': performanceDays.toList()..sort(),
    'firstPerformanceDay': firstPerformanceDay ?? _firstDay(performanceDays),
    'lastPerformanceAt': lastPerformanceAt?.toIso8601String(),
    'bestTempoBpm': bestTempoBpm,
    'bestAccuracy': bestAccuracy,
  };

  factory PhraseProgress.fromJson(
    Map<String, dynamic> json, {
    String? phraseId,
  }) {
    final storedId = json['phraseId'];
    final id =
        phraseId ??
        (storedId is String && storedId.isNotEmpty ? storedId : null);
    if (id == null) {
      throw const FormatException(
        'phraseProgress entry is missing a phrase id',
      );
    }
    return PhraseProgress(
      phraseId: id,
      stabilityDays: _readDouble(json, 'stabilityDays', 0),
      difficulty: _readDouble(json, 'difficulty', 0),
      dueAt: _readDate(json['dueAt']),
      reps: _readInt(json, 'reps', 0),
      lapses: _readInt(json, 'lapses', 0),
      correct: _readInt(json, 'correct', 0),
      incorrect: _readInt(json, 'incorrect', 0),
      correctDays: _readDays(json['correctDays'], 'correctDays'),
      performanceDays: _readDays(json['performanceDays'], 'performanceDays'),
      firstPerformanceDay: _readDay(json['firstPerformanceDay']),
      lastPerformanceAt: _readDate(json['lastPerformanceAt']),
      bestTempoBpm: _readOptionalInt(json['bestTempoBpm'], 'bestTempoBpm'),
      bestAccuracy: _readOptionalDouble(json['bestAccuracy'], 'bestAccuracy'),
    );
  }
}

String? _firstDay(Set<String> days) {
  if (days.isEmpty) return null;
  final sorted = days.toList()..sort();
  return sorted.first;
}

String? _readDay(Object? value) {
  if (value is! String) return null;
  return _tryParseDay(value) == null ? null : value;
}

Set<String> _readDays(Object? value, String key) {
  if (value == null) return <String>{};
  if (value is! List) {
    throw FormatException('phraseProgress.$key must be a list');
  }
  final days = <String>{};
  for (final item in value) {
    if (item is! String || _tryParseDay(item) == null) {
      throw FormatException('phraseProgress.$key must contain day strings');
    }
    days.add(item);
  }
  return days;
}

int _readInt(Map<String, dynamic> json, String key, int fallback) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('phraseProgress.$key must be an integer');
}

int? _readOptionalInt(Object? value, String key) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('phraseProgress.$key must be an integer');
}

double _readDouble(Map<String, dynamic> json, String key, double fallback) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is num && value.isFinite) return value.toDouble();
  throw FormatException('phraseProgress.$key must be a number');
}

double? _readOptionalDouble(Object? value, String key) {
  if (value == null) return null;
  if (value is num && value.isFinite) return value.toDouble();
  throw FormatException('phraseProgress.$key must be a number');
}

DateTime? _readDate(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}

DateTime? _tryParseDay(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  // UTC keeps the span in whole calendar days across DST transitions.
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}
