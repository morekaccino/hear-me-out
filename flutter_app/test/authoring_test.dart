import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/score/authoring.dart';
import 'package:hear_me_out/core/music/score.dart';

import '../tool/content/validate_piece.dart';

Map<String, dynamic> loadContentFixture(String name) {
  final file = File('test/fixtures/content/$name.json');
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw StateError('Fixture $name is not a JSON object');
  }
  return Map<String, dynamic>.from(decoded);
}

Map<String, dynamic> copyContentFixture(String name) {
  return jsonDecode(jsonEncode(loadContentFixture(name)))
      as Map<String, dynamic>;
}

Map<String, dynamic> phraseAt(Map<String, dynamic> json, int index) {
  return (json['phrases'] as List<dynamic>)[index] as Map<String, dynamic>;
}

Map<String, dynamic> eventAt(
  Map<String, dynamic> json,
  int phraseIndex,
  int eventIndex,
) {
  return (phraseAt(json, phraseIndex)['events'] as List<dynamic>)[eventIndex]
      as Map<String, dynamic>;
}

void expectIssue(
  List<ScoreIssue> issues, {
  required String code,
  required String path,
  bool error = true,
}) {
  expect(
    issues.any(
      (issue) =>
          issue.code == code &&
          issue.path == path &&
          (error ? issue.isError : issue.isWarning),
    ),
    isTrue,
    reason: issues.map((issue) => issue.toString()).join('\n'),
  );
}

