import '../../core/learning/objective.dart';
import '../../core/learning/prompt.dart';
import '../../core/learning/session_shape.dart';
import '../../core/learning/template.dart';
import '../../core/music/chords.dart';

/// One template for every multiple-choice family.
///
/// The question, options, and answer live in the objective, so adding a theory
/// or harmony topic is a content change, not a code change.
class ChoiceTemplate implements ExerciseTemplate {
  const ChoiceTemplate({
    required this.id,
    required this.family,
    this.reveal = false,
  });

  @override
  final String id;

  @override
  final SkillFamily family;

  /// Teach cards show the answer instead of asking for it.
  final bool reveal;

  @override
  int get priority => 0;

  @override
  Set<SlotRole> get roles =>
      reveal ? const {SlotRole.teach} : const {
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
    final question = objective.data['question'] as String?;
    final options = objective.data['options'] as List<ChoiceOption>?;
    final correctId = objective.data['correctId'] as String?;
    if (question == null || options == null || correctId == null) return null;

    return ChoicePrompt(
      objective: objective,
      templateId: id,
      question: question,
      options: options,
      correctId: correctId,
      hint: objective.data['hint'] as String?,
      chord: objective.data['chord'] as ChordShape?,
      reveal: reveal,
      isNew: context.isNew,
      exposure: context.occurrence,
    );
  }
}

const List<ExerciseTemplate> theoryTemplates = [
  ChoiceTemplate(id: 'theory.teach', family: SkillFamily.theory, reveal: true),
  ChoiceTemplate(id: 'theory.ask', family: SkillFamily.theory),
];

const List<ExerciseTemplate> harmonyTemplates = [
  ChoiceTemplate(id: 'harmony.teach', family: SkillFamily.harmony, reveal: true),
  ChoiceTemplate(id: 'harmony.ask', family: SkillFamily.harmony),
];
