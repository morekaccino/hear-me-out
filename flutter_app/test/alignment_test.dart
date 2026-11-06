import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/alignment.dart';
import 'package:hear_me_out/core/audio/note_segmenter.dart';

TargetNote targetNote(int index, int midi, {double onset = 0}) => TargetNote(
      index: index,
      midi: midi,
      onsetSeconds: onset,
      durationSeconds: 0.5,
      bar: index ~/ 4,
    );

DetectedNote detectedNote(
  int midi, {
  double confidence = 1.0,
  double start = 0,
}) =>
    DetectedNote(
      startSeconds: start,
      durationSeconds: 0.5,
      midi: midi,
      cents: 0,
      confidence: confidence,
      sampleIndex: (start * 22050).round(),
    );

void main() {
  group('alignNotes', () {
    test('an exact match aligns every note diagonally', () {
      final target = [60, 62, 64, 65]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [60, 62, 64, 65].map(detectedNote).toList();
      final alignment = alignNotes(target: target, detected: detected);

      expect(alignment.length, 4);
      for (var index = 0; index < 4; index++) {
        expect(alignment[index].targetIndex, index);
        expect(alignment[index].detectedIndex, index);
        expect(alignment[index].cost, 0);
      }
    });

    test('one wrong note is matched and costs one', () {
      final target = [60, 62, 64, 65]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [60, 63, 64, 65].map(detectedNote).toList();
      final alignment = alignNotes(target: target, detected: detected);

      expect(alignment[1].detectedIndex, 1);
      expect(alignment[1].cost, 1);
      expect(
        alignment.where((entry) => entry.detectedIndex != null).length,
        4,
      );
    });

    test('one missed note leaves that target unmatched', () {
      final target = [60, 62, 64, 65]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [60, 64, 65].map(detectedNote).toList();
      final alignment = alignNotes(target: target, detected: detected);

      expect(alignment[1].detectedIndex, isNull);
      expect(alignment[1].cost, 1);
      expect(alignment[0].detectedIndex, 0);
      expect(alignment[2].detectedIndex, 1);
      expect(alignment[3].detectedIndex, 2);
    });

    test('one extra note is skipped', () {
      final target = [60, 62, 64, 65]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [60, 61, 62, 64, 65].map(detectedNote).toList();
      final alignment = alignNotes(target: target, detected: detected);

      expect(
        alignment.map((entry) => entry.detectedIndex).toList(),
        [0, 2, 3, 4],
      );
      expect(alignment.every((entry) => entry.matched), isTrue);
      expect(alignment.every((entry) => entry.cost == 0), isTrue);
    });

    test('a repeated note aligns one-to-one', () {
      final target = [60, 60, 62]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [60, 60, 62].map(detectedNote).toList();
      final alignment = alignNotes(target: target, detected: detected);

      expect(
        alignment.map((entry) => entry.detectedIndex).toList(),
        [0, 1, 2],
      );
      expect(alignment.every((entry) => entry.cost == 0), isTrue);
    });

    test('a swapped pair is two wrong matches', () {
      final target = [60, 62]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [62, 60].map(detectedNote).toList();
      final alignment = alignNotes(target: target, detected: detected);

      expect(alignment.every((entry) => entry.matched), isTrue);
      expect(alignment.every((entry) => entry.cost == 1), isTrue);
    });

    test('a false start is an unmatched extra detected note', () {
      final target = [60, 62, 64]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [55, 60, 62, 64].map(detectedNote).toList();
      final alignment = alignNotes(target: target, detected: detected);

      expect(
        alignment.map((entry) => entry.detectedIndex).toList(),
        [1, 2, 3],
      );
      expect(alignment.every((entry) => entry.cost == 0), isTrue);
    });

    test('an early stop leaves trailing targets unmatched', () {
      final target = [60, 62, 64, 65]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [60, 62].map(detectedNote).toList();
      final alignment = alignNotes(target: target, detected: detected);

      expect(alignment[2].detectedIndex, isNull);
      expect(alignment[3].detectedIndex, isNull);
      expect(alignment[2].cost, 1);
      expect(alignment[3].cost, 1);
    });

    test('a low-confidence detection costs 0.5 and still matches', () {
      final target = [60, 62, 64]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [
        detectedNote(60),
        detectedNote(0, confidence: 0.2),
        detectedNote(64),
      ];
      final alignment = alignNotes(target: target, detected: detected);

      expect(alignment[1].detectedIndex, 1);
      expect(alignment[1].cost, 0.5);
    });

    test('an octave error is not a pitch-class match', () {
      final target = [60, 62, 64]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [60, 74, 64].map(detectedNote).toList();
      final alignment = alignNotes(target: target, detected: detected);

      expect(alignment[1].detectedIndex, 1);
      expect(alignment[1].cost, 1.25);
    });

    test('extra detected notes at the end do not break the alignment', () {
      final target = [60, 62]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [60, 62, 64, 65, 67].map(detectedNote).toList();
      final alignment = alignNotes(target: target, detected: detected);

      expect(alignment.length, 2);
      expect(alignment[0].detectedIndex, 0);
      expect(alignment[1].detectedIndex, 1);
    });

    test('no detected notes returns every target unmatched', () {
      final target = [60, 62, 64]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final alignment = alignNotes(target: target, detected: const []);

      expect(alignment.length, 3);
      expect(alignment.every((entry) => entry.detectedIndex == null), isTrue);
    });

    test('an empty target returns an empty alignment', () {
      expect(
        alignNotes(
          target: const [],
          detected: [detectedNote(60)],
        ),
        isEmpty,
      );
    });

    test('maxSlope changes how many interior extras can be skipped', () {
      final target = [60, 62]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [60, 61, 61, 62].map(detectedNote).toList();

      final permissive = alignNotes(
        target: target,
        detected: detected,
        maxSlope: 2,
      );
      final strict = alignNotes(
        target: target,
        detected: detected,
        maxSlope: 1,
      );

      // With room for two interior insertions the aligner skips both 61s and
      // matches 62 exactly. With maxSlope 1 it cannot do that, so at least one
      // target must absorb a wrong note or an extra prefix skip.
      expect(permissive.every((entry) => entry.cost == 0), isTrue);
      expect(strict.any((entry) => entry.cost > 0), isTrue);
    });

    test('matched detected indices are monotonic and never reused', () {
      final target = [60, 62, 64, 65, 67]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [
        60,
        61,
        61,
        61,
        61,
        62,
        64,
        65,
        67,
      ].map(detectedNote).toList();
      final alignment = alignNotes(target: target, detected: detected);
      final matched = alignment
          .where((entry) => entry.matched)
          .map((entry) => entry.detectedIndex!)
          .toList();

      expect(alignment.length, 5);
      expect(matched, orderedEquals([...matched]..sort()));
      expect(matched.toSet().length, matched.length);
    });

    test('the result is deterministic', () {
      final target = [60, 62, 64, 65]
          .asMap()
          .entries
          .map((entry) => targetNote(entry.key, entry.value))
          .toList();
      final detected = [62, 60, 64, 65].map(detectedNote).toList();
      final first = alignNotes(target: target, detected: detected);
      final second = alignNotes(target: target, detected: detected);

      expect(
        first.map((entry) => entry.detectedIndex).toList(),
        second.map((entry) => entry.detectedIndex).toList(),
      );
      expect(
        first.map((entry) => entry.cost).toList(),
        second.map((entry) => entry.cost).toList(),
      );
    });
  });
}
