import 'dart:math';

import 'objective.dart';
import 'prompt.dart';
import 'session_shape.dart';

/// Device and settings features a template may need before it can render.
enum Capability { microphone, playback, timing, polyphony }

/// Everything a template needs to render one slot.
class PromptContext {
  const PromptContext({
    required this.random,
    required this.capabilities,
    required this.mode,
    required this.role,
    required this.occurrence,
    required this.isNew,
  });

  final Random random;
  final Set<Capability> capabilities;
  final AnswerMode mode;
  final SlotRole role;

  /// Which exposure of the objective this slot is.
  final int occurrence;

  final bool isNew;

  bool get canUseMicrophone => capabilities.contains(Capability.microphone);
}

/// A question style. Templates are pure: they turn an objective into a prompt
/// and never touch storage, audio, or widgets.
abstract interface class ExerciseTemplate {
  String get id;

  SkillFamily get family;

  /// The roles this template can fill.
  Set<SlotRole> get roles;

  /// True when answering requires playing into the microphone.
  bool get usesMicrophone;

  /// Capabilities the device must have for this template to be offered.
  Set<Capability> get requires;

  /// Lower wins when several templates can fill the same slot. Used to make the
  /// first attempt at a new idea recognition before production.
  int get priority;

  Prompt? build(ObjectiveRef objective, PromptContext context);
}
