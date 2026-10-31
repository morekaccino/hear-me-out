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

  /// A checkpoint lesson at the end of a unit.
  final bool isReview;
}

class UnitDefinition {
  const UnitDefinition({
    required this.id,
    required this.number,
    required this.title,
    required this.focus,
    required this.lessons,
  });

  final String id;
  final int number;
  final String title;

  /// The unit's single learning focus, shown on the path.
  final String focus;

  final List<LessonDefinition> lessons;

  List<Note> get newNotes => _uniqueNotes([
    for (final lesson in lessons) ...lesson.newNotes,
  ]);

  bool get hasNewNotes => newNotes.isNotEmpty;
}

class SectionDefinition {
  const SectionDefinition({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.units,
  });

  final String id;
  final int number;
  final String title;
  final String subtitle;
  final List<UnitDefinition> units;
}

Note _n(String value) => Note.parse(value);

final List<Note> _staffNotes = [
  _n('E4'),
  _n('F4'),
  _n('G4'),
  _n('A4'),
  _n('B4'),
  _n('C5'),
  _n('D5'),
  _n('E5'),
];

final List<Note> _lowNotes = [
  _n('E3'),
  _n('F3'),
  _n('G3'),
  _n('A3'),
  _n('B3'),
];

final List<Note> _belowStaffNotes = [
  _n('C4'),
  _n('D4'),
  _n('E4'),
  _n('F4'),
  _n('G4'),
  _n('A4'),
];

final List<Note> _allNaturalNotes = _uniqueNotes([
  ..._lowNotes,
  ..._belowStaffNotes,
  ..._staffNotes,
]);

final List<Note> _accidentalNotes = [_n('F#4'), _n('C#5'), _n('Bb4')];

final UnitDefinition _unitOne = UnitDefinition(
  id: 'u1',
  number: 1,
  title: 'The Staff',
  focus: 'Read notes on and around the treble staff',
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
      reviewNotes: _staffNotes,
      isReview: true,
    ),
  ],
);

final UnitDefinition _unitTwo = UnitDefinition(
  id: 'u2',
  number: 2,
  title: 'High Strings',
  focus: 'The B string and high E string, plus high F',
  lessons: [
    LessonDefinition(
      id: 'u2l1',
      unitId: 'u2',
      title: 'B and C again',
      newNotes: const [],
      reviewNotes: [_n('B4'), _n('C5'), ..._staffNotes],
    ),
    LessonDefinition(
      id: 'u2l2',
      unitId: 'u2',
      title: 'D and E again',
      newNotes: const [],
      reviewNotes: [_n('D5'), _n('E5'), ..._staffNotes],
    ),
    LessonDefinition(
      id: 'u2l3',
      unitId: 'u2',
      title: 'High F',
      newNotes: [_n('F5')],
      reviewNotes: [_n('B4'), _n('C5'), _n('D5'), _n('E5')],
    ),
    LessonDefinition(
      id: 'u2l4',
      unitId: 'u2',
      title: 'High-string review',
      newNotes: const [],
      reviewNotes: [_n('B4'), _n('C5'), _n('D5'), _n('E5'), _n('F5')],
      isReview: true,
    ),
  ],
);

final UnitDefinition _unitThree = UnitDefinition(
  id: 'u3',
  number: 3,
  title: 'Below the Staff',
  focus: 'Read C4 and D4 below the staff',
  lessons: [
    LessonDefinition(
      id: 'u3l1',
      unitId: 'u3',
      title: 'C and D below',
      newNotes: [_n('C4'), _n('D4')],
      reviewNotes: [_n('E4'), _n('F4'), _n('G4'), _n('A4')],
    ),
    LessonDefinition(
      id: 'u3l2',
      unitId: 'u3',
      title: 'E and F again',
      newNotes: const [],
      reviewNotes: [_n('C4'), _n('D4'), _n('E4'), _n('F4')],
    ),
    LessonDefinition(
      id: 'u3l3',
      unitId: 'u3',
      title: 'G and A again',
      newNotes: const [],
      reviewNotes: [_n('E4'), _n('F4'), _n('G4'), _n('A4')],
    ),
    LessonDefinition(
      id: 'u3l4',
      unitId: 'u3',
      title: 'Below-staff review',
      newNotes: const [],
      reviewNotes: _belowStaffNotes,
      isReview: true,
    ),
  ],
);

