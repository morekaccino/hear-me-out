import 'dart:math' as math;

/// What a slot in a session is for.
enum SlotRole {
  /// Explain a new idea. Never scored.
  teach,

  /// First attempt at a new idea, with a smaller answer set.
  guided,

  /// Independent practice of a new idea.
  apply,

  /// Spaced review of something learned earlier.
  review,
}

/// The teaching arc of one session: how many slots it has and how many ideas it
/// introduces.
///
/// Notes need four exposures to stick; a rhythm pattern needs fewer, so
/// [exposures] is a parameter rather than a constant.
class SessionShape {
  const SessionShape({
    required this.total,
    required this.newObjectives,
    this.exposures = 4,
  });

  final int total;
  final int newObjectives;
  final int exposures;

  /// Slots left for review once the new objectives have taken theirs.
  int get reviewSlots => total - math.min(total, newObjectives * exposures);

  factory SessionShape.standard({
    required int total,
    required int newObjectives,
    int exposures = 4,
  }) {
    return SessionShape(
      total: total,
      newObjectives: newObjectives,
      exposures: exposures,
    );
  }

  /// The role of a new objective's [occurrence]th exposure.
  static SlotRole roleForOccurrence(int occurrence) {
    return switch (occurrence) {
      0 => SlotRole.teach,
      1 => SlotRole.guided,
      _ => SlotRole.apply,
    };
  }
}