void main() {
  group('authoring parser', () {
    test('parses and validates the worked example', () {
      final document = parseAuthoringDocument(
        loadContentFixture('valid_piece'),
      );
      final score = document.score;

      expect(score.piece.id, 'original-study-in-g');
      expect(score.piece.title, 'Original Study in G');
      expect(score.piece.license, 'original');
      expect(score.piece.capo, 0);
      expect(score.phrases, hasLength(4));
      expect(score.phrases.map((phrase) => phrase.bars), everyElement(1));
      expect(score.phrases.fold<int>(0, (sum, phrase) => sum + phrase.bars), 4);
      expect(
        score.phrases.fold<int>(0, (sum, phrase) => sum + phrase.notes.length),
        15,
      );
      expect(
        score.phrases.fold<int>(0, (sum, phrase) => sum + phrase.rests.length),
        1,
      );

      expect(document.meta?.author, 'Hear Me Out content team');
      expect(document.meta?.kind, 'piece');
      expect(document.meta?.tier, 'foundation');
      expect(document.meta?.stage, 3);
      expect(document.meta?.isEtude, isFalse);

      expect(AuthoringValidator(score).validate(), isEmpty);
    });

    test('roundtrips to a stable authoring document', () {
      final original = parseAuthoringDocument(
        loadContentFixture('valid_piece'),
      );
      final first = authoringToJson(original.score, meta: original.meta);
      final reparsed = parseAuthoringDocument(first);
      final second = authoringToJson(reparsed.score, meta: reparsed.meta);

      expect(first['schemaVersion'], authoringSchemaVersion);
      expect((first['authoring'] as Map<String, dynamic>)['stage'], 3);
      expect(jsonEncode(second), jsonEncode(first));
    });

    test('omits the authoring envelope when no metadata is supplied', () {
      final score = parseAuthoringScore(loadContentFixture('valid_piece'));
      final json = authoringToJson(score);

      expect(json.containsKey('authoring'), isFalse);
      expect(json['schemaVersion'], authoringSchemaVersion);
    });

    test('rejects a future authoring schema version', () {
      expect(
        () => parseAuthoringScore(loadContentFixture('future_schema')),
        throwsA(
          isA<AuthoringFormatException>()
              .having((error) => error.code, 'code', 'authoring.futureSchema')
              .having((error) => error.path, 'path', 'schemaVersion')
              .having(
                (error) => error.message,
                'message',
                allOf(contains('schemaVersion'), contains('2')),
              ),
        ),
      );
    });

    test('rejects a missing authoring schema version', () {
      final json = copyContentFixture('valid_piece')..remove('schemaVersion');

      expect(
        () => parseAuthoringScore(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message.toString(),
            'message',
            contains('schemaVersion'),
          ),
        ),
      );
    });

    test('ignores unknown metadata and top-level fields', () {
      final json = copyContentFixture('valid_piece')..['futureTopLevel'] = true;
      final authoring = json['authoring'] as Map<String, dynamic>
        ..['futureReviewTool'] = <String, dynamic>{'name': 'example'};

      final document = parseAuthoringDocument(json);

      expect(document.score.piece.title, 'Original Study in G');
      expect(document.meta?.author, 'Hear Me Out content team');
      expect(authoring.containsKey('futureReviewTool'), isTrue);
    });

    test('reports the exact path of a structural score error', () {
      final json = copyContentFixture('valid_piece');
      eventAt(json, 0, 2)['durationBeats'] = 'slow';

      expect(
        () => parseAuthoringScore(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message.toString(),
            'message',
            contains('phrases[0].events[2].durationBeats'),
          ),
        ),
      );
    });

    test('rejects an authoring metadata value with the wrong type', () {
      final json = copyContentFixture('valid_piece');
      (json['authoring'] as Map<String, dynamic>)['stage'] = 'third';

      expect(
        () => parseAuthoringScore(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message.toString(),
            'message',
            contains('authoring.stage'),
          ),
        ),
      );
    });

    test('authoring code stays free of Flutter and dart:io', () {
      final library = File('lib/content/score/authoring.dart')
          .readAsStringSync();
      final cli = File('tool/content/validate_piece.dart').readAsStringSync();

      expect(library, isNot(contains('package:flutter/')));
      expect(library, isNot(contains('dart:io')));
      expect(library, isNot(contains('dart:ui')));
      expect(cli, isNot(contains('package:flutter/')));
      expect(cli, isNot(contains('dart:ui')));
    });
  });

  group('authoring validation', () {
    final invalidFixtures = <String, ({String code, String path})>{
      'invalid_chord': (code: 'monophonic.chord', path: 'phrases[0].events[1]'),
      'invalid_overlap': (
        code: 'monophonic.overlap',
        path: 'phrases[0].events[1]',
      ),
      'invalid_bar': (code: 'bar.durationMismatch', path: 'phrases[0].events'),
      'invalid_tie': (
        code: 'tie.mismatch',
        path: 'phrases[3].events[0].tieToNext',
      ),
      'invalid_fingering': (
        code: 'fingering.mismatch',
        path: 'phrases[0].events[0]',
      ),
      'invalid_license': (
        code: 'piece.licenseNotV1Compatible',
        path: 'piece.license',
      ),
    };

    for (final entry in invalidFixtures.entries) {
      test('rejects ${entry.key} with a specific code and path', () {
        final document = parseAuthoringDocument(loadContentFixture(entry.key));
        final issues = AuthoringValidator(document.score).validate();

        expectIssue(issues, code: entry.value.code, path: entry.value.path);
      });
    }

    test('rejects the future schema fixture at the CLI boundary', () {
      final out = StringBuffer();
      final err = StringBuffer();
      final code = runCli(
        ['test/fixtures/content/future_schema.json'],
        out: out,
        err: err,
      );

      expect(code, 1);
      expect(out.toString(), contains('authoring.futureSchema'));
      expect(out.toString(), contains('schemaVersion'));
      expect(err.toString(), isEmpty);
    });

    test('rejects a sounding pitch that disagrees with the written note', () {
      final json = copyContentFixture('valid_piece');
      // G3 sounds as MIDI 43; 55 is the written MIDI number, not the sounding
      // one. The validator must re-derive the pair, never trust the field.
      eventAt(json, 0, 0)['soundingMidi'] = 55;

      final document = parseAuthoringDocument(json);
      final issues = AuthoringValidator(document.score).validate();

      expectIssue(
        issues,
        code: 'note.writtenSoundingMismatch',
        path: 'phrases[0].events[0].soundingMidi',
      );
    });

    test('warns for tempo outside the V1 range', () {
      final json = copyContentFixture('valid_piece');
      phraseAt(json, 0)['targetTempoBpm'] = 100;

      final document = parseAuthoringDocument(json);
      final issues = AuthoringValidator(document.score).validate();

      expectIssue(
        issues,
        code: 'authoring.tempoOutsideV1',
        path: 'phrases[0].targetTempoBpm',
        error: false,
      );
    });

    test('rejects a note outside the written range', () {
      final json = copyContentFixture('valid_piece');
      final event = eventAt(json, 0, 0)
        ..['writtenNote'] = 'A6'
        ..['soundingMidi'] = 81
        ..['string'] = 1
        ..['fret'] = 17;

      final document = parseAuthoringDocument(json);
      final issues = AuthoringValidator(document.score).validate();

      expect(event['writtenNote'], 'A6');
      expectIssue(
        issues,
        code: 'authoring.noteOutOfRange',
        path: 'phrases[0].events[0].writtenNote',
      );
    });

    test('warns above the beginner fret range and rejects above fret 19', () {
      final highJson = copyContentFixture('valid_piece');
      final highEvent = eventAt(highJson, 0, 0)
        ..['writtenNote'] = 'F4'
        ..['soundingMidi'] = 53
        ..['string'] = 6
        ..['fret'] = 13;
      final highDocument = parseAuthoringDocument(highJson);
      final highIssues = AuthoringValidator(highDocument.score).validate();

      expect(highEvent['fret'], 13);
      expectIssue(
        highIssues,
        code: 'authoring.highFret',
        path: 'phrases[0].events[0].fret',
        error: false,
      );

      final extremeJson = copyContentFixture('valid_piece');
      eventAt(extremeJson, 0, 0)
        ..['writtenNote'] = 'C5'
        ..['soundingMidi'] = 60
        ..['string'] = 6
        ..['fret'] = 20;
      final extremeDocument = parseAuthoringDocument(extremeJson);
      final extremeIssues = AuthoringValidator(extremeDocument.score)
          .validate();

      expectIssue(
        extremeIssues,
        code: 'authoring.fretAboveV1Max',
        path: 'phrases[0].events[0].fret',
      );
    });

    test('warns when a score shifts position too often', () {
      final json = copyContentFixture('valid_piece');
      eventAt(json, 0, 1)
        ..['writtenNote'] = 'E4'
        ..['soundingMidi'] = 52
        ..['string'] = 6
        ..['fret'] = 12;

      final document = parseAuthoringDocument(json);
      final issues = AuthoringValidator(document.score).validate();

      expectIssue(
        issues,
        code: 'authoring.tooManyShifts',
        path: 'phrases[3].events[0]',
        error: false,
      );
    });

    test('rejects a note without explicit fingering', () {
      final json = copyContentFixture('valid_piece');
      eventAt(json, 0, 0)
        ..remove('string')
        ..remove('fret');

      final document = parseAuthoringDocument(json);
      final issues = AuthoringValidator(document.score).validate();

      expectIssue(
        issues,
        code: 'authoring.missingFingering',
        path: 'phrases[0].events[0]',
      );
    });

    test('rejects a phrase longer than four bars', () {
      final json = copyContentFixture('valid_piece');
      phraseAt(json, 0)['bars'] = 5;

      final document = parseAuthoringDocument(json);
      final issues = AuthoringValidator(document.score).validate();

      expectIssue(
        issues,
        code: 'authoring.phraseTooLong',
        path: 'phrases[0].bars',
      );
    });
  });

  group('validator CLI', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('hear_me_out_authoring_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    String writeJson(String name, Map<String, dynamic> json) {
      final file = File('${tempDir.path}/$name.json');
      file.writeAsStringSync(jsonEncode(json));
      return file.path;
    }

    test('exits 0 for the valid fixture', () {
      final out = StringBuffer();
      final err = StringBuffer();

      final code = runCli(
        ['test/fixtures/content/valid_piece.json'],
        out: out,
        err: err,
      );

      expect(code, 0);
      expect(out.toString(), contains('PASS'));
      expect(out.toString(), contains('0 error(s), 0 warning(s)'));
      expect(err.toString(), isEmpty);
    });

    test('exits 1 and prints a specific code for an invalid fixture', () {
      final out = StringBuffer();
      final err = StringBuffer();

      final code = runCli(
        ['test/fixtures/content/invalid_chord.json'],
        out: out,
        err: err,
      );

      expect(code, 1);
      expect(out.toString(), contains('monophonic.chord'));
      expect(out.toString(), contains('phrases[0].events[1]'));
      expect(err.toString(), isEmpty);
    });

    test('prints one JSON object with --json', () {
      final out = StringBuffer();

      final code = runCli(
        ['test/fixtures/content/invalid_overlap.json', '--json'],
        out: out,
        err: StringBuffer(),
      );
      final payload = jsonDecode(out.toString()) as Map<String, dynamic>;

      expect(code, 1);
      expect(payload['valid'], isFalse);
      expect(payload['errors'], 1);
      expect(payload['warnings'], 0);
      expect(payload['issues'], isA<List<dynamic>>());
      final first =
          (payload['issues'] as List<dynamic>).first as Map<String, dynamic>;
      expect(first['severity'], 'error');
      expect(first['code'], 'monophonic.overlap');
      expect(first['path'], 'phrases[0].events[1]');
      expect(first['message'], isNotEmpty);
    });

    test('prints a clean JSON object for the valid fixture', () {
      final out = StringBuffer();

      final code = runCli(
        ['test/fixtures/content/valid_piece.json', '--json'],
        out: out,
        err: StringBuffer(),
      );
      final payload = jsonDecode(out.toString()) as Map<String, dynamic>;

      expect(code, 0);
      expect(
        payload.keys,
        containsAll(['valid', 'errors', 'warnings', 'issues']),
      );
      expect(payload['valid'], isTrue);
      expect(payload['errors'], 0);
      expect(payload['warnings'], 0);
      expect(payload['issues'], isEmpty);
    });

    test('warnings pass by default and fail under --strict', () {
      final json = copyContentFixture('valid_piece');
      phraseAt(json, 0)['targetTempoBpm'] = 100;
      final path = writeJson('warning_tempo', json);

      final normalOut = StringBuffer();
      final normalCode = runCli([path], out: normalOut, err: StringBuffer());
      expect(normalCode, 0);
      expect(normalOut.toString(), contains('authoring.tempoOutsideV1'));
      expect(normalOut.toString(), contains('1 warning(s)'));

      final strictOut = StringBuffer();
      final strictCode = runCli(
        [path, '--strict'],
        out: strictOut,
        err: StringBuffer(),
      );
      expect(strictCode, 1);
      expect(strictOut.toString(), contains('FAIL'));
    });

    test(
      '--summary prints piece, tier, stage, bars, tempo, range, and notes',
      () {
        final out = StringBuffer();

        final code = runCli(
          ['test/fixtures/content/valid_piece.json', '--summary'],
          out: out,
          err: StringBuffer(),
        );
        final text = out.toString();

        expect(code, 0);
        expect(text, contains('Piece: Original Study in G'));
        expect(text, contains('Tier: foundation'));
        expect(text, contains('Stage: 3'));
        expect(text, contains('Phrases: 4'));
        expect(text, contains('Bars: 4'));
        expect(text, contains('Tempo: 72 BPM'));
        expect(text, contains('Range: written G3-G5, sounding G2-G4'));
        expect(text, contains('Notes: 15'));
        expect(text, contains('Rests: 1'));
      },
    );

    test('--summary warns about phrase count but does not fail', () {
      final json = copyContentFixture('valid_piece');
      (json['phrases'] as List<dynamic>).removeRange(1, 4);
      final path = writeJson('one_phrase', json);

      final out = StringBuffer();
      final code = runCli([path, '--summary'], out: out, err: StringBuffer());

      expect(code, 0);
      expect(out.toString(), contains('Phrases: 1'));
      expect(out.toString(), contains('authoring.phraseCount'));
      expect(out.toString(), contains('Etudes may use fewer'));
    });

    test('--summary suppresses the phrase warning for etudes', () {
      final json = copyContentFixture('valid_piece');
      (json['phrases'] as List<dynamic>).removeRange(1, 4);
      (json['authoring'] as Map<String, dynamic>)['kind'] = 'etude';
      final path = writeJson('etude', json);

      final out = StringBuffer();
      final code = runCli([path, '--summary'], out: out, err: StringBuffer());

      expect(code, 0);
      expect(out.toString(), contains('Kind: etude'));
      expect(out.toString(), isNot(contains('authoring.phraseCount')));
    });

    test('--summary --json includes the summary object', () {
      final out = StringBuffer();

      final code = runCli(
        ['test/fixtures/content/valid_piece.json', '--summary', '--json'],
        out: out,
        err: StringBuffer(),
      );
      final payload = jsonDecode(out.toString()) as Map<String, dynamic>;
      final summary = payload['summary'] as Map<String, dynamic>;

      expect(code, 0);
      expect(summary['title'], 'Original Study in G');
      expect(summary['tier'], 'foundation');
      expect(summary['stage'], 3);
      expect(summary['phrases'], 4);
      expect(summary['bars'], 4);
      expect(summary['tempoBpm'], {'min': 72, 'max': 72});
      expect(summary['notes'], 15);
      expect(summary['rests'], 1);
    });

    test('--summary preserves authored flat spellings', () {
      final json = copyContentFixture('valid_piece');
      final piece = json['piece'] as Map<String, dynamic>;
      piece['id'] = 'flat-study';
      piece['title'] = 'Flat Study';
      json['phrases'] = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'flat-study-p1',
          'bars': 1,
          'timeSignature': <String, dynamic>{'numerator': 4, 'denominator': 4},
          'targetTempoBpm': 72,
          'difficulty': 1,
          'startBar': 1,
          'pickupBeats': 0.0,
          'events': <Map<String, dynamic>>[
            for (var beat = 0; beat < 4; beat++)
              <String, dynamic>{
                'startBeat': beat,
                'durationBeats': 1,
                'kind': 'note',
                'writtenNote': 'Bb4',
                'soundingMidi': 58,
                'string': 3,
                'fret': 3,
              },
          ],
        },
      ];
      (json['authoring'] as Map<String, dynamic>)['kind'] = 'etude';
      final path = writeJson('flat_study', json);

      final textOut = StringBuffer();
      final textCode = runCli(
        [path, '--summary'],
        out: textOut,
        err: StringBuffer(),
      );

      expect(textCode, 0);
      expect(textOut.toString(), contains('Range: written Bb4, sounding Bb3'));
      expect(textOut.toString(), isNot(contains('A#4')));
      expect(textOut.toString(), isNot(contains('A#3')));

      final jsonOut = StringBuffer();
      final jsonCode = runCli(
        [path, '--summary', '--json'],
        out: jsonOut,
        err: StringBuffer(),
      );
      final payload = jsonDecode(jsonOut.toString()) as Map<String, dynamic>;
      final range =
          (payload['summary'] as Map<String, dynamic>)['range']
              as Map<String, dynamic>;

      expect(jsonCode, 0);
      expect(range['written'], {'min': 'Bb4', 'max': 'Bb4'});
      expect(range['sounding'], {'min': 'Bb3', 'max': 'Bb3'});
    });

    test('rejects malformed JSON with a parse error', () {
      final file = File('${tempDir.path}/broken.json')
        ..writeAsStringSync('{not json');
      final out = StringBuffer();

      final code = runCli([file.path, '--json'], out: out, err: StringBuffer());
      final payload = jsonDecode(out.toString()) as Map<String, dynamic>;

      expect(code, 1);
      expect(payload['valid'], isFalse);
      expect(payload['errors'], 1);
      final issue =
          (payload['issues'] as List<dynamic>).first as Map<String, dynamic>;
      expect(issue['code'], 'authoring.invalidJson');
    });

    test('rejects a JSON root that is not an object', () {
      final file = File('${tempDir.path}/array.json')..writeAsStringSync('[]');
      final out = StringBuffer();

      final code = runCli([file.path, '--json'], out: out, err: StringBuffer());
      final payload = jsonDecode(out.toString()) as Map<String, dynamic>;

      expect(code, 1);
      expect(payload['valid'], isFalse);
      final issue =
          (payload['issues'] as List<dynamic>).first as Map<String, dynamic>;
      expect(issue['code'], 'authoring.invalidDocument');
      expect(issue['path'], '<document>');
    });

    test('exits 2 for usage errors and unreadable files', () {
      final noArgsOut = StringBuffer();
      final noArgsErr = StringBuffer();
      expect(runCli([], out: noArgsOut, err: noArgsErr), 2);
      expect(noArgsErr.toString(), contains('Missing score file'));

      final unknownErr = StringBuffer();
      expect(runCli(['--wat'], out: StringBuffer(), err: unknownErr), 2);
      expect(unknownErr.toString(), contains('Unknown option'));

      final twoFilesErr = StringBuffer();
      expect(
        runCli(
          [
            'test/fixtures/content/valid_piece.json',
            'test/fixtures/content/invalid_chord.json',
          ],
          out: StringBuffer(),
          err: twoFilesErr,
        ),
        2,
      );
      expect(twoFilesErr.toString(), contains('Only one score file'));

      final missingErr = StringBuffer();
      expect(
        runCli(
          ['test/fixtures/content/does_not_exist.json'],
          out: StringBuffer(),
          err: missingErr,
        ),
        2,
      );
      expect(missingErr.toString(), contains('Cannot read'));
    });

    test('exits 2 for a file that is not valid UTF-8', () {
      final file = File('${tempDir.path}/binary.json')
        ..writeAsBytesSync(<int>[0xff, 0xfe, 0x00]);
      final err = StringBuffer();

      final code = runCli([file.path], out: StringBuffer(), err: err);

      expect(code, 2);
      expect(err.toString(), contains('Cannot read'));
    });

    test('--help exits 0 and prints usage', () {
      final out = StringBuffer();

      final code = runCli(['--help'], out: out, err: StringBuffer());

      expect(code, 0);
      expect(out.toString(), contains('Usage:'));
      expect(out.toString(), contains('--strict'));
      expect(out.toString(), contains('--summary'));
    });
  });
}
