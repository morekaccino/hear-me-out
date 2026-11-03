import '../../music/curriculum_model.dart';
import '../../music/note.dart';
import '../note_objective.dart';
import '../objective.dart';
import 'course_data.dart';
import 'course_spec.dart';

/// Expands the 40 unit specs into the 240-lesson course the rest of the app
/// consumes. Each unit always gets six lessons: Discover, Build, Connect,
/// Apply, Integrate, Checkpoint.
List<SectionDefinition> buildCourseSections() {
  final unitsByNumber = <int, CourseUnit>{
    for (final section in courseSections)
      for (final unit in section.units) unit.number: unit,
  };

  return [
    for (final section in courseSections)
      SectionDefinition(
        id: section.id,
        number: section.number,
        title: section.title,
        subtitle: section.subtitle,
        units: [
          for (final unit in section.units)
            UnitDefinition(
              id: unit.id,
              number: unit.number,
              title: unit.title,
              focus: unit.focus,
              lessons: _lessonsFor(unit, unitsByNumber),
            ),
        ],
      ),
  ];
}

List<ChestDefinition> buildCourseChests() => [
  for (final section in courseSections)
    for (final unit in section.units)
      ChestDefinition(
        id: '${unit.id}c1',
        unitId: unit.id,
        afterLessonId: '${unit.id}l3',
        gems: 20 + unit.number * 3,
      ),
];

List<LessonDefinition> _lessonsFor(
  CourseUnit unit,
  Map<int, CourseUnit> unitsByNumber,
) {
  final concepts = unit.concepts;
  final groupOne = concepts.take(2).toList();
  final groupTwo = concepts.skip(2).take(2).toList();
  final extra = concepts.skip(4).toList();

  final prior = <ObjectiveRef>[];
  final reviewNumbers = unit.reviewUnits.isEmpty
      ? _previousUnits(unit.number)
      : unit.reviewUnits;
  for (final number in reviewNumbers) {
    final priorUnit = unitsByNumber[number];
    if (priorUnit == null) continue;
    prior.addAll(priorUnit.concepts);
  }

  final lessons = <LessonDefinition>[];

  lessons.add(
    _lesson(
      id: '${unit.id}l1',
      unitId: unit.id,
      title: 'Discover',
      newConcepts: groupOne,
      reviewConcepts: prior,
      exposures: 5,
      exerciseCount: 16,
    ),
  );
  lessons.add(
    _lesson(
      id: '${unit.id}l2',
      unitId: unit.id,
      title: 'Build',
      newConcepts: const [],
      reviewConcepts: [...concepts, ...prior],
      exposures: 5,
      exerciseCount: 16,
    ),
  );
  lessons.add(
    _lesson(
      id: '${unit.id}l3',
      unitId: unit.id,
      title: 'Connect',
      newConcepts: groupTwo,
      reviewConcepts: [...groupOne, ...prior],
      exposures: 5,
      exerciseCount: 16,
    ),
  );
  lessons.add(
    _lesson(
      id: '${unit.id}l4',
      unitId: unit.id,
      title: 'Apply',
      newConcepts: const [],
      reviewConcepts: [...concepts, ...prior],
      exposures: 5,
      exerciseCount: 16,
    ),
  );
  lessons.add(
    _lesson(
      id: '${unit.id}l5',
      unitId: unit.id,
      title: 'Integrate',
      newConcepts: extra,
      reviewConcepts: [...concepts, ...prior],
      exposures: 5,
      exerciseCount: 16,
    ),
  );
  lessons.add(
    _lesson(
      id: '${unit.id}l6',
      unitId: unit.id,
      title: 'Checkpoint',
      newConcepts: const [],
      reviewConcepts: [...concepts, ...prior],
      isReview: true,
      exposures: 5,
      exerciseCount: unit.checkpointSize,
    ),
  );

  return lessons;
}

LessonDefinition _lesson({
  required String id,
  required String unitId,
  required String title,
  required List<ObjectiveRef> newConcepts,
  required List<ObjectiveRef> reviewConcepts,
  required int exposures,
  required int exerciseCount,
  bool isReview = false,
}) {
  final uniqueNew = _unique(newConcepts);
  final uniqueReview = _unique(reviewConcepts)
      .where(
        (ref) => !uniqueNew.any((candidate) => candidate.id == ref.id),
      )
      .toList();
  // A checkpoint should not ask one objective five times. Cap it at two
  // exposures per distinct objective, with the usual 8-item floor.
  final distinct = uniqueNew.length + uniqueReview.length;
  final effectiveCount = isReview
      ? (distinct * 2).clamp(8, exerciseCount)
      : exerciseCount;
  final newNotes = <Note>[
    for (final ref in uniqueNew)
      if (ref.family == SkillFamily.noteReading && noteOf(ref) != null)
        noteOf(ref)!,
  ];
  final reviewNotes = <Note>[
    for (final ref in uniqueReview)
      if (ref.family == SkillFamily.noteReading && noteOf(ref) != null)
        noteOf(ref)!,
  ];
  return LessonDefinition(
    id: id,
    unitId: unitId,
    title: title,
    newNotes: newNotes,
    reviewNotes: reviewNotes,
    teaches: [
      for (final ref in uniqueNew)
        if (ref.family != SkillFamily.noteReading) ref.id,
    ],
    reviews: [
      for (final ref in uniqueReview)
        if (ref.family != SkillFamily.noteReading) ref.id,
    ],
    exposures: exposures,
    isReview: isReview,
    exerciseCount: effectiveCount,
    guidebookId: unitId,
  );
}

List<ObjectiveRef> _unique(List<ObjectiveRef> refs) {
  final seen = <String>{};
  return [
    for (final ref in refs)
      if (seen.add(ref.id)) ref,
  ];
}

List<int> _previousUnits(int number) => [
  for (var candidate = number - 1; candidate >= 1 && candidate >= number - 3; candidate--)
    candidate,
];
