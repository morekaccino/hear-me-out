import 'dart:math';

import '../core/learning/note_objective.dart';
import '../core/learning/objective.dart';
import '../core/learning/practice_session.dart';
import '../core/learning/progress.dart';
import '../core/learning/skill.dart';
import '../core/music/curriculum.dart';
import '../core/music/note.dart';
import 'skill_objectives.dart';

/// Chooses the one target and builds the plan for a Today practice session.
///
/// The selection is deterministic for a given [ProgressState], [now], and
/// [random] seed. Due skills come first, then weak and fragile skills, then the
/// most recently learned skill. A learner with no history gets the first note
/// in the course. A maintenance block is added only when a previously learned
/// skill exists and is not the session target.
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
    isMaintenanceDay: isMaintenanceDay && maintenanceTarget != null,
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
    final ref = objectiveRefForSkill(skill);
    if (ref != null) return ref;
  }

  final learned =
      progress.skills.values.where((skill) => skill.attempts > 0).toList()
        ..sort((a, b) {
          final aTime = a.lastSeenAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.lastSeenAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final byTime = bTime.compareTo(aTime);
          return byTime != 0 ? byTime : a.objectiveId.compareTo(b.objectiveId);
        });
  for (final skill in learned) {
    final ref = objectiveRefForSkill(skill);
    if (ref != null) return ref;
  }

  for (final lesson in allLessons) {
    if (!progress.completedLessons.contains(lesson.id) &&
        lesson.newNotes.isNotEmpty) {
      return noteObjective(lesson.newNotes.first);
    }
  }
  for (final lesson in allLessons) {
    if (lesson.newNotes.isNotEmpty) return noteObjective(lesson.newNotes.first);
  }
  return noteObjective(noteCatalog.first);
}

ObjectiveRef? _chooseMaintenanceTarget(
  ProgressState progress,
  ObjectiveRef target,
  Random random,
) {
  final candidates = <ObjectiveRef>[];
  for (final skill in progress.skills.values) {
    if (skill.attempts == 0 || skill.objectiveId == target.id) continue;
    final ref = objectiveRefForSkill(skill);
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

  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => a.id.compareTo(b.id));
  return candidates[random.nextInt(candidates.length)];
}
