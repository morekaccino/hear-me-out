import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/alignment.dart';
import 'package:hear_me_out/core/audio/note_segmenter.dart';
import 'package:hear_me_out/core/audio/phrase_scorer.dart';

import 'support/audio_fixtures.dart';

const sampleRate = 22050;

class TestNote {
  const TestNote(
    this.midi,
    this.onset, {
    this.duration = 0.6,
    this.cents = 0,
    this.octave = 0,
  });

  final int midi;
  final double onset;
  final double duration;
  final double cents;
  final int octave;
}

List<TargetNote> makeTargets(
  List<int> midi, {
  double bpm = 60,
  double leadIn = 0.3,
  int beatsPerBar = 4,
  double durationBeats = 0.7,
}) {
  final beat = 60 / bpm;
  return [
    for (var index = 0; index < midi.length; index++)
      TargetNote(
        index: index,
        midi: midi[index],
        onsetSeconds: leadIn + index * beat,
        durationSeconds: beat * durationBeats,
        bar: index ~/ beatsPerBar,
      ),
  ];
}

List<double> renderTake(
  List<TestNote> notes, {
  double seconds = 8,
  double noise = 0,
  int seed = 1,
}) {
  final samples = silentTake(sampleRate, seconds);
  for (final note in notes) {
    addTone(
      samples,
      sampleRate,
      startSeconds: note.onset,
      durationSeconds: note.duration,
      midi: note.midi + note.octave,
      cents: note.cents,
    );
  }
  if (noise > 0) {
    addWhiteNoise(samples, amplitude: noise, seed: seed);
  }
  return samples;
}

List<TestNote> simpleNotes(
  List<int> midi, {
  double bpm = 60,
  double leadIn = 0.3,
}) {
  final beat = 60 / bpm;
  return [
    for (var index = 0; index < midi.length; index++)
      TestNote(midi[index], leadIn + index * beat, duration: beat * 0.6),
  ];
}

DetectedNote detected(
  int midi, {
  double onset = 0.3,
  double confidence = 0.95,
}) =>
    DetectedNote(
      startSeconds: onset,
      durationSeconds: 0.4,
      midi: midi,
      cents: 0,
      confidence: confidence,
      sampleIndex: (onset * sampleRate).round(),
    );

