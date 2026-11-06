import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/music/note_event.dart';
import 'package:hear_me_out/core/music/phrase.dart';
import 'package:hear_me_out/core/music/piece.dart';
import 'package:hear_me_out/core/music/score.dart';
import 'package:hear_me_out/core/music/score_parser.dart';

import 'support/score_fixtures.dart';

Score _scoreFrom(String name) => parseScore(loadScoreFixture(name));

List<String> _codes(List<ScoreIssue> issues) => <String>[
  for (final issue in issues) issue.code,
];

Map<String, dynamic> _lastTieEvent(Map<String, dynamic> json) {
  final phrases = json['phrases'] as List<dynamic>;
  final phrase = phrases.first as Map<String, dynamic>;
  final events = phrase['events'] as List<dynamic>;
  return events.last as Map<String, dynamic>;
}

void main() {
  final base = _scoreFrom('valid_monophonic');

  group('Valid scores', () {
    test('a four-bar monophonic score validates without issues', () {
      expect(base.validate(), isEmpty);
      expect(base.hasErrors, isFalse);
      expect(base.phrases.single.events, hasLength(16));
    });

    test('a valid pickup is accepted', () {
      final score = _scoreFrom('pickup');
      expect(score.validate(), isEmpty);
      expect(score.phrases.single.pickupBeats, 1);
      expect(score.phrases.single.expectedTotalBeats, 9);
    });

    test('a tie is accepted and does not become an overlap', () {
      final score = _scoreFrom('tie');
      expect(score.validate(), isEmpty);
      expect(score.phrases.single.events[3].tieToNext, isTrue);
    });
  });

  group('Monophonic rules', () {
    test('a chord or double stop is rejected', () {
      final issues = _scoreFrom('chord').validate();
      final chord = issues.firstWhere(
        (issue) => issue.code == 'monophonic.chord',
      );

      expect(_codes(issues), ['monophonic.chord']);
      expect(chord.isError, isTrue);
      expect(chord.phraseId, 'fixture-chord');
      expect(chord.eventIndex, 1);
      expect(chord.path, 'phrases[0].events[1]');
      expect(chord.message, contains('chord'));
    });

    test('overlapping note events are rejected', () {
      final issues = _scoreFrom('overlap').validate();
      final overlap = issues.firstWhere(
        (issue) => issue.code == 'monophonic.overlap',
      );

      expect(_codes(issues), ['monophonic.overlap']);
      expect(overlap.phraseId, 'fixture-overlap');
      expect(overlap.eventIndex, 1);
      expect(overlap.path, 'phrases[0].events[1]');
    });
  });

  group('Pitch and fingering', () {
    test('a written/sounding mismatch is rejected', () {
      final issues = _scoreFrom('written_sounding_mismatch').validate();
      final mismatch = issues.firstWhere(
        (issue) => issue.code == 'note.writtenSoundingMismatch',
      );

      expect(_codes(issues), ['note.writtenSoundingMismatch']);
      expect(mismatch.phraseId, 'fixture-mismatch');
      expect(mismatch.eventIndex, 0);
      expect(mismatch.path, 'phrases[0].events[0].soundingMidi');
      expect(mismatch.message, contains('64'));
      expect(mismatch.message, contains('65'));
    });

    test('a wrong string/fret is rejected', () {
      final issues = _scoreFrom('bad_fingering').validate();
      final fingering = issues.firstWhere(
        (issue) => issue.code == 'fingering.mismatch',
      );

      expect(_codes(issues), ['fingering.mismatch']);
      expect(fingering.path, 'phrases[0].events[0]');
      expect(fingering.message, contains('String 2 fret 0'));
    });
  });

  group('Bars and timing', () {
    test('a bar with the wrong duration is rejected', () {
      final issues = _scoreFrom('bad_bar_duration').validate();
      final bar = issues.firstWhere(
        (issue) => issue.code == 'bar.durationMismatch',
      );

      expect(_codes(issues), contains('phrase.barCountMismatch'));
      expect(_codes(issues), contains('bar.durationMismatch'));
      expect(bar.path, 'phrases[0].bars[4]');
      expect(bar.message, contains('Bar 4'));
      expect(bar.message, contains('3'));
      expect(bar.message, contains('4'));
    });

    test('an event with a non-finite value is rejected', () {
      final score = Score(
        piece: base.piece,
        phrases: [
          Phrase(
            id: 'non-finite',
            bars: 1,
            timeSignature: const TimeSignature(4, 4),
            targetTempoBpm: 80,
            events: [
              NoteEvent(
                startBeat: double.nan,
                durationBeats: 1,
                kind: NoteEventKind.note,
                writtenNote: const Note('E', 5),
                soundingMidi: 64,
              ),
              NoteEvent(
                startBeat: double.infinity,
                durationBeats: 1,
                kind: NoteEventKind.rest,
              ),
              NoteEvent(
                startBeat: 0,
                durationBeats: double.infinity,
                kind: NoteEventKind.rest,
              ),
              NoteEvent(
                startBeat: 1,
                durationBeats: 1,
                kind: NoteEventKind.rest,
                velocity: double.nan,
              ),
            ],
          ),
        ],
      );

      final nonFinite = _codes(score.validate())
          .where((code) => code == 'event.nonFinite');

      expect(nonFinite.length, greaterThanOrEqualTo(4));
      expect(score.hasErrors, isTrue);
    });

    test('negative, zero-length, and out-of-range values are rejected', () {
      final score = Score(
        piece: base.piece,
        phrases: [
          Phrase(
            id: 'invalid-values',
            bars: 1,
            timeSignature: const TimeSignature(4, 4),
            targetTempoBpm: 20,
            difficulty: 9,
            events: [
              NoteEvent(
                startBeat: -1,
                durationBeats: 0,
                kind: NoteEventKind.note,
                writtenNote: const Note('E', 5),
                soundingMidi: 64,
                velocity: 2,
              ),
            ],
          ),
        ],
      );

      expect(
        _codes(score.validate()),
        containsAll(<String>[
          'phrase.invalidTempo',
          'phrase.invalidDifficulty',
          'event.invalidStart',
          'event.invalidDuration',
          'event.invalidVelocity',
        ]),
      );
    });

    test('an empty phrase and an empty score are rejected', () {
      final emptyPhrase = Score(
        piece: base.piece,
        phrases: [
          const Phrase(
            id: 'empty',
            bars: 1,
            timeSignature: TimeSignature(4, 4),
            events: [],
            targetTempoBpm: 80,
          ),
        ],
      );

      expect(_codes(emptyPhrase.validate()), contains('phrase.emptyEvents'));
      expect(
        _codes(Score(piece: base.piece, phrases: const []).validate()),
        contains('score.empty'),
      );
    });

    test('an invalid pickup length is rejected', () {
      final score = Score(
        piece: base.piece,
        phrases: [
          Phrase(
            id: 'bad-pickup',
            bars: 1,
            timeSignature: const TimeSignature(4, 4),
            targetTempoBpm: 80,
            pickupBeats: 4,
            events: base.phrases.single.events,
          ),
        ],
      );

      expect(_codes(score.validate()), contains('phrase.invalidPickup'));
    });
  });

  group('Tie rules', () {
    test('a dangling tie is rejected', () {
      final json = loadScoreFixture('tie');
      _lastTieEvent(json)['tieToNext'] = true;
      final issues = parseScore(json).validate();
      final dangling = issues.firstWhere(
        (issue) => issue.code == 'tie.dangling',
      );

      expect(dangling.path, 'phrases[0].events[4].tieToNext');
      expect(dangling.eventIndex, 4);
    });

    test('a tie to a different pitch is rejected', () {
      final json = loadScoreFixture('tie');
      final last = _lastTieEvent(json);
      last['writtenNote'] = 'A4';
      last['soundingMidi'] = 57;
      last['string'] = 3;
      last['fret'] = 2;

      expect(_codes(parseScore(json).validate()), contains('tie.mismatch'));
    });

    test('a tie to a different written spelling is rejected', () {
      final score = Score(
        piece: base.piece,
        phrases: [
          Phrase(
            id: 'enharmonic-tie',
            bars: 1,
            timeSignature: const TimeSignature(4, 4),
            targetTempoBpm: 80,
            events: [
              const NoteEvent(
                startBeat: 0,
                durationBeats: 1,
                kind: NoteEventKind.note,
                writtenNote: Note('C', 5),
                soundingMidi: 60,
                string: 2,
                fret: 1,
                tieToNext: true,
              ),
              const NoteEvent(
                startBeat: 1,
                durationBeats: 3,
                kind: NoteEventKind.note,
                writtenNote: Note('B', 4, accidental: Accidental.sharp),
                soundingMidi: 60,
                string: 2,
                fret: 1,
              ),
            ],
          ),
        ],
      );

      expect(_codes(score.validate()), contains('tie.mismatch'));
    });

    test('a tie that changes string or fret is rejected', () {
      final json = loadScoreFixture('tie');
      final last = _lastTieEvent(json);
      last['string'] = 4;
      last['fret'] = 5;

      expect(_codes(parseScore(json).validate()), contains('tie.mismatch'));
    });

    test('a tie that is not adjacent is rejected', () {
      final json = loadScoreFixture('tie');
      final last = _lastTieEvent(json);
      last['startBeat'] = 4.5;
      last['durationBeats'] = 3.5;

      expect(_codes(parseScore(json).validate()), contains('tie.notAdjacent'));
    });
  });

  group('Score metadata', () {
    test('duplicate phrase ids are rejected', () {
      final duplicate = Score(
        piece: base.piece,
        phrases: [
          base.phrases.single,
          base.phrases.single.copyWith(title: 'Copy'),
        ],
      );
      final issues = duplicate.validate();
      final issue = issues.firstWhere(
        (entry) => entry.code == 'phrase.duplicateId',
      );

      expect(_codes(issues), ['phrase.duplicateId']);
      expect(issue.path, 'phrases[1].id');
      expect(issue.phraseId, 'fixture-valid-4-bar');
    });

    test('licensed material is rejected for V1', () {
      final score = Score(
        piece: base.piece.copyWith(license: 'licensed'),
        phrases: base.phrases,
      );

      expect(
        _codes(score.validate()),
        contains('piece.licenseNotV1Compatible'),
      );
      expect(
        _codes(
          Score(
            piece: base.piece.copyWith(license: 'CC-BY'),
            phrases: base.phrases,
          ).validate(),
        ),
        contains('piece.unknownLicense'),
      );
    });

    test('empty piece metadata is rejected', () {
      final score = Score(
        piece: base.piece.copyWith(
          id: '',
          title: '',
          composer: '',
          license: '',
          key: '',
          tuning: const Tuning(name: '', openStrings: [40, 45, 50, 55, 59, 64]),
        ),
        phrases: base.phrases,
      );

      expect(
        _codes(score.validate()),
        containsAll(<String>[
          'piece.emptyId',
          'piece.emptyTitle',
          'piece.emptyComposer',
          'piece.emptyLicense',
          'piece.emptyKey',
          'piece.emptyTuningName',
        ]),
      );
    });

    test('an invalid tuning shape is rejected', () {
      final score = Score(
        piece: base.piece.copyWith(
          tuning: const Tuning(name: 'Broken', openStrings: [40, 45]),
        ),
        phrases: base.phrases,
      );

      expect(_codes(score.validate()), contains('piece.invalidTuning'));
    });

    test('a non-standard tuning is only a warning', () {
      final score = Score(
        piece: base.piece.copyWith(
          tuning: const Tuning(
            name: 'Drop D',
            openStrings: [38, 45, 50, 55, 59, 64],
          ),
        ),
        phrases: base.phrases,
      );
      final issues = score.validate();
      final warning = issues.firstWhere(
        (issue) => issue.code == 'piece.nonStandardTuning',
      );

      expect(warning.severity, ScoreIssueSeverity.warning);
      expect(warning.isWarning, isTrue);
      expect(warning.path, 'piece.tuning.openStrings');
      expect(_codes(issues), ['piece.nonStandardTuning']);
      expect(score.hasErrors, isFalse);
    });
  });
}
