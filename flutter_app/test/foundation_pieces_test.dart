import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/pieces/launch_pieces.dart';
import 'package:hear_me_out/content/score/authoring.dart';
import 'package:hear_me_out/core/music/guitar.dart';
import 'package:hear_me_out/core/music/note_event.dart';
import 'package:hear_me_out/core/music/score.dart';

import '../tool/content/validate_piece.dart';

/// The recorded T3.1 envelope for one Foundation piece.
///
/// The string set is the actual set of strings the arrangement uses. It must
/// sit inside the string span named by T3.1's `rangeAndPosition`. Stage 1-2
/// pieces must not use string 4 at all.
typedef FoundationCase = ({
  String id,
  int stage,
  Set<int> strings,
  int maxFret,
});

/// The only pieces whose upper melody note needs a fret above T3.1's 0-3
/// planning ceiling to stay inside the planned string range. Every other
/// piece must meet the 0-3 ceiling exactly.
const Set<String> fretReachExceptions = <String>{};

const String contentDirectory = 'assets/content/pieces/foundation';

const List<FoundationCase> foundationCases = <FoundationCase>[
  (id: 'greensleeves', stage: 1, strings: {1, 2, 3}, maxFret: 3),
  (id: 'ode-to-joy', stage: 2, strings: {1, 2}, maxFret: 5),
  (id: 'amazing-grace', stage: 2, strings: {1, 2, 3}, maxFret: 3),
  (id: 'down-by-the-riverside', stage: 3, strings: {3, 4}, maxFret: 5),
  (id: 'original-study-1', stage: 3, strings: {4, 5, 6}, maxFret: 3),
];

/// Reads the `strings X-Y; frets A-B` phrase from T3.1's `rangeAndPosition`.
/// A formatting change fails the test instead of silently skipping the check.
({int minString, int maxString, int maxFret}) parseRangeAndPosition(
  String text,
) {
  final match = RegExp(r'strings\s+(\d+)-(\d+);\s*frets\s+(\d+)-(\d+)')
      .firstMatch(text);
  expect(match, isNotNull, reason: 'Unparseable rangeAndPosition: $text');
  return (
    minString: int.parse(match!.group(1)!),
    maxString: int.parse(match.group(2)!),
    maxFret: int.parse(match.group(4)!),
  );
}

Map<String, dynamic> loadPiece(String id) {
  final file = File('$contentDirectory/$id.json');
  expect(file.existsSync(), isTrue, reason: 'Missing $file');
  final decoded = jsonDecode(file.readAsStringSync());
  expect(decoded, isA<Map<String, dynamic>>());
  return decoded as Map<String, dynamic>;
}

String describeIssues(Iterable<ScoreIssue> issues) =>
    issues.map((issue) => issue.toString()).join('\n');