void main() {
  late PhraseScorer scorer;

  setUp(() {
    scorer = PhraseScorer(sampleRate: sampleRate.toDouble());
  });

  group('PhraseScorer perfect and partial takes', () {
    test('a perfect synthetic phrase is correct and performance ready', () {
      final target = makeTargets([64, 66, 67, 69]);
      final result = scorer.score(
        samples: renderTake(simpleNotes([64, 66, 67, 69])),
        target: target,
        bpm: 60,
      );

      expect(result.outcome, AttemptOutcome.correct);
      expect(result.performanceReady, isTrue);
      expect(result.practicePass, isTrue);
      expect(result.complete, isTrue);
      expect(result.timingWithinTolerance, isTrue);
      expect(result.noteAccuracy, 1);
      expect(result.extraNotes, 0);
      expect(result.notes.every((note) => note.outcome == AttemptOutcome.correct),
          isTrue);
      expect(result.meanOnsetErrorMs, isNotNull);
      expect(result.meanOnsetErrorMs!.abs(), lessThan(5));
      expect(result.medianCents!.abs(), lessThan(3));
    });

    test('a fast sixteenth-note phrase scores correctly', () {
      const bpm = 90.0;
      const beat = 60 / bpm;
      final midi = [64, 66, 67, 69, 71, 72, 74, 76];
      final target = <TargetNote>[
        for (var index = 0; index < midi.length; index++)
          TargetNote(
            index: index,
            midi: midi[index],
            onsetSeconds: 0.3 + index * beat / 4,
            durationSeconds: beat / 4 * 0.8,
            bar: index ~/ 8,
          ),
      ];
      final result = scorer.score(
        samples: renderTake([
          for (var index = 0; index < midi.length; index++)
            TestNote(
              midi[index],
              0.3 + index * beat / 4,
              duration: beat / 4 * 0.85,
            ),
        ]),
        target: target,
        bpm: bpm,
      );

      expect(result.outcome, AttemptOutcome.correct);
      expect(result.performanceReady, isTrue);
    });

    test('one semitone error is incorrect on exactly that note', () {
      final target = makeTargets([64, 66, 67, 69]);
      final notes = simpleNotes([64, 66, 67, 69]);
      final result = scorer.score(
        samples: renderTake([
          notes[0],
          TestNote(67, notes[1].onset, duration: notes[1].duration),
          notes[2],
          notes[3],
        ]),
        target: target,
        bpm: 60,
      );

      expect(result.outcome, AttemptOutcome.incorrect);
      expect(result.notes[1].outcome, AttemptOutcome.incorrect);
      expect(result.notes[1].detectedMidi, 67);
      expect(result.notes[0].outcome, AttemptOutcome.correct);
      expect(result.notes[2].outcome, AttemptOutcome.correct);
      expect(result.notes[3].outcome, AttemptOutcome.correct);
      expect(result.performanceReady, isFalse);
    });

    test('one missed note is indeterminate, never incorrect', () {
      final target = makeTargets([64, 66, 67, 69]);
      final notes = simpleNotes([64, 66, 67, 69]);
      final result = scorer.score(
        samples: renderTake([notes[0], notes[1], notes[3]]),
        target: target,
        bpm: 60,
      );

      expect(result.outcome, AttemptOutcome.indeterminate);
      expect(result.notes[2].outcome, AttemptOutcome.indeterminate);
      expect(result.notes[2].detectedMidi, isNull);
      expect(result.notes[0].outcome, AttemptOutcome.correct);
      expect(result.complete, isFalse);
      expect(result.performanceReady, isFalse);
    });

    test('one extra note is an error', () {
      final target = makeTargets([64, 66, 67, 69]);
      final notes = simpleNotes([64, 66, 67, 69]);
      final result = scorer.score(
        samples: renderTake([
          notes[0],
          const TestNote(50, 1.05, duration: 0.12),
          notes[1],
          notes[2],
          notes[3],
        ]),
        target: target,
        bpm: 60,
      );

      expect(result.outcome, AttemptOutcome.incorrect);
      expect(result.extraNotes, 1);
      expect(result.practicePass, isFalse);
      expect(result.performanceReady, isFalse);
    });

    test('an early stop is incomplete, not a failure', () {
      final target = makeTargets([64, 66, 67, 69]);
      final notes = simpleNotes([64, 66, 67, 69]);
      final result = scorer.score(
        samples: renderTake([notes[0], notes[1], notes[2]]),
        target: target,
        bpm: 60,
      );

      expect(result.outcome, AttemptOutcome.indeterminate);
      expect(result.earlyStop, isTrue);
      expect(result.complete, isFalse);
    });

    test('a false start is incomplete and does not consume a target', () {
      final target = makeTargets([64, 66, 67, 69]);
      final notes = simpleNotes([64, 66, 67, 69]);
      final result = scorer.score(
        samples: renderTake([
          const TestNote(64, 0.1, duration: 0.1),
          ...notes,
        ]),
        target: target,
        bpm: 60,
        countInSeconds: 0.3,
      );

      expect(result.falseStart, isTrue);
      expect(result.outcome, AttemptOutcome.indeterminate);
      expect(result.complete, isFalse);
      expect(result.notes.every((note) => note.outcome == AttemptOutcome.correct),
          isTrue);
      expect(result.extraNotes, 0);
    });

    test('silence is indeterminate', () {
      final result = scorer.score(
        samples: silentTake(sampleRate, 4),
        target: makeTargets([64, 66, 67, 69]),
        bpm: 60,
      );

      expect(result.outcome, AttemptOutcome.indeterminate);
      expect(result.complete, isFalse);
      expect(result.performanceReady, isFalse);
      expect(result.notes.every((note) => note.outcome == AttemptOutcome.indeterminate),
          isTrue);
    });

    test('noise only is indeterminate', () {
      final samples = silentTake(sampleRate, 4);
      addWhiteNoise(samples, amplitude: 0.1, seed: 4);
      final result = scorer.score(
        samples: samples,
        target: makeTargets([64, 66, 67, 69]),
        bpm: 60,
      );

      expect(result.outcome, AttemptOutcome.indeterminate);
      expect(result.complete, isFalse);
    });

    test('25 percent indeterminate makes the whole take indeterminate', () {
      final target = makeTargets([60, 62, 64, 65, 67, 69, 71, 72]);
      final notes = simpleNotes([60, 62, 64, 65, 67, 69, 71, 72]);
      final result = scorer.score(
        samples: renderTake([
          notes[0],
          notes[1],
          notes[3],
          notes[4],
          notes[5],
          notes[7],
        ]),
        target: target,
        bpm: 60,
      );

      final indeterminate =
          result.notes.where((note) => note.outcome == AttemptOutcome.indeterminate);
      expect(indeterminate.length, 2);
      expect(result.outcome, AttemptOutcome.indeterminate);
      expect(result.practicePass, isFalse);
    });
  });

  group('PhraseScorer timing against the fixed click grid', () {
    test('a rushed take fails with "rushed"', () {
      final target = makeTargets([64, 66, 67, 69]);
      final notes = simpleNotes([64, 66, 67, 69])
          .map((note) => TestNote(note.midi, note.onset - 0.08,
              duration: note.duration))
          .toList();
      final result = scorer.score(
        samples: renderTake(notes),
        target: target,
        bpm: 60,
      );

      expect(result.timingWithinTolerance, isFalse);
      expect(result.timingIssue, 'rushed');
      expect(result.outcome, AttemptOutcome.incorrect);
      expect(result.performanceReady, isFalse);
    });

    test('a dragged take fails with "dragged"', () {
      final target = makeTargets([64, 66, 67, 69]);
      final notes = simpleNotes([64, 66, 67, 69])
          .map((note) => TestNote(note.midi, note.onset + 0.08,
              duration: note.duration))
          .toList();
      final result = scorer.score(
        samples: renderTake(notes),
        target: target,
        bpm: 60,
      );

      expect(result.timingWithinTolerance, isFalse);
      expect(result.timingIssue, 'dragged');
      expect(result.outcome, AttemptOutcome.incorrect);
    });

    test('90 BPM passes a 50 ms tolerance but fails a 70 ms rush', () {
      final target = makeTargets([64, 66, 67, 69], bpm: 90);
      final perfect = scorer.score(
        samples: renderTake(simpleNotes([64, 66, 67, 69], bpm: 90)),
        target: target,
        bpm: 90,
      );
      expect(perfect.timingWithinTolerance, isTrue);
      expect(perfect.outcome, AttemptOutcome.correct);

      final rushedNotes = simpleNotes([64, 66, 67, 69], bpm: 90)
          .map((note) => TestNote(note.midi, note.onset - 0.07,
              duration: note.duration))
          .toList();
      final rushed = scorer.score(
        samples: renderTake(rushedNotes),
        target: target,
        bpm: 90,
      );
      expect(rushed.timingWithinTolerance, isFalse);
      expect(rushed.timingIssue, 'rushed');
    });

    test('DTW does not warp the fixed click grid', () {
      // Notes are all correct but each one lands later than the click: a
      // warped alignment could hide this. The scorer must not.
      final target = makeTargets([60, 62, 64, 65, 67, 69, 71, 72]);
      final notes = [
        for (var index = 0; index < 8; index++)
          TestNote(60 + [0, 2, 4, 5, 7, 9, 11, 12][index],
              target[index].onsetSeconds + index * 0.04,
              duration: 0.4),
      ];
      final result = scorer.score(
        samples: renderTake(notes),
        target: target,
        bpm: 60,
      );

      expect(result.timingWithinTolerance, isFalse);
      expect(result.timingIssue, 'dragged');
    });

    test('a bar-to-bar trend is reported as drift', () {
      final target = makeTargets([60, 62, 64, 65, 67, 69, 71, 72]);
      final notes = [
        for (var index = 0; index < 8; index++)
          TestNote(
            60 + [0, 2, 4, 5, 7, 9, 11, 12][index],
            target[index].onsetSeconds + (index < 4 ? -0.015 : 0.075),
            duration: 0.5,
          ),
      ];
      final result = scorer.score(
        samples: renderTake(notes),
        target: target,
        bpm: 60,
      );

      expect(result.driftMsPerBar, isNotNull);
      expect(result.driftMsPerBar!.abs(), greaterThan(50));
      expect(result.timingWithinTolerance, isFalse);
      expect(result.timingIssue, 'dragged');
    });

    test('timing tolerance follows the documented table', () {
      expect(PhraseScorer.timingToleranceForBpm(40), 100);
      expect(PhraseScorer.timingToleranceForBpm(60), 80);
      expect(PhraseScorer.timingToleranceForBpm(75), 65);
      expect(PhraseScorer.timingToleranceForBpm(90), 50);
      expect(PhraseScorer.timingToleranceForBpm(120), 40);
      expect(() => PhraseScorer.timingToleranceForBpm(0), throwsArgumentError);
    });
  });

  group('PhraseScorer pitch and intonation', () {
    test('an octave error is incorrect with the flag set', () {
      final target = makeTargets([64, 66, 67, 69]);
      final notes = simpleNotes([64, 66, 67, 69]);
      final result = scorer.score(
        samples: renderTake([
          notes[0],
          TestNote(notes[1].midi + 12, notes[1].onset,
              duration: notes[1].duration),
          notes[2],
          notes[3],
        ]),
        target: target,
        bpm: 60,
      );

      expect(result.outcome, AttemptOutcome.incorrect);
      expect(result.notes[1].outcome, AttemptOutcome.incorrect);
      expect(result.notes[1].octaveError, isTrue);
      expect(result.notes[1].detectedMidi, 78);
      expect(result.notes[1].inTune, isFalse);
    });

    test('20 cents is correct and in tune; 40 cents is correct but flagged', () {
      final target = makeTargets([64, 66, 67, 69]);
      final inTune = scorer.score(
        samples: renderTake(simpleNotes([64, 66, 67, 69])
            .map((note) => TestNote(note.midi, note.onset,
                duration: note.duration, cents: 20))
            .toList()),
        target: target,
        bpm: 60,
      );
      expect(inTune.outcome, AttemptOutcome.correct);
      expect(inTune.notes.every((note) => note.inTune), isTrue);
      expect(inTune.medianCents!.abs(), closeTo(20, 3));
      expect(inTune.intonationInTune, isTrue);

      final outOfTune = scorer.score(
        samples: renderTake(simpleNotes([64, 66, 67, 69])
            .map((note) => TestNote(note.midi, note.onset,
                duration: note.duration, cents: 40))
            .toList()),
        target: target,
        bpm: 60,
      );
      expect(outOfTune.outcome, AttemptOutcome.correct);
      expect(outOfTune.notes.every((note) => note.inTune), isFalse);
      expect(outOfTune.medianCents!.abs(), closeTo(40, 3));
      expect(outOfTune.intonationInTune, isFalse);
    });

    test('a low-confidence detection is indeterminate', () {
      final target = makeTargets([64, 66]);
      final result = scorer.scoreDetections(
        target: target,
        detected: [
          detected(64, onset: target[0].onsetSeconds),
          detected(66, onset: target[1].onsetSeconds, confidence: 0.3),
        ],
        bpm: 60,
      );

      expect(result.notes[1].outcome, AttemptOutcome.indeterminate);
      expect(result.outcome, AttemptOutcome.indeterminate);
    });

    test('a low-confidence extra note is not counted as an extra error', () {
      final target = makeTargets([64, 66]);
      final result = scorer.scoreDetections(
        target: target,
        detected: [
          detected(64, onset: target[0].onsetSeconds),
          detected(50, onset: 0.8, confidence: 0.2),
          detected(66, onset: target[1].onsetSeconds),
        ],
        bpm: 60,
      );

      expect(result.extraNotes, 0);
      expect(result.outcome, AttemptOutcome.correct);
    });
  });

  group('PhraseScorer thresholds', () {
    test('practice pass allows 85 percent and rejects 75 percent', () {
      final target = makeTargets([60, 62, 64, 65, 67, 69, 71, 72]);
      final passing = scorer.scoreDetections(
        target: target,
        detected: [
          for (var index = 0; index < 8; index++)
            detected(
              index == 7 ? target[index].midi + 1 : target[index].midi,
              onset: target[index].onsetSeconds,
            ),
        ],
        bpm: 60,
      );
      expect(passing.outcome, AttemptOutcome.incorrect);
      expect(passing.practicePass, isTrue);
      expect(passing.performanceReady, isFalse);

      final failing = scorer.scoreDetections(
        target: target,
        detected: [
          for (var index = 0; index < 8; index++)
            detected(
              index >= 6 ? target[index].midi + 1 : target[index].midi,
              onset: target[index].onsetSeconds,
            ),
        ],
        bpm: 60,
      );
      expect(failing.practicePass, isFalse);
    });

    test('performance ready requires every note and acceptable timing', () {
      final target = makeTargets([60, 62, 64, 65]);
      final perfect = scorer.scoreDetections(
        target: target,
        detected: [
          for (final note in target)
            detected(note.midi, onset: note.onsetSeconds),
        ],
        bpm: 60,
      );
      expect(perfect.performanceReady, isTrue);

      final late = scorer.scoreDetections(
        target: target,
        detected: [
          for (final note in target)
            detected(note.midi, onset: note.onsetSeconds + 0.1),
        ],
        bpm: 60,
      );
      expect(late.performanceReady, isFalse);
      expect(late.timingWithinTolerance, isFalse);
    });

    test('the same samples produce identical JSON', () {
      final target = makeTargets([64, 66, 67, 69]);
      final samples = renderTake(simpleNotes([64, 66, 67, 69]));
      final first = scorer.score(samples: samples, target: target, bpm: 60);
      final second = scorer.score(samples: samples, target: target, bpm: 60);
      expect(
        jsonEncode(first.toJson()),
        jsonEncode(second.toJson()),
      );
    });
  });

  group('PhraseScorer null models', () {
    test('1000 random note sequences almost never pass', () {
      final random = Random(7);
      var correct = 0;
      var performanceReady = 0;
      for (var trial = 0; trial < 1000; trial++) {
        final length = 4 + random.nextInt(5);
        final bpm = 60 + random.nextDouble() * 30;
        final beat = 60 / bpm;
        final target = <TargetNote>[
          for (var index = 0; index < length; index++)
            TargetNote(
              index: index,
              midi: 55 + random.nextInt(20),
              onsetSeconds: 0.3 + index * beat,
              durationSeconds: beat * 0.8,
              bar: index ~/ 4,
            ),
        ];
        final detectedNotes = <DetectedNote>[
          for (var index = 0; index < length; index++)
            DetectedNote(
              startSeconds: target[index].onsetSeconds +
                  (random.nextDouble() - 0.5) * 0.04,
              durationSeconds: beat * 0.8,
              midi: 55 + random.nextInt(20),
              cents: (random.nextDouble() - 0.5) * 20,
              confidence: 0.9,
              sampleIndex: 0,
            ),
        ];
        final result = scorer.scoreDetections(
          target: target,
          detected: detectedNotes,
          bpm: bpm,
        );
        if (result.outcome == AttemptOutcome.correct) correct++;
        if (result.performanceReady) performanceReady++;
      }

      expect(correct / 1000, lessThanOrEqualTo(0.05));
      expect(performanceReady, 0);
    });

    test('1000 one-semitone errors are all rejected', () {
      final random = Random(11);
      var incorrect = 0;
      var rejected = 0;
      for (var trial = 0; trial < 1000; trial++) {
        final length = 4 + random.nextInt(5);
        final bpm = 60 + random.nextDouble() * 30;
        final beat = 60 / bpm;
        final shifted = random.nextInt(length);
        final target = <TargetNote>[
          for (var index = 0; index < length; index++)
            TargetNote(
              index: index,
              midi: 55 + random.nextInt(20),
              onsetSeconds: 0.3 + index * beat,
              durationSeconds: beat * 0.8,
              bar: index ~/ 4,
            ),
        ];
        final detectedNotes = <DetectedNote>[
          for (var index = 0; index < length; index++)
            DetectedNote(
              startSeconds: target[index].onsetSeconds,
              durationSeconds: beat * 0.8,
              midi: target[index].midi + (index == shifted ? 1 : 0),
              cents: 0,
              confidence: 0.95,
              sampleIndex: 0,
            ),
        ];
        final result = scorer.scoreDetections(
          target: target,
          detected: detectedNotes,
          bpm: bpm,
        );
        if (result.outcome == AttemptOutcome.incorrect) incorrect++;
        if (result.outcome != AttemptOutcome.correct) rejected++;
      }

      expect(rejected, 1000);
      expect(incorrect / 1000, greaterThanOrEqualTo(0.95));
    });

    test('100 silence and noise takes are indeterminate', () {
      const lowRate = 8000;
      final lowRateScorer = PhraseScorer(sampleRate: lowRate.toDouble());
      final target = <TargetNote>[
        for (var index = 0; index < 4; index++)
          TargetNote(
            index: index,
            midi: 55 + index * 2,
            onsetSeconds: 0.1 + index * 0.15,
            durationSeconds: 0.12,
            bar: 0,
          ),
      ];
      var indeterminate = 0;
      for (var trial = 0; trial < 100; trial++) {
        final samples = silentTake(lowRate, 0.9);
        if (trial >= 30) {
          addWhiteNoise(
            samples,
            amplitude: 0.02 + (trial % 10) * 0.014,
            seed: trial,
          );
        }
        final result = lowRateScorer.score(
          samples: samples,
          target: target,
          bpm: 60,
        );
        if (result.outcome == AttemptOutcome.indeterminate) indeterminate++;
      }
      expect(indeterminate / 100, greaterThanOrEqualTo(0.9));
    });
  });
}
