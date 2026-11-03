import '../../music/chord.dart';
import '../../music/chords.dart';
import '../../music/guitar.dart';
import '../../music/interval.dart';
import '../../music/key.dart';
import '../../music/note.dart';
import '../../music/progression.dart';
import '../../music/rhythm.dart';
import '../../music/scale.dart';
import '../../music/sound_spec.dart';
import '../choice_objective.dart';
import '../note_objective.dart';
import '../objective.dart';
import '../rhythm_objective.dart';

/// Builders for the generated course. Every helper returns a stable objective
/// with the data its templates need.

ObjectiveRef noteConcept(String note) => noteObjective(Note.parse(note));

ObjectiveRef fretConcept(String note, {int maxFret = 5}) => ObjectiveRef(
  'fret:$note:$maxFret',
  family: SkillFamily.fretboard,
  data: {'note': Note.parse(note), 'maxFret': maxFret},
);

ObjectiveRef rhythmConcept(String patternId) {
  final pattern = rhythmPatterns.firstWhere(
    (candidate) => candidate.id == patternId,
    orElse: () => rhythmPatterns.first,
  );
  return rhythmObjective(pattern);
}

ObjectiveRef chordShapeConcept(String shapeId) {
  final chord = chordById[shapeId]!;
  final options = _distractors(chordShapes.map((shape) => shape.name).toList(), chord.name);
  return _choice(
    id: 'chord:${chord.id}',
    family: SkillFamily.harmony,
    question: 'Which chord is this shape?',
    answers: options,
    correct: chord.name,
    hint: 'Start from the lowest sounding string.',
    chord: chord,
  );
}

ObjectiveRef keySignatureConcept(String tonic, {bool minor = false}) {
  final key = KeySignature.of(tonic, minor: minor);
  final count = key.accidentalCount;
  final label = count == 0
      ? 'no sharps or flats'
      : count == 1
      ? (key.isFlat ? '1 flat' : '1 sharp')
      : '$count ${key.isFlat ? 'flats' : 'sharps'}';
  final options = _nearbyCounts(key);
  return _choice(
    id: 'keysig:${key.id}',
    family: SkillFamily.theory,
    question: 'How many sharps or flats does ${key.display} have?',
    answers: options,
    correct: label,
    hint: '${key.relativeMajorTonic} major is the relative major.',
  );
}

ObjectiveRef intervalConcept(String lower, String upper, {bool harmonic = false}) {
  final lowerNote = Note.parse(lower);
  final upperNote = Note.parse(upper);
  final interval = intervalBetween(lowerNote, upperNote);
  final options = _intervalOptions(interval);
  return _choice(
    id: 'interval:${interval.abbreviation}:${harmonic ? 'harmonic' : 'melodic'}',
    family: SkillFamily.theory,
    question: 'What interval is ${lowerNote.pitchClass} to ${upperNote.pitchClass}?',
    answers: options,
    correct: interval.name,
    hint: 'Count the staff steps, then check the semitones.',
  );
}

ObjectiveRef earIntervalConcept(
  String lower,
  String upper, {
  bool harmonic = false,
}) {
  final lowerNote = Note.parse(lower);
  final upperNote = Note.parse(upper);
  final interval = intervalBetween(lowerNote, upperNote);
  final options = _intervalOptions(interval);
  return _choice(
    id: 'ear:interval:${interval.abbreviation}:${harmonic ? 'harmonic' : 'melodic'}',
    family: SkillFamily.ear,
    question: 'Listen. Which interval do you hear?',
    answers: options,
    correct: interval.name,
    hint: 'Sing the lower note, then step up.',
    audio: SoundSpec.interval(lowerNote, upperNote, harmonic: harmonic),
  );
}

ObjectiveRef chordQualityConcept(String root, ChordQuality quality) {
  final chord = ChordSymbol(root: Note.parse('${root}4'), quality: quality);
  final options = _qualityOptions(quality);
  return _choice(
    id: 'chordquality:${chord.root.pitchClass}:${quality.name}',
    family: SkillFamily.theory,
    question: 'What kind of chord is ${chord.symbol}?',
    answers: options,
    correct: quality.label,
    hint: 'Check the third and the fifth.',
  );
}

ObjectiveRef earChordQualityConcept(String root, ChordQuality quality) {
  final chord = ChordSymbol(root: Note.parse('${root}4'), quality: quality);
  final options = _qualityOptions(quality);
  return _choice(
    id: 'ear:chordquality:${chord.root.pitchClass}:${quality.name}',
    family: SkillFamily.ear,
    question: 'Listen. What kind of chord do you hear?',
    answers: options,
    correct: quality.label,
    hint: 'Major sounds bright; minor sounds darker.',
    audio: SoundSpec.chord(chord.notes),
  );
}

