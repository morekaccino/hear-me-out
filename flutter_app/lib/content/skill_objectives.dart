import '../core/learning/note_objective.dart';
import '../core/learning/objective.dart';
import '../core/learning/skill.dart';
import 'objectives.dart';

/// Resolves one scheduled skill back to the objective a session can render.
///
/// Note objectives are built on demand; every other family comes from the
/// content catalog. This is the single content-level owner of the mapping.
ObjectiveRef? objectiveRefForSkill(SkillProgress skill) {
  final note = noteFromObjectiveId(skill.objectiveId);
  if (note != null) return noteObjective(note, stage: skill.box);
  return objectiveCatalog[skill.objectiveId];
}
