import 'dart:math' as math;

import 'attempt_outcome.dart';
import 'objective.dart';

export 'attempt_outcome.dart';
export 'objective.dart' show SkillFamily;

extension SkillFamilySchedule on SkillFamily {
  String get label => switch (this) {
    SkillFamily.noteReading => 'Note reading',
    SkillFamily.fretboard => 'Fretboard',
    SkillFamily.rhythm => 'Rhythm',
    SkillFamily.ear => 'Ear training',
    SkillFamily.harmony => 'Harmony',
    SkillFamily.theory => 'Theory',
    SkillFamily.technique => 'Technique',
    SkillFamily.sightReading => 'Sight-reading',
    SkillFamily.repertoire => 'Repertoire',
    SkillFamily.improvisation => 'Improvisation',
  };

  bool get isPerformance => switch (this) {
    SkillFamily.noteReading ||
    SkillFamily.fretboard ||
    SkillFamily.rhythm ||
    SkillFamily.technique ||
    SkillFamily.sightReading ||
    SkillFamily.repertoire ||
    SkillFamily.improvisation => true,
    _ => false,
  };
}

/// The four ratings used by the scheduler.
enum ResponseRating {
  again(1),
  hard(2),
  good(3),
  easy(4);

  const ResponseRating(this.grade);

  final int grade;
}

/// What the learner did with one prompt. Used by the controller to build a
/// rating without letting the UI decide about scheduling.
class SkillAnswer {
  const SkillAnswer({
    required this.objectiveId,
    required this.family,
    required this.outcome,
    required this.now,
    this.responseMs = 0,
    this.usedHint = false,
    this.revealed = false,
    this.production = false,
    this.transfer = false,
    this.templateId,
    this.absCents,
  });

  final String objectiveId;
  final SkillFamily family;

  /// Tri-state verdict. [AttemptOutcome.indeterminate] is a retry signal and
  /// never reaches the scheduler.
  final AttemptOutcome outcome;
  final DateTime now;
  final int responseMs;
  final bool usedHint;
  final bool revealed;
  final bool production;
  final bool transfer;
  final String? templateId;
  final double? absCents;

  bool get correct => outcome == AttemptOutcome.correct;

  ResponseRating get rating {
    if (outcome != AttemptOutcome.correct || revealed) {
      return ResponseRating.again;
    }
    if (usedHint) return ResponseRating.hard;
    final target = defaultTargetMs(family);
    if (responseMs > target * 2.5) return ResponseRating.hard;
    if (responseMs > target * 1.3) return ResponseRating.hard;
    if (production && responseMs > 0 && responseMs < target * 0.6) {
      return ResponseRating.easy;
    }
    return ResponseRating.good;
  }
}

int defaultTargetMs(SkillFamily family) => switch (family) {
  SkillFamily.noteReading => 4000,
  SkillFamily.fretboard => 6000,
  SkillFamily.rhythm => 6000,
  SkillFamily.ear => 5000,
  SkillFamily.harmony => 6000,
  SkillFamily.theory => 5000,
  SkillFamily.technique => 8000,
  SkillFamily.sightReading => 12000,
  SkillFamily.repertoire => 15000,
  SkillFamily.improvisation => 12000,
};

/// The FSRS-6 scheduler, with default weights from the open-spaced-repetition
/// project. The weights are pinned so scheduling is deterministic and testable.
class FsrsScheduler {
  const FsrsScheduler({
    this.weights = defaultWeights,
    this.desiredRetention = 0.9,
  });

  static const List<double> defaultWeights = [
    0.212,
    1.2931,
    2.3065,
    8.2956,
    6.4133,
    0.8334,
    3.0194,
    0.001,
    1.8722,
    0.1666,
    0.796,
    1.4835,
    0.0614,
    0.2629,
    1.6483,
    0.6014,
    1.8729,
    0.5425,
    0.0912,
    0.0658,
    0.1542,
  ];

  final List<double> weights;
  final double desiredRetention;

  double get decay => weights[20];

  double get factor => math.pow(0.9, -1 / decay).toDouble() - 1;

  /// Probability of recall after [elapsedDays] for a skill with [stabilityDays].
  double retrievability(double stabilityDays, double elapsedDays) {
    if (stabilityDays <= 0) return 0;
    if (elapsedDays <= 0) return 1;
    return math
        .pow(1 + factor * elapsedDays / stabilityDays, -decay)
        .toDouble();
  }

