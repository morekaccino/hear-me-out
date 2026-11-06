import 'onboarding_choices.dart';

/// The stages V1 content can actually place a learner into.
///
/// Stage 12 is a performance checkpoint and 11 is an exam-style Phase 2 task,
/// so neither is a placement target. Stages 4, 6, 7, and 8 are Phase 2 or
/// self/teacher-reviewed and are mapped to the nearest V1 stage.
const List<int> placementStages = <int>[1, 2, 3, 5, 9, 10];

/// Stages that exist in the plan but not as V1 placement targets.
const Set<int> placementPhase2Stages = <int>{4, 6, 7, 8};

/// A placement result is a starting point, not a diagnosis. Re-check every
/// four to six weeks; five weeks sits inside that window.
const Duration placementRetestInterval = Duration(days: 35);

/// A dismissed re-test prompt is snoozed for two weeks. Nothing is forced.
const Duration placementRetestSnooze = Duration(days: 14);

/// The three reading checks are enough to nudge the inferred stage. They are
/// not a scored test and never touch the learner's skill schedule.
const int placementReadingChecks = 3;

/// The stage a learner would get before the mapping to a V1 stage.
int inferPlacementStage({
  required ReadingLevel? readingLevel,
  int readingCorrect = 0,
  int readingTotal = placementReadingChecks,
  bool playedTarget = false,
  bool playedOther = false,
  int techniqueYes = 0,
}) {
  final base = switch (readingLevel) {
    ReadingLevel.noteNames => 1,
    ReadingLevel.slowReader => 2,
    ReadingLevel.comfortable => 5,
    null => 2,
  };
  var score = base;
  if (readingTotal > 0) {
    if (readingCorrect >= readingTotal) {
      score += 2;
    } else if (readingCorrect >= 2) {
      score += 1;
    }
  }
  if (playedTarget) {
    score += 2;
  } else if (playedOther) {
    score += 1;
  }
  if (techniqueYes >= 3) {
    score += 1;
  }
  return score.clamp(1, 10);
}

/// The nearest V1 stage for [inferredStage].
///
/// A tie goes to the lower stage: a slightly easier start is easier to correct
/// than an over-placement. Stages 6-8 land on 5 or 9 as the plan requires.
int resolvePlacementStage(int inferredStage) {
  var nearest = placementStages.first;
  var nearestDistance = (nearest - inferredStage).abs();
  for (final stage in placementStages.skip(1)) {
    final distance = (stage - inferredStage).abs();
    if (distance < nearestDistance ||
        (distance == nearestDistance && stage < nearest)) {
      nearest = stage;
      nearestDistance = distance;
    }
  }
  return nearest;
}

/// The Phase 2 stage the check pointed at, when [inferredStage] is not a V1
/// placement target. Null when the inferred stage is already placeable.
int? phase2StageFor(int inferredStage) {
  return placementPhase2Stages.contains(inferredStage) ? inferredStage : null;
}

/// One persisted placement result.
///
/// It is deliberately separate from `ProgressState`: saving a placement must
/// never reset completed lessons, note boxes, XP, minutes, streak, or phrase
/// evidence. The store owns the version and validates this shape.
class PlacementRecord {
  const PlacementRecord({
    required this.stage,
    required this.inferredStage,
    required this.starterPieceIds,
    required this.savedAt,
    required this.nextRetestAt,
    this.phase2Stage,
    this.manualOverride = false,
    this.retestDismissedAt,
  });

  /// The V1 stage the learner starts at. Always one of [placementStages].
  final int stage;

  /// The raw stage the short check pointed at, before V1 mapping.
  final int inferredStage;

  /// The Phase 2 stage that was skipped during mapping, if any.
  final int? phase2Stage;

  /// Three ids from the real launch-piece list.
  final List<String> starterPieceIds;

  final DateTime savedAt;
  final DateTime nextRetestAt;

  /// True when the learner chose the stage instead of accepting the check.
  final bool manualOverride;

  /// When the learner last dismissed the re-test prompt.
  final DateTime? retestDismissedAt;

  bool get hasPhase2Gap => phase2Stage != null;

