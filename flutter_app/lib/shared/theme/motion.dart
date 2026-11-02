import 'package:flutter/animation.dart';

/// One motion vocabulary for the whole app.
///
/// Each duration has a job, so a new animation picks the feeling instead of a
/// random number:
/// - [fast] is for things leaving or reacting to a tap.
/// - [base] is for the question changing and panels arriving.
/// - [slow] is for entering a lesson or filling the progress bar.
class DuoMotion {
  DuoMotion._();

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  /// Settles with a small overshoot. Use for rewards, pops, and fills.
  static const Curve overshoot = Cubic(0.34, 1.56, 0.64, 1);

  /// Standard arrival.
  static const Curve enter = Curves.easeOutCubic;

  /// Standard dismissal. Quieter than the arrival.
  static const Curve exit = Curves.easeInCubic;
}