ObjectiveRef romanNumeralConcept(String tonic, int degree, {bool minor = false}) {
  final key = KeySignature.of(tonic, minor: minor);
  final triads = diatonicTriads(key);
  final normalized = ((degree - 1) % 7) + 1;
  final triad = triads[normalized - 1];
  final options = _romanOptions(triads, triad.romanNumeral);
  return _choice(
    id: 'roman:${key.id}:${triad.romanNumeral}',
    family: SkillFamily.harmony,
    question: 'In ${key.display}, which chord is built on scale degree $normalized?',
    answers: options,
    correct: triad.romanNumeral,
    hint: 'The quality follows the key signature.',
  );
}

ObjectiveRef scaleDegreeConcept(String tonic, int degree, {bool minor = false}) {
  final key = KeySignature.of(tonic, minor: minor);
  final target = key.degree(degree);
  final options = _degreeOptions(key, target);
  return _choice(
    id: 'degree:${key.id}:$degree',
    family: SkillFamily.theory,
    question: 'Which note is scale degree $degree in ${key.display}?',
    answers: options,
    correct: target.pitchClass,
    hint: 'Spell the scale first, then count.',
  );
}

ObjectiveRef progressionConcept(
  String tonic,
  List<int> degrees, {
  bool minor = false,
  String? name,
}) {
  final key = KeySignature.of(tonic, minor: minor);
  final progression = Progression.diatonic(key, degrees, name: name);
  final options = _progressionOptions(progression);
  return _choice(
    id: 'progression:${progression.id}',
    family: SkillFamily.harmony,
    question: 'Which progression is ${progression.chordSymbols} in ${key.display}?',
    answers: options,
    correct: progression.display,
    hint: 'Name each chord by its scale degree.',
  );
}

ObjectiveRef earProgressionConcept(
  String tonic,
  List<int> degrees, {
  bool minor = false,
  String? name,
}) {
  final key = KeySignature.of(tonic, minor: minor);
  final progression = Progression.diatonic(key, degrees, name: name);
  final options = _progressionOptions(progression);
  return _choice(
    id: 'ear:progression:${progression.id}',
    family: SkillFamily.ear,
    question: 'Listen. Which progression do you hear?',
    answers: options,
    correct: progression.display,
    hint: 'Find the tonic, then hear the bass movement.',
    audio: SoundSpec.progression([
      for (final chord in progression.chords) chord.notes,
    ]),
  );
}

ObjectiveRef cadenceConcept(String tonic, CadenceType type, {bool minor = false}) {
  final key = KeySignature.of(tonic, minor: minor);
  final degrees = switch (type) {
    CadenceType.authentic => const [5, 1],
    CadenceType.plagal => const [4, 1],
    CadenceType.deceptive => const [5, 6],
    CadenceType.half => const [1, 5],
  };
  final progression = Progression.diatonic(key, degrees);
  final options = CadenceType.values.map((value) => value.label).toList();
  return _choice(
    id: 'cadence:${key.id}:${type.name}',
    family: SkillFamily.harmony,
    question: 'Which cadence is ${progression.chordSymbols} in ${key.display}?',
    answers: options,
    correct: type.label,
    hint: 'Look at the last two chords.',
  );
}

ObjectiveRef earCadenceConcept(String tonic, CadenceType type) {
  final key = KeySignature.major(tonic);
  final degrees = switch (type) {
    CadenceType.authentic => const [5, 1],
    CadenceType.plagal => const [4, 1],
    CadenceType.deceptive => const [5, 6],
    CadenceType.half => const [1, 5],
  };
  final progression = Progression.diatonic(key, degrees);
  final options = CadenceType.values.map((value) => value.label).toList();
  return _choice(
    id: 'ear:cadence:${key.id}:${type.name}',
    family: SkillFamily.ear,
    question: 'Listen. Which cadence do you hear?',
    answers: options,
    correct: type.label,
    hint: 'Does the phrase feel finished or suspended?',
    audio: SoundSpec.progression([
      for (final chord in progression.chords) chord.notes,
    ]),
  );
}

ObjectiveRef scaleConcept(
  String tonic,
  ScaleMode mode, {
  int degree = 3,
}) {
  final scale = Scale(root: Note.parse('${tonic}4'), mode: mode);
  final target = scale.degree(degree);
  final options = _scaleOptions(scale, target);
  return _choice(
    id: 'scale:${scale.id}:$degree',
    family: SkillFamily.theory,
    question: 'Which note is scale degree $degree of ${scale.display}?',
    answers: options,
    correct: target.pitchClass,
    hint: 'Use the mode pattern, not just the major scale.',
  );
}

