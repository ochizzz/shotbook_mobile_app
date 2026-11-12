import 'package:flutter/material.dart';

abstract final class ShotbookColors {
  static const background = Color(0xFF0E0E0E);
  static const surface = Color(0xFF181818);
  static const card = Color(0xFF202020);
  static const primary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFFA0A0A0);
  static const border = Color(0xFF303030);
}

/// Titles and decorative text: Cormorant Garamond (OFL, bundled).
const shotbookTitleFont = 'CormorantGaramond';

/// Everything else: Spectral (OFL, bundled). Sturdy enough for small text.
const shotbookBodyFont = 'Spectral';

/// The design is strict: corners are almost square everywhere.
const shotbookRadius = 2.0;
final shotbookBorderRadius = BorderRadius.circular(shotbookRadius);
final shotbookShape = RoundedRectangleBorder(
  borderRadius: shotbookBorderRadius,
);

TextTheme _textTheme() {
  final base = ThemeData.dark().textTheme.apply(
    fontFamily: shotbookBodyFont,
    bodyColor: ShotbookColors.primary,
    displayColor: ShotbookColors.primary,
  );
  TextStyle? title(TextStyle? style, {double? size}) => style?.copyWith(
    fontFamily: shotbookTitleFont,
    fontWeight: FontWeight.w600,
    fontSize: size,
    height: 1.1,
  );
  return base.copyWith(
    displayLarge: title(base.displayLarge),
    displayMedium: title(base.displayMedium),
    displaySmall: title(base.displaySmall, size: 38),
    headlineLarge: title(base.headlineLarge),
    headlineMedium: title(base.headlineMedium, size: 32),
    headlineSmall: title(base.headlineSmall, size: 27),
    titleLarge: title(base.titleLarge, size: 25),
    titleMedium: title(base.titleMedium, size: 20),
  );
}

final _roundedButtonStyle = ButtonStyle(
  shape: WidgetStatePropertyAll(shotbookShape),
);

final shotbookDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: shotbookBodyFont,
  scaffoldBackgroundColor: ShotbookColors.background,
  colorScheme:
      ColorScheme.fromSeed(
        seedColor: ShotbookColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: ShotbookColors.primary,
        onPrimary: ShotbookColors.background,
        primaryContainer: ShotbookColors.primary,
        onPrimaryContainer: ShotbookColors.background,
        secondaryContainer: ShotbookColors.card,
        onSecondaryContainer: ShotbookColors.primary,
        surface: ShotbookColors.surface,
        onSurface: ShotbookColors.primary,
        secondary: ShotbookColors.secondary,
        outline: ShotbookColors.border,
      ),
  textTheme: _textTheme(),
  dividerColor: ShotbookColors.border,
  appBarTheme: const AppBarTheme(
    backgroundColor: ShotbookColors.background,
    surfaceTintColor: Colors.transparent,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: ShotbookColors.background,
    indicatorColor: ShotbookColors.card,
    indicatorShape: shotbookShape,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    height: 68,
  ),
  cardTheme: CardThemeData(shape: shotbookShape, margin: EdgeInsets.zero),
  chipTheme: ChipThemeData(shape: shotbookShape),
  filledButtonTheme: FilledButtonThemeData(style: _roundedButtonStyle),
  outlinedButtonTheme: OutlinedButtonThemeData(style: _roundedButtonStyle),
  textButtonTheme: TextButtonThemeData(style: _roundedButtonStyle),
  elevatedButtonTheme: ElevatedButtonThemeData(style: _roundedButtonStyle),
  iconButtonTheme: IconButtonThemeData(style: _roundedButtonStyle),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    shape: shotbookShape,
    backgroundColor: ShotbookColors.primary,
    foregroundColor: ShotbookColors.background,
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: ShotbookColors.surface,
    shape: shotbookShape,
    showDragHandle: true,
  ),
  dialogTheme: DialogThemeData(shape: shotbookShape),
  popupMenuTheme: PopupMenuThemeData(shape: shotbookShape),
  snackBarTheme: SnackBarThemeData(
    shape: shotbookShape,
    behavior: SnackBarBehavior.floating,
  ),
  listTileTheme: ListTileThemeData(shape: shotbookShape),
  sliderTheme: const SliderThemeData(
    activeTrackColor: ShotbookColors.primary,
    thumbColor: ShotbookColors.primary,
    inactiveTrackColor: ShotbookColors.border,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ShotbookColors.surface,
    hintStyle: const TextStyle(color: ShotbookColors.secondary),
    border: OutlineInputBorder(
      borderRadius: shotbookBorderRadius,
      borderSide: const BorderSide(color: ShotbookColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: shotbookBorderRadius,
      borderSide: const BorderSide(color: ShotbookColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: shotbookBorderRadius,
      borderSide: const BorderSide(color: ShotbookColors.primary),
    ),
  ),
);