  /// The interval that reaches [retention] for a given stability.
  double intervalDays(double stabilityDays, {double? retention}) {
    final target = retention ?? desiredRetention;
    return stabilityDays / factor * (math.pow(target, -1 / decay) - 1);
  }

  double initialStability(ResponseRating rating) => weights[rating.grade - 1];

  double initialDifficulty(ResponseRating rating) {
    final value = weights[4] - math.exp(weights[5] * (rating.grade - 1)) + 1;
    return value.clamp(1.0, 10.0);
  }

  double nextDifficulty(double difficulty, ResponseRating rating) {
    final delta = -weights[6] * (rating.grade - 3);
    final adjusted = difficulty + delta * (10 - difficulty) / 9;
    final targetDifficulty = initialDifficulty(ResponseRating.easy);
    final reverted = weights[7] * targetDifficulty + (1 - weights[7]) * adjusted;
    return reverted.clamp(1.0, 10.0);
  }

  double nextStabilityOnSuccess({
    required double stabilityDays,
    required double difficulty,
    required double retrievability,
    required ResponseRating rating,
  }) {
    final hardPenalty = rating == ResponseRating.hard ? weights[15] : 1.0;
    final easyBonus = rating == ResponseRating.easy ? weights[16] : 1.0;
    final increase =
        math.exp(weights[8]) *
        (11 - difficulty) *
        math.pow(stabilityDays, -weights[9]) *
        (math.exp((1 - retrievability) * weights[10]) - 1) *
        hardPenalty *
        easyBonus;
    final next = stabilityDays * (1 + increase);
    return next < stabilityDays ? stabilityDays : next;
  }

  double nextStabilityOnFailure({
    required double stabilityDays,
    required double difficulty,
    required double retrievability,
  }) {
    final next =
        weights[11] *
        math.pow(difficulty, -weights[12]) *
        (math.pow(stabilityDays + 1, weights[13]) - 1) *
        math.exp(weights[14] * (1 - retrievability));
    return math.max(0.1, next).toDouble();
  }

  double nextStabilitySameDay({
    required double stabilityDays,
    required ResponseRating rating,
  }) {
    final next =
        stabilityDays *
        math.exp(weights[17] * (rating.grade - 3 + weights[18])) *
        math.pow(stabilityDays, -weights[19]);
    return math.max(0.1, next).toDouble();
  }

  /// Applies one review and returns the new memory state.
  FsrsReviewResult review({
    required double stabilityDays,
    required double difficulty,
    required DateTime lastSeenAt,
    required DateTime now,
    required ResponseRating rating,
    required bool isFirstReview,
    required SkillFamily family,
  }) {
    if (isFirstReview) {
      final initialStability = this.initialStability(rating);
      final initialDifficulty = this.initialDifficulty(rating);
      return FsrsReviewResult(
        stabilityDays: _cap(initialStability, family),
        difficulty: initialDifficulty,
        dueAt: now.add(_durationFor(initialStability, family)),
      );
    }

    final elapsedDays = math.max(
      0.0,
      now.difference(lastSeenAt).inMinutes / (60 * 24),
    );
    final retrievabilityNow = retrievability(stabilityDays, elapsedDays);
    final newDifficulty = nextDifficulty(difficulty, rating);

    final newStability = rating == ResponseRating.again
        ? nextStabilityOnFailure(
            stabilityDays: stabilityDays,
            difficulty: newDifficulty,
            retrievability: retrievabilityNow,
          )
        : elapsedDays < 1
        ? nextStabilitySameDay(stabilityDays: stabilityDays, rating: rating)
        : nextStabilityOnSuccess(
            stabilityDays: stabilityDays,
            difficulty: newDifficulty,
            retrievability: retrievabilityNow,
            rating: rating,
          );

    final capped = _cap(newStability, family);
    return FsrsReviewResult(
      stabilityDays: capped,
      difficulty: newDifficulty,
      dueAt: now.add(_durationFor(capped, family, rating: rating)),
    );
  }

  double _cap(double stabilityDays, SkillFamily family) {
    final cap = family.isPerformance ? 30.0 : 180.0;
    return stabilityDays.clamp(0.1, cap);
  }