ObjectiveRef earScaleDegreeConcept(String tonic, int degree) {
  final key = KeySignature.major(tonic);
  final target = key.degree(degree);
  final options = _degreeOptions(key, target);
  return _choice(
    id: 'ear:degree:${key.id}:$degree',
    family: SkillFamily.ear,
    question: 'Listen to the cadence, then name scale degree $degree.',
    answers: options,
    correct: target.pitchClass,
    hint: 'The cadence establishes the tonic.',
    audio: SoundSpec.sequence([
      key.degree(1),
      key.degree(5),
      key.degree(1),
      target,
    ], bpm: 70),
  );
}

ObjectiveRef circleOfFifthsConcept(String tonic) {
  final key = KeySignature.major(tonic);
  final dominant = KeySignature.major(_transposeTonic(tonic, 7));
  final subdominant = KeySignature.major(_transposeTonic(tonic, 5));
  final options = [dominant.display, subdominant.display, key.display, 'Relative minor'];
  return _choice(
    id: 'circle:${key.id}',
    family: SkillFamily.theory,
    question: 'Which key is the dominant of ${key.display}?',
    answers: options,
    correct: dominant.display,
    hint: 'The dominant is a perfect fifth above the tonic.',
  );
}

ObjectiveRef transpositionConcept(String fromTonic, String toTonic) {
  final from = KeySignature.major(fromTonic);
  final to = KeySignature.major(toTonic);
  final fromProgression = Progression.diatonic(from, const [1, 4, 5, 1]);
  final toProgression = Progression.diatonic(to, const [1, 4, 5, 1]);
  final options = [
    toProgression.chordSymbols,
    Progression.diatonic(to, const [1, 5, 6, 4]).chordSymbols,
    Progression.diatonic(to, const [2, 5, 1]).chordSymbols,
    fromProgression.chordSymbols,
  ];
  return _choice(
    id: 'transpose:${from.id}:${to.id}',
    family: SkillFamily.theory,
    question:
        'A I–IV–V–I progression in ${from.display} is ${fromProgression.chordSymbols}. What is it in ${to.display}?',
    answers: options,
    correct: toProgression.chordSymbols,
    hint: 'Keep the roman numerals and change the key.',
  );
}

ObjectiveRef meterConcept(String meter, int beats) {
  final correct = '$beats ${beats == 1 ? 'beat' : 'beats'}';
  final options = <String>{
    correct,
    '2 beats',
    '3 beats',
    '4 beats',
    '6 beats',
    '7 beats',
  }.take(4).toList();
  return _choice(
    id: 'meter:$meter',
    family: SkillFamily.theory,
    question: 'How many beats are in one $meter bar?',
    answers: options,
    correct: correct,
    hint: 'The top number tells you the beats per bar.',
  );
}

ObjectiveRef noteValueConcept(String name, double beats) {
  final correct = _beatsLabel(beats);
  final options = <String>[
    correct,
    _beatsLabel(0.5),
    _beatsLabel(1),
    _beatsLabel(2),
    _beatsLabel(4),
  ];
  return _choice(
    id: 'value:$name',
    family: SkillFamily.theory,
    question: 'How many beats does a $name last in 4/4?',
    answers: options,
    correct: correct,
    hint: 'A quarter note is one beat.',
  );
}

String _beatsLabel(double beats) {
  if (beats == 0.5) return 'half a beat';
  if (beats == 1) return '1 beat';
  if (beats == 1.5) return '1.5 beats';
  if (beats == 2) return '2 beats';
  if (beats == 3) return '3 beats';
  if (beats == 4) return '4 beats';
  return '${beats.toStringAsFixed(1)} beats';
}

ObjectiveRef techniqueConcept({
  required String id,
  required String question,
  required List<String> answers,
  required String correct,
  String? hint,
}) => _choice(
  id: 'technique:$id',
  family: SkillFamily.technique,
  question: question,
  answers: answers,
  correct: correct,
  hint: hint,
);

ObjectiveRef repertoireConcept({
  required String id,
  required String question,
  required List<String> answers,
  required String correct,
  String? hint,
}) => _choice(
  id: 'repertoire:$id',
  family: SkillFamily.repertoire,
  question: question,
  answers: answers,
  correct: correct,
  hint: hint,
);

ObjectiveRef sightReadingConcept({
  required String id,
  required String question,
  required List<String> answers,
  required String correct,
  String? hint,
}) => _choice(
  id: 'sightreading:$id',
  family: SkillFamily.sightReading,
  question: question,
  answers: answers,
  correct: correct,
  hint: hint,
);

ObjectiveRef improvisationConcept({
  required String id,
  required String question,
  required List<String> answers,
  required String correct,
  String? hint,
}) => _choice(
  id: 'improvisation:$id',
  family: SkillFamily.improvisation,
  question: question,
  answers: answers,
  correct: correct,
  hint: hint,
);

