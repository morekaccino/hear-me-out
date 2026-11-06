import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/latency_rig.dart';

class _RigResult {
  const _RigResult({required this.code, required this.out, required this.err});

  final int code;
  final String out;
  final String err;
}

_RigResult _run(List<String> args) {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = runRig(args, out, err);
  return _RigResult(code: code, out: out.toString(), err: err.toString());
}

Map<String, dynamic> _singleJson(_RigResult result) {
  final lines = result.out
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .toList();
  expect(lines, hasLength(1), reason: 'stdout must be one JSON object');
  final decoded = jsonDecode(lines.single);
  expect(decoded, isA<Map<String, dynamic>>());
  return decoded as Map<String, dynamic>;
}

void main() {
  const reference = 'test/fixtures/audio/ref.wav';
  const take = 'test/fixtures/audio/take.wav';
  const late = 'test/fixtures/audio/late.wav';
  const expected = 'test/fixtures/audio/expected.json';
  const speaker = 'test/fixtures/audio/speaker.wav';
  const headphones = 'test/fixtures/audio/headphones.wav';

  group('loopback CLI', () {
    test('passes the documented 5 ms fixture with one JSON object', () {
      final result = _run([
        'loopback',
        '--reference',
        reference,
        '--recorded',
        take,
        '--json',
      ]);

      expect(result.code, 0);
      expect(result.err, isEmpty);
      final json = _singleJson(result);
      expect(json['timingUsable'], isTrue);
      expect(json['offsetVerified'], isTrue);
      expect(json['driftVerified'], isTrue);
      expect(json['offsetMs'], 5.0);
      expect(json['failures'], isEmpty);
      expect(json['gates'], isA<Map<String, dynamic>>());
    });

    test('fails the documented 25 ms fixture with exit 1', () {
      final result = _run([
        'loopback',
        '--reference',
        reference,
        '--recorded',
        late,
        '--json',
      ]);

      expect(result.code, 1);
      final json = _singleJson(result);
      expect(json['timingUsable'], isFalse);
      expect(json['offsetVerified'], isTrue);
      expect(json['offsetMs'], 25.0);
      expect(json['failures'], isNotEmpty);
    });

    test('honors a gate override', () {
      final result = _run([
        'loopback',
        '--reference',
        reference,
        '--recorded',
        late,
        '--max-offset-ms',
        '30',
        '--json',
      ]);

      expect(result.code, 0);
      final json = _singleJson(result);
      expect(json['timingUsable'], isTrue);
      expect(json['gates']['maxOffsetMs'], 30.0);
    });

    test('prints UNVERIFIED and n/a for an unaligned take', () {
      final directory = Directory.systemTemp.createTempSync('rig_unverified');
      try {
        final refPath = '${directory.path}/ref.wav';
        final takePath = '${directory.path}/take.wav';
        expect(
          _run([
            'generate',
            '--out',
            refPath,
            '--duration',
            '4',
            '--interval',
            '0.5',
            '--sample-rate',
            '16000',
          ]).code,
          0,
        );
        expect(
          _run([
            'simulate',
            '--reference',
            refPath,
            '--out',
            takePath,
            '--offset-ms',
            '-400',
          ]).code,
          0,
        );

        final table = _run([
          'loopback',
          '--reference',
          refPath,
          '--recorded',
          takePath,
        ]);
        expect(table.code, 1);
        expect(table.out, contains('UNVERIFIED'));
        expect(table.out, contains('n/a'));
        expect(table.out, contains('timingUsable: NO'));
        expect(table.out, isNot(contains('PASS')));

        final json = _singleJson(
          _run([
            'loopback',
            '--reference',
            refPath,
            '--recorded',
            takePath,
            '--json',
          ]),
        );
        expect(json['offsetVerified'], isFalse);
        expect(json['driftVerified'], isFalse);
        expect(json['offsetMs'], isNull);
        expect(json['driftMsPer60s'], isNull);
        expect(json['timingUsable'], isFalse);
      } finally {
        directory.deleteSync(recursive: true);
      }
    });
  });

  group('recall CLI', () {
    test('accepts the canonical onsetsSeconds manifest', () {
      final result = _run([
        'recall',
        '--recorded',
        take,
        '--expected',
        expected,
        '--json',
      ]);

      expect(result.code, 0);
      final json = _singleJson(result);
      expect(json['noteRecall'], 1.0);
      expect(json['recallUsable'], isTrue);
      expect(json['failures'], isEmpty);
    });

    test('accepts a bare array and a notes object', () {
      final directory = Directory.systemTemp.createTempSync('rig_manifest');
      try {
        final onsets = [
          for (var index = 0; index < 23; index++) 0.5 + index * 0.5,
        ];
        final arrayPath = '${directory.path}/array.json';
        final notesPath = '${directory.path}/notes.json';
        File(arrayPath).writeAsStringSync(jsonEncode(onsets));
        File(notesPath).writeAsStringSync(
          jsonEncode({
            'notes': [
              for (final onset in onsets) {'onsetSeconds': onset},
            ],
          }),
        );

        for (final path in [arrayPath, notesPath]) {
          final result = _run([
            'recall',
            '--recorded',
            take,
            '--expected',
            path,
            '--json',
          ]);
          expect(result.code, 0, reason: path);
          expect(_singleJson(result)['noteRecall'], 1.0);
        }
      } finally {
        directory.deleteSync(recursive: true);
      }
    });
  });

  group('bleed CLI', () {
    test('requires headphones for the documented speaker fixture', () {
      final result = _run([
        'bleed',
        '--speaker',
        speaker,
        '--headphones',
        headphones,
        '--expected',
        expected,
        '--json',
      ]);

      expect(result.code, 1);
      final json = _singleJson(result);
      expect(json['headphonesRequired'], isTrue);
      expect(json['speakerRecall'], closeTo(0.8696, 0.001));
      expect(json['headphoneRecall'], 1.0);
      expect(json['recallDrop'], closeTo(0.1304, 0.001));
      expect(json['speakerFalseOnsetsPerMinute'], closeTo(15.0, 0.1));
    });
  });

  group('bad input', () {
    test('missing file returns exit 2 with one JSON object', () {
      final result = _run([
        'loopback',
        '--reference',
        'missing.wav',
        '--recorded',
        'missing.wav',
        '--json',
      ]);

      expect(result.code, 2);
      final json = _singleJson(result);
      expect(json['error'], contains('File not found'));
      expect(json['exitCode'], 2);
    });

    test('unknown option returns exit 2 on stderr', () {
      final result = _run([
        'loopback',
        '--reference',
        reference,
        '--recorded',
        take,
        '--wat',
        '1',
      ]);

      expect(result.code, 2);
      expect(result.out, isEmpty);
      expect(result.err, contains('Unknown option'));
    });

    test('unknown command returns exit 2', () {
      final result = _run(['wat']);

      expect(result.code, 2);
      expect(result.err, contains('Unknown command'));
    });

    test('rejects a recall-drop gate above one', () {
      final result = _run([
        'recall',
        '--recorded',
        take,
        '--expected',
        expected,
        '--max-recall-drop',
        '2',
      ]);

      expect(result.code, 2);
      expect(result.err, contains('between 0 and 1'));
    });

    test('rejects a non-positive match window', () {
      final result = _run([
        'recall',
        '--recorded',
        take,
        '--expected',
        expected,
        '--match-window-ms',
        '0',
      ]);

      expect(result.code, 2);
      expect(result.err, contains('must be positive'));
    });
  });

  group('generate CLI', () {
    test('rejects a zero-click reference before writing a file', () {
      final directory = Directory.systemTemp.createTempSync('rig_generate');
      try {
        final outputPath = '${directory.path}/empty.wav';
        final result = _run([
          'generate',
          '--out',
          outputPath,
          '--duration',
          '0.4',
          '--interval',
          '1',
        ]);

        expect(result.code, 2);
        expect(result.err, contains('no clicks'));
        expect(File(outputPath).existsSync(), isFalse);
      } finally {
        directory.deleteSync(recursive: true);
      }
    });
  });

  test('--help exits 0 and documents every command', () {
    final result = _run(['--help']);

    expect(result.code, 0);
    expect(result.out, contains('loopback'));
    expect(result.out, contains('recall'));
    expect(result.out, contains('bleed'));
    expect(result.out, contains('Exit codes'));
  });
}
