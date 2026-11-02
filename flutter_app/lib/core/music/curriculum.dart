import 'dart:math';

import '../learning/course/course_builder.dart';
import 'curriculum_model.dart';
import 'note.dart';

export 'curriculum_model.dart';

/// The generated 8-section / 40-unit / 240-lesson course.
final List<SectionDefinition> sections = buildCourseSections();

final List<UnitDefinition> curriculum = [
  for (final section in sections) ...section.units,
];

final List<LessonDefinition> allLessons = [
  for (final unit in curriculum) ...unit.lessons,
];

final Map<String, LessonDefinition> lessonById = {
  for (final lesson in allLessons) lesson.id: lesson,
};

final Map<String, UnitDefinition> unitById = {
  for (final unit in curriculum) unit.id: unit,
};

/// One chest per unit. The generated course puts it after the unit's third
/// lesson, so it unlocks halfway through the unit.
final List<ChestDefinition> chests = buildCourseChests();

final Map<String, ChestDefinition> chestById = {
  for (final chest in chests) chest.id: chest,
};

ChestDefinition? chestForUnit(String unitId) {
  for (final chest in chests) {
    if (chest.unitId == unitId) return chest;
  }
  return null;
}

/// Every note that can appear as an answer option.
final List<Note> noteCatalog = _uniqueNotes([
  _n('E3'),
  _n('F3'),
  _n('G3'),
  _n('A3'),
  _n('B3'),
  _n('C4'),
  _n('D4'),
  _n('E4'),
  _n('F4'),
  _n('G4'),
  _n('A4'),
  _n('B4'),
  _n('C5'),
  _n('D5'),
  _n('E5'),
  _n('F5'),
  _n('F#4'),
  _n('G#4'),
  _n('C#5'),
  _n('Bb4'),
]);

Note _n(String value) => Note.parse(value);

List<Note> _uniqueNotes(List<Note> notes) {
  final seen = <String>{};
  return [
    for (final note in notes)
      if (seen.add(note.id)) note,
  ];
}

/// Plausible answer buttons for the current note, including [correct].
///
/// [guided] adds one distant option, so a learner meeting a note for the first
/// time chooses between ideas rather than between neighbouring staff steps.
List<Note> answerChoices(
  Note correct, {
  int count = 4,
  bool guided = false,
  Random? random,
}) {
  final rng = random ?? Random();
  final source = correct.accidental == Accidental.natural
      ? noteCatalog.where((note) => note.accidental == Accidental.natural)
      : noteCatalog;
  final candidates = [...source]..removeWhere((note) => note.id == correct.id);
  candidates.sort((a, b) {
    final distanceA = (a.diatonicIndex - correct.diatonicIndex).abs();
    final distanceB = (b.diatonicIndex - correct.diatonicIndex).abs();
    if (distanceA != distanceB) return distanceA.compareTo(distanceB);
    final accidentalA = a.accidental == correct.accidental ? 0 : 1;
    final accidentalB = b.accidental == correct.accidental ? 0 : 1;
    if (accidentalA != accidentalB) return accidentalA.compareTo(accidentalB);
    return a.id.compareTo(b.id);
  });

  final chosen = <Note>[];
  if (guided && candidates.length > 3) {
    final far = candidates.sublist(candidates.length ~/ 2)..shuffle(rng);
    chosen.add(far.first);
  }
  final nearby = candidates.take(8).toList()..shuffle(rng);
  for (final note in nearby) {
    if (chosen.length >= count - 1) break;
    if (chosen.any((candidate) => candidate.id == note.id)) continue;
    chosen.add(note);
  }

  final options = [...chosen, correct]..shuffle(rng);
  return options;
}

/// Old lesson IDs from the 40-lesson curriculum. Existing progress is mapped
/// through this table so notes, XP, and completed lessons are preserved.
const Map<String, String> legacyLessonIdMap = {
  'u1l1': 'c3u4l1',
  'u1l2': 'c3u4l2',
  'u1l3': 'c3u4l3',
  'u1l4': 'c3u4l4',
  'u1l5': 'c3u4l6',
  'u2l1': 'c3u4l1',
  'u2l2': 'c3u4l2',
  'u2l3': 'c3u4l4',
  'u2l4': 'c3u4l6',
  'u3l1': 'c3u3l1',
  'u3l2': 'c3u3l2',
  'u3l3': 'c3u3l3',
  'u3l4': 'c3u3l6',
  'u4l1': 'c3u3l1',
  'u4l2': 'c3u3l2',
  'u4l3': 'c3u3l3',
  'u4l4': 'c3u3l6',
  'u5l1': 'c3u10l1',
  'u5l2': 'c3u10l1',
  'u5l3': 'c3u10l2',
  'u5l4': 'c3u10l6',
  'u6l1': 'c3u7l1',
  'u6l2': 'c3u7l1',
  'u6l3': 'c3u7l1',
  'u6l4': 'c3u7l6',
  'u7l1': 'c3u8l1',
  'u7l2': 'c3u8l1',
  'u7l3': 'c3u8l1',
  'u7l4': 'c3u8l6',
  'u8l1': 'c3u20l1',
  'u8l2': 'c3u20l6',
  'u9l1': 'c3u16l1',
  'u9l2': 'c3u16l1',
  'u9l3': 'c3u16l1',
  'u9l4': 'c3u16l6',
  'u10l1': 'c3u5l1',
  'u10l2': 'c3u5l1',
  'u10l3': 'c3u5l1',
  'u10l4': 'c3u5l1',
  'u10l5': 'c3u5l6',
};
