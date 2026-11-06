import 'calibration.dart';

/// Whether a phrase take may be scored and recorded.
///
/// Decision 0001: a scored take needs a trustworthy clock. The learner either
/// confirms wired headphones (so the click does not leak into the microphone)
/// or the device passes the loopback calibration gate. Neither path is assumed
/// by default. When both are false the take is practice only and must not
/// update phrase progress.
class ScoredTakeGate {
  const ScoredTakeGate({
    this.headphonesConfirmed = false,
    this.clockVerified = false,
  });

  /// Builds the gate from a loopback calibration report.
  ///
  /// A report only verifies the clock when the measurement itself is usable
  /// and the first reference click was matched. Diagnostic offset values from
  /// an unverified take cannot open the gate.
  factory ScoredTakeGate.fromCalibration(
    CalibrationReport? report, {
    bool headphonesConfirmed = false,
  }) {
    final verified =
        report != null && report.timingUsable && report.offsetVerified;
    return ScoredTakeGate(
      headphonesConfirmed: headphonesConfirmed,
      clockVerified: verified,
    );
  }

  final bool headphonesConfirmed;
  final bool clockVerified;

  bool get allowsScoredTake => headphonesConfirmed || clockVerified;

  bool get isPracticeOnly => !allowsScoredTake;

  String get reason {
    if (headphonesConfirmed && clockVerified) {
      return 'Wired headphones confirmed and the device clock is verified.';
    }
    if (headphonesConfirmed) return 'Wired headphones confirmed.';
    if (clockVerified) return 'Device clock verified.';
    return 'No wired headphones or verified clock. This take is practice only.';
  }
}
