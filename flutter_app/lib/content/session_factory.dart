import 'dart:math';

import '../core/learning/composer.dart';
import '../core/learning/lesson_run.dart';
import '../core/learning/objective.dart';
import '../core/learning/progress.dart';
import '../core/learning/prompt.dart';
import '../core/learning/session_shape.dart';
import '../core/learning/skill.dart';
import '../core/learning/template.dart';
import '../core/music/curriculum.dart';
import '../core/music/note.dart';
import 'note_reading/objectives.dart';
import 'objectives.dart';
import 'packs.dart';
import 'skill_objectives.dart';

/// Builds the prompts for one curriculum lesson.
///
/// This is the composition root: it decides which objectives are new, which are
/// worth reviewing, then hands the arc to [SessionComposer]. A new topic adds
/// objectives to the catalog and templates to the pack, not code here.
List<Prompt> buildLessonSession({
  required LessonDefinition lesson,
  required ProgressState progress,
  required DateTime now,
  required bool micAvailable,
  AnswerMode mode = AnswerMode.mixed,
  Random? random,
}) {
  final rng = random ?? Random(now.millisecondsSinceEpoch);
  final baseCount =
      lesson.exerciseCount ??
      (lesson.isReview ? reviewExercisesPerLesson : exercisesPerLesson);

  // A note is still "new" until it has reached box 2. Exiting early or getting
  // one wrong answer must not rob it of its teaching exposures.
  final freshNotes = lesson.newNotes
      .where((note) => (progress.progressFor(note)?.box ?? 0) < 2)
      .take(2)
      .toList();
  final freshIds = freshNotes.map((note) => note.id).toSet();

  final newRefs = <ObjectiveRef>[
    for (final note in freshNotes)
      noteObjective(note, stage: progress.progressFor(note)?.box ?? 0),
    for (final id in lesson.teaches)
      if (objectiveCatalog[id] != null) objectiveCatalog[id]!,
  ];

  final reviewRefs = <ObjectiveRef>[
    for (final note in _reviewPool(lesson, progress, now, freshIds))
      noteObjective(note, stage: progress.progressFor(note)?.box ?? 0),
    for (final id in lesson.reviews)
      if (objectiveCatalog[id] != null) objectiveCatalog[id]!,
  ];

  // Review slots may revisit what the lesson teaches, but only when there is
  // not enough older material to fill them without repeating one question.
  final pool = <ObjectiveRef>[...reviewRefs];
  if (pool.length < 2) {
    for (final ref in newRefs) {
      if (!pool.any((existing) => existing.id == ref.id)) pool.add(ref);
    }
  }

  final effectivePool = pool.isNotEmpty
      ? pool
      : [for (final note in noteCatalog) noteObjective(note)];

  // A lesson with only two notes cannot fill twelve slots without asking the
  // same note six times. Cap the session at what the material can carry: each
  // distinct objective appears at most [lesson.exposures] times.
  final distinct = <String>{
    for (final ref in newRefs) ref.id,
    for (final ref in effectivePool) ref.id,
  }.length;
  // New material gets the full five-exposure arc. A review-only lesson should
  // not drill one objective five times, so it is capped at two exposures.
  final maxPerObjective = newRefs.isEmpty ? 2 : lesson.exposures;
  final budget = distinct * maxPerObjective;
  final total = budget < baseCount ? (budget < 8 ? 8 : budget) : baseCount;

  final shape = SessionShape.standard(
    total: total,
    newObjectives: newRefs.length,
    exposures: lesson.exposures,
  );

  return const SessionComposer(appContentPack).compose(
    shape: shape,
    newObjectives: newRefs,
    reviewPool: effectivePool,
    mode: mode,
    capabilities: _capabilities(micAvailable),
    random: rng,
  );
}

List<Prompt> buildPracticeExercises({
  required String kind,
  required ProgressState progress,
  required DateTime now,
  required bool micAvailable,
  AnswerMode mode = AnswerMode.mixed,
  Random? random,
}) {
  final rng = random ?? Random(now.millisecondsSinceEpoch);
  final pool = _practicePool(kind, progress, now);
  final shape = SessionShape.standard(
    total: exercisesPerLesson,
    newObjectives: 0,
  );

  return const SessionComposer(appContentPack).compose(
    shape: shape,
    newObjectives: const [],
    reviewPool: [
      for (final note in pool)
        noteObjective(note, stage: progress.progressFor(note)?.box ?? 0),
    ],
    mode: mode,
    capabilities: _capabilities(micAvailable),
    random: rng,
  );
}

