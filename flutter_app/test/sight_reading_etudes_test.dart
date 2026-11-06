import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/score/authoring.dart';
import 'package:hear_me_out/core/music/guitar.dart';
import 'package:hear_me_out/core/music/note_event.dart';
import 'package:hear_me_out/core/music/phrase.dart';
import 'package:hear_me_out/core/music/piece.dart';
import 'package:hear_me_out/core/music/score.dart';

import '../tool/content/validate_piece.dart';

const String etudeRoot = 'assets/content/etudes';
const String expectedReview =
    'Machine validation and rubric review; human playtest pending T3.8';

/// Key signatures used by the set. Only the five keys named in T3.6 are
/// allowed; the accidental checks derive from these pitch-class sets.
const Map<String, Set<int>> keyPitchClasses = <String, Set<int>>{
  'C major': <int>{0, 2, 4, 5, 7, 9, 11},
  'G major': <int>{7, 9, 11, 0, 2, 4, 6},
  'D major': <int>{2, 4, 6, 7, 9, 11, 1},
  'A minor': <int>{9, 11, 0, 2, 4, 5, 7},
  'E minor': <int>{4, 6, 7, 9, 11, 0, 2},
};

const Map<String, int> keyTonicClasses = <String, int>{
  'C major': 0,
  'G major': 7,
  'D major': 2,
  'A minor': 9,
  'E minor': 4,
};

const Map<int, ({int stage, String tier, int tempo})> levelRubric =
    <int, ({int stage, String tier, int tempo})>{
      1: (stage: 1, tier: 'foundation', tempo: 60),
      2: (stage: 2, tier: 'foundation', tempo: 66),
      3: (stage: 3, tier: 'foundation', tempo: 72),
      4: (stage: 5, tier: 'returner', tempo: 76),
      5: (stage: 9, tier: 'returner', tempo: 70),
    };

class LoadedEtude {
  const LoadedEtude({
    required this.level,
    required this.number,
    required this.file,
    required this.document,
  });

  final int level;
  final int number;
  final File file;
  final AuthoringDocument document;

  Score get score => document.score;

  AuthoringMeta get meta => document.meta!;

  String get id => score.piece.id;

  List<NoteEvent> get notes => <NoteEvent>[
    for (final phrase in score.phrases) ...phrase.notes,
  ];

  List<NoteEvent> get events => <NoteEvent>[
    for (final phrase in score.phrases) ...phrase.events,
  ];

  int get totalBars =>
      score.phrases.fold<int>(0, (sum, phrase) => sum + phrase.bars);
}

List<File> _filesForLevel(int level) {
  final directory = Directory('$etudeRoot/level_$level');
  if (!directory.existsSync()) {
    throw StateError('Missing etude directory ${directory.path}');
  }
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

LoadedEtude _loadEtude(int level, int number, File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw StateError('${file.path} is not a JSON object');
  }
  final raw = Map<String, dynamic>.from(decoded);
  return LoadedEtude(
    level: level,
    number: number,
    file: file,
    document: parseAuthoringDocument(raw),
  );
}

String _describeIssues(Iterable<ScoreIssue> issues) =>
    issues.map((issue) => issue.toString()).join('\n');

Set<int> _accidentalPitchClasses(LoadedEtude etude) {
  final key = etude.score.piece.key;
  final signature = keyPitchClasses[key];
  if (signature == null) {
    throw StateError('${etude.id} uses unsupported key $key');
  }
  final pitchClasses = <int>{
    for (final note in etude.notes) note.writtenNote!.midi % 12,
  };
  return pitchClasses.difference(signature);
}

List<({bool first, bool second})> _phrasePositions(LoadedEtude etude) {
  return <({bool first, bool second})>[
    for (final phrase in etude.score.phrases)
      (
        first: phrase.notes.any((note) => note.fret! <= 1),
        second: phrase.notes.any((note) => note.fret! >= 4),
      ),
  ];
}

