import 'note.dart';

class LessonDefinition {
  const LessonDefinition({
    required this.id,
    required this.unitId,
    required this.title,
    required this.newNotes,
    required this.reviewNotes,
    this.teaches = const <String>[],
    this.reviews = const <String>[],
    this.exposures = 4,
    this.isReview = false,
    this.exerciseCount,
    this.guidebookId,
  });

  final String id;
  final String unitId;
  final String title;

  /// Notes introduced by this lesson. At most two.
  final List<Note> newNotes;

  /// Notes that may appear as review material.
  final List<Note> reviewNotes;

  /// Non-note objectives introduced by this lesson, by catalog id.
  final List<String> teaches;

  /// Non-note objectives that may appear as review material, by catalog id.
  final List<String> reviews;

  /// Teaching exposures per new objective.
  final int exposures;

  /// A checkpoint lesson at the end of a unit.
  final bool isReview;

  /// Optional override for the number of exercises in this lesson.
  final int? exerciseCount;

  /// Optional guidebook id for the unit.
  final String? guidebookId;
}

class UnitDefinition {
  const UnitDefinition({
    required this.id,
    required this.number,
    required this.title,
    required this.focus,
    required this.lessons,
  });

  final String id;
  final int number;
  final String title;

  /// The unit's single learning focus, shown on the path.
  final String focus;

  final List<LessonDefinition> lessons;

  List<Note> get newNotes => _uniqueNotes([
    for (final lesson in lessons) ...lesson.newNotes,
  ]);

  bool get hasNewNotes => newNotes.isNotEmpty;
}

class SectionDefinition {
  const SectionDefinition({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.units,
  });

  final String id;
  final int number;
  final String title;
  final String subtitle;
  final List<UnitDefinition> units;
}

/// A chest sits on the path after [afterLessonId] and unlocks with it.
class ChestDefinition {
  const ChestDefinition({
    required this.id,
    required this.unitId,
    required this.afterLessonId,
    required this.gems,
  });

  final String id;
  final String unitId;
  final String afterLessonId;
  final int gems;
}

List<Note> _uniqueNotes(List<Note> notes) {
  final seen = <String>{};
  return [
    for (final note in notes)
      if (seen.add(note.id)) note,
  ];
}
