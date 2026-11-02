import 'objective.dart';
import 'session_shape.dart';
import 'template.dart';

/// The registry of question styles a session can draw from.
///
/// A topic is added by registering its templates here, not by changing the
/// composer.
class ContentPack {
  const ContentPack({required this.id, required this.templates});

  final String id;
  final List<ExerciseTemplate> templates;

  /// Every template that can fill one slot.
  ///
  /// [microphone] selects the answer surface: true means "the learner must
  /// play", false means "the learner answers without the mic".
  List<ExerciseTemplate> candidatesFor({
    required SkillFamily family,
    required SlotRole role,
    required Set<Capability> capabilities,
    required bool microphone,
  }) {
    return [
      for (final template in templates)
        if (template.family == family &&
            template.roles.contains(role) &&
            template.usesMicrophone == microphone &&
            capabilities.containsAll(template.requires))
          template,
    ];
  }
}