int _positionShifts(LoadedEtude etude) {
  final positions = _phrasePositions(etude);
  var shifts = 0;
  for (var index = 1; index < positions.length; index++) {
    final previous = positions[index - 1];
    final current = positions[index];
    final leftFirst = previous.first && !previous.second;
    final leftSecond = previous.second && !previous.first;
    final rightFirst = current.first && !current.second;
    final rightSecond = current.second && !current.first;
    if ((leftFirst && rightSecond) || (leftSecond && rightFirst)) {
      shifts++;
    }
  }
  return shifts;
}

String _rhythmSignature(Phrase phrase) {
  return phrase.events
      .map((event) => '${event.durationBeats}:${event.kind.name}')
      .join(',');
}

const Set<String> allowedSkillTags = <String>{
  'note-reading.open-strings',
  'note-reading.first-position',
  'note-reading.second-position',
  'rhythm.quarter-notes',
  'rhythm.eighth-notes',
  'rhythm.half-notes',
  'rhythm.dotted-rhythms',
  'rhythm.rests',
  'technique.accidentals',
  'technique.position-shift',
  'sightreading.phrase-endings',
  'sightreading.rhythmic-motif',
  'sightreading.fluency',
};

Set<int> _phraseAccidentalPitchClasses(LoadedEtude etude, Phrase phrase) {
  final signature = keyPitchClasses[etude.score.piece.key]!;
  final pitchClasses = <int>{
    for (final note in phrase.notes) note.writtenNote!.midi % 12,
  };
  return pitchClasses.difference(signature);
}

void expectPhraseSkills(LoadedEtude etude) {
  final signatures = etude.score.phrases.map(_rhythmSignature).toList();

  for (var index = 0; index < etude.score.phrases.length; index++) {
    final phrase = etude.score.phrases[index];
    final tags = phrase.skills;
    final frets = <int>[for (final note in phrase.notes) note.fret!];
    final durations = <double>{
      for (final event in phrase.events) event.durationBeats,
    };

    expect(tags, isNotEmpty, reason: '${phrase.id}: empty skills');
    expect(
      tags.toSet(),
      hasLength(tags.length),
      reason: '${phrase.id}: duplicate skill tag',
    );
    for (final tag in tags) {
      expect(
        allowedSkillTags,
        contains(tag),
        reason: '${phrase.id}: unknown skill tag $tag',
      );
    }

    if (tags.contains('note-reading.first-position')) {
      expect(
        tags,
        isNot(contains('note-reading.second-position')),
        reason:
            '${phrase.id}: first-position phrase cannot claim second position',
      );
      expect(
        tags,
        isNot(contains('technique.position-shift')),
        reason: '${phrase.id}: first-position phrase cannot claim a shift',
      );
      final ceiling = etude.level >= 4
          ? 3
          : etude.level == 1
          ? 3
          : 5;
      expect(
        frets.every((fret) => fret <= ceiling),
        isTrue,
        reason:
            '${phrase.id}: first-position frets must stay at or below $ceiling',
      );
    }

    if (tags.contains('note-reading.second-position')) {
      expect(
        frets.every((fret) => fret >= 2 && fret <= 5),
        isTrue,
        reason: '${phrase.id}: second-position frets must stay in 2-5',
      );
      expect(
        frets.any((fret) => fret >= 4),
        isTrue,
        reason: '${phrase.id}: second-position phrase needs a fret 4-5 note',
      );
      expect(
        frets.any((fret) => fret <= 1),
        isFalse,
        reason:
            '${phrase.id}: second-position phrase cannot include first position',
      );
    }

    if (tags.contains('technique.position-shift')) {
      expect(
        frets.any((fret) => fret >= 4),
        isTrue,
        reason: '${phrase.id}: a shift tag needs a second-position note',
      );
    }

    if (tags.contains('note-reading.open-strings')) {
      expect(
        frets.any((fret) => fret == 0),
        isTrue,
        reason: '${phrase.id}: open-string tag needs a fret 0 note',
      );
    }

    if (tags.contains('rhythm.eighth-notes')) {
      expect(
        durations.any((duration) => (duration - 0.5).abs() < 1e-9),
        isTrue,
        reason: '${phrase.id}: eighth-note tag needs an eighth note',
      );
    }
    if (tags.contains('rhythm.quarter-notes')) {
      expect(
        durations.any((duration) => (duration - 1.0).abs() < 1e-9),
        isTrue,
        reason: '${phrase.id}: quarter-note tag needs a quarter note',
      );
    }
    if (tags.contains('rhythm.half-notes')) {
      expect(
        durations.any((duration) => (duration - 2.0).abs() < 1e-9),
        isTrue,
        reason: '${phrase.id}: half-note tag needs a half note',
      );
    }
    if (tags.contains('rhythm.dotted-rhythms')) {
      expect(
        durations.any(
          (duration) =>
              (duration - 1.5).abs() < 1e-9 || (duration - 3.0).abs() < 1e-9,
        ),
        isTrue,
        reason: '${phrase.id}: dotted-rhythm tag needs a dotted value',
      );
    }
    if (tags.contains('rhythm.rests')) {
      expect(
        phrase.events.any((event) => event.isRest),
        isTrue,
        reason: '${phrase.id}: rest tag needs a rest',
      );
    }
    if (tags.contains('technique.accidentals')) {
      expect(
        _phraseAccidentalPitchClasses(etude, phrase),
        isNotEmpty,
        reason: '${phrase.id}: accidental tag needs a note outside the key',
      );
    }
    if (tags.contains('sightreading.rhythmic-motif')) {
      final signature = _rhythmSignature(phrase);
      expect(
        signatures.where((value) => value == signature).length,
        greaterThanOrEqualTo(2),
        reason: '${phrase.id}: rhythmic-motif tag needs a repeated rhythm',
      );
    }
    if (tags.contains('sightreading.phrase-endings')) {
      final notes = phrase.notes;
      expect(notes.length, greaterThanOrEqualTo(2), reason: phrase.id);
      final interval =
          (notes.last.writtenNote!.midi -
                  notes[notes.length - 2].writtenNote!.midi)
              .abs();
      expect(
        interval,
        inInclusiveRange(1, 2),
        reason: '${phrase.id}: phrase-ending tag needs a step or half-step',
      );
    }
  }
}