final UnitDefinition _unitFour = UnitDefinition(
  id: 'u4',
  number: 4,
  title: 'Low Strings',
  focus: 'Read the low E and A strings in first position',
  lessons: [
    LessonDefinition(
      id: 'u4l1',
      unitId: 'u4',
      title: 'A and B low',
      newNotes: [_n('A3'), _n('B3')],
      reviewNotes: [_n('E3'), _n('F3'), _n('G3')],
    ),
    LessonDefinition(
      id: 'u4l2',
      unitId: 'u4',
      title: 'Low E and F',
      newNotes: [_n('E3'), _n('F3')],
      reviewNotes: [_n('A3'), _n('B3'), ..._belowStaffNotes],
    ),
    LessonDefinition(
      id: 'u4l3',
      unitId: 'u4',
      title: 'G below',
      newNotes: [_n('G3')],
      reviewNotes: [_n('E3'), _n('F3'), _n('A3'), _n('B3')],
    ),
    LessonDefinition(
      id: 'u4l4',
      unitId: 'u4',
      title: 'Low-string review',
      newNotes: const [],
      reviewNotes: _lowNotes,
      isReview: true,
    ),
  ],
);

final UnitDefinition _unitFive = UnitDefinition(
  id: 'u5',
  number: 5,
  title: 'First Position',
  focus: 'Mix every first-position note across all six strings',
  lessons: [
    LessonDefinition(
      id: 'u5l1',
      unitId: 'u5',
      title: 'Lower half',
      newNotes: const [],
      reviewNotes: [_n('C4'), _n('D4'), _n('E4'), _n('F4')],
    ),
    LessonDefinition(
      id: 'u5l2',
      unitId: 'u5',
      title: 'Upper half',
      newNotes: const [],
      reviewNotes: [_n('G4'), _n('A4'), _n('B4'), _n('C5'), _n('D5'), _n('E5'), _n('F5')],
    ),
    LessonDefinition(
      id: 'u5l3',
      unitId: 'u5',
      title: 'Full position',
      newNotes: const [],
      reviewNotes: _allNaturalNotes,
    ),
    LessonDefinition(
      id: 'u5l4',
      unitId: 'u5',
      title: 'First-position checkpoint',
      newNotes: const [],
      reviewNotes: _allNaturalNotes,
      isReview: true,
    ),
  ],
);

final UnitDefinition _unitSix = UnitDefinition(
  id: 'u6',
  number: 6,
  title: 'Accidentals',
  focus: 'Add sharps and flats to the staff',
  lessons: [
    LessonDefinition(
      id: 'u6l1',
      unitId: 'u6',
      title: 'F sharp',
      newNotes: [_n('F#4')],
      reviewNotes: _allNaturalNotes,
    ),
    LessonDefinition(
      id: 'u6l2',
      unitId: 'u6',
      title: 'C sharp',
      newNotes: [_n('C#5')],
      reviewNotes: [_n('F#4'), ..._allNaturalNotes],
    ),
    LessonDefinition(
      id: 'u6l3',
      unitId: 'u6',
      title: 'B flat',
      newNotes: [_n('Bb4')],
      reviewNotes: [_n('F#4'), _n('C#5'), ..._allNaturalNotes],
    ),
    LessonDefinition(
      id: 'u6l4',
      unitId: 'u6',
      title: 'Accidental review',
      newNotes: const [],
      reviewNotes: [..._accidentalNotes, ..._allNaturalNotes],
      isReview: true,
    ),
  ],
);

final List<SectionDefinition> sections = [
  SectionDefinition(
    id: 's1',
    number: 1,
    title: 'Foundations',
    subtitle: 'Read the staff and find the first notes',
    units: [_unitOne, _unitTwo, _unitThree],
  ),
  SectionDefinition(
    id: 's2',
    number: 2,
    title: 'First Position',
    subtitle: 'Play across all six strings without moving your hand',
    units: [_unitFour, _unitFive],
  ),
  SectionDefinition(
    id: 's3',
    number: 3,
    title: 'Accidentals',
    subtitle: 'Add sharps and flats to the staff',
    units: [_unitSix],
  ),
];

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

/// Every note that can appear as an answer option.
final List<Note> noteCatalog = _uniqueNotes([
  ..._allNaturalNotes,
  ..._accidentalNotes,
  _n('G#4'),
]);

/// Old lesson IDs from the 4-unit curriculum. Existing progress is mapped
/// through this table so notes, XP, and completed lessons are preserved.
const Map<String, String> legacyLessonIdMap = {
  'u2l1': 'u3l1', // old C4 -> new C/D below
  'u2l2': 'u3l1', // old D4 -> new C/D below
  'u2l3': 'u2l3', // high F stayed in place
  'u2l4': 'u5l4', // old first-position review -> first-position checkpoint
  'u3l1': 'u4l1', // old low A/B -> low strings
  'u3l2': 'u4l2', // old low E/F -> low strings
  'u3l3': 'u4l3', // old low G -> low strings
  'u3l4': 'u4l4', // old low review -> low checkpoint
  'u4l1': 'u6l1', // old F sharp -> accidentals
  'u4l2': 'u6l2', // old C sharp -> accidentals
  'u4l3': 'u6l3', // old B flat -> accidentals
  'u4l4': 'u6l4', // old accidental review -> accidental checkpoint
};

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
