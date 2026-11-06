import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/note_segmenter.dart';
import 'package:hear_me_out/core/audio/phrase_prompt.dart';
import 'package:hear_me_out/core/audio/phrase_scorer.dart';
import 'package:hear_me_out/core/audio/phrase_verifier.dart';

import 'support/phrase_fixtures.dart';

void main() {
  late PhrasePlayPrompt prompt;
  late PhraseVerifier verifier;

  setUpAll(() {
    final score = loadCorpusScore('foundation/ode-to-joy.json');
    prompt = PhrasePlayPrompt(phrase: score.phrases.first);
    verifier = const PhraseVerifier();
  });

  group('PhraseVerifier on a real corpus phrase', () {
    test('a clean take is correct with one positive next step', () {
      final verification = verifier.verify(
        prompt: prompt,
        samples: renderPromptTake(prompt),
        sampleRate: 22050,
      );

      expect(verification.outcome, AttemptOutcome.correct);
      expect(verification.noteAccuracy, 1);
      expect(verification.timingWithinTolerance, isTrue);
      expect(verification.complete, isTrue);
      expect(verification.worstBar, isNull);
      expect(verification.confidence, greaterThanOrEqualTo(0.7));
      expect(verification.practicePass, isTrue);
      expect(verification.performanceReady, isTrue);
      expect(verification.updatesProgress, isTrue);
      expect(
        verification.correction,
        'Clean take. Keep this tempo and add the next bar.',
      );
    });

    test('one wrong note is incorrect and names the bar and notes', () {
      final verification = verifier.verify(
        prompt: prompt,
        samples: renderPromptTake(prompt, wrongMidi: {7: 62}),
        sampleRate: 22050,
      );

      expect(verification.outcome, AttemptOutcome.incorrect);
      expect(verification.complete, isTrue);
      expect(verification.worstBar, 2);
      expect(verification.noteAccuracy, lessThan(1));
      expect(verification.updatesProgress, isTrue);
      expect(verification.correction, 'Bar 2: E5 came out D5');
    });

    test('a missing note is an indeterminate retry and records nothing', () {
      final verification = verifier.verify(
        prompt: prompt,
        samples: renderPromptTake(prompt, skip: {3}),
        sampleRate: 22050,
      );

      expect(verification.outcome, AttemptOutcome.indeterminate);
      expect(verification.complete, isFalse);
      expect(verification.worstBar, isNull);
      expect(verification.updatesProgress, isFalse);
      expect(
        verification.correction,
        'Could not hear the whole phrase — try again.',
      );
      expect(verification.correction, isNot(contains('wrong')));
      expect(verification.correction, isNot(contains('Bar')));
    });

    test('rushed or dragged timing is incorrect with a timing correction', () {
      final verification = verifier.verify(
        prompt: prompt,
        samples: renderPromptTake(prompt, onsetShiftSeconds: 0.12),
        sampleRate: 22050,
      );

      expect(verification.outcome, AttemptOutcome.incorrect);
      expect(verification.timingWithinTolerance, isFalse);
      expect(verification.worstBar, isNotNull);
      expect(verification.correction, contains('dragged'));
      expect(verification.correction, contains('Keep the pulse'));
      expect(verification.correction, startsWith('Bar '));
    });

    test('an extra note is incorrect', () {
      final last = prompt.targets.last;
      final verification = verifier.verify(
        prompt: prompt,
        samples: renderPromptTake(
          prompt,
          extras: [(midi: 50, atSeconds: last.onsetSeconds + 0.8)],
        ),
        sampleRate: 22050,
      );

      expect(verification.outcome, AttemptOutcome.incorrect);
      expect(verification.result.extraNotes, greaterThanOrEqualTo(1));
      expect(verification.updatesProgress, isTrue);
    });

    test('a determinate but low-confidence take withholds bar feedback', () {
      final target = prompt.targetNotes;
      final detected = <DetectedNote>[
        for (var index = 0; index < target.length; index++)
          DetectedNote(
            startSeconds: target[index].onsetSeconds,
            durationSeconds: 0.4,
            midi: index == 7 ? target[index].midi - 2 : target[index].midi,
            cents: 0,
            confidence: 0.65,
            sampleIndex: (target[index].onsetSeconds * 22050).round(),
          ),
      ];
      final result = PhraseScorer(sampleRate: 22050)
          .scoreDetections(target: target, detected: detected, bpm: 72);

      final verification = verifier.fromResult(prompt: prompt, result: result);

      expect(verification.outcome, AttemptOutcome.incorrect);
      expect(verification.complete, isTrue);
      expect(verification.confidence, lessThan(0.7));
      expect(verification.worstBar, isNull);
      expect(verification.correction, isNot(contains('Bar ')));
      expect(verification.correction, contains('Play it once more'));
    });
  });
}
