import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/pieces/launch_pieces.dart';
import 'package:hear_me_out/content/score/authoring.dart';
import 'package:hear_me_out/core/music/guitar.dart';
import 'package:hear_me_out/core/music/note.dart';
import 'package:hear_me_out/core/music/phrase.dart';
import 'package:hear_me_out/core/music/score.dart';

/// The five Returner pieces locked by T3.1.
const List<String> returnerPieceIds = <String>[
  'scarborough-fair',
  'londonderry-air',
  'bach-minuet-in-g',
  'spanish-romance',
  'original-study-2',
];

/// Arrangement expectations that are specific to this ticket. The string sets
/// record the documented deviations from the T3.1 planning notes:
/// - Bach's authentic two-register melody needs strings 2-5 in first position.
/// - Londonderry Air and Spanish Romance need string 4 for low melody notes.
/// Everything else stays inside the planned first-position shapes.
class _PieceExpectation {
  const _PieceExpectation({
    required this.strings,
    required this.maxFret,
    required this.lowestWritten,
    required this.highestWritten,
    required this.phraseBars,
  });

  final Set<int> strings;
  final int maxFret;
  final String lowestWritten;
  final String highestWritten;
  final List<int> phraseBars;
}

const Map<String, _PieceExpectation> _expectations =
    <String, _PieceExpectation>{
      'scarborough-fair': _PieceExpectation(
        strings: <int>{1, 2, 3},
        maxFret: 5,
        lowestWritten: 'A4',
        highestWritten: 'A5',
        phraseBars: <int>[4, 4, 2, 2],
      ),
      'londonderry-air': _PieceExpectation(
        strings: <int>{1, 2, 3, 4},
        maxFret: 5,
        lowestWritten: 'E4',
        highestWritten: 'G5',
        phraseBars: <int>[4, 4, 2, 3],
      ),
      'bach-minuet-in-g': _PieceExpectation(
        strings: <int>{2, 3, 4, 5},
        maxFret: 4,
        lowestWritten: 'C4',
        highestWritten: 'D5',
        phraseBars: <int>[4, 4, 4, 4],
      ),
      'spanish-romance': _PieceExpectation(
        strings: <int>{1, 2, 3, 4},
        maxFret: 4,
        lowestWritten: 'E4',
        highestWritten: 'E5',
        phraseBars: <int>[4, 4, 4, 4],
      ),
      'original-study-2': _PieceExpectation(
        strings: <int>{1, 2, 3, 4},
        maxFret: 5,
        lowestWritten: 'D4',
        highestWritten: 'G5',
        phraseBars: <int>[4, 4, 4, 4],
      ),
    };

Map<String, dynamic> loadPiece(String id) {
  final file = File('assets/content/pieces/returner/$id.json');
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw StateError('$id is not a JSON object');
  }
  return Map<String, dynamic>.from(decoded);
}

Score loadScore(String id) => parseAuthoringScore(loadPiece(id));