/// Practice across every skill family, not just notes. This is the review
/// engine that makes a year-long course possible: theory, ear, rhythm, chords,
/// and technique all come back when they are due.
List<Prompt> buildSkillPracticeExercises({
  required String kind,
  required ProgressState progress,
  required DateTime now,
  required bool micAvailable,
  AnswerMode mode = AnswerMode.mixed,
  int total = exercisesPerLesson,
  Random? random,
}) {
  final rng = random ?? Random(now.millisecondsSinceEpoch);
  final skills = _skillPool(kind, progress, now);
  final refs = _refsForSkills(skills);
  if (refs.isEmpty) {
    return buildPracticeExercises(
      kind: kind,
      progress: progress,
      now: now,
      micAvailable: micAvailable,
      mode: mode,
      random: rng,
    );
  }

  final shape = SessionShape.standard(total: total, newObjectives: 0);
  return const SessionComposer(appContentPack).compose(
    shape: shape,
    newObjectives: const [],
    reviewPool: refs,
    mode: mode,
    capabilities: _capabilities(micAvailable),
    random: rng,
  );
}

List<SkillProgress> _skillPool(
  String kind,
  ProgressState progress,
  DateTime now,
) {
  final due = progress.dueSkills(now);
  final fragile = progress.fragileSkills(limit: 12);
  final weak = progress.weakSkills(limit: 12);
  final learned = progress.skills.values
      .where((skill) => skill.attempts > 0)
      .toList();
  final pool = switch (kind) {
    'due' => due,
    'weak' => [...fragile, ...weak],
    'smart' => [...due, ...fragile, ...weak],
    _ => learned,
  };
  final seen = <String>{};
  return [
    for (final skill in pool)
      if (seen.add(skill.objectiveId)) skill,
  ].take(24).toList();
}

List<ObjectiveRef> _refsForSkills(List<SkillProgress> skills) {
  final refs = <ObjectiveRef>[];
  for (final skill in skills) {
    final ref = objectiveRefForSkill(skill);
    if (ref != null) refs.add(ref);
  }
  return refs;
}

Set<Capability> _capabilities(bool micAvailable) {
  return micAvailable ? const {Capability.microphone} : const {};
}

/// Notes the lesson may review, ranked: due first, then weak, then recent.
List<Note> _reviewPool(
  LessonDefinition lesson,
  ProgressState progress,
  DateTime now,
  Set<String> freshIds,
) {
  final learned = _learnedNotes(progress);
  final candidates = _uniqueNotes([
    ...lesson.reviewNotes,
    ...learned,
  ]).where((note) => !freshIds.contains(note.id)).toList();

  if (candidates.isEmpty) {
    return const [];
  }

  final due = progress
      .dueNotes(now, pool: candidates)
      .where((note) => !freshIds.contains(note.id));
  final weak = progress
      .weakNotes(limit: 8)
      .where((note) => !freshIds.contains(note.id));
  final recent = [...candidates]..sort((a, b) {
    final lastA = progress.progressFor(a)?.lastSeenAt;
    final lastB = progress.progressFor(b)?.lastSeenAt;
    if (lastA == null && lastB == null) return a.id.compareTo(b.id);
    if (lastA == null) return 1;
    if (lastB == null) return -1;
    return lastB.compareTo(lastA);
  });

  final ranked = _uniqueNotes([...due, ...weak, ...recent]);
  return ranked.isEmpty ? candidates : ranked;
}

List<Note> _practicePool(String kind, ProgressState progress, DateTime now) {
  final learned = _learnedNotes(progress);
  List<Note> pool;
  switch (kind) {
    case 'due':
      pool = progress.dueNotes(now);
      if (pool.isEmpty) pool = progress.weakNotes();
      if (pool.isEmpty) pool = learned;
    case 'weak':
      pool = progress.weakNotes();
      if (pool.isEmpty) pool = learned;
    default:
      pool = learned;
  }

  if (pool.isEmpty) {
    pool = _firstNotePool();
  }
  return pool;
}

List<Note> _firstNotePool() {
  for (final lesson in allLessons) {
    if (lesson.newNotes.isNotEmpty) return lesson.newNotes;
  }
  return noteCatalog.take(8).toList();
}

List<Note> _learnedNotes(ProgressState progress) {
  final notes = <Note>[];
  for (final entry in progress.notes.entries) {
    if (entry.value.attempts > 0) {
      final parsed = Note.tryParse(entry.key);
      if (parsed != null) notes.add(parsed);
    }
  }
  return notes;
}

List<Note> _uniqueNotes(List<Note> notes) {
  final seen = <String>{};
  return [
    for (final note in notes)
      if (seen.add(note.id)) note,
  ];
}
