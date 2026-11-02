import '../core/learning/course/course_data.dart';
import '../core/learning/objective.dart';
import 'rhythm/objectives.dart';
import 'theory/objectives.dart';

/// Every non-note objective a lesson can name by id.
///
/// Note objectives are created on demand from the curriculum, so they are not
/// in this catalog. Course concepts are included here so generated lessons can
/// resolve their `teaches` and `reviews` ids.
final Map<String, ObjectiveRef> objectiveCatalog = {
  for (final section in courseSections)
    for (final unit in section.units)
      for (final concept in unit.concepts) concept.id: concept,
  for (final objective in [
    ...theoryObjectives,
    ...harmonyObjectives,
    ...rhythmObjectives.values,
  ])
    objective.id: objective,
};
