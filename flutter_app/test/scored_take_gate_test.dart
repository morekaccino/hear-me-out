import 'package:flutter_test/flutter_test.dart';
import 'package:hear_me_out/core/audio/calibration.dart';
import 'package:hear_me_out/core/audio/scored_take_gate.dart';

CalibrationReport report({
  bool timingUsable = true,
  bool offsetVerified = true,
}) {
  return CalibrationReport(
    offsetMs: 2,
    driftMsPer60s: 4,
    falseOnsetsPerMinute: 0,
    noteRecall: 1,
    timingUsable: timingUsable,
    failures: const <String>[],
    offsetVerified: offsetVerified,
    driftVerified: offsetVerified,
  );
}

void main() {
  group('ScoredTakeGate', () {
    test('is practice only by default', () {
      const gate = ScoredTakeGate();
      expect(gate.headphonesConfirmed, isFalse);
      expect(gate.clockVerified, isFalse);
      expect(gate.allowsScoredTake, isFalse);
      expect(gate.isPracticeOnly, isTrue);
      expect(gate.reason, contains('practice only'));
    });

    test('wired headphones allow a scored take', () {
      const gate = ScoredTakeGate(headphonesConfirmed: true);
      expect(gate.allowsScoredTake, isTrue);
      expect(gate.reason, 'Wired headphones confirmed.');
    });

    test('a verified clock allows a scored take', () {
      const gate = ScoredTakeGate(clockVerified: true);
      expect(gate.allowsScoredTake, isTrue);
      expect(gate.reason, 'Device clock verified.');
    });

    test('a calibration report opens the gate only when it is usable', () {
      final usable = ScoredTakeGate.fromCalibration(report());
      expect(usable.clockVerified, isTrue);
      expect(usable.allowsScoredTake, isTrue);

      final unverifiedOffset = ScoredTakeGate.fromCalibration(
        report(offsetVerified: false),
      );
      expect(unverifiedOffset.clockVerified, isFalse);
      expect(unverifiedOffset.allowsScoredTake, isFalse);

      final failedTiming = ScoredTakeGate.fromCalibration(
        report(timingUsable: false),
      );
      expect(failedTiming.clockVerified, isFalse);
      expect(failedTiming.allowsScoredTake, isFalse);

      final missing = ScoredTakeGate.fromCalibration(null);
      expect(missing.clockVerified, isFalse);
    });
  });
}
