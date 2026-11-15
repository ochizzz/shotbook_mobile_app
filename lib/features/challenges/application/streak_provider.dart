import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/streak.dart';

/// Active days (local dates, `yyyy-mm-dd`), newest [streakHistoryLimit].
const streakPreferenceKey = 'shotbook.streak.days';

/// "Now" for the streak, the challenge of the week and the recipe of the
/// day. Tests override it to pin the date.
final challengesClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// The days on which the app was used. Empty until [StreakNotifier.markToday]
/// has read storage, and stays empty when storage is unavailable (widget
/// tests without mocked preferences), so the streak is 0 there.
class StreakNotifier extends Notifier<Set<DateTime>> {
  AppLifecycleListener? _lifecycle;

  @override
  Set<DateTime> build() {
    ref.onDispose(() {
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    return const {};
  }

  /// Records today as an active day. Called when the app starts and again
  /// whenever it comes back to the foreground on a later day.
  Future<void> markToday() async {
    _markOnResume();
    final today = calendarDay(ref.read(challengesClockProvider)());
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = (prefs.getStringList(streakPreferenceKey) ?? const [])
          .map(parseDayKey)
          .whereType<DateTime>();
      if (!ref.mounted) return;
      final days = trimHistory({...saved, ...state, today});
      // Always a new set, so the streak is recomputed for the new date.
      state = days.toSet();
      await prefs.setStringList(streakPreferenceKey, [
        for (final day in days) dayKey(day),
      ]);
    } catch (_) {
      // No storage, no streak: the badge stays hidden and nothing breaks.
    }
  }

  void _markOnResume() {
    if (_lifecycle != null) return;
    try {
      _lifecycle = AppLifecycleListener(onResume: markToday);
    } catch (_) {
      // No widgets binding (plain unit tests): explicit calls still count.
    }
  }
}

final streakHistoryProvider = NotifierProvider<StreakNotifier, Set<DateTime>>(
  StreakNotifier.new,
);

/// Consecutive days with the app opened, ending today. 0 = no streak yet.
final streakDaysProvider = Provider<int>(
  (ref) => countStreak(
    ref.watch(streakHistoryProvider),
    ref.watch(challengesClockProvider)(),
  ),
);

/// Monday to Sunday of the current week: was the app used that day?
final streakWeekProvider = Provider<List<bool>>(
  (ref) => activeDaysOfWeek(
    ref.watch(streakHistoryProvider),
    ref.watch(challengesClockProvider)(),
  ),
);
