import 'package:flutter/material.dart';

abstract final class ShotbookColors {
  static const background = Color(0xFF0E0E0E);
  static const surface = Color(0xFF181818);
  static const card = Color(0xFF202020);
  static const primary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFFA0A0A0);
  static const border = Color(0xFF303030);
}

/// One serif family for the whole app: Noto Serif Display (OFL, bundled in
/// assets/fonts). A modern, tall take on the Times New Roman tradition with
/// full Cyrillic support.
const shotbookFontFamily = 'NotoSerifDisplay';

final shotbookDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: shotbookFontFamily,
  scaffoldBackgroundColor: ShotbookColors.background,
  colorScheme:
      ColorScheme.fromSeed(
        seedColor: ShotbookColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: ShotbookColors.primary,
        onPrimary: ShotbookColors.background,
        surface: ShotbookColors.surface,
        onSurface: ShotbookColors.primary,
        secondary: ShotbookColors.secondary,
        outline: ShotbookColors.border,
      ),
  textTheme: ThemeData.dark().textTheme
      .apply(
        fontFamily: shotbookFontFamily,
        bodyColor: ShotbookColors.primary,
        displayColor: ShotbookColors.primary,
      )
      .copyWith(
        displaySmall: ThemeData.dark().textTheme.displaySmall?.copyWith(
          fontFamily: shotbookFontFamily,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.6,
        ),
        titleLarge: ThemeData.dark().textTheme.titleLarge?.copyWith(
          fontFamily: shotbookFontFamily,
          fontWeight: FontWeight.w500,
        ),
      ),
  dividerColor: ShotbookColors.border,
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: ShotbookColors.background,
    indicatorColor: ShotbookColors.card,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    height: 68,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ShotbookColors.surface,
    hintStyle: const TextStyle(color: ShotbookColors.secondary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: ShotbookColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: ShotbookColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: ShotbookColors.primary),
    ),
  ),
);
