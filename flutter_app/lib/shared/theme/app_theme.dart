import 'package:flutter/material.dart';

/// Mode-independent semantic palette. Neutrals come from [DuoPalette]; accents
/// stay the same in both themes.
class AppColors {
  AppColors._();

  static bool _dark = false;

  static void applyBrightness(Brightness brightness) {
    _dark = brightness == Brightness.dark;
  }

  static bool get isDark => _dark;

  static DuoPalette get _p => _dark ? DuoPalette.dark : DuoPalette.light;

  static const green = Color(0xFF58CC02);
  static const greenDark = Color(0xFF58A700);
  static const blue = Color(0xFF1CB0F6);
  static const blueDark = Color(0xFF1899D6);
  static const blueLine = Color(0xFF84D8FF);
  static const teal = Color(0xFF00CD9C);
  static const tealDark = Color(0xFF00A87F);
  static const pink = Color(0xFFFF70D6);
  static const pinkDark = Color(0xFFE055B3);
  static const red = Color(0xFFFF4B4B);
  static const redDark = Color(0xFFEA2B2B);
  static const yellow = Color(0xFFFFC800);
  static const yellowDark = Color(0xFFE5A400);
  static const orange = Color(0xFFFF9600);
  static const orangeDark = Color(0xFFE08600);
  static const purple = Color(0xFFCE82FF);
  static const purpleDark = Color(0xFFA560E8);
  static const ink = Color(0xFF1F1F1F);

  static Color get greenSoft => _p.greenSoft;
  static Color get blueSoft => _p.blueSoft;
  static Color get purpleSoft => _p.purpleSoft;
  static Color get redSoft => _p.redSoft;
  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get border => _p.border;
  static Color get borderStrong => _p.borderStrong;
  static Color get text => _p.text;
  static Color get textMuted => _p.textMuted;
  static Color get textLight => _p.textLight;
}

/// A unit's path color and its darker pressed edge.
class DuoUnitColor {
  const DuoUnitColor(this.face, this.dark);

  final Color face;
  final Color dark;
}

const List<DuoUnitColor> duoUnitColors = [
  DuoUnitColor(AppColors.green, AppColors.greenDark),
  DuoUnitColor(AppColors.teal, AppColors.tealDark),
  DuoUnitColor(AppColors.blue, AppColors.blueDark),
  DuoUnitColor(AppColors.purple, AppColors.purpleDark),
  DuoUnitColor(AppColors.pink, AppColors.pinkDark),
  DuoUnitColor(AppColors.orange, AppColors.orangeDark),
];

/// Unit 1 is green, unit 2 teal, and so on.
DuoUnitColor duoUnitColor(int unitNumber) =>
    duoUnitColors[(unitNumber - 1) % duoUnitColors.length];

/// Duolingo-style neutrals for light and dark surfaces.
class DuoPalette {
  const DuoPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMuted,
    required this.textLight,
    required this.greenSoft,
    required this.blueSoft,
    required this.purpleSoft,
    required this.redSoft,
    required this.snackbar,
  });

  static const light = DuoPalette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF7F7F7),
    border: Color(0xFFE5E5E5),
    borderStrong: Color(0xFFD0D0D0),
    text: Color(0xFF3C3C3C),
    textMuted: Color(0xFF777777),
    textLight: Color(0xFFAFAFAF),
    greenSoft: Color(0xFFD7FFB8),
    blueSoft: Color(0xFFDDF4FF),
    purpleSoft: Color(0xFFF7E6FF),
    redSoft: Color(0xFFFFDFE0),
    snackbar: Color(0xFF1F1F1F),
  );

  static const dark = DuoPalette(
    background: Color(0xFF131F24),
    surface: Color(0xFF202F36),
    border: Color(0xFF37464F),
    borderStrong: Color(0xFF52656D),
    text: Color(0xFFF1F7FB),
    textMuted: Color(0xFF8FA3AD),
    textLight: Color(0xFF52656D),
    greenSoft: Color(0xFF1D3A2B),
    blueSoft: Color(0xFF133441),
    purpleSoft: Color(0xFF33243D),
    redSoft: Color(0xFF3A2022),
    snackbar: Color(0xFF202F36),
  );

  final Color background;
  final Color surface;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textMuted;
  final Color textLight;
  final Color greenSoft;
  final Color blueSoft;
  final Color purpleSoft;
  final Color redSoft;
  final Color snackbar;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(DuoPalette.light, Brightness.light);

  static ThemeData get dark => _build(DuoPalette.dark, Brightness.dark);

  static ThemeData _build(DuoPalette palette, Brightness brightness) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.green,
          onPrimary: Colors.white,
          secondary: AppColors.blue,
          onSecondary: Colors.white,
          surface: palette.background,
          onSurface: palette.text,
          error: AppColors.red,
          onError: Colors.white,
          outline: palette.border,
        );

    final baseText = ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: 'Nunito',
      bodyColor: palette.text,
      displayColor: palette.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Nunito',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      cardColor: palette.surface,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textTheme: baseText.copyWith(
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          height: 1.05,
          color: palette.text,
        ),
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          height: 1.1,
          color: palette.text,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.15,
          color: palette.text,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: palette.text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: palette.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: palette.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: palette.textMuted,
        ),
        labelLarge: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.text,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.background,
        indicatorColor: palette.blueSoft,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: states.contains(WidgetState.selected)
                ? AppColors.blue
                : palette.textLight,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? AppColors.blue
                : palette.textLight,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1.5,
        space: 1.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.snackbar,
        contentTextStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
