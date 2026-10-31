import 'dart:math';

import '../music/curriculum.dart';
import '../music/note.dart';
import 'progress.dart';

const int exercisesPerLesson = 10;
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
  });

  final LessonDefinition lesson;
  final List<Exercise> exercises;
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

  Exercise get current => exercises[index];

  bool get isFinished => index >= exercises.length;

  bool get outOfLives => lives <= 0;

  int get answered => correct + wrong;

  double get accuracy => answered == 0 ? 0 : correct / answered;

  double get progress =>
      exercises.isEmpty ? 0 : (index / exercises.length).clamp(0.0, 1.0);

  int get earnedXp {
    if (isPractice) return 5;
    final perfect = answered > 0 && wrong == 0;
    final base = lesson.isReview ? 15 : 10;
    return base + (perfect ? 5 : 0);
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

  // A note is still "new" until it has reached box 2. Exiting early or getting
  // one wrong answer must not rob it of its three teaching exposures.
  final freshNotes = lesson.newNotes
      .where((note) => (progress.progressFor(note)?.box ?? 0) < 2)
      .take(2)
      .toList();

  final learned = <Note>[];
  for (final entry in progress.notes.entries) {
    if (entry.value.attempts > 0) {
      final parsed = Note.tryParse(entry.key);
      if (parsed != null) learned.add(parsed);
    }
  }

  final pool = _uniqueNotes([...lesson.reviewNotes, ...learned, ...freshNotes]);

  final due = progress.dueNotes(now, pool: pool);
  final weak = progress.weakNotes(limit: 8);
  final rest = [...pool]..shuffle(rng);
  final ranked = _uniqueNotes([...due, ...weak, ...rest]);

  final entries = <_NoteEntry>[
    for (final note in freshNotes)
      for (var exposure = 0; exposure < 3; exposure++)
        _NoteEntry(note: note, priority: 0, exposure: exposure),
  ];

  final counts = <String, int>{for (final note in freshNotes) note.id: 3};
  final reviewNeeded = exercisesPerLesson - entries.length;
  if (reviewNeeded > 0) {
    var previousReview = '';
    var cursor = 0;
    for (var index = 0; index < reviewNeeded; index++) {
      final candidates = ranked.isEmpty ? pool : ranked;
      if (candidates.isEmpty) break;
      Note? choice;
      for (var attempt = 0; attempt < candidates.length; attempt++) {
        final candidate = candidates[(cursor + attempt) % candidates.length];
        if (candidate.id == previousReview && candidates.length > 1) continue;
        if ((counts[candidate.id] ?? 0) >= 5 && candidates.length > 1) continue;
        choice = candidate;
        cursor = (cursor + attempt + 1) % candidates.length;
        break;
      }
      choice ??= candidates.first;
      entries.add(
        _NoteEntry(
          note: choice,
          priority: due.any((note) => note.id == choice!.id) ? 1 : 3,
          exposure: 0,
        ),
      );
      previousReview = choice.id;
      counts[choice.id] = (counts[choice.id] ?? 0) + 1;
    }
  }

  while (entries.length < exercisesPerLesson) {
    final fallback = freshNotes.isNotEmpty
        ? freshNotes
        : (pool.isNotEmpty ? pool : curriculum.first.lessons.first.newNotes);
    if (fallback.isEmpty) break;
    final note = fallback[entries.length % fallback.length];
    entries.add(_NoteEntry(note: note, priority: 2, exposure: 0));
  }

  final ordered = _orderEntries(entries.take(exercisesPerLesson).toList());
  final freshIds = freshNotes.map((note) => note.id).toSet();
  final seen = <String, int>{};
  final exercises = <Exercise>[];
  for (final entry in ordered) {
    final exposure = seen[entry.note.id] ?? 0;
    final isNew = freshIds.contains(entry.note.id) && exposure < 3;
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

/// Arrange notes with the most frequent note first, never placing the same
/// note next to itself when an alternative exists.
List<_NoteEntry> _orderEntries(List<_NoteEntry> entries) {
  final remaining = [...entries];
  final ordered = <_NoteEntry>[];
  String? previousId;

  while (remaining.isNotEmpty) {
    final counts = <String, int>{};
    for (final entry in remaining) {
      counts[entry.note.id] = (counts[entry.note.id] ?? 0) + 1;
    }
    final candidates = remaining
        .where((entry) => entry.note.id != previousId)
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
    previousId = chosen.note.id;
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
  final learned = <Note>[];
  for (final entry in progress.notes.entries) {
    if (entry.value.attempts > 0) {
      final parsed = Note.tryParse(entry.key);
      if (parsed != null) learned.add(parsed);
    }
  }

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

  final shuffled = [...pool]..shuffle(rng);
  final entries = <_NoteEntry>[];
  var previousId = '';
  var cursor = 0;
  while (entries.length < exercisesPerLesson) {
    Note? note;
    for (var attempt = 0; attempt < shuffled.length; attempt++) {
      final candidate = shuffled[(cursor + attempt) % shuffled.length];
      if (candidate.id == previousId && shuffled.length > 1) continue;
      note = candidate;
      cursor = (cursor + attempt + 1) % shuffled.length;
      break;
    }
    note ??= shuffled.first;
    entries.add(_NoteEntry(note: note, priority: 0));
    previousId = note.id;
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

List<Note> _uniqueNotes(List<Note> notes) {
  final seen = <String>{};
  return [
    for (final note in notes)
      if (seen.add(note.id)) note,
  ];
}
