import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/note_segmenter.dart';
import 'package:hear_me_out/core/audio/onset_detector.dart';

import 'support/audio_fixtures.dart';

const sampleRate = 22050.0;

void main() {
  late OnsetDetector detector;
  late NoteSegmenter segmenter;

  setUp(() {
    detector = OnsetDetector(sampleRate: sampleRate);
    segmenter = NoteSegmenter(sampleRate: sampleRate);
  });

  List<DetectedNote> detectNotes(List<double> samples) {
    return segmenter.segment(
      samples: samples,
      onsets: detector.detect(samples),
    );
  }

  group('NoteSegmenter', () {
    test('detects known guitar pitches with high confidence', () {
      const notes = {
        'E2': 40,
        'A2': 45,
        'D3': 50,
        'G3': 55,
        'B3': 59,
        'E4': 64,
        'F#4': 66,
        'Bb4': 70,
        'E5': 76,
      };
      for (final entry in notes.entries) {
        final samples = silentTake(22050, 1.2);
        addTone(
          samples,
          22050,
          startSeconds: 0.2,
          durationSeconds: 0.8,
          midi: entry.value,
        );
        final detected = detectNotes(samples);
        expect(detected.length, 1, reason: entry.key);
        expect(detected.first.midi, entry.value, reason: entry.key);
        expect(detected.first.cents.abs(), lessThan(3), reason: entry.key);
        expect(
          detected.first.confidence,
          greaterThanOrEqualTo(0.9),
          reason: entry.key,
        );
      }
    });

    test('vibrato keeps the pitch and a determinate confidence', () {
      final samples = silentTake(22050, 1.2);
      addTone(
        samples,
        22050,
        startSeconds: 0.2,
        durationSeconds: 0.8,
        midi: 64,
        vibratoCents: 25,
      );
      final detected = detectNotes(samples);
      expect(detected.length, 1);
      expect(detected.first.midi, 64);
      expect(detected.first.cents.abs(), lessThan(30));
      expect(detected.first.confidence, greaterThanOrEqualTo(0.6));
    });

    test('background noise keeps the pitch', () {
      final samples = silentTake(22050, 1.2);
      addTone(
        samples,
        22050,
        startSeconds: 0.2,
        durationSeconds: 0.8,
        midi: 57,
        noise: 0.004,
        seed: 5,
      );
      final detected = detectNotes(samples);
      expect(detected.length, 1);
      expect(detected.first.midi, 57);
      expect(detected.first.confidence, greaterThanOrEqualTo(0.6));
    });

    test('a weak fundamental with a strong second harmonic is not octave-off',
        () {
      final samples = silentTake(22050, 1.2);
      addTone(
        samples,
        22050,
        startSeconds: 0.2,
        durationSeconds: 0.8,
        midi: 64,
        harmonics: const [0.2, 1.0, 0.4, 0.2],
      );
      final detected = detectNotes(samples);
      expect(detected.length, 1);
      expect(detected.first.midi, 64);
    });

    test('a missing fundamental is not lowered by the octave guard', () {
      final samples = silentTake(22050, 1.2);
      addTone(
        samples,
        22050,
        startSeconds: 0.2,
        durationSeconds: 0.8,
        midi: 64,
        harmonics: const [0.0, 1.0, 0.4, 0.2],
      );
      final detected = detectNotes(samples);
      expect(detected.length, 1);
      expect(detected.first.midi, 64);
    });

    test('a noise burst produces an indeterminate note, not a pitch', () {
      final samples = silentTake(22050, 1);
      final burst = silentTake(22050, 0.3);
      addWhiteNoise(burst, amplitude: 0.3, seed: 9);
      final start = (0.4 * sampleRate).round();
      for (var index = 0; index < burst.length; index++) {
        final envelope = math.exp(-index / (0.08 * sampleRate));
        samples[start + index] += burst[index] * envelope;
      }
      final detected = detectNotes(samples);
      expect(detected.length, 1);
      expect(detected.first.confidence, lessThan(0.6));
    });

    test('successive onsets produce separate notes', () {
      final samples = silentTake(22050, 2.2);
      for (var index = 0; index < 3; index++) {
        addTone(
          samples,
          22050,
          startSeconds: 0.3 + index * 0.5,
          durationSeconds: 0.4,
          midi: 60 + index * 2,
        );
      }
      final detected = detectNotes(samples);
      expect(detected.length, 3);
      expect(detected.map((note) => note.midi).toList(), [60, 62, 64]);
    });

    test('fast sixteenth notes are segmented separately', () {
      final samples = silentTake(22050, 1.4);
      const beat = 60 / 90;
      for (var index = 0; index < 4; index++) {
        addTone(
          samples,
          22050,
          startSeconds: 0.3 + index * beat / 4,
          durationSeconds: beat / 4 * 0.9,
          midi: 64 + index * 2,
        );
      }
      final detected = detectNotes(samples);
      expect(detected.length, 4);
      expect(
        detected.map((note) => note.midi).toList(),
        [64, 66, 68, 70],
      );
    });

    test('empty input is safe', () {
      expect(
        segmenter.segment(samples: const [], onsets: const []),
        isEmpty,
      );
      expect(
        segmenter.segment(
          samples: silentTake(22050, 1),
          onsets: const [],
        ),
        isEmpty,
      );
    });
  });
}