ObjectiveRef choiceConcept({
  required String id,
  required SkillFamily family,
  required String question,
  required List<String> answers,
  required String correct,
  String? hint,
  SoundSpec? audio,
}) => _choice(
  id: id,
  family: family,
  question: question,
  answers: answers,
  correct: correct,
  hint: hint,
  audio: audio,
);

/// A build-the-answer question: place [tokens] in [correctOrder].
ObjectiveRef orderConcept({
  required String id,
  required SkillFamily family,
  required String question,
  required List<String> tokens,
  required List<String> correctOrder,
}) => ObjectiveRef(
  id,
  family: family,
  data: {
    'question': question,
    'tokens': tokens,
    'correctOrder': correctOrder,
  },
);

// ---------------------------------------------------------------------------
// Helpers

ObjectiveRef _choice({
  required String id,
  required SkillFamily family,
  required String question,
  required List<String> answers,
  required String correct,
  String? hint,
  ChordShape? chord,
  SoundSpec? audio,
}) {
  final unique = <String>[];
  for (final answer in answers) {
    if (!unique.contains(answer)) unique.add(answer);
  }
  final correctIndex = unique.indexOf(correct);
  if (correctIndex < 0) {
    throw ArgumentError('Correct answer "$correct" is not in $unique for $id');
  }
  return choiceObjective(
    id: id,
    family: family,
    question: question,
    answers: unique,
    correctIndex: correctIndex,
    hint: hint,
    chord: chord,
    audio: audio,
  );
}

List<String> _distractors(List<String> all, String correct, {int count = 4}) {
  final others = all.where((value) => value != correct).toList();
  final selected = <String>[correct];
  for (var index = 0; index < others.length && selected.length < count; index++) {
    selected.add(others[index]);
  }
  return selected;
}

List<String> _intervalOptions(Interval correct) {
  final options = <String>[correct.name];
  for (final interval in Interval.simple) {
    if (options.length >= 4) break;
    if (interval.name != correct.name) options.add(interval.name);
  }
  return options;
}

List<String> _qualityOptions(ChordQuality correct) {
  final options = <String>[correct.label];
  for (final quality in ChordQuality.values) {
    if (options.length >= 4) break;
    if (quality.label != correct.label) options.add(quality.label);
  }
  return options;
}

List<String> _nearbyCounts(KeySignature key) {
  final correct = key.accidentalCount;
  final labels = <String>[];
  for (var delta = -1; delta <= 2; delta++) {
    final count = (correct + delta).clamp(0, 7);
    labels.add(
      count == 0
          ? 'no sharps or flats'
          : count == 1
          ? (key.isFlat ? '1 flat' : '1 sharp')
          : '$count ${key.isFlat ? 'flats' : 'sharps'}',
    );
  }
  return labels;
}

List<String> _romanOptions(List<DiatonicChord> triads, String correct) {
  final options = <String>[correct];
  for (final triad in triads) {
    if (options.length >= 4) break;
    if (triad.romanNumeral != correct) options.add(triad.romanNumeral);
  }
  return options;
}

List<String> _degreeOptions(KeySignature key, Note correct) {
  final options = <String>[correct.pitchClass];
  for (var degree = 1; degree <= 7; degree++) {
    if (options.length >= 4) break;
    final pitch = key.degree(degree).pitchClass;
    if (!options.contains(pitch)) options.add(pitch);
  }
  return options;
}

List<String> _progressionOptions(Progression correct) {
  final options = <String>[correct.display];
  final alternatives = [
    'I–V–vi–IV',
    'ii–V–I',
    'I–IV–V–I',
    'vi–IV–I–V',
  ];
  for (final alternative in alternatives) {
    if (options.length >= 4) break;
    if (!options.contains(alternative)) options.add(alternative);
  }
  return options;
}

List<String> _scaleOptions(Scale scale, Note correct) {
  final options = <String>[correct.pitchClass];
  for (var degree = 1; degree <= scale.semitones.length - 1; degree++) {
    if (options.length >= 4) break;
    final pitch = scale.degree(degree).pitchClass;
    if (!options.contains(pitch)) options.add(pitch);
  }
  return options;
}

String _transposeTonic(String tonic, int semitones) {
  final note = Note.parse('${tonic}4');
  final transposed = note.transposed(semitones);
  return transposed.pitchClass;
}

/// The scale positions used by the fretboard units.
const Map<int, List<int>> cagedRootFrets = {
  1: [0, 3, 5, 7, 10],
  2: [1, 5, 7, 9, 12],
  3: [2, 5, 7, 10, 12],
  4: [3, 5, 8, 10, 12],
  5: [5, 7, 10, 12, 15],
};

int noteAtFret(int stringNumber, int fret) =>
    Guitar.soundingNoteAt(stringNumber, fret).midi;
