import '../../core/learning/objective.dart';
import '../../core/music/rhythm.dart';

ObjectiveRef rhythmObjective(RhythmPattern pattern) => ObjectiveRef(
  'rhythm:${pattern.id}',
  family: SkillFamily.rhythm,
  data: {'pattern': pattern},
);

final Map<String, ObjectiveRef> rhythmObjectives = {
  for (final pattern in rhythmPatterns) 'rhythm:${pattern.id}': rhythmObjective(pattern),
};

RhythmPattern? patternOf(ObjectiveRef ref) =>
    ref.data['pattern'] as RhythmPattern?;