  Duration _durationFor(
    double stabilityDays,
    SkillFamily family, {
    ResponseRating rating = ResponseRating.good,
  }) {
    if (rating == ResponseRating.again) return const Duration(minutes: 10);
    final days = intervalDays(stabilityDays);
    final clamped = days.clamp(10 / (60 * 24), family.isPerformance ? 30.0 : 180.0);
    return Duration(
      milliseconds: (clamped * 24 * 60 * 60 * 1000).round(),
    );
  }
}

class FsrsReviewResult {
  const FsrsReviewResult({
    required this.stabilityDays,
    required this.difficulty,
    required this.dueAt,
  });

  final double stabilityDays;
  final double difficulty;
  final DateTime dueAt;
}

/// One objective's memory and performance state.
class SkillProgress {
  SkillProgress({
    required this.objectiveId,
    required this.family,
    this.stabilityDays = 0,
    this.difficulty = 5,
    this.dueAt,
    this.lastSeenAt,
    this.reps = 0,
    this.lapses = 0,
    this.correct = 0,
    this.incorrect = 0,
    Set<String>? correctDays,
    this.productionCorrect = 0,
    this.transferCorrect = 0,
    this.averageResponseMs = 0,
    this.level = 0,
    this.fragile = false,
    this.masteredAt,
    List<String>? recentTemplateIds,
    this.centsSamples = 0,
    this.centsTotal = 0,
    this.box = 0,
    this.streak = 0,
    this.bestStreak = 0,
  }) : correctDays = correctDays ?? <String>{},
       recentTemplateIds = recentTemplateIds ?? <String>[];

  final String objectiveId;
  final SkillFamily family;
  double stabilityDays;
  double difficulty;
  DateTime? dueAt;
  DateTime? lastSeenAt;
  int reps;
  int lapses;
  int correct;
  int incorrect;
  final Set<String> correctDays;
  int productionCorrect;
  int transferCorrect;
  double averageResponseMs;
  int level;
  bool fragile;
  DateTime? masteredAt;
  final List<String> recentTemplateIds;
  int centsSamples;
  double centsTotal;

  /// Legacy Leitner box, kept for the existing note chips and migration.
  int box;
  int streak;
  int bestStreak;

  int get attempts => correct + incorrect;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  double get averageAbsCents =>
      centsSamples == 0 ? 0 : centsTotal / centsSamples;

  bool get mastered =>
      stabilityDays >= 21 &&
      reps >= 4 &&
      correctDays.length >= 3 &&
      productionCorrect >= 1 &&
      transferCorrect >= 1;

  bool get isDue => dueAt != null && !dueAt!.isAfter(DateTime.now());

  double retrievabilityAt(DateTime now, FsrsScheduler scheduler) {
    if (stabilityDays <= 0 || lastSeenAt == null) return 0;
    final elapsed = math.max(
      0.0,
      now.difference(lastSeenAt!).inMinutes / (60 * 24),
    );
    return scheduler.retrievability(stabilityDays, elapsed);
  }

  void recordAnswer(
    SkillAnswer answer, {
    FsrsScheduler scheduler = const FsrsScheduler(),
    DateTime? nowOverride,
  }) {
    // An indeterminate attempt is a retry signal, not evidence. Leave every
    // field untouched, including the memory state and the evidence counters.
    if (answer.outcome == AttemptOutcome.indeterminate) return;

    final now = nowOverride ?? answer.now;
    final first = reps == 0;
    final result = scheduler.review(
      stabilityDays: stabilityDays <= 0 ? 1 : stabilityDays,
      difficulty: difficulty,
      lastSeenAt: lastSeenAt ?? now,
      now: now,
      rating: answer.rating,
      isFirstReview: first,
      family: family,
    );

    reps++;
    lastSeenAt = now;
    stabilityDays = result.stabilityDays;
    difficulty = result.difficulty;
    dueAt = result.dueAt;
    if (answer.rating == ResponseRating.again) {
      lapses++;
      streak = 0;
      box = math.max(0, box - 2);
    } else {
      streak++;
      bestStreak = math.max(bestStreak, streak);
      box = math.min(5, box + 1);
      correctDays.add(_dayKey(now));
    }

    if (answer.outcome == AttemptOutcome.correct) {
      correct++;
      if (answer.production) productionCorrect++;
      if (answer.transfer) transferCorrect++;
    } else {
      incorrect++;
    }

    if (answer.responseMs > 0) {
      averageResponseMs = averageResponseMs == 0
          ? answer.responseMs.toDouble()
          : averageResponseMs * 0.7 + answer.responseMs * 0.3;
    }

    if (answer.absCents != null && answer.absCents!.isFinite) {
      centsSamples++;
      centsTotal += answer.absCents!;
    }

    if (answer.templateId != null) {
      recentTemplateIds.add(answer.templateId!);
      if (recentTemplateIds.length > 8) {
        recentTemplateIds.removeAt(0);
      }
    }

    fragile = lapses >= 2 || (attempts >= 4 && accuracy < 0.6);
    if (mastered) {
      masteredAt ??= now;
    } else {
      masteredAt = null;
    }

    // Adaptive difficulty: three clean successes at the current level raise it;
    // a lapse lowers it.
    if (answer.outcome == AttemptOutcome.correct &&
        streak > 0 &&
        streak % 3 == 0 &&
        level < 3) {
      level++;
    } else if (answer.outcome != AttemptOutcome.correct && level > 0) {
      level--;
    }
  }

