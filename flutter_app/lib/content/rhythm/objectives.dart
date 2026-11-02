import '../../core/learning/objective.dart';
import '../../core/learning/rhythm_objective.dart';
import '../../core/music/rhythm.dart';

export '../../core/learning/rhythm_objective.dart';

final Map<String, ObjectiveRef> rhythmObjectives = {
  for (final pattern in rhythmPatterns)
    'rhythm:${pattern.id}': rhythmObjective(pattern),
};
