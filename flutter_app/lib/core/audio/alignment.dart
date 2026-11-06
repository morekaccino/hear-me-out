import 'dart:math' as math;
import 'dart:typed_data';

import 'note_segmenter.dart';

/// One note in the fixed click grid.
class TargetNote {
  const TargetNote({
    required this.index,
    required this.midi,
    required this.onsetSeconds,
    required this.durationSeconds,
    required this.bar,
  });

  /// Stable identifier, normally the note's position in the phrase.
  final int index;

  /// Sounding MIDI note. Guitar notation is written an octave higher; the
  /// caller must pass sounding pitch.
  final int midi;

  /// Expected onset on the fixed click grid, in seconds.
  final double onsetSeconds;

  final double durationSeconds;

  /// Zero-based bar used for drift reporting.
  final int bar;
}

/// The alignment of one target note.
class NoteAlignment {
  const NoteAlignment({
    required this.targetIndex,
    required this.detectedIndex,
    required this.cost,
  });

  final int targetIndex;

  /// Index into the detected-note list, or null when the target was not
  /// attempted.
  final int? detectedIndex;

  final double cost;

  bool get matched => detectedIndex != null;

  @override
  String toString() => matched
      ? 'NoteAlignment(target $targetIndex -> detected $detectedIndex)'
      : 'NoteAlignment(target $targetIndex -> unmatched)';
}

