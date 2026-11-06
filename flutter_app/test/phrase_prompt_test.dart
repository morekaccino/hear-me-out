import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/phrase_prompt.dart';
import 'package:hear_me_out/core/audio/phrase_scorer.dart';
import 'package:hear_me_out/core/music/phrase.dart';

import 'support/phrase_fixtures.dart';

void main() {
  group('PhrasePlayPrompt from a real corpus phrase', () {
    late Phrase phrase;
    late PhrasePlayPrompt prompt;

    setUpAll(() {
      final score = loadCorpusScore('foundation/ode-to-joy.json');
      phrase = score.phrases.first;
      prompt = PhrasePlayPrompt(phrase: phrase);
    });

    test('carries the phrase, tempo, tolerances, and backing spec', () {
      expect(phrase.id, 'ode-to-joy-p1');
      expect(prompt.bpm, 72);
      expect(prompt.timingToleranceMs, PhraseScorer.timingToleranceForBpm(72));
      expect(prompt.intonationToleranceCents, 30);
      expect(prompt.countInBeats, 4);
      expect(prompt.backing.clickMode, PhraseClickMode.visualCountIn);
      expect(prompt.backing.audible, isFalse);
      expect(prompt.beatsPerBar, 4);
      expect(prompt.countInSeconds, closeTo(3.333333, 1e-5));
      expect(prompt.phraseSeconds, closeTo(6.666667, 1e-5));
      expect(prompt.recordingDurationSeconds, closeTo(10, 1e-5));
    });

    test('converts written notes to sounding targets on the fixed grid', () {
      expect(prompt.targets, hasLength(8));
      expect(prompt.targetNotes, hasLength(8));

      final expectedMidi = [66, 66, 67, 69, 69, 67, 66, 64];
      final expectedNames = ['F#5', 'F#5', 'G5', 'A5', 'A5', 'G5', 'F#5', 'E5'];
      for (var index = 0; index < 8; index++) {
        final target = prompt.targets[index];
        final beat = 60 / 72;
        expect(target.index, index);
        expect(target.midi, expectedMidi[index]);
        expect(target.writtenNote.id, expectedNames[index]);
        expect(target.startBeat, closeTo(index.toDouble(), 1e-9));
        expect(
          target.onsetSeconds,
          closeTo(prompt.countInSeconds + index * beat, 1e-9),
        );
        expect(target.durationBeats, 1);
        expect(target.durationSeconds, closeTo(beat, 1e-9));
        expect(target.bar, index < 4 ? 0 : 1);
        expect(target.displayBar, index < 4 ? 1 : 2);
        expect(target.beatInBar, (index % 4) + 1);
      }
    });

    test('preview spec uses sounding pitch and no count-in', () {
      final preview = prompt.previewSpec;
      expect(preview.bpm, 72);
      expect(preview.events, hasLength(8));
      expect(preview.events.first.midi, 66);
      expect(preview.events.first.startBeat, 0);
      expect(preview.events.last.startBeat, 7);
      expect(preview.events.last.midi, 64);
    });
  });

  group('pickup and rest handling', () {
    late PhrasePlayPrompt prompt;

    setUpAll(() {
      final score = loadCorpusScore('returner/londonderry-air.json');
      prompt = PhrasePlayPrompt(phrase: score.phrases.first);
    });

    test('a two-beat pickup shifts bar and beat labels without shifting time', () {
      final phrase = prompt.phrase;
      expect(phrase.pickupBeats, 2);
      expect(prompt.targets, hasLength(21));
      expect(prompt.phraseSeconds, closeTo(14 * 60 / 54, 1e-9));

      final first = prompt.targets.first;
      expect(first.startBeat, 0.5);
      expect(first.writtenNote.id, 'F#4');
      expect(first.midi, 54);
      expect(first.displayBar, 1);
      expect(first.beatInBar, 1.5);
      expect(
        first.onsetSeconds,
        closeTo(prompt.countInSeconds + 0.5 * 60 / 54, 1e-9),
      );

      // Beat 2.0 starts the first full bar, not the pickup.
      final barTwo = prompt.targets.firstWhere(
        (target) => (target.startBeat - 2.0).abs() < 1e-9,
      );
      expect(barTwo.writtenNote.id, 'B4');
      expect(barTwo.displayBar, 2);
      expect(barTwo.bar, 1);
      expect(barTwo.beatInBar, 1);

      // The pickup rest at beat 0 and the rest at beat 8 never become targets.
      expect(
        prompt.targets.where((target) => target.startBeat == 0).isEmpty,
        isTrue,
      );
      expect(
        prompt.targets.where((target) => target.startBeat == 8).isEmpty,
        isTrue,
      );
      expect(prompt.targets.last.displayBar, 4);
      expect(prompt.targets.last.bar, 3);
    });
  });

  group('tie handling', () {
    test('a tie is one attack with the summed duration', () {
      final score = loadCorpusScore('foundation/amazing-grace.json');
      final phrase = score.phrases.firstWhere(
        (candidate) => candidate.id == 'amazing-grace-p4',
      );
      final prompt = PhrasePlayPrompt(phrase: phrase);

      expect(prompt.targets, hasLength(1));
      final target = prompt.targets.single;
      expect(target.writtenNote.id, 'G4');
      expect(target.midi, 55);
      expect(target.startBeat, 0);
      expect(target.durationBeats, 5);
      expect(target.displayBar, 7);
      expect(target.beatInBar, 1);
      expect(target.onsetSeconds, closeTo(prompt.countInSeconds, 1e-9));
    });
  });

  test(
    'a target list is built from a real corpus phrase, not synthetic data',
    () {
      final score = loadCorpusScore('foundation/ode-to-joy.json');
      final prompt = PhrasePlayPrompt(phrase: score.phrases.first);
      expect(prompt.targets, isNotEmpty);
      expect(
        prompt.targets.map((target) => target.writtenNote.id).toSet(),
        containsAll(<String>['F#5', 'G5', 'A5', 'E5']),
      );
    },
  );
}
