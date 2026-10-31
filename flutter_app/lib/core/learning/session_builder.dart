import 'dart:math';

import '../music/curriculum.dart';
import '../music/note.dart';
import 'progress.dart';

const int exercisesPerLesson = 12;
const int reviewExercisesPerLesson = 15;
const int newNoteExposures = 4;
const int maxMistakeRetries = 4;
const int livesPerLesson = 3;

class Exercise {
  Exercise({
    required this.note,
    required this.mode,
    required this.isNew,
    required this.newExposure,
    required this.choices,
  });

  final Note note;
  final AnswerMode mode;
  final bool isNew;
  final int newExposure;
  final List<Note> choices;

  bool get isPlay => mode == AnswerMode.play;
}

class LessonRun {
  LessonRun({
    required this.lesson,
    required this.exercises,
    required this.isPractice,
    this.practiceTitle,
  }) : baseExercises = exercises.length;

  final LessonDefinition lesson;
  final List<Exercise> exercises;
  final int baseExercises;
  final bool isPractice;
  final String? practiceTitle;

  int index = 0;
  int lives = livesPerLesson;
  int correct = 0;
  int wrong = 0;
  int combo = 0;
  int bestCombo = 0;

  bool awaitingNext = false;
  bool? lastCorrect;
  bool lastOctaveError = false;
  double? lastCents;
  Note? lastDetected;
  Note? lastTarget;

  final List<Exercise> _mistakes = [];
  final Set<String> _queuedMistakes = {};

  Exercise get current => exercises[index];

  bool get isFinished => index >= exercises.length;

  bool get outOfLives => lives <= 0;

  bool get isReviewingMistakes => index >= baseExercises;

  int get pendingMistakes => _mistakes.length;

  int get answered => correct + wrong;

  double get accuracy => answered == 0 ? 0 : correct / answered;

  double get progress {
    if (exercises.isEmpty) return 0;
    if (index >= baseExercises) return 1;
    final completed = index + (awaitingNext ? 1 : 0);
    return (completed / baseExercises).clamp(0.0, 1.0);
  }

  int get earnedXp {
    if (isPractice) return 5;
    final perfect = answered > 0 && wrong == 0;
    final base = lesson.isReview ? 15 : 10;
    return base + (perfect ? 5 : 0);
  }

  void queueMistake(Exercise exercise) {
    if (_queuedMistakes.length >= maxMistakeRetries) return;
    if (!_queuedMistakes.add(exercise.note.id)) return;
    _mistakes.add(
      Exercise(
        note: exercise.note,
        mode: exercise.mode,
        isNew: false,
        newExposure: 0,
        choices: [...exercise.choices],
      ),
    );
  }

  bool appendNextMistake() {
    if (_mistakes.isEmpty) return false;
    exercises.add(_mistakes.removeAt(0));
    return true;
  }
}

List<Exercise> buildLessonExercises({
  required LessonDefinition lesson,
  required ProgressState progress,
  required DateTime now,
  required bool micAvailable,
  AnswerMode mode = AnswerMode.mixed,
  Random? random,
}) {
  final rng = random ?? Random(now.millisecondsSinceEpoch);
  final baseCount = lesson.isReview
      ? reviewExercisesPerLesson
      : exercisesPerLesson;

  // A note is still "new" until it has reached box 2. Exiting early or getting
  // one wrong answer must not rob it of its teaching exposures.
  final freshNotes = lesson.newNotes
      .where((note) => (progress.progressFor(note)?.box ?? 0) < 2)
      .take(2)
      .toList();
  final freshIds = freshNotes.map((note) => note.id).toSet();

  final learned = _learnedNotes(progress);
  final reviewCandidates = _uniqueNotes([
    ...lesson.reviewNotes,
    ...learned,
  ]).where((note) => !freshIds.contains(note.id)).toList();

  final due = progress
      .dueNotes(now, pool: reviewCandidates)
      .where((note) => !freshIds.contains(note.id));
  final weak = progress
      .weakNotes(limit: 8)
      .where((note) => !freshIds.contains(note.id));
  final recent = [...reviewCandidates]..sort((a, b) {
    final lastA = progress.progressFor(a)?.lastSeenAt;
    final lastB = progress.progressFor(b)?.lastSeenAt;
    if (lastA == null && lastB == null) return a.id.compareTo(b.id);
    if (lastA == null) return 1;
    if (lastB == null) return -1;
    return lastB.compareTo(lastA);
  });
  final ranked = _uniqueNotes([...due, ...weak, ...recent]);
  final fillPool = ranked.isEmpty
      ? _uniqueNotes([...freshNotes, ...lesson.reviewNotes])
      : ranked;

  final entries = <_NoteEntry>[
    for (final note in freshNotes)
      for (var exposure = 0; exposure < newNoteExposures; exposure++)
        _NoteEntry(note: note, priority: 0, exposure: exposure),
  ];

  var cursor = 0;
  while (entries.length < baseCount && fillPool.isNotEmpty) {
    final note = fillPool[cursor % fillPool.length];
    cursor++;
    entries.add(
      _NoteEntry(
        note: note,
        priority: due.any((dueNote) => dueNote.id == note.id) ? 1 : 3,
        exposure: 0,
      ),
    );
  }

  // Defensive fallback for a malformed lesson definition.
  if (entries.isEmpty) {
    final fallback = freshNotes.isNotEmpty
        ? freshNotes
        : (lesson.reviewNotes.isNotEmpty ? lesson.reviewNotes : noteCatalog);
    for (var index = 0; index < baseCount && fallback.isNotEmpty; index++) {
      entries.add(
        _NoteEntry(note: fallback[index % fallback.length], priority: 2),
      );
    }
  }

  final ordered = _orderEntries(entries.take(baseCount).toList());
  final seen = <String, int>{};
  final exercises = <Exercise>[];
  for (final entry in ordered) {
    final exposure = seen[entry.note.id] ?? 0;
    final isNew = freshIds.contains(entry.note.id) && exposure < newNoteExposures;
    exercises.add(
      Exercise(
        note: entry.note,
        mode: AnswerMode.name,
        isNew: isNew,
        newExposure: isNew ? exposure : 0,
        choices: answerChoices(entry.note, random: rng),
      ),
    );
    seen[entry.note.id] = exposure + 1;
  }

  _assignModes(exercises, requestedMode: mode, micAvailable: micAvailable);
  return exercises;
}

