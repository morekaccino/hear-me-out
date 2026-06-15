import 'package:flutter/services.dart';

class HapticPatterns {
  HapticPatterns._();

  static void correctNote() {
    HapticFeedback.lightImpact();
  }

  static Future<void> streakMilestone() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
  }

  static void incorrectNote() {
    HapticFeedback.lightImpact();
  }

  static Future<void> levelUp() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.heavyImpact();
  }

  static void subtle() {
    HapticFeedback.selectionClick();
  }
}
