import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/note_matcher.dart';
import 'package:hear_me_out/core/audio/pitch_source.dart';
import 'package:hear_me_out/core/music/note.dart';

void main() {
  final start = DateTime(2026, 10, 31, 10);

  PitchFrame frameForMidi(double midi, {double clarity = 0.95}) {
    return PitchFrame(
      frequency: midiToFrequency(midi),
      clarity: clarity,
      rms: 0.1,
      timestamp: start,
    );
  }

  MatchResult feed(
    NoteMatcher matcher,
    double midi, {
    int frames = 3,
    int offsetMs = 1,
  }) {
    MatchResult result = const MatchResult(
      state: MatchState.listening,
      reading: PitchReading.silent,
    );
    for (var index = 0; index < frames; index++) {
      result = matcher.addFrame(
        frameForMidi(midi),
        now: start.add(Duration(milliseconds: offsetMs + index)),
      );
    }
    return result;
  }

  group('NoteMatcher', () {
    test('three stable frames of the sounding note are correct', () {
      final matcher = NoteMatcher(a4: 440, toleranceCents: 30)
        ..startExercise(Note.parse('C4'), now: start, grace: Duration.zero);
      final result = feed(matcher, 48);
      expect(result.state, MatchState.correct);
      expect(result.reading.note?.id, 'C3');
    });

    test('a note outside the cents tolerance is not accepted', () {
      final matcher = NoteMatcher(a4: 440, toleranceCents: 30)
        ..startExercise(Note.parse('C4'), now: start, grace: Duration.zero);
      final result = feed(matcher, 48.4);
      expect(result.state, MatchState.listening);
      expect(result.reading.cents, closeTo(40, 1));
    });

    test('the correct pitch class in the wrong octave is flagged', () {
      final matcher = NoteMatcher(a4: 440, toleranceCents: 30)
        ..startExercise(Note.parse('C4'), now: start, grace: Duration.zero);
      final result = feed(matcher, 60, frames: 6);
      expect(result.state, MatchState.octave);
    });

    test('a stable wrong note is flagged only after six frames', () {
      final matcher = NoteMatcher(a4: 440, toleranceCents: 30)
        ..startExercise(Note.parse('C4'), now: start, grace: Duration.zero);
      expect(feed(matcher, 50, frames: 5).state, MatchState.listening);
      expect(feed(matcher, 50, frames: 1, offsetMs: 7).state, MatchState.wrong);
    });

    test('the grace period ignores the tail of the previous note', () {
      final matcher = NoteMatcher(a4: 440, toleranceCents: 30)
        ..startExercise(
          Note.parse('C4'),
          now: start,
          grace: const Duration(milliseconds: 500),
        );
      final early = feed(matcher, 48, frames: 3, offsetMs: 100);
      expect(early.state, MatchState.listening);
      final later = feed(matcher, 48, frames: 3, offsetMs: 600);
      expect(later.state, MatchState.correct);
    });

    test('silence clears the stable-note window', () {
      final matcher = NoteMatcher(a4: 440, toleranceCents: 30)
        ..startExercise(Note.parse('C4'), now: start, grace: Duration.zero);
      final silent = matcher.addFrame(
        PitchFrame(frequency: 0, clarity: 0, rms: 0, timestamp: start),
        now: start,
      );
      expect(silent.state, MatchState.silent);
    });
  });
}
