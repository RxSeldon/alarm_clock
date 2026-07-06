import 'package:flutter/material.dart';

/// Pure grayscale palette -- no hue anywhere. Light mode reads as
/// white-on-grey, dark mode as black-on-grey, so the app never looks like a
/// typical seeded-purple/blue Material demo.
class AppPalette {
  const AppPalette._();

  static const Color black = Color(0xFF0B0B0B);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color graphite = Color(0xFF2C2C2C);
  static const Color steel = Color(0xFF4B4B4B);
  static const Color ash = Color(0xFF8A8A8A);
  static const Color silver = Color(0xFFBDBDBD);
  static const Color fog = Color(0xFFE4E4E4);
  static const Color paper = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: AppPalette.paper,
        surface: AppPalette.white,
        onBackground: AppPalette.black,
        primary: AppPalette.black,
        onPrimary: AppPalette.white,
        outline: AppPalette.fog,
        muted: AppPalette.steel,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: AppPalette.black,
        surface: AppPalette.charcoal,
        onBackground: AppPalette.fog,
        primary: AppPalette.white,
        onPrimary: AppPalette.black,
        outline: AppPalette.graphite,
        muted: AppPalette.ash,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onBackground,
    required Color primary,
    required Color onPrimary,
    required Color outline,
    required Color muted,
  }) {
    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: muted,
      onSecondary: onBackground,
      error: const Color(0xFFB3261E),
      onError: AppPalette.white,
      surface: surface,
      onSurface: onBackground,
      outline: outline,
    );

    final TextTheme textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.w200,
        letterSpacing: -1,
        color: onBackground,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displayMedium: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w300,
        color: onBackground,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onBackground,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: onBackground,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: onBackground),
      bodySmall: TextStyle(fontSize: 12, color: muted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: outline,
      splashFactory: InkRipple.splashFactory,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        centerTitle: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.35)
              : outline,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        labelStyle: TextStyle(color: onBackground, fontWeight: FontWeight.w600),
        secondaryLabelStyle: TextStyle(color: onPrimary, fontWeight: FontWeight.w600),
        side: BorderSide(color: outline),
        shape: const StadiumBorder(),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: const CircleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onBackground,
          side: BorderSide(color: outline),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary),
        ),
        labelStyle: TextStyle(color: muted),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: onBackground,
      ),
    );
  }
}