void expectCadence(LoadedEtude etude) {
  final notes = etude.notes;
  expect(notes.length, greaterThanOrEqualTo(2), reason: etude.id);
  final tonic = keyTonicClasses[etude.score.piece.key]!;
  expect(
    notes.last.writtenNote!.midi % 12,
    tonic,
    reason: '${etude.id}: the etude must end on the tonic',
  );
  final finalInterval =
      (notes.last.writtenNote!.midi - notes[notes.length - 2].writtenNote!.midi)
          .abs();
  expect(
    finalInterval,
    inInclusiveRange(1, 2),
    reason:
        '${etude.id}: the last two notes must form a step or half-step cadence',
  );
}

void main() {
  late final List<LoadedEtude> etudes;

  setUpAll(() {
    etudes = <LoadedEtude>[
      for (var level = 1; level <= 5; level++)
        for (var index = 0; index < _filesForLevel(level).length; index++)
          _loadEtude(level, index + 1, _filesForLevel(level)[index]),
    ];
  });

  test('ships 12 etudes per level and 60 in total with unique ids', () {
    expect(etudes, hasLength(60));
    for (var level = 1; level <= 5; level++) {
      expect(
        etudes.where((etude) => etude.level == level),
        hasLength(12),
        reason: 'level $level must contain exactly 12 etudes',
      );
    }

    final pieceIds = etudes.map((etude) => etude.id).toList();
    expect(pieceIds.toSet(), hasLength(pieceIds.length));

    final phraseIds = <String>[
      for (final etude in etudes)
        for (final phrase in etude.score.phrases) phrase.id,
    ];
    expect(phraseIds.toSet(), hasLength(phraseIds.length));

    for (final etude in etudes) {
      expect(
        etude.file.uri.pathSegments.last,
        '${etude.id}.json',
        reason: 'the file name must match the piece id',
      );
      expect(
        etude.id,
        matches(RegExp(r'^etude-l[1-5]-\d{2}$')),
        reason: 'stable id format',
      );
    }
  });

  test('every etude parses and passes the T3.2 validators', () {
    for (final etude in etudes) {
      final issues = AuthoringValidator(etude.score).validate();
      expect(
        issues,
        isEmpty,
        reason: '${etude.file.path}\n${_describeIssues(issues)}',
      );
      expect(etude.score.validate(), isEmpty, reason: etude.file.path);
    }
  });

  test('metadata and provenance are honest for every etude', () {
    for (final etude in etudes) {
      final score = etude.score;
      final piece = score.piece;
      final meta = etude.meta;
      final rubric = levelRubric[etude.level]!;

      expect(
        piece.title,
        'Sight-reading Etude L${etude.level}-'
        '${etude.number.toString().padLeft(2, '0')}',
        reason: etude.id,
      );
      expect(piece.composer, 'Hear Me Out', reason: etude.id);
      expect(piece.license, 'original', reason: etude.id);
      expect(piece.capo, 0, reason: etude.id);
      expect(piece.tuning.isStandard, isTrue, reason: etude.id);
      expect(piece.tuning.openStrings, <int>[
        40,
        45,
        50,
        55,
        59,
        64,
      ], reason: etude.id);
      expect(
        piece.sections,
        anyOf(equals(<String>['A']), equals(<String>['A', 'B'])),
        reason: etude.id,
      );
      expect(keyPitchClasses.containsKey(piece.key), isTrue, reason: etude.id);

      expect(meta.kind, 'etude', reason: etude.id);
      expect(meta.tier, rubric.tier, reason: etude.id);
      expect(meta.stage, rubric.stage, reason: etude.id);
      expect(meta.author, isNotEmpty, reason: etude.id);
      expect(meta.source, isNotEmpty, reason: etude.id);
      expect(meta.notes, isNotEmpty, reason: etude.id);
      expect(
        meta.reviewedBy,
        expectedReview,
        reason:
            '${etude.id}: reviewedBy must state machine review and pending '
            'T3.8 playtest, never a human review',
      );
      expect(
        meta.reviewedBy,
        isNot(contains('human review')),
        reason: etude.id,
      );
    }
  });

  test('phrase skills describe the phrase notes, not the level', () {
    for (final etude in etudes) {
      expectPhraseSkills(etude);
    }
  });

  test('notation is monophonic, explicit, in range, and fully barred', () {
    for (final etude in etudes) {
      final score = etude.score;
      final piece = score.piece;
      var startBar = 1;

      for (
        var phraseIndex = 0;
        phraseIndex < score.phrases.length;
        phraseIndex++
      ) {
        final phrase = score.phrases[phraseIndex];
        expect(phrase.id, '${etude.id}-p${phraseIndex + 1}');
        expect(phrase.bars, inInclusiveRange(1, 4), reason: phrase.id);
        expect(phrase.timeSignature, piece.timeSignature, reason: phrase.id);
        expect(phrase.startBar, startBar, reason: phrase.id);
        expect(phrase.pickupBeats, 0, reason: phrase.id);
        expect(
          phrase.totalBeats,
          closeTo(phrase.expectedTotalBeats, 1e-9),
          reason: '${phrase.id} must fill every declared bar',
        );
        expect(phrase.events, isNotEmpty, reason: phrase.id);
        expect(phrase.events.first.startBeat, 0, reason: phrase.id);
        expect(
          phrase.events.last.endBeat,
          closeTo(phrase.expectedTotalBeats, 1e-9),
          reason: phrase.id,
        );
        expect(phrase.events.last.tieToNext, isFalse, reason: phrase.id);

        for (var index = 1; index < phrase.events.length; index++) {
          final previous = phrase.events[index - 1];
          final event = phrase.events[index];
          expect(
            event.startBeat,
            greaterThanOrEqualTo(previous.endBeat - 1e-9),
            reason: '${phrase.id} events $index and ${index - 1} overlap',
          );
          expect(
            event.startBeat,
            greaterThan(previous.startBeat),
            reason: '${phrase.id} events must be in performance order',
          );
        }

        for (final event in phrase.events) {
          if (event.isRest) {
            expect(event.writtenNote, isNull, reason: phrase.id);
            expect(event.soundingMidi, isNull, reason: phrase.id);
            expect(event.string, isNull, reason: phrase.id);
            expect(event.fret, isNull, reason: phrase.id);
            expect(event.tieToNext, isFalse, reason: phrase.id);
            continue;
          }

          final written = event.writtenNote;
          final sounding = event.soundingMidi;
          final string = event.string;
          final fret = event.fret;
          expect(written, isNotNull, reason: phrase.id);
          expect(sounding, isNotNull, reason: phrase.id);
          expect(string, isNotNull, reason: phrase.id);
          expect(fret, isNotNull, reason: phrase.id);
          expect(
            sounding,
            Guitar.soundingMidiForWritten(written!),
            reason: '${phrase.id}: written/sounding pair',
          );
          expect(
            piece.tuning.soundingMidiAt(string!, fret!),
            sounding,
            reason: '${phrase.id}: string/fret does not produce the pitch',
          );
          expect(
            written.midi,
            inInclusiveRange(52, 88),
            reason: '${phrase.id}: written range must stay inside E3-E6',
          );
          expect(string, inInclusiveRange(1, 6), reason: phrase.id);
          expect(fret, inInclusiveRange(0, 19), reason: phrase.id);
        }

        startBar += phrase.bars;
      }
      expect(score.phrases.last.startBar, startBar - score.phrases.last.bars);
    }
  });

  test('level 1 follows the four-bar open-string and pulse rubric', () {
    for (final etude in etudes.where((etude) => etude.level == 1)) {
      final piece = etude.score.piece;
      final durations = <double>{
        for (final event in etude.events) event.durationBeats,
      };

      expect(etude.totalBars, 4, reason: etude.id);
      expect(piece.timeSignature.numerator, 4, reason: etude.id);
      expect(piece.timeSignature.denominator, 4, reason: etude.id);
      expect(
        piece.timeSignature,
        etude.score.phrases.first.timeSignature,
        reason: etude.id,
      );
      for (final phrase in etude.score.phrases) {
        expect(phrase.targetTempoBpm, 60, reason: etude.id);
      }
      for (final note in etude.notes) {
        expect(note.string, inInclusiveRange(1, 3), reason: etude.id);
        expect(note.fret, inInclusiveRange(0, 3), reason: etude.id);
      }
      expect(
        etude.notes.any((note) => note.fret == 0),
        isTrue,
        reason: '${etude.id}: level 1 must use open strings',
      );
      expect(durations, everyElement(anyOf(1.0, 2.0)), reason: etude.id);
      expect(durations, containsAll(<double>[1.0, 2.0]), reason: etude.id);
      expect(_accidentalPitchClasses(etude), isEmpty, reason: etude.id);
      for (var index = 1; index < etude.notes.length; index++) {
        final interval =
            (etude.notes[index].writtenNote!.midi -
                    etude.notes[index - 1].writtenNote!.midi)
                .abs();
        expect(
          interval,
          lessThanOrEqualTo(2),
          reason: '${etude.id}: level 1 must stay stepwise or repeated',
        );
      }
      expectCadence(etude);
    }
  });

  test('level 2 follows the strings 1-3 quarter/eighth rubric', () {
    for (final etude in etudes.where((etude) => etude.level == 2)) {
      final piece = etude.score.piece;
      final durations = <double>{
        for (final event in etude.events) event.durationBeats,
      };

      expect(etude.totalBars, 8, reason: etude.id);
      expect(
        piece.timeSignature,
        anyOf(const TimeSignature(4, 4), const TimeSignature(3, 4)),
        reason: etude.id,
      );
      for (final phrase in etude.score.phrases) {
        expect(phrase.targetTempoBpm, 66, reason: etude.id);
        expect(
          phrase.targetTempoBpm,
          inInclusiveRange(50, 90),
          reason: etude.id,
        );
      }
      for (final note in etude.notes) {
        expect(note.string, inInclusiveRange(1, 3), reason: etude.id);
        expect(note.fret, inInclusiveRange(0, 5), reason: etude.id);
      }
      expect(
        etude.notes.any((note) => note.fret == 0),
        isTrue,
        reason: '${etude.id}: level 2 first position must use open strings',
      );
      expect(durations, everyElement(anyOf(0.5, 1.0)), reason: etude.id);
      expect(durations, containsAll(<double>[0.5, 1.0]), reason: etude.id);
      expect(
        _accidentalPitchClasses(etude).length,
        lessThanOrEqualTo(1),
        reason: '${etude.id}: level 2 allows at most one accidental',
      );
      expectCadence(etude);
    }
  });

  test('level 3 follows the 12-bar dotted-rhythm rubric', () {
    for (final etude in etudes.where((etude) => etude.level == 3)) {
      final piece = etude.score.piece;
      final durations = <double>{
        for (final event in etude.events) event.durationBeats,
      };

      expect(etude.totalBars, 12, reason: etude.id);
      expect(
        piece.timeSignature,
        anyOf(const TimeSignature(4, 4), const TimeSignature(3, 4)),
        reason: etude.id,
      );
      for (final phrase in etude.score.phrases) {
        expect(phrase.targetTempoBpm, 72, reason: etude.id);
      }
      for (final note in etude.notes) {
        expect(note.string, inInclusiveRange(1, 6), reason: etude.id);
        expect(note.fret, inInclusiveRange(0, 5), reason: etude.id);
      }
      expect(
        etude.notes.any((note) => note.fret == 0),
        isTrue,
        reason: '${etude.id}: level 3 first position must use open strings',
      );
      expect(
        etude.notes.any((note) => note.string! >= 4),
        isTrue,
        reason: '${etude.id}: level 3 must reach the lower strings',
      );
      expect(durations, containsAll(<double>[0.5, 1.0]), reason: etude.id);
      expect(
        durations.any(
          (duration) =>
              (duration - 1.5).abs() < 1e-9 || (duration - 3.0).abs() < 1e-9,
        ),
        isTrue,
        reason: '${etude.id}: level 3 needs a dotted rhythm',
      );
      expect(
        _accidentalPitchClasses(etude).length,
        inInclusiveRange(1, 2),
        reason: '${etude.id}: level 3 needs one or two accidentals',
      );

      final signatures = etude.score.phrases.map(_rhythmSignature).toList();
      expect(
        signatures[0],
        signatures[2],
        reason:
            '${etude.id}: phrases 1 and 3 must state the same rhythmic motif',
      );
      expectCadence(etude);
    }
  });

  test('level 4 follows the 12-bar first/second-position shift rubric', () {
    for (final etude in etudes.where((etude) => etude.level == 4)) {
      final piece = etude.score.piece;
      final durations = <double>{
        for (final event in etude.events) event.durationBeats,
      };

      expect(etude.totalBars, 12, reason: etude.id);
      expect(
        piece.timeSignature,
        anyOf(const TimeSignature(4, 4), const TimeSignature(3, 4)),
        reason: etude.id,
      );
      for (final phrase in etude.score.phrases) {
        expect(phrase.targetTempoBpm, 76, reason: etude.id);
        expect(phrase.bars, inInclusiveRange(1, 4), reason: etude.id);
      }
      for (final note in etude.notes) {
        expect(note.string, inInclusiveRange(1, 4), reason: etude.id);
        expect(note.fret, inInclusiveRange(0, 5), reason: etude.id);
      }
      expect(durations, everyElement(anyOf(0.5, 1.0)), reason: etude.id);
      expect(durations, containsAll(<double>[0.5, 1.0]), reason: etude.id);
      expect(
        _accidentalPitchClasses(etude),
        isEmpty,
        reason: '${etude.id}: level 4 is tonal and stays in its key',
      );
      expect(
        etude.events.any((event) => event.tieToNext),
        isFalse,
        reason: '${etude.id}: level 4 forbids slurs',
      );
      expect(
        _positionShifts(etude),
        greaterThanOrEqualTo(2),
        reason:
            '${etude.id}: level 4 needs two phrase-level first/second-position '
            'changes; guide-finger fingering is T3.8 review',
      );
      expectCadence(etude);
    }
  });

  test('level 5 follows the stage-9 four-bar fluency rubric', () {
    for (final etude in etudes.where((etude) => etude.level == 5)) {
      final durations = <double>{
        for (final event in etude.events) event.durationBeats,
      };
      final positions = _phrasePositions(etude);

      expect(etude.totalBars, 4, reason: etude.id);
      for (final phrase in etude.score.phrases) {
        expect(phrase.targetTempoBpm, 70, reason: etude.id);
        expect(phrase.bars, inInclusiveRange(1, 4), reason: etude.id);
      }
      for (final note in etude.notes) {
        expect(note.string, inInclusiveRange(1, 6), reason: etude.id);
        expect(note.fret, inInclusiveRange(0, 5), reason: etude.id);
      }
      expect(durations, containsAll(<double>[0.5, 1.0]), reason: etude.id);
      expect(
        etude.events.any((event) => event.isRest),
        isTrue,
        reason: '${etude.id}: level 5 needs rest cells',
      );
      expect(
        positions.any((phrase) => phrase.second && !phrase.first),
        isTrue,
        reason:
            '${etude.id}: level 5 needs an exclusively second-position phrase',
      );
      expect(
        positions.any((phrase) => phrase.first && !phrase.second),
        isTrue,
        reason:
            '${etude.id}: level 5 needs an exclusively first-position phrase',
      );
      expectCadence(etude);
    }
  });

  test('the set varies keys, meters, and level difficulty', () {
    final keys = etudes.map((etude) => etude.score.piece.key).toSet();
    expect(
      keys,
      containsAll(<String>[
        'C major',
        'G major',
        'D major',
        'A minor',
        'E minor',
      ]),
    );

    for (var level = 2; level <= 5; level++) {
      final meters = etudes
          .where((etude) => etude.level == level)
          .map((etude) => etude.score.piece.timeSignature)
          .toSet();
      expect(
        meters,
        containsAll(const <TimeSignature>[
          TimeSignature(4, 4),
          TimeSignature(3, 4),
        ]),
        reason: 'level $level must vary 4/4 and 3/4',
      );
    }

    expect(levelRubric.values.map((rubric) => rubric.tempo).toList(), <int>[
      60,
      66,
      72,
      76,
      70,
    ]);
    expect(
      etudes
          .where((etude) => etude.level == 1)
          .every((etude) => etude.totalBars == 4),
      isTrue,
    );
    expect(
      etudes
          .where((etude) => etude.level == 2)
          .every((etude) => etude.totalBars == 8),
      isTrue,
    );
    expect(
      etudes
          .where((etude) => etude.level == 3)
          .every((etude) => etude.totalBars == 12),
      isTrue,
    );
    expect(
      etudes
          .where((etude) => etude.level == 4)
          .every((etude) => etude.totalBars == 12),
      isTrue,
    );
    expect(
      etudes
          .where((etude) => etude.level == 5)
          .every((etude) => etude.totalBars == 4),
      isTrue,
    );
  });

  test('the validator CLI passes every etude in strict mode', () {
    for (final etude in etudes) {
      final out = StringBuffer();
      final err = StringBuffer();
      final code = runCli(
        <String>[etude.file.path, '--strict'],
        out: out,
        err: err,
      );

      expect(
        code,
        0,
        reason: '${etude.file.path}\n${out.toString()}\n${err.toString()}',
      );
      expect(err.toString(), isEmpty, reason: etude.file.path);
      expect(out.toString(), contains('PASS'), reason: etude.file.path);
      expect(
        out.toString(),
        contains('0 error(s), 0 warning(s)'),
        reason: etude.file.path,
      );
    }
  });
}
