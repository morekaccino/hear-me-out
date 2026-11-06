import '../core/learning/note_objective.dart';
import '../core/learning/objective.dart';
import '../core/learning/phrase_objective.dart';
import '../core/learning/progress.dart';
import '../core/learning/skill.dart';
import 'objectives.dart';
import 'pieces/phrase_objectives.dart';

/// Resolves one scheduled skill back to the objective a session can render.
///
/// Note objectives are built on demand; phrase skills come from the runtime
/// phrase registry; every other family comes from the content catalog. This is
/// the single content-level owner of the mapping.
ObjectiveRef? objectiveRefForSkill(
  SkillProgress skill, {
  ProgressState? progress,
  PhraseObjectiveResolver? phraseResolver,
}) {
  final note = noteFromObjectiveId(skill.objectiveId);
  if (note != null) return noteObjective(note, stage: skill.box);

  if (skill.objectiveId.startsWith(phraseObjectivePrefix)) {
    final phraseId = phraseIdFromObjectiveId(skill.objectiveId);
    if (phraseId == null) return null;
    final practicedVersion = progress
        ?.phraseProgressFor(phraseId)
        ?.contentVersion;
    final resolved = (phraseResolver ?? phraseObjectiveResolver).resolvePhrase(
      phraseId,
      contentVersion: practicedVersion,
    );
    if (resolved == null) return null;
    // Preserve the stored skill id. A legacy `phrase:<phraseId>` skill must
    // keep scheduling under the same key, even when the resolver's canonical
    // id includes the piece id.
    return ObjectiveRef(
      skill.objectiveId,
      family: resolved.family,
      stage: skill.box,
      data: resolved.data,
    );
  }

  return objectiveCatalog[skill.objectiveId];
}