class _NoteEntry {
  _NoteEntry({required this.note, required this.priority, this.exposure = 0});

  final Note note;
  final int priority;
  final int exposure;
}

/// Arrange notes with the most frequent note first, keeping the same note out
/// of the last two positions when another option exists.
List<_NoteEntry> _orderEntries(List<_NoteEntry> entries) {
  final remaining = [...entries];
  final ordered = <_NoteEntry>[];
  final recentIds = <String>[];

  while (remaining.isNotEmpty) {
    final counts = <String, int>{};
    for (final entry in remaining) {
      counts[entry.note.id] = (counts[entry.note.id] ?? 0) + 1;
    }
    final candidates = remaining
        .where((entry) => !recentIds.contains(entry.note.id))
        .toList();
    final choices = candidates.isEmpty ? remaining : candidates;
    choices.sort((a, b) {
      final countCompare = (counts[b.note.id] ?? 0).compareTo(
        counts[a.note.id] ?? 0,
      );
      if (countCompare != 0) return countCompare;
      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;
      final exposureCompare = a.exposure.compareTo(b.exposure);
      if (exposureCompare != 0) return exposureCompare;
      return a.note.id.compareTo(b.note.id);
    });
    final chosen = choices.first;
    remaining.remove(chosen);
    ordered.add(chosen);
    recentIds.add(chosen.note.id);
    if (recentIds.length > 2) recentIds.removeAt(0);
  }
  return ordered;
}

List<Exercise> buildPracticeExercises({
  required String kind,
  required ProgressState progress,
  required DateTime now,
  required bool micAvailable,
  AnswerMode mode = AnswerMode.mixed,
  Random? random,
}) {
  final rng = random ?? Random(now.millisecondsSinceEpoch);
  final learned = _learnedNotes(progress);

  List<Note> pool;
  switch (kind) {
    case 'due':
      pool = progress.dueNotes(now);
      if (pool.isEmpty) pool = progress.weakNotes();
      if (pool.isEmpty) pool = learned;
      break;
    case 'weak':
      pool = progress.weakNotes();
      if (pool.isEmpty) pool = learned;
      break;
    default:
      pool = learned;
  }

  if (pool.isEmpty) {
    pool = [...curriculum.first.lessons.first.newNotes];
  }

  final entries = <_NoteEntry>[];
  var cursor = 0;
  while (entries.length < exercisesPerLesson) {
    final note = pool[cursor % pool.length];
    cursor++;
    entries.add(_NoteEntry(note: note, priority: 0));
  }

  final exercises = [
    for (final entry in _orderEntries(entries))
      Exercise(
        note: entry.note,
        mode: AnswerMode.name,
        isNew: false,
        newExposure: 0,
        choices: answerChoices(entry.note, random: rng),
      ),
  ];
  _assignModes(exercises, requestedMode: mode, micAvailable: micAvailable);
  return exercises;
}

void _assignModes(
  List<Exercise> exercises, {
  required AnswerMode requestedMode,
  required bool micAvailable,
}) {
  if (!micAvailable || requestedMode == AnswerMode.name) {
    for (var i = 0; i < exercises.length; i++) {
      exercises[i] = Exercise(
        note: exercises[i].note,
        mode: AnswerMode.name,
        isNew: exercises[i].isNew,
        newExposure: exercises[i].newExposure,
        choices: exercises[i].choices,
      );
    }
    return;
  }

  if (requestedMode == AnswerMode.play) {
    for (var i = 0; i < exercises.length; i++) {
      exercises[i] = Exercise(
        note: exercises[i].note,
        mode: AnswerMode.play,
        isNew: exercises[i].isNew,
        newExposure: exercises[i].newExposure,
        choices: exercises[i].choices,
      );
    }
    return;
  }

  var playCount = 0;
  for (var i = 0; i < exercises.length; i++) {
    final exercise = exercises[i];
    final firstExposure = exercise.isNew && exercise.newExposure == 0;
    final usePlay = !firstExposure && (i.isEven || playCount < 3);
    exercises[i] = Exercise(
      note: exercise.note,
      mode: usePlay ? AnswerMode.play : AnswerMode.name,
      isNew: exercise.isNew,
      newExposure: exercise.newExposure,
      choices: exercise.choices,
    );
    if (usePlay) playCount++;
  }

  if (playCount < 3) {
    for (var i = exercises.length - 1; i >= 0 && playCount < 3; i--) {
      final exercise = exercises[i];
      if (exercise.mode == AnswerMode.play) continue;
      if (exercise.isNew && exercise.newExposure == 0) continue;
      exercises[i] = Exercise(
        note: exercise.note,
        mode: AnswerMode.play,
        isNew: exercise.isNew,
        newExposure: exercise.newExposure,
        choices: exercise.choices,
      );
      playCount++;
    }
  }
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