  SkillProgress copy() => SkillProgress(
    objectiveId: objectiveId,
    family: family,
    stabilityDays: stabilityDays,
    difficulty: difficulty,
    dueAt: dueAt,
    lastSeenAt: lastSeenAt,
    reps: reps,
    lapses: lapses,
    correct: correct,
    incorrect: incorrect,
    correctDays: {...correctDays},
    productionCorrect: productionCorrect,
    transferCorrect: transferCorrect,
    averageResponseMs: averageResponseMs,
    level: level,
    fragile: fragile,
    masteredAt: masteredAt,
    recentTemplateIds: [...recentTemplateIds],
    centsSamples: centsSamples,
    centsTotal: centsTotal,
    box: box,
    streak: streak,
    bestStreak: bestStreak,
  );

  Map<String, dynamic> toJson() => {
    'objectiveId': objectiveId,
    'family': family.name,
    'stabilityDays': stabilityDays,
    'difficulty': difficulty,
    'dueAt': dueAt?.toIso8601String(),
    'lastSeenAt': lastSeenAt?.toIso8601String(),
    'reps': reps,
    'lapses': lapses,
    'correct': correct,
    'incorrect': incorrect,
    'correctDays': correctDays.toList(),
    'productionCorrect': productionCorrect,
    'transferCorrect': transferCorrect,
    'averageResponseMs': averageResponseMs,
    'level': level,
    'fragile': fragile,
    'masteredAt': masteredAt?.toIso8601String(),
    'recentTemplateIds': recentTemplateIds,
    'centsSamples': centsSamples,
    'centsTotal': centsTotal,
    'box': box,
    'streak': streak,
    'bestStreak': bestStreak,
  };

  factory SkillProgress.fromJson(Map<String, dynamic> json) {
    final familyName = json['family'] as String? ?? SkillFamily.theory.name;
    final family = SkillFamily.values.firstWhere(
      (value) => value.name == familyName,
      orElse: () => SkillFamily.theory,
    );
    return SkillProgress(
      objectiveId: json['objectiveId'] as String? ?? '',
      family: family,
      stabilityDays: (json['stabilityDays'] as num?)?.toDouble() ?? 0,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 5,
      dueAt: _parseDate(json['dueAt']),
      lastSeenAt: _parseDate(json['lastSeenAt']),
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      lapses: (json['lapses'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      incorrect: (json['incorrect'] as num?)?.toInt() ?? 0,
      correctDays: {
        for (final day in (json['correctDays'] as List<dynamic>? ?? const []))
          if (day is String) day,
      },
      productionCorrect: (json['productionCorrect'] as num?)?.toInt() ?? 0,
      transferCorrect: (json['transferCorrect'] as num?)?.toInt() ?? 0,
      averageResponseMs: (json['averageResponseMs'] as num?)?.toDouble() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 0,
      fragile: json['fragile'] as bool? ?? false,
      masteredAt: _parseDate(json['masteredAt']),
      recentTemplateIds: [
        for (final id
            in (json['recentTemplateIds'] as List<dynamic>? ?? const []))
          if (id is String) id,
      ],
      centsSamples: (json['centsSamples'] as num?)?.toInt() ?? 0,
      centsTotal: (json['centsTotal'] as num?)?.toDouble() ?? 0,
      box: (json['box'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
    );
  }
}

String _dayKey(DateTime time) =>
    '${time.year.toString().padLeft(4, '0')}-'
    '${time.month.toString().padLeft(2, '0')}-'
    '${time.day.toString().padLeft(2, '0')}';

DateTime? _parseDate(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
