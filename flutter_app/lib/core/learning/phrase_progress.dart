import 'attempt_outcome.dart';

/// One scored phrase attempt, expressed in domain terms.
///
/// Audio and UI layers map their own result types to this before recording.
/// [outcome] is the tri-state verdict; an indeterminate attempt is a retry and
/// must not be recorded.
class PhraseAttempt {
  const PhraseAttempt({
    required this.phraseId,
    required this.outcome,
    required this.now,
    this.accuracy = 0,
    this.tempoBpm,
    this.pieceId,
    this.contentVersion,
  });

  final String phraseId;
  final AttemptOutcome outcome;
  final DateTime now;

  /// Fraction of determinate target notes that were correct, in `[0, 1]`.
  final double accuracy;

  /// Tempo the phrase was played at, when known.
  final int? tempoBpm;

  /// Piece that owns [phraseId], when the caller knows it. The phrase skill
  /// uses the canonical `phrase:<pieceId>:<phraseId>` id when present and the
  /// legacy `phrase:<phraseId>` id otherwise.
  final String? pieceId;

  /// Content version the learner practiced against, when known.
  final int? contentVersion;
}

/// Persisted performance progress for one phrase.
///
/// This is a storage shape only. The scheduler and the mastery decision live
/// with the phrase-session work (T2.5). A phrase is identified by [Phrase.id].
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
    this.contentVersion = 1,
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

  /// The first counted performance day. Stored explicitly so the performance
  /// window can still be computed if the day set is pruned later.
  String? firstPerformanceDay;

  DateTime? lastPerformanceAt;
  int? bestTempoBpm;

  /// Best raw note accuracy as a fraction in `[0, 1]` across determinate
  /// takes, including failed takes. This is a high-water mark, not a
  /// pass/mastery signal.
  double? bestAccuracy;

  /// The phrase content version this evidence was last practiced against.
  ///
  /// Progress is keyed by [phraseId], so a content edit never moves or resets
  /// it. The intended phrase UI compares this value with the current
  /// `Phrase.contentVersion` and asks for a re-test instead of claiming mastery
  /// of unseen notes. No UI consumes [needsRetestFor] yet; the phrase UI stays
  /// behind the T1.7 switch.
  int contentVersion;

  int get attempts => correct + incorrect;

  /// True when the current arrangement differs from the evidence's version.
  bool needsRetestFor(int currentContentVersion) =>
      contentVersion != currentContentVersion;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  /// Records one determinate phrase attempt.
  ///
  /// Indeterminate attempts are retries and change nothing. A determinate
  /// attempt updates the raw phrase counters only; it never touches atomic
  /// skills or legacy note progress.
  void recordAttempt(PhraseAttempt attempt) {
    if (attempt.outcome == AttemptOutcome.indeterminate) return;

    final day = _dayKey(attempt.now);
    reps++;
    lastPerformanceAt = attempt.now;
    performanceDays.add(day);
    firstPerformanceDay ??= day;
    if (attempt.outcome == AttemptOutcome.correct) {
      correct++;
      correctDays.add(day);
    } else {
      incorrect++;
    }
    if (attempt.accuracy.isFinite && attempt.accuracy > (bestAccuracy ?? 0)) {
      bestAccuracy = attempt.accuracy;
    }
    final tempo = attempt.tempoBpm;
    if (tempo != null && tempo > (bestTempoBpm ?? 0)) {
      bestTempoBpm = tempo;
    }
  }

  /// The latest counted performance day, or null when there is none.
  String? get lastPerformanceDay {
    if (performanceDays.isEmpty) return null;
    final days = performanceDays.toList()..sort();
    return days.last;
  }

  /// Days between the first and last counted performance day.
  ///
  /// This is raw evidence for the future mastery decision. It is not a
  /// mastery claim and does not consider determinacy, timing, transfer, or a
  /// checkpoint.
  int get performanceSpanDays {
    if (performanceDays.length < 2) return 0;
    final days = performanceDays.toList()..sort();
    final first = _tryParseDay(firstPerformanceDay ?? days.first);
    final last = _tryParseDay(days.last);
    if (first == null || last == null) return 0;
    return last.difference(first).inDays;
  }

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
    contentVersion: contentVersion,
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
    'contentVersion': contentVersion,
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
      dueAt: _readDate(json['dueAt'], 'dueAt'),
      reps: _readInt(json, 'reps', 0),
      lapses: _readInt(json, 'lapses', 0),
      correct: _readInt(json, 'correct', 0),
      incorrect: _readInt(json, 'incorrect', 0),
      correctDays: _readDays(json['correctDays'], 'correctDays'),
      performanceDays: _readDays(json['performanceDays'], 'performanceDays'),
      firstPerformanceDay: _readDay(json['firstPerformanceDay']),
      lastPerformanceAt: _readDate(
        json['lastPerformanceAt'],
        'lastPerformanceAt',
      ),
      bestTempoBpm: _readOptionalInt(json['bestTempoBpm'], 'bestTempoBpm'),
      bestAccuracy: _readOptionalDouble(json['bestAccuracy'], 'bestAccuracy'),
      contentVersion: _readContentVersion(json),
    );
  }
}

String? _firstDay(Set<String> days) {
  if (days.isEmpty) return null;
  final sorted = days.toList()..sort();
  return sorted.first;
}

String _dayKey(DateTime time) =>
    '${time.year.toString().padLeft(4, '0')}-'
    '${time.month.toString().padLeft(2, '0')}-'
    '${time.day.toString().padLeft(2, '0')}';

String? _readDay(Object? value) {
  if (value == null) return null;
  if (value is! String || _tryParseDay(value) == null) {
    throw const FormatException(
      'phraseProgress.firstPerformanceDay must be a yyyy-MM-dd day',
    );
  }
  return value;
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

int _readContentVersion(Map<String, dynamic> json) {
  final value = _readInt(json, 'contentVersion', 1);
  if (value < 1) {
    throw const FormatException(
      'phraseProgress.contentVersion must be at least 1',
    );
  }
  return value;
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

DateTime? _readDate(Object? value, String key) {
  if (value == null) return null;
  if (value is! String || DateTime.tryParse(value) == null) {
    throw FormatException(
      'phraseProgress.$key must be an ISO-8601 date-time string',
    );
  }
  return DateTime.parse(value).toLocal();
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
