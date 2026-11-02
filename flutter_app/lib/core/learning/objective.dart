/// The kind of skill an objective trains.
///
/// The session engine reasons about families and roles only. It never imports a
/// note, a staff, or an audio detector, which is what lets a new topic plug in
/// without touching the composer.
enum SkillFamily {
  noteReading,
  rhythm,
  ear,
  fretboard,
  harmony,
  theory,
  technique,
  sightReading,
  repertoire,
  improvisation,
}

/// A pointer to one teachable unit, plus the data a template needs to render it.
///
/// Two refs are equal when they name the same objective, even if their payloads
/// differ. That equality is what lets the composer space repeats of one idea
/// apart from each other.
class ObjectiveRef {
  const ObjectiveRef(
    this.id, {
    required this.family,
    this.stage = 0,
    this.data = const <String, Object?>{},
  });

  final String id;
  final SkillFamily family;

  /// How far the learner has come with this objective: 0 is brand new, higher
  /// means more mastery. Families assign their own meaning to it.
  final int stage;

  final Map<String, Object?> data;

  @override
  bool operator ==(Object other) => other is ObjectiveRef && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}