  bool retestDue(DateTime now) => !now.isBefore(nextRetestAt);

  PlacementRecord copyWith({
    int? stage,
    int? inferredStage,
    int? phase2Stage,
    bool clearPhase2Stage = false,
    List<String>? starterPieceIds,
    DateTime? savedAt,
    DateTime? nextRetestAt,
    bool? manualOverride,
    DateTime? retestDismissedAt,
  }) {
    return PlacementRecord(
      stage: stage ?? this.stage,
      inferredStage: inferredStage ?? this.inferredStage,
      phase2Stage: clearPhase2Stage ? null : (phase2Stage ?? this.phase2Stage),
      starterPieceIds: starterPieceIds ?? this.starterPieceIds,
      savedAt: savedAt ?? this.savedAt,
      nextRetestAt: nextRetestAt ?? this.nextRetestAt,
      manualOverride: manualOverride ?? this.manualOverride,
      retestDismissedAt: retestDismissedAt ?? this.retestDismissedAt,
    );
  }

  /// Snoozes the neutral re-test prompt without changing the placement.
  PlacementRecord dismissRetest(DateTime now) {
    return copyWith(
      nextRetestAt: now.add(placementRetestSnooze),
      retestDismissedAt: now,
    );
  }

  Map<String, dynamic> toJson() => {
    'stage': stage,
    'inferredStage': inferredStage,
    'phase2Stage': phase2Stage,
    'starterPieceIds': starterPieceIds,
    'savedAt': savedAt.toIso8601String(),
    'nextRetestAt': nextRetestAt.toIso8601String(),
    'manualOverride': manualOverride,
    'retestDismissedAt': retestDismissedAt?.toIso8601String(),
  };

  factory PlacementRecord.fromJson(Map<String, dynamic> json) {
    final stage = (json['stage'] as num?)?.toInt();
    if (stage == null || !placementStages.contains(stage)) {
      throw const FormatException('placement stage must be a V1 stage');
    }

    final inferredStage = (json['inferredStage'] as num?)?.toInt();
    if (inferredStage == null || inferredStage < 1 || inferredStage > 10) {
      throw const FormatException('inferredStage must be between 1 and 10');
    }

    final phase2Value = json['phase2Stage'];
    int? phase2Stage;
    if (phase2Value != null) {
      if (phase2Value is! num) {
        throw const FormatException('phase2Stage must be a number');
      }
      phase2Stage = phase2Value.toInt();
      if (!placementPhase2Stages.contains(phase2Stage)) {
        throw const FormatException('phase2Stage must be a Phase 2 stage');
      }
    }

    final starterValue = json['starterPieceIds'];
    if (starterValue is! List || starterValue.length != 3) {
      throw const FormatException('starterPieceIds must contain three pieces');
    }
    final starterPieceIds = <String>[];
    for (final id in starterValue) {
      if (id is! String || id.isEmpty) {
        throw const FormatException('starter piece ids must be strings');
      }
      starterPieceIds.add(id);
    }

    final savedAt = _parseDate(json['savedAt'], 'savedAt');
    final nextRetestAt = _parseDate(json['nextRetestAt'], 'nextRetestAt');
    if (nextRetestAt.isBefore(savedAt)) {
      throw const FormatException('nextRetestAt must not precede savedAt');
    }

    final manualValue = json['manualOverride'];
    if (manualValue != null && manualValue is! bool) {
      throw const FormatException('manualOverride must be a boolean');
    }

    final dismissedAt = json['retestDismissedAt'] == null
        ? null
        : _parseDate(json['retestDismissedAt'], 'retestDismissedAt');

    return PlacementRecord(
      stage: stage,
      inferredStage: inferredStage,
      phase2Stage: phase2Stage,
      starterPieceIds: List<String>.unmodifiable(starterPieceIds),
      savedAt: savedAt,
      nextRetestAt: nextRetestAt,
      manualOverride: manualValue as bool? ?? false,
      retestDismissedAt: dismissedAt,
    );
  }
}

DateTime _parseDate(Object? value, String field) {
  if (value is! String) {
    throw FormatException('$field must be an ISO date string');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$field must be an ISO date string');
  }
  return parsed.toLocal();
}
