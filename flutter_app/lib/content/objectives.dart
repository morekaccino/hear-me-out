import '../core/learning/objective.dart';
import 'rhythm/objectives.dart';
import 'theory/objectives.dart';

/// Every non-note objective a lesson can name by id.
///
/// Note objectives are created on demand from the curriculum, so they are not
/// in this catalog.
final Map<String, ObjectiveRef> objectiveCatalog = {
  for (final objective in [
    ...theoryObjectives,
    ...harmonyObjectives,
    ...rhythmObjectives.values,
  ])
    objective.id: objective,
};
