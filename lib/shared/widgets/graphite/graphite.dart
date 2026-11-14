import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../features/challenges/application/streak_provider.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/tr.dart';

export 'viewfinder_ticks.dart';

/// "ПОЗА", "НАСТРОЙКИ КАМЕРЫ": mono caps, tertiary.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.color, super.key});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: ShotbookText.section.copyWith(color: color),
  );
}

/// Label left, value right, 1 px rule under (44 px row).
class MetaRow extends StatelessWidget {
  const MetaRow({
    required this.label,
    required this.value,
    this.mono = false,
    super.key,
  });

  final String label;
  final String value;

  /// Shooting data reads better monospaced.
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ShotbookColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label takes what it needs (up to ~40 %), the value the rest:
          // long words like "Экспокоррекция" never break mid-word.
          Flexible(
            flex: 2,
            child: Text(
              label,
              softWrap: true,
              style: const TextStyle(
                fontSize: 14,
                color: ShotbookColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: mono
                  ? ShotbookText.data.copyWith(fontSize: 13)
                  : const TextStyle(
                      fontSize: 14,
                      color: ShotbookColors.primary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flame + "3 дня подряд"; opens Challenges. Hidden while there is no
/// streak yet, unless [showWhenEmpty].
class StreakBadge extends ConsumerWidget {
  const StreakBadge({this.showWhenEmpty = false, super.key});

  final bool showWhenEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(streakDaysProvider);
    if (days <= 0 && !showWhenEmpty) return const SizedBox.shrink();
    return InkWell(
      key: const Key('streak-badge'),
      borderRadius: shotbookBorderRadius,
      onTap: () => context.push('/challenges'),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: shotbookBorderRadius,
          border: Border.all(color: ShotbookColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 15,
              color: ShotbookColors.accent,
            ),
            const SizedBox(width: 6),
            Text(
              days <= 0
                  ? context.tr('Start a streak')
                  : streakLabel(context, days),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ShotbookColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "1 день подряд", "3 дня подряд", "5 дней подряд" / "3-day streak".
String streakLabel(BuildContext context, int days) {
  if (!context.isRussian) return '$days-day streak';
  final mod10 = days % 10, mod100 = days % 100;
  final word = mod10 == 1 && mod100 != 11
      ? 'день'
      : mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)
      ? 'дня'
      : 'дней';
  return '$days $word подряд';
}

/// RU | EN segmented switch (Graphite language switch).
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);
    return Container(
      key: const Key('language-switch'),
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: shotbookBorderRadius,
        border: Border.all(color: ShotbookColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final code in supportedLanguageCodes)
            GestureDetector(
              key: Key('language-switch-$code'),
              onTap: () => ref.read(languageProvider.notifier).select(code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: code == current
                      ? ShotbookColors.card
                      : Colors.transparent,
                ),
                child: Text(
                  code.toUpperCase(),
                  style: TextStyle(
                    fontFamily: shotbookMonoFont,
                    fontSize: 12,
                    color: code == current
                        ? ShotbookColors.primary
                        : ShotbookColors.tertiary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Large screen title (Display, Unbounded 26).
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Filter chip (36 high, radius 8): selected = light fill with dark text,
/// otherwise a 1 px border with grey text.
class GraphiteChip extends StatelessWidget {
  const GraphiteChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? ShotbookColors.primary : Colors.transparent,
            borderRadius: shotbookBorderRadius,
            border: Border.all(
              color: selected ? ShotbookColors.primary : ShotbookColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected
                  ? ShotbookColors.background
                  : ShotbookColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
