import '../../core/learning/objective.dart';
import '../../core/learning/prompt.dart';
import '../../core/learning/session_shape.dart';
import '../../core/learning/template.dart';
import '../../core/music/curriculum.dart';
import '../../core/music/guitar.dart';
import 'objectives.dart';

const String noteTeachTemplateId = 'note.teach';
const String noteNameTemplateId = 'note.name';
const String notePlayTemplateId = 'note.play';
const String notePlaceTemplateId = 'note.place';
const String noteFretboardTemplateId = 'note.fretboard';

/// Shows a new note on the staff with its name and fretboard position.
/// Never scored, so meeting a note cannot count against the learner.
class NoteTeachTemplate implements ExerciseTemplate {
  const NoteTeachTemplate();

  @override
  String get id => noteTeachTemplateId;

  @override
  int get priority => 0;

  @override
  SkillFamily get family => SkillFamily.noteReading;

  @override
  Set<SlotRole> get roles => const {SlotRole.teach};

  @override
  bool get usesMicrophone => false;

  @override
  Set<Capability> get requires => const {};

  @override
  Prompt? build(ObjectiveRef objective, PromptContext context) {
    final note = noteOf(objective);
    if (note == null) return null;
    return NotePrompt(
      objective: objective,
      templateId: id,
      task: NoteTask.teach,
      note: note,
      isNew: true,
    );
  }
}

class NoteNameTemplate implements ExerciseTemplate {
  const NoteNameTemplate();

  @override
  String get id => noteNameTemplateId;

  @override
  int get priority => 0;

  @override
  SkillFamily get family => SkillFamily.noteReading;

  @override
  Set<SlotRole> get roles => const {
    SlotRole.guided,
    SlotRole.apply,
    SlotRole.review,
  };

  @override
  bool get usesMicrophone => false;

  @override
  Set<Capability> get requires => const {};

  @override
  Prompt? build(ObjectiveRef objective, PromptContext context) {
    final note = noteOf(objective);
    if (note == null) return null;
    final guided = context.role == SlotRole.guided;
    return NotePrompt(
      objective: objective,
      templateId: id,
      task: NoteTask.name,
      note: note,
      choices: answerChoices(
        note,
        count: guided ? 3 : 4,
        guided: guided,
        random: context.random,
      ),
      isNew: context.isNew,
      exposure: context.occurrence,
    );
  }
}

class NotePlayTemplate implements ExerciseTemplate {
  const NotePlayTemplate();

  @override
  String get id => notePlayTemplateId;

  @override
  int get priority => 0;

  @override
  SkillFamily get family => SkillFamily.noteReading;

  @override
  Set<SlotRole> get roles => const {
    SlotRole.guided,
    SlotRole.apply,
    SlotRole.review,
  };

  @override
  bool get usesMicrophone => true;

  @override
  Set<Capability> get requires => const {Capability.microphone};

  @override
  Prompt? build(ObjectiveRef objective, PromptContext context) {
    final note = noteOf(objective);
    if (note == null) return null;
    return NotePrompt(
      objective: objective,
      templateId: id,
      task: NoteTask.play,
      note: note,
      // Kept so the learner can fall back to note names if the microphone
      // cannot start mid-exercise.
      choices: answerChoices(note, random: context.random),
      isNew: context.isNew,
      exposure: context.occurrence,
    );
  }
}

/// Place the named note where it belongs on the staff.
class NotePlaceTemplate implements ExerciseTemplate {
  const NotePlaceTemplate();

  @override
  String get id => notePlaceTemplateId;

  @override
  int get priority => 1;

  @override
  SkillFamily get family => SkillFamily.noteReading;

  @override
  Set<SlotRole> get roles => const {
    SlotRole.guided,
    SlotRole.apply,
    SlotRole.review,
  };

  @override
  bool get usesMicrophone => false;

  @override
  Set<Capability> get requires => const {};