/// Aligns target and detected notes with a constrained dynamic program.
///
/// The cost model is:
/// - 0.0 for an exact sounding MIDI match;
/// - 1.0 for a different pitch class;
/// - 1.25 for an octave error (a wrong pitch class plus a separate penalty);
/// - 0.5 for a low-confidence detection, whose pitch is not trusted.
///
/// Insertions (extra detected notes) and deletions (missed target notes) cost
/// [insertPenalty] and [skipPenalty]. In the aligned interior no more than
/// [maxSlope] consecutive insertions or deletions are allowed, which is the
/// slope constraint: a single target cannot absorb an unbounded run of
/// detected notes, and vice versa. Prefixes and suffixes may be skipped
/// without a run limit so a false start or an early stop still yields a
/// complete alignment.
///
/// Ties prefer a diagonal match, then skipping a target, then skipping a
/// detected note. The result is deterministic.
List<NoteAlignment> alignNotes({
  required List<TargetNote> target,
  required List<DetectedNote> detected,
  double skipPenalty = 1.0,
  double insertPenalty = 1.0,
  double maxSlope = 2.0,
}) {
  if (target.isEmpty) return const [];
  if (skipPenalty < 0 || insertPenalty < 0) {
    throw ArgumentError('penalties must be non-negative');
  }
  if (maxSlope < 1) {
    throw ArgumentError.value(maxSlope, 'maxSlope', 'must be at least 1');
  }

  final targetCount = target.length;
  final detectedCount = detected.length;
  if (detectedCount == 0) {
    return [
      for (final note in target)
        NoteAlignment(
          targetIndex: note.index,
          detectedIndex: null,
          cost: skipPenalty,
        ),
    ];
  }

  final maxRun = math.max(1, maxSlope.floor());
  final runStates = maxRun + 1;
  final stateCount =
      (targetCount + 1) * (detectedCount + 1) * runStates * runStates;
  final costs = Float64List(stateCount)
    ..fillRange(0, stateCount, double.infinity);
  final choices = Int8List(stateCount)..fillRange(0, stateCount, -1);
  final previousH = Int8List(stateCount)..fillRange(0, stateCount, -1);
  final previousV = Int8List(stateCount)..fillRange(0, stateCount, -1);

  int stateIndex(int i, int j, int h, int v) =>
      ((i * (detectedCount + 1) + j) * runStates + h) * runStates + v;

  // Prefixes: skipping any number of targets or detected notes before the
  // first match is always allowed.
  for (var i = 0; i <= targetCount; i++) {
    costs[stateIndex(i, 0, 0, 0)] = i * skipPenalty;
  }
  for (var j = 0; j <= detectedCount; j++) {
    costs[stateIndex(0, j, 0, 0)] = j * insertPenalty;
  }

  void update(
    int i,
    int j,
    int h,
    int v,
    double cost,
    int choice,
    int fromH,
    int fromV,
  ) {
    final index = stateIndex(i, j, h, v);
    if (cost + 1e-12 < costs[index]) {
      costs[index] = cost;
      choices[index] = choice;
      previousH[index] = fromH;
      previousV[index] = fromV;
    }
  }

  for (var i = 0; i <= targetCount; i++) {
    for (var j = 0; j <= detectedCount; j++) {
      for (var h = 0; h < runStates; h++) {
        for (var v = 0; v < runStates; v++) {
          final index = stateIndex(i, j, h, v);
          final cost = costs[index];
          if (!cost.isFinite) continue;

          if (i < targetCount && j < detectedCount) {
            update(
              i + 1,
              j + 1,
              0,
              0,
              cost + _matchCost(target[i], detected[j]),
              _choiceDiagonal,
              h,
              v,
            );
          }
          if (i < targetCount && v < maxRun) {
            update(
              i + 1,
              j,
              0,
              v + 1,
              cost + skipPenalty,
              _choiceSkipTarget,
              h,
              v,
            );
          }
          if (j < detectedCount && h < maxRun) {
            update(
              i,
              j + 1,
              h + 1,
              0,
              cost + insertPenalty,
              _choiceSkipDetected,
              h,
              v,
            );
          }
        }
      }
    }
  }

  // Suffix skips are free of the run limit, so a miss at the end of a phrase
  // still aligns cleanly.
  var bestI = 0;
  var bestJ = 0;
  var bestH = 0;
  var bestV = 0;
  var bestTotal = double.infinity;
  var bestProgress = -1;
  var bestRank = 3;
  for (var i = 0; i <= targetCount; i++) {
    for (var j = 0; j <= detectedCount; j++) {
      for (var h = 0; h < runStates; h++) {
        for (var v = 0; v < runStates; v++) {
          final index = stateIndex(i, j, h, v);
          final cost = costs[index];
          if (!cost.isFinite) continue;
          final total = cost +
              (targetCount - i) * skipPenalty +
              (detectedCount - j) * insertPenalty;
          final rank = h == 0 && v == 0
              ? 0
              : h == 0
                  ? 1
                  : 2;
          final progress = i + j;
          final better = total < bestTotal - 1e-12 ||
              ((total - bestTotal).abs() <= 1e-12 &&
                  (progress > bestProgress ||
                      (progress == bestProgress && rank < bestRank)));
          if (better) {
            bestTotal = total;
            bestI = i;
            bestJ = j;
            bestH = h;
            bestV = v;
            bestProgress = progress;
            bestRank = rank;
          }
        }
      }
    }
  }

  final matched = List<_MatchedNote?>.filled(targetCount, null);
  var i = bestI;
  var j = bestJ;
  var h = bestH;
  var v = bestV;
  while (i > 0 || j > 0) {
    final index = stateIndex(i, j, h, v);
    final choice = choices[index];
    if (choice == _choiceDiagonal) {
      matched[i - 1] = _MatchedNote(
        detectedIndex: j - 1,
        cost: _matchCost(target[i - 1], detected[j - 1]),
      );
      final fromH = previousH[index];
      final fromV = previousV[index];
      i -= 1;
      j -= 1;
      h = fromH;
      v = fromV;
    } else if (choice == _choiceSkipTarget) {
      matched[i - 1] = _MatchedNote(
        detectedIndex: null,
        cost: skipPenalty,
      );
      final fromH = previousH[index];
      final fromV = previousV[index];
      i -= 1;
      h = fromH;
      v = fromV;
    } else if (choice == _choiceSkipDetected) {
      final fromH = previousH[index];
      final fromV = previousV[index];
      j -= 1;
      h = fromH;
      v = fromV;
    } else {
      // Prefix state: every remaining target in this prefix was skipped.
      for (var prefix = 0; prefix < i; prefix++) {
        matched[prefix] = _MatchedNote(
          detectedIndex: null,
          cost: skipPenalty,
        );
      }
      break;
    }
  }

  return [
    for (var position = 0; position < targetCount; position++)
      NoteAlignment(
        targetIndex: target[position].index,
        detectedIndex: matched[position]?.detectedIndex,
        cost: matched[position]?.cost ?? skipPenalty,
      ),
  ];
}

const _choiceDiagonal = 1;
const _choiceSkipTarget = 2;
const _choiceSkipDetected = 3;

class _MatchedNote {
  const _MatchedNote({required this.detectedIndex, required this.cost});
  final int? detectedIndex;
  final double cost;
}

double _matchCost(TargetNote target, DetectedNote detected) {
  if (detected.confidence < DetectedNote.determinateConfidence) return 0.5;
  final interval = (detected.midi - target.midi).abs();
  if (interval == 0) return 0;
  if (interval % 12 == 0) return 1.25;
  return 1;
}
