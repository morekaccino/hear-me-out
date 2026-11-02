import '../music/chords.dart';
import '../music/sound_spec.dart';
import 'objective.dart';
import 'prompt.dart';

/// Builds a multiple-choice objective whose content lives in the pack rather
/// than in code. The helper is generic so every topic can use it.
ObjectiveRef choiceObjective({
  required String id,
  required SkillFamily family,
  required String question,
  required List<String> answers,
  required int correctIndex,
  String? hint,
  ChordShape? chord,
  SoundSpec? audio,
}) {
  final options = [
    for (var index = 0; index < answers.length; index++)
      ChoiceOption('$id:$index', answers[index]),
  ];
  return ObjectiveRef(
    id,
    family: family,
    data: {
      'question': question,
      'options': options,
      'correctId': options[correctIndex].id,
      'hint': hint,
      'chord': chord,
      'audio': audio,
    },
  );
}