  @override
  Prompt? build(ObjectiveRef objective, PromptContext context) {
    final note = noteOf(objective);
    if (note == null) return null;
    return StaffTapPrompt(
      objective: objective,
      templateId: id,
      note: note,
      isNew: context.isNew,
      exposure: context.occurrence,
    );
  }
}

/// Find the written note on the neck. Any correct string and fret counts.
class NoteFretboardTemplate implements ExerciseTemplate {
  const NoteFretboardTemplate();

  @override
  String get id => noteFretboardTemplateId;

  @override
  int get priority => 2;

  @override
  SkillFamily get family => SkillFamily.noteReading;

  @override
  Set<SlotRole> get roles => const {
    SlotRole.guided,
    SlotRole.apply,
    SlotRole.review,
  };

  @override
  bool get usesMicrophone => false;

  @override
  Set<Capability> get requires => const {};

  @override
  Prompt? build(ObjectiveRef objective, PromptContext context) {
    final note = noteOf(objective);
    if (note == null) return null;
    final best = Guitar.bestPosition(note, maxFret: 15);
    final maxFret = best == null ? 12 : (best.fret < 4 ? 4 : best.fret);
    return FretTapPrompt(
      objective: objective,
      templateId: id,
      note: note,
      maxFret: maxFret,
      isNew: context.isNew,
      exposure: context.occurrence,
    );
  }
}

const List<ExerciseTemplate> noteReadingTemplates = [
  NoteTeachTemplate(),
  NoteNameTemplate(),
  NotePlayTemplate(),
  NotePlaceTemplate(),
  NoteFretboardTemplate(),
];

/// A fretboard question for the `fretboard` family. The objective carries the
/// target note and a max fret; the prompt asks the learner to find it.
class FretFindTemplate implements ExerciseTemplate {
  const FretFindTemplate();

  @override
  String get id => 'fret.find';

  @override
  int get priority => 0;

  @override
  SkillFamily get family => SkillFamily.fretboard;

  @override
  Set<SlotRole> get roles => const {
    SlotRole.guided,
    SlotRole.apply,
    SlotRole.review,
  };

  @override
  bool get usesMicrophone => false;

  @override
  Set<Capability> get requires => const {};

  @override
  Prompt? build(ObjectiveRef objective, PromptContext context) {
    final note = noteOf(objective);
    if (note == null) return null;
    return FretTapPrompt(
      objective: objective,
      templateId: id,
      note: note,
      maxFret: objective.data['maxFret'] as int? ?? 5,
      isNew: context.isNew,
      exposure: context.occurrence,
    );
  }
}

const List<ExerciseTemplate> fretboardTemplates = [
  FretboardTeachTemplate(),
  FretFindTemplate(),
];

/// A teach card for a fretboard objective. Shows the target note and every
/// first-position place it can be played.
class FretboardTeachTemplate implements ExerciseTemplate {
  const FretboardTeachTemplate();

  @override
  String get id => 'fret.teach';

  @override
  int get priority => 0;

  @override
  SkillFamily get family => SkillFamily.fretboard;

  @override
  Set<SlotRole> get roles => const {SlotRole.teach};

  @override
  bool get usesMicrophone => false;

  @override
  Set<Capability> get requires => const {};

  @override
  Prompt? build(ObjectiveRef objective, PromptContext context) {
    final note = noteOf(objective);
    if (note == null) return null;
    final maxFret = objective.data['maxFret'] as int? ?? 5;
    final positions = Guitar.positionsFor(note, maxFret: maxFret);
    final label = positions.isEmpty
        ? 'Find it on the neck.'
        : positions.map((position) => position.label).join(' or ');
    return ChoicePrompt(
      objective: objective,
      templateId: id,
      question: 'Where is ${note.display}?',
      options: [ChoiceOption('answer', label)],
      correctId: 'answer',
      reveal: true,
      isNew: true,
    );
  }
}
