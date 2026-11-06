import '../music/curriculum.dart';
import '../music/note.dart';
import 'attempt_outcome.dart';
import 'prompt.dart';

const int exercisesPerLesson = 12;
const int reviewExercisesPerLesson = 15;

/// Notes get four exposures while their box is below 2; exiting early cannot
/// rob a new note of a teaching exposure.
const int newNoteExposures = 4;
const int maxMistakeRetries = 4;

/// One lesson in progress. Owns ordering and mistake retries; knows nothing
/// about how prompts were generated, and has no lives or failure resource.
class LessonRun {
  LessonRun({
    required this.lesson,
    required this.exercises,
    required this.isPractice,
    this.practiceTitle,
    this.isJumpTest = false,
    this.jumpTargetSectionId,
  }) : baseExercises = exercises.length;

  final LessonDefinition lesson;
  final List<Prompt> exercises;
  final int baseExercises;
  final bool isPractice;
  final String? practiceTitle;
  final bool isJumpTest;
  final String? jumpTargetSectionId;

  int index = 0;
  int correct = 0;
  int wrong = 0;
  int combo = 0;
  int bestCombo = 0;

  bool awaitingNext = false;
  AttemptOutcome? lastOutcome;

  /// The determinate verdict of the last answer, or null when nothing has
  /// been answered or the attempt was indeterminate. An indeterminate attempt
  /// is not a wrong answer.
  bool? get lastCorrect => switch (lastOutcome) {
    null => null,
    AttemptOutcome.correct => true,
    AttemptOutcome.incorrect => false,
    AttemptOutcome.indeterminate => null,
  };
  bool lastOctaveError = false;
  double? lastCents;
  Note? lastDetected;
  Note? lastTarget;

  final List<Prompt> _mistakes = [];
  final Set<String> _queuedMistakes = {};

  Prompt get current => exercises[index];

  /// The current prompt when it is a note-reading prompt.
  ///
  /// Null once another family reaches the runtime. Screens should pattern-match
  /// on `current` instead of assuming every session is about notes.
  NotePrompt? get currentNote {
    final prompt = exercises[index];
    return prompt is NotePrompt ? prompt : null;
  }

  bool get isFinished => index >= exercises.length;

  bool get isReviewingMistakes => index >= baseExercises;

  int get pendingMistakes => _mistakes.length;

  int get scoredCount => exercises.where((prompt) => prompt.isScored).length;

  int get answered => correct + wrong;

  double get accuracy => answered == 0 ? 0 : correct / answered;

  /// Where the learner is in the lesson, for the progress bar caption.
  String get stepLabel {
    if (isPractice) return practiceTitle ?? 'Practice';
    if (isReviewingMistakes) return 'Mistake review';
    final total = exercises.isEmpty ? 1 : exercises.length;
    return 'Step ${(index + 1).clamp(1, total)} of $total';
  }

  double get progress {
    if (exercises.isEmpty) return 0;
    if (index >= baseExercises) return 1;
    final completed = index + (awaitingNext ? 1 : 0);
    return (completed / baseExercises).clamp(0.0, 1.0);
  }

  int get earnedXp {
    if (isPractice) return 5;
    final perfect = answered > 0 && wrong == 0;
    final base = isJumpTest ? 20 : (lesson.isReview ? 15 : 10);
    return base + (perfect ? 5 : 0);
  }

  void queueMistake(Prompt prompt) {
    if (!prompt.isScored) return;
    if (_queuedMistakes.length >= maxMistakeRetries) return;
    if (!_queuedMistakes.add(prompt.objective.id)) return;
    _mistakes.add(prompt.retry());
  }

  bool appendNextMistake() {
    if (_mistakes.isEmpty) return false;
    exercises.add(_mistakes.removeAt(0));
    return true;
  }
}
