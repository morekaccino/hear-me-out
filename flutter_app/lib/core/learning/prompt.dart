import '../music/chords.dart';
import '../music/note.dart';
import '../music/rhythm.dart';
import '../music/sound_spec.dart';
import 'objective.dart';

/// How the learner prefers to answer. [mixed] is the default.
enum AnswerMode { mixed, name, play }

AnswerMode answerModeFromName(String? value) {
  return AnswerMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => AnswerMode.mixed,
  );
}

/// One option in a multiple-choice question.
class ChoiceOption {
  const ChoiceOption(this.id, this.label);

  final String id;
  final String label;
}

/// One thing the learner is asked to do.
///
/// Prompts are immutable data. They describe the question, never the answer,
/// and never own audio or UI state.
///
/// Sealed on purpose: the widget layer can then switch exhaustively. The cost
/// is that a new question style adds its subclass to this file rather than to
/// `lib/content`.
sealed class Prompt {
  const Prompt({required this.objective, required this.templateId});

  final ObjectiveRef objective;

  /// The template that produced this prompt. Kept for tests and analytics.
  final String templateId;

  SkillFamily get family;

  /// Teach prompts explain a new idea and are never scored.
  bool get isScored => true;

  bool get isTeach => false;

  /// True when answering requires playing into the microphone.
  bool get usesMicrophone => false;

  /// True for a teaching exposure of an objective introduced this session.
  bool get isNew;

  /// A copy suitable for an end-of-lesson mistake retry.
  Prompt retry();
}

enum NoteTask { teach, name, play, place, hear }

/// A prompt about one written note.
final class NotePrompt extends Prompt {
  const NotePrompt({
    required super.objective,
    required super.templateId,
    required this.task,
    required this.note,
    this.choices = const <Note>[],
    this.isNew = false,
    this.exposure = 0,
  });

  final NoteTask task;
  final Note note;

  /// Tap targets for [NoteTask.name] and [NoteTask.hear]. Empty otherwise.
  final List<Note> choices;

  @override
  final bool isNew;

  /// Which of the note's teaching exposures this prompt is.
  final int exposure;

  @override
  SkillFamily get family => SkillFamily.noteReading;

  @override
  bool get isScored => task != NoteTask.teach;

  @override
  bool get isTeach => task == NoteTask.teach;

  @override
  bool get usesMicrophone => task == NoteTask.play;

  bool get isPlay => task == NoteTask.play;

  /// A first attempt at a new note shows fewer, more distant options.
  bool get isGuided => task == NoteTask.name && choices.length < 4;

  @override
  NotePrompt retry() {
    // A teach card has nothing to retry: returning it unchanged keeps the
    // invariant that a retry is always a well-formed prompt.
    if (task == NoteTask.teach) return this;
    return NotePrompt(
      objective: objective,
      templateId: templateId,
      task: task,
      note: note,
      choices: choices,
    );
  }
}

/// Put a named note on the staff.
final class StaffTapPrompt extends Prompt {
  const StaffTapPrompt({
    required super.objective,
    required super.templateId,
    required this.note,
    this.isNew = false,
    this.exposure = 0,
  });

  final Note note;

  @override
  final bool isNew;

  final int exposure;

  @override
  SkillFamily get family => objective.family;

  @override
  StaffTapPrompt retry() => StaffTapPrompt(
    objective: objective,
    templateId: templateId,
    note: note,
  );
}

/// Find a written note anywhere on the fretboard.
final class FretTapPrompt extends Prompt {
  const FretTapPrompt({
    required super.objective,
    required super.templateId,
    required this.note,
    required this.maxFret,
    this.isNew = false,
    this.exposure = 0,
  });

  final Note note;
  final int maxFret;

  @override
  final bool isNew;

  final int exposure;

  @override
  SkillFamily get family => objective.family;

  @override
  FretTapPrompt retry() => FretTapPrompt(
    objective: objective,
    templateId: templateId,
    note: note,
    maxFret: maxFret,
  );
}

/// A question answered by tapping one labelled option.
///
/// [reveal] turns it into a teach card that shows the answer instead of asking
/// for it. [chord] renders a fretboard diagram above the question.
final class ChoicePrompt extends Prompt {  const ChoicePrompt({
    required super.objective,
    required super.templateId,
    required this.question,
    required this.options,
    required this.correctId,
    this.hint,
    this.chord,
    this.audio,
    this.reveal = false,
    this.isNew = false,
    this.exposure = 0,
  });

  final String question;
  final List<ChoiceOption> options;
  final String correctId;
  final String? hint;
  final ChordShape? chord;

  /// Optional audio stimulus for ear-training questions.
  final SoundSpec? audio;

  final bool reveal;

  @override
  final bool isNew;

  final int exposure;

  @override
  SkillFamily get family => objective.family;

  @override
  bool get isScored => !reveal;

  @override
  bool get isTeach => reveal;

  @override
  ChoicePrompt retry() => ChoicePrompt(
    objective: objective,
    templateId: templateId,
    question: question,
    options: options,
    correctId: correctId,
    hint: hint,
    chord: chord,
    audio: audio,
  );
}

/// Put labelled tokens in the correct order.
///
/// Used for chord spelling, scale construction, and progression building. The
/// labels can repeat (a I–IV–V–I progression has two C chords in C), so the
/// verifier compares the sequence of labels rather than token ids.
final class OrderPrompt extends Prompt {
  const OrderPrompt({
    required super.objective,
    required super.templateId,
    required this.question,
    required this.tokens,
    required this.correctOrder,
    this.reveal = false,
    this.isNew = false,
    this.exposure = 0,
  });

  final String question;
  final List<String> tokens;
  final List<String> correctOrder;
  final bool reveal;

  @override
  final bool isNew;

  final int exposure;

  @override
  SkillFamily get family => objective.family;

  @override
  bool get isScored => !reveal;

  @override
  bool get isTeach => reveal;

  @override
  OrderPrompt retry() => OrderPrompt(
    objective: objective,
    templateId: templateId,
    question: question,
    tokens: tokens,
    correctOrder: correctOrder,
  );
}

/// Count or tap a rhythm against a steady pulse.
enum RhythmTask { teach, tap }

final class RhythmPrompt extends Prompt {
  const RhythmPrompt({
    required super.objective,
    required super.templateId,
    required this.pattern,
    required this.question,
    this.task = RhythmTask.tap,
    this.isNew = false,
    this.exposure = 0,
  });

  final RhythmPattern pattern;
  final String question;
  final RhythmTask task;

  @override
  final bool isNew;

  final int exposure;

  @override
  SkillFamily get family => objective.family;

  @override
  bool get isScored => task != RhythmTask.teach;

  @override
  bool get isTeach => task == RhythmTask.teach;

  @override
  RhythmPrompt retry() => RhythmPrompt(
    objective: objective,
    templateId: templateId,
    pattern: pattern,
    question: question,
  );
}
