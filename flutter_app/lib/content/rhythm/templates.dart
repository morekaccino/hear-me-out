import '../../core/learning/objective.dart';
import '../../core/learning/prompt.dart';
import '../../core/learning/session_shape.dart';
import '../../core/learning/template.dart';
import 'objectives.dart';

/// Shows the pattern before the learner taps it.
class RhythmTeachTemplate implements ExerciseTemplate {
  const RhythmTeachTemplate();

  @override
  String get id => 'rhythm.teach';

  @override
  int get priority => 0;

  @override
  SkillFamily get family => SkillFamily.rhythm;

  @override
  Set<SlotRole> get roles => const {SlotRole.teach};

  @override
  bool get usesMicrophone => false;

  @override
  Set<Capability> get requires => const {};

  @override
  Prompt? build(ObjectiveRef objective, PromptContext context) {
    final pattern = patternOf(objective);
    if (pattern == null) return null;
    return RhythmPrompt(
      objective: objective,
      templateId: id,
      pattern: pattern,
      question: 'Count it in your head, then tap it.',
      task: RhythmTask.teach,
      isNew: true,
    );
  }
}

class RhythmTapTemplate implements ExerciseTemplate {
  const RhythmTapTemplate();

  @override
  String get id => 'rhythm.tap';

  @override
  int get priority => 0;

  @override
  SkillFamily get family => SkillFamily.rhythm;

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
    final pattern = patternOf(objective);
    if (pattern == null) return null;
    return RhythmPrompt(
      objective: objective,
      templateId: id,
      pattern: pattern,
      question: 'Tap the rhythm',
      isNew: context.isNew,
      exposure: context.occurrence,
    );
  }
}

const List<ExerciseTemplate> rhythmTemplates = [
  RhythmTeachTemplate(),
  RhythmTapTemplate(),
];
