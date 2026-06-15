// flutter_app/lib/config/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // Note names (chromatic scale)
  static const List<String> noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  // Pitch detection
  static const double minFrequency = 50.0;
  static const double maxFrequency = 2000.0;
  static const double minClarity = 0.6;
  static const double clarityThreshold = 0.8;
  static const int fftSize = 4096;
  static const double smoothingTimeConstant = 0.8;
  static const int sampleRate = 44100;

  // Detection timing (ms)
  static const int cooldownMs = 120;
  static const int confidenceThreshold = 1;
  static const int historyWindowMs = 700;
  static const int refractoryMs = 700;
  static const int successDelayMs = 600;
  static const int successResetMs = 1500;
  static const int detectionResetMs = 800;

  // Game mechanics
  static const int xpPerLevel = 500;
  static const int masteryCorrectStreak = 3;
  static const int maxLearningCards = 5;
  static const double reviewProbability = 0.30;

  // Monetization
  static const int freeDailySessions = 3;
  static const double proMonthlyPrice = 4.99;
  static const double teacherMonthlyPrice = 9.99;
}

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF14141F);
  static const Color card = Color(0xFF1A1A2E);
  static const Color accent = Color(0xFFA855F7);
  static const Color accent2 = Color(0xFF06B6D4);
  static const Color success = Color(0xFF10B981);
  static const Color warm = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color text = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color border = Color(0xFF1E293B);
}
