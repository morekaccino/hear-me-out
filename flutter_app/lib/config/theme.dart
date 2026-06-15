// flutter_app/lib/config/theme.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkMaterialTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent2,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.text,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: const TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3,
        ),
        titleLarge: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w600,
        ),
        titleMedium: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500,
        ),
        bodyLarge: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w400,
        ),
        bodyMedium: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2,
          color: AppColors.accent,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.accent),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static CupertinoThemeData get cupertinoTheme {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.background,
      barBackgroundColor: AppColors.surface,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.text,
      ),
    );
  }
}
