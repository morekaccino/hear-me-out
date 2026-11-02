import '../../core/learning/choice_objective.dart';
import '../../core/learning/objective.dart';
import '../../core/music/chords.dart';

export '../../core/learning/choice_objective.dart';

final List<ObjectiveRef> theoryObjectives = [
  choiceObjective(
    id: 'key:G',
    family: SkillFamily.theory,
    question: 'How many sharps does G major have?',
    answers: const ['0', '1', '2', '3'],
    correctIndex: 1,
    hint: 'G major raises F to F sharp.',
  ),
  choiceObjective(
    id: 'key:F',
    family: SkillFamily.theory,
    question: 'How many flats does F major have?',
    answers: const ['0', '1', '2', '3'],
    correctIndex: 1,
    hint: 'F major lowers B to B flat.',
  ),
  choiceObjective(
    id: 'key:D',
    family: SkillFamily.theory,
    question: 'How many sharps does D major have?',
    answers: const ['1', '2', '3', '4'],
    correctIndex: 2,
    hint: 'D major sharps F and C.',
  ),
  choiceObjective(
    id: 'capo:2',
    family: SkillFamily.theory,
    question: 'Capo on fret 2. You play a G shape. Which chord sounds?',
    answers: const ['G', 'A', 'B', 'F'],
    correctIndex: 1,
    hint: 'A capo moves every shape up by its fret. G plus two frets is A.',
  ),
  choiceObjective(
    id: 'capo:3',
    family: SkillFamily.theory,
    question: 'Capo on fret 3. You play a D shape. Which chord sounds?',
    answers: const ['D', 'E', 'F', 'G'],
    correctIndex: 2,
    hint: 'D plus three frets is F.',
  ),
  choiceObjective(
    id: 'meter:4_4',
    family: SkillFamily.theory,
    question: 'How many beats are in one 4/4 bar?',
    answers: const ['2', '3', '4', '6'],
    correctIndex: 2,
  ),
  choiceObjective(
    id: 'meter:3_4',
    family: SkillFamily.theory,
    question: 'How many beats are in one 3/4 bar?',
    answers: const ['2', '3', '4', '6'],
    correctIndex: 1,
    hint: 'Three quarter notes per bar, like a waltz.',
  ),
  choiceObjective(
    id: 'meter:6_8',
    family: SkillFamily.theory,
    question: 'How many eighth notes are in one 6/8 bar?',
    answers: const ['3', '4', '6', '8'],
    correctIndex: 2,
    hint: 'Six eighth notes, felt as two groups of three.',
  ),
];

final List<ObjectiveRef> harmonyObjectives = [
  for (final chord in chordShapes) _chordObjective(chord),
];

ObjectiveRef _chordObjective(ChordShape chord) {
  final distractors = chordShapes
      .where((candidate) => candidate.id != chord.id)
      .take(3)
      .toList();
  final position = chord.id.codeUnits.fold(0, (sum, unit) => sum + unit) % 4;
  final ordered = [...distractors]..insert(position, chord);
  return choiceObjective(
    id: 'chord:${chord.id}',
    family: SkillFamily.harmony,
    question: 'Which chord is this shape?',
    answers: [for (final option in ordered) option.name],
    correctIndex: position,
    chord: chord,
  );
}
