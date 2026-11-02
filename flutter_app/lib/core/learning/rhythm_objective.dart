import '../music/rhythm.dart';
import 'objective.dart';

ObjectiveRef rhythmObjective(RhythmPattern pattern) => ObjectiveRef(
  'rhythm:${pattern.id}',
  family: SkillFamily.rhythm,
  data: {'pattern': pattern},
);

RhythmPattern? patternOf(ObjectiveRef ref) =>
    ref.data['pattern'] as RhythmPattern?;
