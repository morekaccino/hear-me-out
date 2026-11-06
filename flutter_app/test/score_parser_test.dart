import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/music/score_parser.dart';

import 'support/score_fixtures.dart';

void main() {
  group('parseScore', () {
    test('parses a valid monophonic score', () {
      final score = parseScore(loadScoreFixture('valid_monophonic'));

      expect(score.piece.title, 'Open String Study');
      expect(score.piece.composer, 'Test Fixture');
      expect(score.piece.license, 'public-domain');
      expect(score.piece.tuning.isStandard, isTrue);
      expect(score.phrases, hasLength(1));

      final phrase = score.phrases.single;
      expect(phrase.id, 'fixture-valid-4-bar');
      expect(phrase.bars, 4);
      expect(phrase.targetTempoBpm, 80);
      expect(phrase.events, hasLength(16));
      expect(phrase.notes, hasLength(14));
      expect(phrase.rests, hasLength(2));
      expect(phrase.events.first.writtenNote?.id, 'G4');
      expect(phrase.events.first.soundingMidi, 55);
      expect(phrase.events[1].string, 3);
      expect(phrase.events[1].fret, 2);
    });

    test('roundtrips to a stable canonical document', () {
      final score = parseScore(loadScoreFixture('valid_monophonic'));
      final first = scoreToJson(score);
      final second = scoreToJson(parseScore(first));

      expect(first['schemaVersion'], scoreSchemaVersion);
      expect(jsonEncode(second), jsonEncode(first));
    });

    test('roundtrips pickup and tie fixtures', () {
      for (final name in ['pickup', 'tie']) {
        final score = parseScore(loadScoreFixture(name));
        final first = scoreToJson(score);
        final second = scoreToJson(parseScore(first));

        expect(jsonEncode(second), jsonEncode(first), reason: name);
      }
    });

    test('ignores unknown fields for forward compatibility', () {
      final json = loadScoreFixture('valid_monophonic');
      json['generator'] = 'unit-test';
      final piece = json['piece'] as Map<String, dynamic>;
      piece['futureField'] = true;
      final phrases = json['phrases'] as List<dynamic>;
      final phrase = phrases.first as Map<String, dynamic>;
      phrase['futureField'] = 1;
      final events = phrase['events'] as List<dynamic>;
      final event = events.first as Map<String, dynamic>;
      event['futureField'] = 'ignored';

      final score = parseScore(json);

      expect(score.piece.title, 'Open String Study');
      expect(score.phrases.single.events.first.soundingMidi, 55);
    });

    test('does not perform semantic validation while parsing', () {
      final score = parseScore(loadScoreFixture('written_sounding_mismatch'));

      expect(score.phrases.single.events.first.soundingMidi, 65);
      expect(
        score.validate().map((issue) => issue.code),
        contains('note.writtenSoundingMismatch'),
      );
    });
  });

  group('parseScore errors', () {
    test('rejects a future schemaVersion', () {
      final json = loadScoreFixture('valid_monophonic')..['schemaVersion'] = 2;

      expect(
        () => parseScore(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(contains('schemaVersion'), contains('2')),
          ),
        ),
      );
    });

    test('rejects a missing schemaVersion', () {
      final json = loadScoreFixture('valid_monophonic')
        ..remove('schemaVersion');

      expect(
        () => parseScore(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('schemaVersion'),
          ),
        ),
      );
    });

    test('rejects a non-integer schemaVersion', () {
      final json = loadScoreFixture('valid_monophonic')
        ..['schemaVersion'] = 'one';

      expect(
        () => parseScore(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('schemaVersion'),
          ),
        ),
      );
    });

    test('reports a bad piece field with its path', () {
      final json = loadScoreFixture('valid_monophonic');
      final piece = json['piece'] as Map<String, dynamic>;
      piece['title'] = 42;

      expect(
        () => parseScore(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('piece.title'),
          ),
        ),
      );
    });

    test('reports a bad nested event field with its path', () {
      final json = loadScoreFixture('valid_monophonic');
      final phrases = json['phrases'] as List<dynamic>;
      final phrase = phrases.first as Map<String, dynamic>;
      final events = phrase['events'] as List<dynamic>;
      final event = events.first as Map<String, dynamic>;
      event['durationBeats'] = 'slow';

      expect(
        () => parseScore(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('phrases[0].events[0].durationBeats'),
          ),
        ),
      );
    });

    test('rejects a missing phrases array with its path', () {
      final json = loadScoreFixture('valid_monophonic')..remove('phrases');

      expect(
        () => parseScore(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('phrases'),
          ),
        ),
      );
    });

    test('rejects a phrase that is not an object', () {
      final json = loadScoreFixture('valid_monophonic');
      (json['phrases'] as List<dynamic>)[0] = 'phrase';

      expect(
        () => parseScore(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('phrases[0]'),
          ),
        ),
      );
    });

    test('rejects an event that is not an object', () {
      final json = loadScoreFixture('valid_monophonic');
      final phrases = json['phrases'] as List<dynamic>;
      final phrase = phrases.first as Map<String, dynamic>;
      (phrase['events'] as List<dynamic>)[0] = 'note';

      expect(
        () => parseScore(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('phrases[0].events[0]'),
          ),
        ),
      );
    });
  });
}