void main() {
  group('Returner arrangement envelope', () {
    for (final id in returnerPieceIds) {
      test('$id parses and matches the locked T3.1 metadata', () {
        final document = parseAuthoringDocument(loadPiece(id));
        final score = document.score;
        final launch = launchPieceById(id);

        expect(launch, isNotNull, reason: 'T3.1 must list $id');
        expect(launch!.tier, LaunchTier.returner);
        expect(launch.v1Stage, isIn(<int>[5, 9, 10]));

        expect(document.meta?.kind, 'piece');
        expect(document.meta?.tier, 'returner');
        expect(document.meta?.stage, launch.v1Stage);
        expect(document.meta?.reviewedBy, 'Pending musical review');

        // The piece block must not drift from the locked launch list.
        expect(score.piece.id, id);
        expect(score.piece.title, launch.piece.title);
        expect(score.piece.composer, launch.piece.composer);
        expect(score.piece.license, launch.piece.license);
        expect(score.piece.key, launch.piece.key);
        expect(score.piece.timeSignature, launch.piece.timeSignature);
        expect(score.piece.capo, 0);
        expect(score.piece.tuning.isStandard, isTrue);
      });

      test('$id has no model or authoring issues', () {
        final score = loadScore(id);

        // Score.validate owns the monophonic, bar, tie, and fingering rules.
        expect(score.validate(), isEmpty);
        // AuthoringValidator adds tempo, phrase length, range, and shift checks.
        final issues = AuthoringValidator(score).validate();
        expect(
          issues,
          isEmpty,
          reason: issues.map((issue) => issue.toString()).join('\n'),
        );
      });
    }
  });

  group('Returner phrase shape', () {
    for (final id in returnerPieceIds) {
      test('$id has four playable phrases from bar 1', () {
        final score = loadScore(id);
        final expectation = _expectations[id]!;
        final phrases = score.phrases;

        expect(phrases, hasLength(4));
        expect(
          phrases.map((phrase) => phrase.bars).toList(),
          expectation.phraseBars,
        );

        var nextStartBar = 1;
        for (var index = 0; index < phrases.length; index++) {
          final phrase = phrases[index];
          expect(phrase.id, '$id-p${index + 1}');
          expect(phrase.bars, inInclusiveRange(2, 4));
          expect(phrase.startBar, nextStartBar);
          expect(phrase.targetTempoBpm, inInclusiveRange(50, 90));
          expect(phrase.targetTempoBpm, launchPieceById(id)!.targetTempoBpm);
          expect(phrase.timeSignature, score.piece.timeSignature);
          nextStartBar += phrase.bars;
        }

        final totalBars = phrases.fold<int>(
          0,
          (sum, phrase) => sum + phrase.bars,
        );
        expect(totalBars, inInclusiveRange(8, 16));
        expect(totalBars, expectation.phraseBars.fold<int>(0, (a, b) => a + b));
      });

      test('$id covers every phrase bar without gaps or overlaps', () {
        final score = loadScore(id);

        for (final phrase in score.phrases) {
          var cursor = 0.0;
          for (final event in phrase.events) {
            expect(
              event.startBeat,
              closeTo(cursor, 1e-9),
              reason: '${phrase.id} has a gap or overlap',
            );
            expect(event.durationBeats, greaterThan(0));
            cursor += event.durationBeats;
          }
          expect(cursor, closeTo(phrase.expectedTotalBeats, 1e-9));
        }
      });
    }
  });

  group('Returner notation and fingering', () {
    for (final id in returnerPieceIds) {
      test('$id keeps written, sounding, string, and fret in agreement', () {
        final score = loadScore(id);
        final expectation = _expectations[id]!;
        var lowest = 127;
        var highest = 0;

        for (final phrase in score.phrases) {
          for (final event in phrase.events) {
            if (!event.isNote) continue;
            final written = event.writtenNote!;
            final sounding = event.soundingMidi!;
            final string = event.string!;
            final fret = event.fret!;

            expect(
              sounding,
              Guitar.soundingMidiForWritten(written),
              reason: '${phrase.id} declares the wrong sounding pitch',
            );
            expect(
              score.piece.tuning.soundingMidiAt(string, fret),
              sounding,
              reason: '${phrase.id} string $string fret $fret is wrong',
            );
            expect(string, isIn(expectation.strings));
            expect(fret, inInclusiveRange(0, expectation.maxFret));
            expect(written.midi, inInclusiveRange(52, 88)); // written E3-E6

            lowest = math.min(lowest, written.midi);
            highest = math.max(highest, written.midi);
          }
        }

        expect(lowest, Note.parse(expectation.lowestWritten).midi);
        expect(highest, Note.parse(expectation.highestWritten).midi);
      });

      test('$id is strictly one note at a time', () {
        final score = loadScore(id);

        for (final phrase in score.phrases) {
          final noteStarts = <double>[];
          for (final event in phrase.events) {
            if (!event.isNote) continue;
            noteStarts.add(event.startBeat);
          }
          noteStarts.sort();
          for (var index = 1; index < noteStarts.length; index++) {
            expect(
              noteStarts[index],
              greaterThan(noteStarts[index - 1]),
              reason: '${phrase.id} has two notes at the same onset',
            );
          }
        }
      });
    }
  });

  group('Stage fit', () {
    // The deliberate second-position marker in these arrangements is E5 on
    // string 2 fret 5. First position uses the open first string instead.
    bool usesSecondPosition(Phrase phrase) =>
        phrase.notes.any((event) => event.string == 2 && event.fret == 5);

    for (final id in <String>[
      'scarborough-fair',
      'londonderry-air',
      'original-study-2',
    ]) {
      test('$id makes exactly two position shifts', () {
        final score = loadScore(id);
        final plan = score.phrases.map(usesSecondPosition).toList();

        var shifts = 0;
        for (var index = 1; index < plan.length; index++) {
          if (plan[index] != plan[index - 1]) shifts++;
        }
        expect(shifts, 2, reason: 'position plan: $plan');
        expect(plan.first, isFalse);
        expect(plan.last, isFalse);
      });
    }

    for (final id in <String>['bach-minuet-in-g', 'spanish-romance']) {
      test('$id stays in first position', () {
        final score = loadScore(id);
        expect(score.phrases.any(usesSecondPosition), isFalse);
      });
    }
  });

  group('Single-line reductions', () {
    for (final id in <String>['bach-minuet-in-g', 'spanish-romance']) {
      test('$id has one melody line and no bass or arpeggio voice', () {
        final score = loadScore(id);
        var lowest = 127;

        for (final phrase in score.phrases) {
          final notes = phrase.notes;
          expect(
            notes.length,
            phrase.events.length - phrase.rests.length,
            reason: '${phrase.id} must not hide a second voice',
          );
          for (final note in notes) {
            // The model stores one written pitch per event. There is no
            // second note, bass line, or arpeggio event anywhere in the JSON.
            expect(note.writtenNote, isNotNull);
            expect(note.soundingMidi, isNotNull);
            expect(note.string, isNotNull);
            expect(note.fret, isNotNull);
            lowest = math.min(lowest, note.writtenNote!.midi);
          }
        }

        // Melody only: the lowest written note stays in the melody register.
        // Bach's octave-reduced opening phrase goes down to C4; Spanish
        // Romance goes down to E4. Neither reaches the bass E3 or below.
        expect(
          lowest,
          greaterThanOrEqualTo(id == 'bach-minuet-in-g' ? 60 : 64),
        );
      });
    }
  });
}
