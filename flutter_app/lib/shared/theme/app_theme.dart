import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const green = Color(0xFF58CC02);
  static const greenDark = Color(0xFF46A302);
  static const greenSoft = Color(0xFFD7FFB8);
  static const blue = Color(0xFF1CB0F6);
  static const blueDark = Color(0xFF1289C7);
  static const blueSoft = Color(0xFFDDF4FF);
  static const red = Color(0xFFFF4B4B);
  static const redDark = Color(0xFFD33131);
  static const redSoft = Color(0xFFFFDFE0);
  static const yellow = Color(0xFFFFC800);
  static const yellowDark = Color(0xFFE6A700);
  static const purple = Color(0xFFCE82FF);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F7F7);
  static const border = Color(0xFFE5E5E5);
  static const borderStrong = Color(0xFFD0D0D0);
  static const text = Color(0xFF3C3C3C);
  static const textMuted = Color(0xFF777777);
  static const textLight = Color(0xFFAFAFAF);
  static const ink = Color(0xFF1F1F1F);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.green,
          onPrimary: Colors.white,
          secondary: AppColors.blue,
          onSecondary: Colors.white,
          surface: AppColors.background,
          onSurface: AppColors.text,
          error: AppColors.red,
          onError: Colors.white,
          outline: AppColors.border,
        );

    final baseText = ThemeData.light().textTheme.apply(
      fontFamily: 'Nunito',
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textTheme: baseText.copyWith(
        displayLarge: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          height: 1.05,
          color: AppColors.text,
        ),
        headlineLarge: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          height: 1.1,
          color: AppColors.text,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.15,
          color: AppColors.text,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: AppColors.text,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppColors.textMuted,
        ),
        labelLarge: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.greenSoft,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: states.contains(WidgetState.selected)
                ? AppColors.greenDark
                : AppColors.textLight,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? AppColors.greenDark
                : AppColors.textLight,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1.5,
        space: 1.5,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
