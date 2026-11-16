import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/content/reference_take.dart';
import 'package:hear_me_out/core/content/reference_take_validator.dart';

import '../tool/content/validate_reference_takes.dart';

Map<String, dynamic> validTakeJson({
  String pieceId = 'ode-to-joy',
  String phraseId = 'ode-to-joy-p1',
  String variant = 'target',
  int bpm = 72,
  String file = 'audio/ode-to-joy-p1-target.wav',
  int durationMs = 8450,
  String guitar = 'steel-string acoustic, 6-string',
  String microphone = 'small-diaphragm condenser, 30 cm, 12th fret',
  String recordedOn = '2026-11-16',
  String consentId = 'rt-0007',
}) {
  return <String, dynamic>{
    'pieceId': pieceId,
    'phraseId': phraseId,
    'variant': variant,
    'bpm': bpm,
    'file': file,
    'durationMs': durationMs,
    'guitar': guitar,
    'microphone': microphone,
    'recordedOn': recordedOn,
    'consentId': consentId,
  };
}

Map<String, dynamic> manifestJson(
  List<Map<String, dynamic>> takes, {
  int schemaVersion = 1,
}) {
  return <String, dynamic>{'schemaVersion': schemaVersion, 'takes': takes};
}

ReferenceTakeManifest manifestWith(List<Map<String, dynamic>> takes) =>
    ReferenceTakeManifest.fromJson(manifestJson(takes));

Map<String, dynamic> takeJsonWith(Map<String, dynamic> overrides) {
  return validTakeJson()..addAll(overrides);
}

Matcher isReferenceTakeError(String code, String path) {
  return throwsA(
    isA<ReferenceTakeFormatException>()
        .having((error) => error.code, 'code', code)
        .having((error) => error.path, 'path', path),
  );
}

final ReferenceTakeCatalog testCatalog = MapReferenceTakeCatalog(
  const <ReferenceTakePhrase>[
    ReferenceTakePhrase(
      pieceId: 'ode-to-joy',
      phraseId: 'ode-to-joy-p1',
      targetTempoBpm: 72,
    ),
    ReferenceTakePhrase(
      pieceId: 'amazing-grace',
      phraseId: 'amazing-grace-p1',
      targetTempoBpm: 66,
    ),
  ],
);

List<ReferenceTakeIssue> validateTakes(List<Map<String, dynamic>> takes) {
  return ReferenceTakeValidator(testCatalog).validate(manifestWith(takes));
}

void expectIssue(
  List<ReferenceTakeIssue> issues, {
  required String code,
  required String path,
}) {
  expect(
    issues.any((issue) => issue.code == code && issue.path == path),
    isTrue,
    reason: issues.map((issue) => issue.toString()).join('\n'),
  );
}

