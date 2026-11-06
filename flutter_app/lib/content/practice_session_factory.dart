import 'dart:math';

import '../core/learning/note_objective.dart';
import '../core/learning/objective.dart';
import '../core/learning/practice_session.dart';
import '../core/learning/progress.dart';
import '../core/learning/skill.dart';
import '../core/music/curriculum.dart';
import '../core/music/note.dart';
import 'objectives.dart';

/// Chooses the one target and builds the plan for a Today practice session.
///
/// The selection is deterministic for a given [ProgressState], [now], and
/// [random] seed. Due skills come first, then weak and fragile skills. If the
/// learner has no attempts yet, the first note in the course becomes the
/// target. A maintenance block prefers a previously learned skill that is not
/// the session target.
PracticeSession buildPracticeSession({
  required ProgressState progress,
  required DateTime now,
  PracticeSessionLength length = PracticeSessionLength.five,
  bool isMaintenanceDay = false,
  Random? random,
}) {
  final rng = random ?? Random(now.millisecondsSinceEpoch);
  final target = _chooseTarget(progress, now);
  final maintenanceTarget = _chooseMaintenanceTarget(progress, target, rng);

  return PracticeSession(
    target: target,
    length: length,
    isMaintenanceDay: isMaintenanceDay,
    maintenanceTarget: maintenanceTarget,
  );
}

ObjectiveRef _chooseTarget(ProgressState progress, DateTime now) {
  final ranked = <String, SkillProgress>{};
  for (final skill in [
    ...progress.dueSkills(now),
    ...progress.weakSkills(),
    ...progress.fragileSkills(),
  ]) {
    ranked.putIfAbsent(skill.objectiveId, () => skill);
  }

  for (final skill in ranked.values) {
    final ref = _refForSkill(skill);
    if (ref != null) return ref;
  }

  for (final lesson in allLessons) {
    if (lesson.newNotes.isNotEmpty) return noteObjective(lesson.newNotes.first);
  }
  return noteObjective(noteCatalog.first);
}

ObjectiveRef? _refForSkill(SkillProgress skill) {
  if (skill.objectiveId.startsWith('note:')) {
    final note = Note.tryParse(skill.objectiveId.substring(5));
    if (note != null) return noteObjective(note, stage: skill.box);
    return null;
  }
  return objectiveCatalog[skill.objectiveId];
}

ObjectiveRef _chooseMaintenanceTarget(
  ProgressState progress,
  ObjectiveRef target,
  Random random,
) {
  final candidates = <ObjectiveRef>[];
  for (final skill in progress.skills.values) {
    if (skill.attempts == 0 || skill.objectiveId == target.id) continue;
    final ref = _refForSkill(skill);
    if (ref != null) candidates.add(ref);
  }

  if (candidates.isEmpty) {
    for (final entry in progress.notes.entries) {
      if (entry.value.attempts == 0) continue;
      final note = Note.tryParse(entry.key);
      if (note == null) continue;
      final ref = noteObjective(note);
      if (ref.id == target.id) continue;
      candidates.add(ref);
    }
  }

  if (candidates.isEmpty) return target;
  candidates.sort((a, b) => a.id.compareTo(b.id));
  return candidates[random.nextInt(candidates.length)];
}
