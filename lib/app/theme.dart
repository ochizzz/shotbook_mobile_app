import 'package:flutter/material.dart';

/// Graphite tokens (design/penpot_graphite.md).
abstract final class ShotbookColors {
  static const background = Color(0xFF131416);
  static const surface = Color(0xFF1A1B1E);
  static const card = Color(0xFF212225);
  static const border = Color(0xFF2D2F34);
  static const primary = Color(0xFFF1F2F3);
  static const secondary = Color(0xFF8B8F96);
  static const tertiary = Color(0xFF5A5D64);
  static const accent = Color(0xFFF5A623);
  static const danger = Color(0xFFFF6B6B);
  static const success = Color(0xFF6BD68F);
  static const placeholder = Color(0xFF2A2C30);
}

/// Big headings and the wordmark.
const shotbookTitleFont = 'Unbounded';

/// Everything else.
const shotbookBodyFont = 'Onest';

/// Shooting data (ISO, shutter, lens) and section labels.
const shotbookMonoFont = 'JetBrainsMono';

/// Chips, badges, small elements.
const shotbookRadius = 8.0;
final shotbookBorderRadius = BorderRadius.circular(shotbookRadius);
final shotbookShape = RoundedRectangleBorder(
  borderRadius: shotbookBorderRadius,
);

/// Cards, photos, buttons, search.
const shotbookCardRadiusValue = 10.0;
final shotbookCardRadius = BorderRadius.circular(shotbookCardRadiusValue);
final shotbookCardShape = RoundedRectangleBorder(
  borderRadius: shotbookCardRadius,
);

/// Tiny tags.
final shotbookTagRadius = BorderRadius.circular(2);

/// Ready-made text styles that are not part of Material's text theme.
abstract final class ShotbookText {
  static const wordmark = TextStyle(
    fontFamily: shotbookTitleFont,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    letterSpacing: 1.5,
    color: ShotbookColors.primary,
  );

  /// "ISO 100 · 1/60 · f1.8 · 26 мм"
  static const data = TextStyle(
    fontFamily: shotbookMonoFont,
    fontWeight: FontWeight.w400,
    fontSize: 11,
    letterSpacing: 0.6,
    height: 1.2,
    color: ShotbookColors.primary,
  );

  /// "ПОЗА", "НАСТРОЙКИ КАМЕРЫ"
  static const section = TextStyle(
    fontFamily: shotbookMonoFont,
    fontWeight: FontWeight.w400,
    fontSize: 11,
    letterSpacing: 0.6,
    color: ShotbookColors.tertiary,
  );

  /// Accent label over titles ("ПОРТРЕТ", "СНЯТО ПО РЕЦЕПТУ").
  static const kicker = TextStyle(
    fontFamily: shotbookMonoFont,
    fontWeight: FontWeight.w400,
    fontSize: 11,
    letterSpacing: 0.6,
    color: ShotbookColors.accent,
  );

  static const handle = TextStyle(
    fontFamily: shotbookMonoFont,
    fontSize: 12,
    letterSpacing: 0.3,
    color: ShotbookColors.secondary,
  );
}

TextTheme _textTheme() {
  const display = TextStyle(
    fontFamily: shotbookTitleFont,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
    height: 1.2,
    color: ShotbookColors.primary,
  );
  const body = TextStyle(
    fontFamily: shotbookBodyFont,
    color: ShotbookColors.primary,
  );
  return TextTheme(
    displayLarge: display.copyWith(fontSize: 40),
    displayMedium: display.copyWith(fontSize: 32),
    displaySmall: display.copyWith(fontSize: 28),
    headlineLarge: display.copyWith(fontSize: 28),
    headlineMedium: display.copyWith(fontSize: 26),
    headlineSmall: display.copyWith(fontSize: 22),
    titleLarge: body.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: body.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
    titleSmall: body.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
    bodyLarge: body.copyWith(fontSize: 15, height: 1.4),
    bodyMedium: body.copyWith(fontSize: 14, height: 1.4),
    bodySmall: body.copyWith(
      fontSize: 12,
      height: 1.35,
      color: ShotbookColors.secondary,
    ),
    labelLarge: body.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
    labelMedium: body.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
    labelSmall: body.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
  );
}

final _buttonShape = WidgetStatePropertyAll(shotbookCardShape);

final shotbookDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: shotbookBodyFont,
  scaffoldBackgroundColor: ShotbookColors.background,
  canvasColor: ShotbookColors.background,
  colorScheme: const ColorScheme.dark(
    primary: ShotbookColors.primary,
    onPrimary: ShotbookColors.background,
    primaryContainer: ShotbookColors.primary,
    onPrimaryContainer: ShotbookColors.background,
    secondary: ShotbookColors.accent,
    onSecondary: ShotbookColors.background,
    secondaryContainer: ShotbookColors.card,
    onSecondaryContainer: ShotbookColors.primary,
    surface: ShotbookColors.background,
    onSurface: ShotbookColors.primary,
    onSurfaceVariant: ShotbookColors.secondary,
    surfaceContainerLowest: ShotbookColors.background,
    surfaceContainerLow: ShotbookColors.surface,
    surfaceContainer: ShotbookColors.surface,
    surfaceContainerHigh: ShotbookColors.card,
    surfaceContainerHighest: ShotbookColors.card,
    outline: ShotbookColors.border,
    outlineVariant: ShotbookColors.border,
    error: ShotbookColors.danger,
  ),
  textTheme: _textTheme(),
  dividerColor: ShotbookColors.border,
  dividerTheme: const DividerThemeData(
    color: ShotbookColors.border,
    thickness: 1,
    space: 1,
  ),
  iconTheme: const IconThemeData(color: ShotbookColors.primary, size: 24),
  appBarTheme: const AppBarTheme(
    backgroundColor: ShotbookColors.background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontFamily: shotbookBodyFont,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: ShotbookColors.primary,
    ),
  ),
  cardTheme: CardThemeData(
    color: ShotbookColors.card,
    elevation: 0,
    shape: shotbookCardShape,
    margin: EdgeInsets.zero,
  ),
  chipTheme: ChipThemeData(
    shape: shotbookShape,
    side: const BorderSide(color: ShotbookColors.border),
    backgroundColor: Colors.transparent,
    selectedColor: ShotbookColors.primary,
    labelStyle: const TextStyle(
      fontFamily: shotbookBodyFont,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: ShotbookColors.secondary,
    ),
    secondaryLabelStyle: const TextStyle(
      fontFamily: shotbookBodyFont,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: ShotbookColors.background,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    showCheckmark: false,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      shape: _buttonShape,
      minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? ShotbookColors.card
            : ShotbookColors.primary,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? ShotbookColors.tertiary
            : ShotbookColors.background,
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: shotbookBodyFont,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      shape: _buttonShape,
      minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
      side: const WidgetStatePropertyAll(
        BorderSide(color: ShotbookColors.border),
      ),
      foregroundColor: const WidgetStatePropertyAll(ShotbookColors.primary),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: shotbookBodyFont,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(shotbookShape),
      foregroundColor: const WidgetStatePropertyAll(ShotbookColors.secondary),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: shotbookBodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(shape: WidgetStatePropertyAll(shotbookShape)),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    shape: shotbookCardShape,
    backgroundColor: ShotbookColors.primary,
    foregroundColor: ShotbookColors.background,
    elevation: 0,
    focusElevation: 0,
    hoverElevation: 0,
    highlightElevation: 0,
    extendedTextStyle: const TextStyle(
      fontFamily: shotbookBodyFont,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: ShotbookColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
    ),
    showDragHandle: true,
    dragHandleColor: ShotbookColors.tertiary,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: ShotbookColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: shotbookCardShape,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: ShotbookColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: shotbookShape,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: ShotbookColors.card,
    contentTextStyle: const TextStyle(
      fontFamily: shotbookBodyFont,
      fontSize: 14,
      color: ShotbookColors.primary,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: shotbookCardRadius,
      side: const BorderSide(color: ShotbookColors.border),
    ),
    behavior: SnackBarBehavior.floating,
  ),
  listTileTheme: ListTileThemeData(
    shape: shotbookShape,
    iconColor: ShotbookColors.secondary,
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: ShotbookColors.primary,
    unselectedLabelColor: ShotbookColors.tertiary,
    labelStyle: TextStyle(
      fontFamily: shotbookBodyFont,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    unselectedLabelStyle: TextStyle(
      fontFamily: shotbookBodyFont,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    indicator: ShortUnderlineIndicator(),
    indicatorSize: TabBarIndicatorSize.label,
    dividerColor: ShotbookColors.border,
    tabAlignment: TabAlignment.start,
    labelPadding: EdgeInsets.only(right: 24),
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: ShotbookColors.primary,
    thumbColor: ShotbookColors.primary,
    inactiveTrackColor: ShotbookColors.border,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: ShotbookColors.secondary,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ShotbookColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    hintStyle: const TextStyle(
      fontFamily: shotbookBodyFont,
      fontSize: 15,
      color: ShotbookColors.secondary,
    ),
    labelStyle: const TextStyle(color: ShotbookColors.secondary),
    prefixIconColor: ShotbookColors.secondary,
    suffixIconColor: ShotbookColors.secondary,
    border: OutlineInputBorder(
      borderRadius: shotbookCardRadius,
      borderSide: const BorderSide(color: ShotbookColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: shotbookCardRadius,
      borderSide: const BorderSide(color: ShotbookColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: shotbookCardRadius,
      borderSide: const BorderSide(color: ShotbookColors.secondary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: shotbookCardRadius,
      borderSide: const BorderSide(color: ShotbookColors.danger),
    ),
  ),
);

/// Graphite tab indicator: a 20×2 amber line under the start of the label.
class ShortUnderlineIndicator extends Decoration {
  const ShortUnderlineIndicator({
    this.width = 20,
    this.color = ShotbookColors.accent,
  });

  final double width;
  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _ShortUnderlinePainter(width, color);
}

class _ShortUnderlinePainter extends BoxPainter {
  _ShortUnderlinePainter(this.width, this.color);

  final double width;
  final Color color;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final rect = Rect.fromLTWH(
      offset.dx,
      offset.dy + size.height - 2,
      width,
      2,
    );
    canvas.drawRect(rect, Paint()..color = color);
  }
}