void main() {
  group('reference-take parser', () {
    test('parses one take and round-trips the manifest', () {
      final json = manifestJson(<Map<String, dynamic>>[validTakeJson()]);
      final manifest = ReferenceTakeManifest.fromJson(json);
      final take = manifest.takes.single;

      expect(take.pieceId, 'ode-to-joy');
      expect(take.phraseId, 'ode-to-joy-p1');
      expect(take.variant, ReferenceTakeVariant.target);
      expect(take.bpm, 72);
      expect(take.file, 'audio/ode-to-joy-p1-target.wav');
      expect(take.durationMs, 8450);
      expect(take.guitar, 'steel-string acoustic, 6-string');
      expect(take.microphone, 'small-diaphragm condenser, 30 cm, 12th fret');
      expect(take.recordedOn, '2026-11-16');
      expect(take.consentId, 'rt-0007');
      expect(manifest.toJson(), json);
    });

    test('parses the empty manifest the app ships', () {
      final manifest = ReferenceTakeManifest.fromJson(<String, dynamic>{
        'schemaVersion': 1,
        'takes': <dynamic>[],
      });

      expect(manifest.takes, isEmpty);
      expect(manifest.toJson(), <String, dynamic>{
        'schemaVersion': 1,
        'takes': <dynamic>[],
      });
    });

    test('ignores unknown fields at the document and take levels', () {
      final json = manifestJson(<Map<String, dynamic>>[
        validTakeJson()..['futureTakeField'] = 'ignored',
      ])..['futureDocumentField'] = true;

      final manifest = ReferenceTakeManifest.fromJson(json);

      expect(
        manifest.toJson(),
        manifestJson(<Map<String, dynamic>>[validTakeJson()]),
      );
    });

    test('accepts integral JSON doubles for bpm and durationMs', () {
      final json = manifestJson(<Map<String, dynamic>>[
        validTakeJson()..['bpm'] = 72.0,
      ])..['takes'][0]['durationMs'] = 8450.0;

      final take = ReferenceTakeManifest.fromJson(json).takes.single;

      expect(take.bpm, 72);
      expect(take.durationMs, 8450);
    });

    test('rejects a missing or malformed schemaVersion', () {
      final cases = <Map<String, dynamic>>[
        <String, dynamic>{'takes': <dynamic>[]},
        <String, dynamic>{'schemaVersion': '1', 'takes': <dynamic>[]},
        <String, dynamic>{'schemaVersion': 1.5, 'takes': <dynamic>[]},
        <String, dynamic>{'schemaVersion': null, 'takes': <dynamic>[]},
      ];

      for (final json in cases) {
        expect(
          () => ReferenceTakeManifest.fromJson(json),
          isReferenceTakeError('referenceTake.schemaVersion', 'schemaVersion'),
          reason: '$json',
        );
      }
    });

    test('rejects a future schemaVersion instead of guessing', () {
      expect(
        () => ReferenceTakeManifest.fromJson(
          manifestJson(<Map<String, dynamic>>[], schemaVersion: 2),
        ),
        isReferenceTakeError('referenceTake.futureSchema', 'schemaVersion'),
      );
    });

    test('rejects an unsupported older schemaVersion', () {
      expect(
        () => ReferenceTakeManifest.fromJson(
          manifestJson(<Map<String, dynamic>>[], schemaVersion: 0),
        ),
        isReferenceTakeError(
          'referenceTake.unsupportedSchema',
          'schemaVersion',
        ),
      );
    });

    test('rejects a takes value that is not a list', () {
      expect(
        () => ReferenceTakeManifest.fromJson(<String, dynamic>{
          'schemaVersion': 1,
          'takes': <String, dynamic>{},
        }),
        isReferenceTakeError('referenceTake.invalidTakes', 'takes'),
      );
      expect(
        () => ReferenceTakeManifest.fromJson(<String, dynamic>{
          'schemaVersion': 1,
        }),
        isReferenceTakeError('referenceTake.invalidTakes', 'takes'),
      );
    });

    test('rejects a take that is not an object', () {
      expect(
        () => ReferenceTakeManifest.fromJson(<String, dynamic>{
          'schemaVersion': 1,
          'takes': <dynamic>[1],
        }),
        isReferenceTakeError('referenceTake.invalidTake', 'takes[0]'),
      );
    });

    test('rejects an unknown variant', () {
      expect(
        () => manifestWith(<Map<String, dynamic>>[
          validTakeJson(variant: 'fast'),
        ]),
        isReferenceTakeError(
          'referenceTake.invalidVariant',
          'takes[0].variant',
        ),
      );
    });

    test('rejects every missing required field with its exact path', () {
      const fields = <String>[
        'pieceId',
        'phraseId',
        'variant',
        'bpm',
        'file',
        'durationMs',
        'guitar',
        'microphone',
        'recordedOn',
        'consentId',
      ];

      for (final field in fields) {
        final take = validTakeJson()..remove(field);
        expect(
          () => manifestWith(<Map<String, dynamic>>[take]),
          isReferenceTakeError('referenceTake.missingField', 'takes[0].$field'),
          reason: 'field $field',
        );
      }
    });

    test('rejects every wrong field type', () {
      final wrongTypes = <String, Object>{
        'pieceId': 1,
        'phraseId': true,
        'variant': 1,
        'bpm': '72',
        'file': 3,
        'durationMs': '8450',
        'guitar': <String>[],
        'microphone': 5,
        'recordedOn': 20261116,
        'consentId': <String, dynamic>{},
      };

      for (final entry in wrongTypes.entries) {
        final take = takeJsonWith(<String, dynamic>{entry.key: entry.value});
        expect(
          () => manifestWith(<Map<String, dynamic>>[take]),
          isReferenceTakeError(
            'referenceTake.invalidType',
            'takes[0].${entry.key}',
          ),
          reason: 'field ${entry.key}',
        );
      }
    });

    test('rejects a recordedOn that is not a date-only value', () {
      const values = <String>[
        '2026-11-16T00:00:00Z',
        '16-11-2026',
        '2026-02-30',
        '2026-13-01',
        '2026-11-16 ',
      ];

      for (final value in values) {
        expect(
          () => manifestWith(<Map<String, dynamic>>[
            validTakeJson(recordedOn: value),
          ]),
          isReferenceTakeError(
            'referenceTake.invalidDate',
            'takes[0].recordedOn',
          ),
          reason: value,
        );
      }
    });

    test('accepts a real leap day', () {
      final manifest = manifestWith(<Map<String, dynamic>>[
        validTakeJson(recordedOn: '2024-02-29'),
      ]);

      expect(manifest.takes.single.recordedOn, '2024-02-29');
    });
  });

  group('reference-take validator', () {
    test('accepts the empty manifest', () {
      expect(validateTakes(<Map<String, dynamic>>[]), isEmpty);
    });

    test('accepts a target and a slow take for the same phrase', () {
      final issues = validateTakes(<Map<String, dynamic>>[
        validTakeJson(),
        validTakeJson(
          variant: 'slow',
          bpm: 54,
          file: 'audio/ode-to-joy-p1-slow.wav',
        ),
      ]);

      expect(issues, isEmpty);
    });

    test('accepts the slow envelope boundaries', () {
      for (final bpm in <int>[44, 54]) {
        final issues = validateTakes(<Map<String, dynamic>>[
          validTakeJson(
            variant: 'slow',
            bpm: bpm,
            file: 'audio/ode-to-joy-p1-slow.wav',
          ),
        ]);

        expect(issues, isEmpty, reason: '$bpm BPM');
      }
    });

    test('uses each phrase declared target tempo', () {
      final issues = validateTakes(<Map<String, dynamic>>[
        validTakeJson(
          pieceId: 'amazing-grace',
          phraseId: 'amazing-grace-p1',
          bpm: 66,
          file: 'audio/amazing-grace-p1-target.wav',
        ),
      ]);

      expect(issues, isEmpty);
    });

    test('rejects an unknown piece', () {
      final issues = validateTakes(<Map<String, dynamic>>[
        validTakeJson(pieceId: 'ode-to-joy-2'),
      ]);

      expectIssue(
        issues,
        code: 'referenceTake.unknownPiece',
        path: 'takes[0].pieceId',
      );
    });

    test('rejects an unknown phrase', () {
      final issues = validateTakes(<Map<String, dynamic>>[
        validTakeJson(phraseId: 'ode-to-joy-p9'),
      ]);

      expectIssue(
        issues,
        code: 'referenceTake.unknownPhrase',
        path: 'takes[0].phraseId',
      );
    });

    test('rejects blank pieceId and phraseId values', () {
      final issues = validateTakes(<Map<String, dynamic>>[
        takeJsonWith(<String, dynamic>{'pieceId': '   ', 'phraseId': ''}),
      ]);

      expectIssue(
        issues,
        code: 'referenceTake.missingKey',
        path: 'takes[0].pieceId',
      );
      expectIssue(
        issues,
        code: 'referenceTake.missingKey',
        path: 'takes[0].phraseId',
      );
    });

    test('rejects a duplicate (pieceId, phraseId, variant)', () {
      final issues = validateTakes(<Map<String, dynamic>>[
        validTakeJson(),
        validTakeJson(file: 'audio/ode-to-joy-p1-target-copy.wav'),
      ]);

      expectIssue(issues, code: 'referenceTake.duplicateKey', path: 'takes[1]');
    });

    test('rejects a target take at the wrong tempo', () {
      final issues = validateTakes(<Map<String, dynamic>>[
        validTakeJson(bpm: 73),
      ]);

      expectIssue(
        issues,
        code: 'referenceTake.bpmOutsideTempoEnvelope',
        path: 'takes[0].bpm',
      );
    });

    test('rejects slow takes outside 60-75 percent', () {
      for (final bpm in <int>[43, 55]) {
        final issues = validateTakes(<Map<String, dynamic>>[
          validTakeJson(
            variant: 'slow',
            bpm: bpm,
            file: 'audio/ode-to-joy-p1-slow.wav',
          ),
        ]);

        expectIssue(
          issues,
          code: 'referenceTake.bpmOutsideTempoEnvelope',
          path: 'takes[0].bpm',
        );
      }
    });

    test('rejects a zero or negative duration', () {
      for (final durationMs in <int>[0, -1]) {
        final issues = validateTakes(<Map<String, dynamic>>[
          validTakeJson(durationMs: durationMs),
        ]);

        expectIssue(
          issues,
          code: 'referenceTake.durationNotPositive',
          path: 'takes[0].durationMs',
        );
      }
    });

    test('rejects an empty file path', () {
      final issues = validateTakes(<Map<String, dynamic>>[
        validTakeJson(file: '   '),
      ]);

      expectIssue(
        issues,
        code: 'referenceTake.emptyFile',
        path: 'takes[0].file',
      );
    });

    test('rejects a duplicate file path', () {
      final issues = validateTakes(<Map<String, dynamic>>[
        validTakeJson(),
        validTakeJson(
          variant: 'slow',
          bpm: 54,
          file: validTakeJson()['file'] as String,
        ),
      ]);

      expectIssue(
        issues,
        code: 'referenceTake.duplicateFile',
        path: 'takes[1].file',
      );
    });

    test('reports every issue, not only the first', () {
      final issues = validateTakes(<Map<String, dynamic>>[
        takeJsonWith(<String, dynamic>{
          'pieceId': 'not-a-piece',
          'durationMs': 0,
          'file': '',
        }),
      ]);

      expect(issues, hasLength(3));
      expectIssue(
        issues,
        code: 'referenceTake.unknownPiece',
        path: 'takes[0].pieceId',
      );
      expectIssue(
        issues,
        code: 'referenceTake.durationNotPositive',
        path: 'takes[0].durationMs',
      );
      expectIssue(
        issues,
        code: 'referenceTake.emptyFile',
        path: 'takes[0].file',
      );
    });
  });

  group('reference-take asset', () {
    test('ships an empty, valid manifest', () {
      final file = File('assets/content/reference_takes/manifest.json');
      expect(file.existsSync(), isTrue);

      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final manifest = ReferenceTakeManifest.fromJson(decoded);

      expect(manifest.takes, isEmpty);
      expect(
        ReferenceTakeValidator(
          MapReferenceTakeCatalog(const <ReferenceTakePhrase>[]),
        ).validate(manifest),
        isEmpty,
      );
    });

    test('declares the manifest directory in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec, contains('- assets/content/reference_takes/'));
    });

    test('ships no audio until the human takes exist', () {
      final audioFiles = Directory('assets/content/reference_takes')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.wav'));

      expect(
        audioFiles,
        isEmpty,
        reason: 'T3.5 must not add placeholder or synthetic WAVs.',
      );
    });

    test('core stays free of Flutter, dart:io, and lib/content', () {
      for (final path in <String>[
        'lib/core/content/reference_take.dart',
        'lib/core/content/reference_take_validator.dart',
      ]) {
        final source = File(path).readAsStringSync();

        expect(source, isNot(contains('package:flutter/')), reason: path);
        expect(source, isNot(contains('dart:io')), reason: path);
        expect(source, isNot(contains('dart:ui')), reason: path);
        expect(source, isNot(contains('lib/content/')), reason: path);
      }
    });

    test('the CLI stays free of Flutter imports', () {
      final source = File('tool/content/validate_reference_takes.dart')
          .readAsStringSync();

      expect(source, isNot(contains('package:flutter/')));
      expect(source, isNot(contains('dart:ui')));
    });
  });

  group('reference-take CLI', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'hear_me_out_reference_takes_',
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    String writeManifest(String name, Map<String, dynamic> json) {
      final file = File('${tempDir.path}/$name.json')
        ..writeAsStringSync(jsonEncode(json));
      return file.path;
    }

    test('passes the shipped empty manifest against the real pieces', () {
      final out = StringBuffer();
      final code = runCli(
        <String>['assets/content/reference_takes/manifest.json'],
        out: out,
        err: StringBuffer(),
      );

      expect(code, 0);
      expect(out.toString(), contains('PASS'));
      expect(out.toString(), contains('0 error(s), 0 warning(s)'));
    });

    test('passes a take that resolves through the real piece registry', () {
      final path = writeManifest(
        'valid',
        manifestJson(<Map<String, dynamic>>[validTakeJson()]),
      );
      final out = StringBuffer();
      final code = runCli(<String>[path], out: out, err: StringBuffer());

      expect(code, 0);
      expect(out.toString(), contains('PASS'));
      expect(out.toString(), isNot(contains('error ')));
    });

    test('fails for an unknown phrase with exit 1', () {
      final path = writeManifest(
        'unknown_phrase',
        manifestJson(<Map<String, dynamic>>[
          validTakeJson(phraseId: 'ode-to-joy-p9'),
        ]),
      );
      final out = StringBuffer();
      final code = runCli(<String>[path], out: out, err: StringBuffer());

      expect(code, 1);
      expect(out.toString(), contains('referenceTake.unknownPhrase'));
      expect(out.toString(), contains('FAIL'));
      expect(out.toString(), contains('1 error(s), 0 warning(s).'));
    });

    test('prints one JSON object in --json mode', () {
      final validPath = writeManifest(
        'valid',
        manifestJson(<Map<String, dynamic>>[validTakeJson()]),
      );
      final validOut = StringBuffer();
      final validCode = runCli(
        <String>[validPath, '--json'],
        out: validOut,
        err: StringBuffer(),
      );
      final validPayload =
          jsonDecode(validOut.toString()) as Map<String, dynamic>;

      expect(validCode, 0);
      expect(validPayload['valid'], isTrue);
      expect(validPayload['errors'], 0);
      expect(validPayload['warnings'], 0);
      expect(validPayload['issues'], isEmpty);

      final invalidPath = writeManifest(
        'invalid',
        manifestJson(<Map<String, dynamic>>[validTakeJson(bpm: 73)]),
      );
      final invalidOut = StringBuffer();
      final invalidCode = runCli(
        <String>[invalidPath, '--json'],
        out: invalidOut,
        err: StringBuffer(),
      );
      final invalidPayload =
          jsonDecode(invalidOut.toString()) as Map<String, dynamic>;
      final issue =
          (invalidPayload['issues'] as List<dynamic>).single
              as Map<String, dynamic>;

      expect(invalidCode, 1);
      expect(invalidPayload['valid'], isFalse);
      expect(invalidPayload['errors'], 1);
      expect(issue['severity'], 'error');
      expect(issue['code'], 'referenceTake.bpmOutsideTempoEnvelope');
      expect(issue['path'], 'takes[0].bpm');
    });

    test('fails a future schemaVersion at the CLI boundary', () {
      final path = writeManifest(
        'future',
        manifestJson(<Map<String, dynamic>>[], schemaVersion: 2),
      );
      final out = StringBuffer();
      final code = runCli(<String>[path], out: out, err: StringBuffer());

      expect(code, 1);
      expect(out.toString(), contains('referenceTake.futureSchema'));
      expect(out.toString(), contains('schemaVersion'));
    });

    test('fails invalid JSON and a non-object root with exit 1', () {
      final broken = File('${tempDir.path}/broken.json')
        ..writeAsStringSync('{');
      final brokenOut = StringBuffer();
      expect(
        runCli(<String>[broken.path], out: brokenOut, err: StringBuffer()),
        1,
      );
      expect(brokenOut.toString(), contains('referenceTake.invalidJson'));

      final array = File('${tempDir.path}/array.json')..writeAsStringSync('[]');
      final arrayOut = StringBuffer();
      expect(
        runCli(<String>[array.path], out: arrayOut, err: StringBuffer()),
        1,
      );
      expect(arrayOut.toString(), contains('referenceTake.invalidDocument'));
      expect(arrayOut.toString(), contains('<document>'));
    });

    test('exits 2 for usage errors and unreadable files', () {
      final noArgsOut = StringBuffer();
      final noArgsErr = StringBuffer();
      expect(runCli(<String>[], out: noArgsOut, err: noArgsErr), 2);
      expect(noArgsErr.toString(), contains('Missing manifest file'));

      final unknownErr = StringBuffer();
      expect(
        runCli(<String>['--wat'], out: StringBuffer(), err: unknownErr),
        2,
      );
      expect(unknownErr.toString(), contains('Unknown option'));

      final twoFilesErr = StringBuffer();
      expect(
        runCli(
          <String>['a.json', 'b.json'],
          out: StringBuffer(),
          err: twoFilesErr,
        ),
        2,
      );
      expect(twoFilesErr.toString(), contains('Only one manifest'));

      final missingErr = StringBuffer();
      expect(
        runCli(
          <String>['${tempDir.path}/does_not_exist.json'],
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

      final code = runCli(<String>[file.path], out: StringBuffer(), err: err);

      expect(code, 2);
      expect(err.toString(), contains('Cannot read'));
    });

    test('--help exits 0 and prints usage', () {
      final out = StringBuffer();

      final code = runCli(<String>['--help'], out: out, err: StringBuffer());

      expect(code, 0);
      expect(out.toString(), contains('Usage:'));
      expect(out.toString(), contains('--json'));
      expect(out.toString(), contains('Exit codes:'));
    });
  });
}
