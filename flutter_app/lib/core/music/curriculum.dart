import 'dart:math';

import 'note.dart';

class LessonDefinition {
  const LessonDefinition({
    required this.id,
    required this.unitId,
    required this.title,
    required this.newNotes,
    required this.reviewNotes,
    this.isReview = false,
  });

  final String id;
  final String unitId;
  final String title;

  /// Notes introduced by this lesson. At most two.
  final List<Note> newNotes;

  /// Notes that may appear as review material.
  final List<Note> reviewNotes;

  final bool isReview;
}

class UnitDefinition {
  const UnitDefinition({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.lessons,
  });

  final String id;
  final int number;
  final String title;
  final String subtitle;
  final List<LessonDefinition> lessons;
}

Note _n(String value) => Note.parse(value);

final List<Note> _unitOneNotes = [
  _n('E4'),
  _n('F4'),
  _n('G4'),
  _n('A4'),
  _n('B4'),
  _n('C5'),
  _n('D5'),
  _n('E5'),
];

final List<Note> _unitTwoNotes = [
  ..._unitOneNotes,
  _n('C4'),
  _n('D4'),
  _n('F5'),
];

final List<Note> _lowNotes = [_n('E3'), _n('F3'), _n('G3'), _n('A3'), _n('B3')];

final List<Note> _naturalNotes = [..._unitTwoNotes, ..._lowNotes];

final List<UnitDefinition> curriculum = [
  UnitDefinition(
    id: 'u1',
    number: 1,
    title: 'Read the Staff',
    subtitle: 'Find your first notes in treble clef',
    lessons: [
      LessonDefinition(
        id: 'u1l1',
        unitId: 'u1',
        title: 'E and F',
        newNotes: [_n('E4'), _n('F4')],
        reviewNotes: const [],
      ),
      LessonDefinition(
        id: 'u1l2',
        unitId: 'u1',
        title: 'G and A',
        newNotes: [_n('G4'), _n('A4')],
        reviewNotes: [_n('E4'), _n('F4')],
      ),
      LessonDefinition(
        id: 'u1l3',
        unitId: 'u1',
        title: 'B and C',
        newNotes: [_n('B4'), _n('C5')],
        reviewNotes: [_n('E4'), _n('F4'), _n('G4'), _n('A4')],
      ),
      LessonDefinition(
        id: 'u1l4',
        unitId: 'u1',
        title: 'D and E',
        newNotes: [_n('D5'), _n('E5')],
        reviewNotes: [
          _n('E4'),
          _n('F4'),
          _n('G4'),
          _n('A4'),
          _n('B4'),
          _n('C5'),
        ],
      ),
      LessonDefinition(
        id: 'u1l5',
        unitId: 'u1',
        title: 'Staff review',
        newNotes: const [],
        reviewNotes: _unitOneNotes,
        isReview: true,
      ),
    ],
  ),
  UnitDefinition(
    id: 'u2',
    number: 2,
    title: 'First Position',
    subtitle: 'Extend your range without moving your hand',
    lessons: [
      LessonDefinition(
        id: 'u2l1',
        unitId: 'u2',
        title: 'Middle C',
        newNotes: [_n('C4')],
        reviewNotes: _unitOneNotes,
      ),
      LessonDefinition(
        id: 'u2l2',
        unitId: 'u2',
        title: 'D below the staff',
        newNotes: [_n('D4')],
        reviewNotes: [_n('C4'), ..._unitOneNotes],
      ),
      LessonDefinition(
        id: 'u2l3',
        unitId: 'u2',
        title: 'High F',
        newNotes: [_n('F5')],
        reviewNotes: [_n('C4'), _n('D4'), ..._unitOneNotes],
      ),
      LessonDefinition(
        id: 'u2l4',
        unitId: 'u2',
        title: 'First position review',
        newNotes: const [],
        reviewNotes: _unitTwoNotes,
        isReview: true,
      ),
    ],
  ),
  UnitDefinition(
    id: 'u3',
    number: 3,
    title: 'Low Strings',
    subtitle: 'Read the notes below the staff',
    lessons: [
      LessonDefinition(
        id: 'u3l1',
        unitId: 'u3',
        title: 'A and B below',
        newNotes: [_n('A3'), _n('B3')],
        reviewNotes: _unitTwoNotes,
      ),
      LessonDefinition(
        id: 'u3l2',
        unitId: 'u3',
        title: 'Low E and F',
        newNotes: [_n('E3'), _n('F3')],
        reviewNotes: [_n('A3'), _n('B3'), ..._unitTwoNotes],
      ),
      LessonDefinition(
        id: 'u3l3',
        unitId: 'u3',
        title: 'G below',
        newNotes: [_n('G3')],
        reviewNotes: [_n('E3'), _n('F3'), _n('A3'), _n('B3'), ..._unitTwoNotes],
      ),
      LessonDefinition(
        id: 'u3l4',
        unitId: 'u3',
        title: 'Low string review',
        newNotes: const [],
        reviewNotes: _naturalNotes,
        isReview: true,
      ),
    ],
  ),
  UnitDefinition(
    id: 'u4',
    number: 4,
    title: 'Accidentals',
    subtitle: 'Sharps and flats on the staff',
    lessons: [
      LessonDefinition(
        id: 'u4l1',
        unitId: 'u4',
        title: 'F sharp',
        newNotes: [_n('F#4')],
        reviewNotes: _naturalNotes,
      ),
      LessonDefinition(
        id: 'u4l2',
        unitId: 'u4',
        title: 'C sharp',
        newNotes: [_n('C#5')],
        reviewNotes: [_n('F#4'), ..._naturalNotes],
      ),
      LessonDefinition(
        id: 'u4l3',
        unitId: 'u4',
        title: 'B flat',
        newNotes: [_n('Bb4')],
        reviewNotes: [_n('F#4'), _n('C#5'), ..._naturalNotes],
      ),
      LessonDefinition(
        id: 'u4l4',
        unitId: 'u4',
        title: 'Accidental review',
        newNotes: const [],
        reviewNotes: [_n('F#4'), _n('C#5'), _n('Bb4'), ..._naturalNotes],
        isReview: true,
      ),
    ],
  ),
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

/// Every note that can appear as an answer option.
final List<Note> noteCatalog = _uniqueNotes([
  ..._naturalNotes,
  _n('F#4'),
  _n('C#5'),
  _n('Bb4'),
  _n('G#4'),
]);

List<Note> _uniqueNotes(List<Note> notes) {
  final seen = <String>{};
  return [
    for (final note in notes)
      if (seen.add(note.id)) note,
  ];
}

/// Plausible answer buttons for the current note, including [correct].
List<Note> answerChoices(Note correct, {int count = 4, Random? random}) {
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

  final nearby = candidates.take(8).toList()..shuffle(rng);
  final chosen = nearby.take(count - 1).toList();
  final options = [...chosen, correct]..shuffle(rng);
  return options;
}
