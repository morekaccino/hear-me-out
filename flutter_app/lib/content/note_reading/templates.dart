import '../../core/learning/objective.dart';
import '../../core/learning/prompt.dart';
import '../../core/learning/session_shape.dart';
import '../../core/learning/template.dart';
import '../../core/music/curriculum.dart';
import 'objectives.dart';

const String noteTeachTemplateId = 'note.teach';
const String noteNameTemplateId = 'note.name';
const String notePlayTemplateId = 'note.play';
const String notePlaceTemplateId = 'note.place';
const String noteFretboardTemplateId = 'note.fretboard';

/// Shows a new note on the staff with its name and fretboard position.
/// Never scored, so meeting a note cannot cost a heart.
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
    return FretTapPrompt(
      objective: objective,
      templateId: id,
      note: note,
      maxFret: 4,
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
