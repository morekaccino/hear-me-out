import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/content/pieces/phrase_objectives.dart';
import 'package:hear_me_out/features/phrase/phrase_loop_flag.dart';
import 'package:hear_me_out/features/phrase/phrase_player_screen.dart';

import 'support/phrase_fixtures.dart';

void main() {
  test('the phrase loop is off by default', () {
    expect(phraseLoopEnabled, isFalse);
  });

  test('the gated entry point returns null while the flag is off', () {
    final score = loadCorpusScore('foundation/ode-to-joy.json');
    expect(phrasePlayerFor(score.phrases.first), isNull);
  });

  test('the gated entry resolves through the T2.11 content registry', () {
    final registry = PhraseObjectiveRegistry();
    registry.registerScore(loadCorpusScore('foundation/ode-to-joy.json'));

    final record = registry.recordFor('ode-to-joy-p1');
    expect(record, isNotNull);
    expect(record!.piece.id, 'ode-to-joy');
    expect(record.phrase.id, 'ode-to-joy-p1');

    // The registry resolves the content, but the decision-0001 gate still keeps
    // the player unreachable.
    expect(
      phrasePlayerForPhraseId('ode-to-joy-p1', registry: registry),
      isNull,
    );
    expect(
      phrasePlayerForPhraseId('missing-phrase', registry: registry),
      isNull,
    );
  });

  test('main navigation has no phrase entry', () {
    const navigationFiles = <String>[
      'lib/features/home_shell.dart',
      'lib/features/path/path_screen.dart',
      'lib/features/practice/practice_screen.dart',
    ];
    for (final path in navigationFiles) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('PhrasePlayerScreen')), reason: path);
      expect(source, isNot(contains('phrasePlayerFor')), reason: path);
      expect(source, isNot(contains('features/phrase')), reason: path);
      expect(source, isNot(contains('phrase_player_screen')), reason: path);
    }
  });
}