void main() {
  group('Foundation package', () {
    test('the five Foundation files match the T3.1 launch list', () {
      final launchIds = launchPiecesForTier(LaunchTier.foundation)
          .map((launch) => launch.piece.id)
          .toList();

      expect(
        foundationCases.map((entry) => entry.id).toList(),
        launchIds,
        reason: 'The arrangement file set must stay aligned with T3.1.',
      );

      for (final entry in foundationCases) {
        expect(
          File('$contentDirectory/${entry.id}.json').existsSync(),
          isTrue,
          reason: 'Missing ${entry.id}.json',
        );
      }
    });

    for (final entry in foundationCases) {
      group(entry.id, () {
        late Map<String, dynamic> raw;
        late AuthoringDocument document;
        late Score score;
        late LaunchPiece launch;

        setUp(() {
          raw = loadPiece(entry.id);
          document = parseAuthoringDocument(raw);
          score = document.score;
          launch = launchPieceById(entry.id)!;
        });

        test('parses and validates with zero errors and warnings', () {
          expect(raw['schemaVersion'], authoringSchemaVersion);

          final issues = AuthoringValidator(score).validate();
          expect(issues, isEmpty, reason: describeIssues(issues));
          expect(score.validate(), isEmpty);

          expect(document.meta, isNotNull);
          expect(document.meta!.kind, 'piece');
          expect(document.meta!.tier, 'foundation');
          expect(document.meta!.stage, entry.stage);
          expect(document.meta!.reviewedBy, isNotEmpty);
          expect(document.meta!.author, isNotEmpty);
          expect(document.meta!.source, isNotEmpty);
          expect(document.meta!.notes, isNotEmpty);
        });

        test('matches the T3.1 piece metadata and recorded envelope', () {
          final piece = score.piece;
          expect(piece.id, entry.id);
          expect(piece.id, launch.piece.id);
          expect(piece.title, launch.piece.title);
          expect(piece.composer, launch.piece.composer);
          expect(piece.license, launch.piece.license);
          expect(piece.timeSignature, launch.piece.timeSignature);
          expect(piece.key, launch.piece.key);
          expect(piece.capo, 0);
          expect(piece.capo, launch.piece.capo);
          expect(piece.tuning.isStandard, isTrue);
          expect(launch.piece.tuning.isStandard, isTrue);
          expect(piece.tuning.openStrings, <int>[40, 45, 50, 55, 59, 64]);
          expect(launch.tier, LaunchTier.foundation);
          expect(launch.v1Stage, entry.stage);
          expect(launch.phraseCount, 4);
          expect(launch.techniqueFocus, isNotEmpty);
          expect(launch.rangeAndPosition, isNotEmpty);

          final t31 = parseRangeAndPosition(launch.rangeAndPosition);
          final actualMin = entry.strings.reduce((a, b) => a < b ? a : b);
          final actualMax = entry.strings.reduce((a, b) => a > b ? a : b);
          expect(actualMin, greaterThanOrEqualTo(t31.minString));
          expect(actualMax, lessThanOrEqualTo(t31.maxString));

          if (fretReachExceptions.contains(entry.id)) {
            expect(entry.maxFret, greaterThan(t31.maxFret));
          } else {
            expect(entry.maxFret, t31.maxFret);
          }
        });

        test('has four well-formed phrases in performance order', () {
          expect(score.phrases, hasLength(4));

          var startBar = 1;
          var totalBars = 0;
          for (var index = 0; index < score.phrases.length; index++) {
            final phrase = score.phrases[index];
            expect(phrase.id, '${entry.id}-p${index + 1}');
            expect(phrase.title, isNotEmpty);
            expect(
              phrase.bars,
              inInclusiveRange(2, 4),
              reason: '${phrase.id} must be 2-4 bars',
            );
            expect(phrase.timeSignature, score.piece.timeSignature);
            expect(phrase.timeSignature, launch.piece.timeSignature);
            expect(phrase.targetTempoBpm, inInclusiveRange(50, 90));
            expect(phrase.targetTempoBpm, launch.targetTempoBpm);
            expect(phrase.difficulty, inInclusiveRange(1, 5));
            expect(phrase.skills, isNotEmpty);
            expect(phrase.startBar, startBar);
            expect(
              phrase.pickupBeats,
              inInclusiveRange(0, phrase.timeSignature.beatsPerBar - 1e-9),
            );
            if (index > 0) {
              expect(
                phrase.pickupBeats,
                0,
                reason: 'Only the first phrase may open with an anacrusis.',
              );
            }
            expect(phrase.events, isNotEmpty);
            expect(
              phrase.totalBeats,
              closeTo(phrase.expectedTotalBeats, 1e-9),
              reason: '${phrase.id} does not fill its declared bars',
            );

            startBar += phrase.bars;
            totalBars += phrase.bars;
          }

          expect(score.phrases.first.startBar, 1);
          expect(totalBars, inInclusiveRange(8, 16));
          expect(
            score.phrases.last.startBar,
            totalBars - score.phrases.last.bars + 1,
          );
          expect(startBar, totalBars + 1);
        });

        test('is monophonic with complete bar coverage', () {
          for (final phrase in score.phrases) {
            final events = phrase.events;
            expect(events.first.startBeat, 0);
            expect(events.first.isNote, isTrue);
            expect(
              events.last.endBeat,
              closeTo(phrase.expectedTotalBeats, 1e-9),
            );
            expect(events.last.tieToNext, isFalse);

            for (var index = 1; index < events.length; index++) {
              final previous = events[index - 1];
              final event = events[index];
              expect(
                event.startBeat,
                greaterThanOrEqualTo(previous.endBeat - 1e-9),
                reason: '${phrase.id} events $index and ${index - 1} overlap',
              );
            }

            // No two notes may start at the same beat: that is a chord.
            for (var index = 1; index < events.length; index++) {
              if (!events[index].isNote || !events[index - 1].isNote) continue;
              expect(
                events[index].startBeat,
                greaterThan(events[index - 1].startBeat),
              );
            }
          }
        });

        test('stage 1-2 stays on strings 1-3', () {
          if (entry.stage > 2) return;

          final t31 = parseRangeAndPosition(launch.rangeAndPosition);
          expect(t31.minString, 1);
          expect(t31.maxString, lessThanOrEqualTo(3));

          for (final phrase in score.phrases) {
            for (final event in phrase.events) {
              if (!event.isNote) continue;
              expect(
                event.string,
                inInclusiveRange(1, 3),
                reason:
                    '${phrase.id}: stage-${entry.stage} may not use string 4',
              );
            }
          }
        });

        test('every note is playable and pitch-consistent', () {
          expect(score.piece.tuning.isStandard, isTrue);
          final t31 = parseRangeAndPosition(launch.rangeAndPosition);
          var actualMaxFret = 0;

          for (final phrase in score.phrases) {
            for (var index = 0; index < phrase.events.length; index++) {
              final event = phrase.events[index];
              final eventPath = '${phrase.id}.events[$index]';
              if (event.kind == NoteEventKind.rest) {
                expect(event.writtenNote, isNull, reason: eventPath);
                expect(event.soundingMidi, isNull, reason: eventPath);
                expect(event.string, isNull, reason: eventPath);
                expect(event.fret, isNull, reason: eventPath);
                expect(event.tieToNext, isFalse, reason: eventPath);
                continue;
              }

              final written = event.writtenNote;
              final sounding = event.soundingMidi;
              final string = event.string;
              final fret = event.fret;
              expect(
                written,
                isNotNull,
                reason: '$eventPath: missing written note',
              );
              expect(
                sounding,
                isNotNull,
                reason: '$eventPath: missing sounding MIDI',
              );
              expect(string, isNotNull, reason: '$eventPath: missing string');
              expect(fret, isNotNull, reason: '$eventPath: missing fret');

              expect(
                sounding,
                Guitar.soundingMidiForWritten(written!),
                reason: '$eventPath: written/sounding pair disagrees',
              );
              expect(
                score.piece.tuning.soundingMidiAt(string!, fret!),
                sounding,
                reason: '$eventPath: string/fret does not produce the pitch',
              );
              expect(
                written.midi,
                inInclusiveRange(52, 88),
                reason: '$eventPath: written note is outside E3-E6',
              );
              expect(
                string,
                inInclusiveRange(t31.minString, t31.maxString),
                reason:
                    '$eventPath: string $string is outside '
                    'T3.1 range ${launch.rangeAndPosition}',
              );
              expect(
                fret,
                inInclusiveRange(0, entry.maxFret),
                reason: eventPath,
              );
              if (fret > actualMaxFret) actualMaxFret = fret;

              if (event.tieToNext) {
                expect(index + 1, lessThan(phrase.events.length));
                final next = phrase.events[index + 1];
                expect(
                  next.isNote,
                  isTrue,
                  reason: '$eventPath: tied into a rest',
                );
                expect(next.startBeat, closeTo(event.endBeat, 1e-9));
                expect(next.writtenNote, written);
                expect(next.soundingMidi, sounding);
                expect(next.string, string);
                expect(next.fret, fret);
              }
            }
          }

          expect(
            actualMaxFret,
            entry.maxFret,
            reason: 'The recorded envelope must be tight and up to date.',
          );
        });

        test('passes the content validator CLI in strict mode', () {
          final out = StringBuffer();
          final err = StringBuffer();
          final code = runCli(
            ['$contentDirectory/${entry.id}.json', '--strict'],
            out: out,
            err: err,
          );

          expect(code, 0, reason: '${out.toString()}\n${err.toString()}');
          expect(err.toString(), isEmpty);
          expect(out.toString(), contains('PASS'));
          expect(out.toString(), contains('0 error(s), 0 warning(s)'));
        });
      });
    }
  });
}
