import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shotbook/features/challenges/application/streak_provider.dart';
import 'package:shotbook/features/challenges/domain/streak.dart';

DateTime d(int year, int month, int day) => DateTime(year, month, day);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('countStreak', () {
    final now = DateTime(2026, 11, 14, 18, 30);

    test('no days is no streak', () {
      expect(countStreak(const [], now), 0);
    });

    test('today only counts 1', () {
      expect(countStreak([d(2026, 11, 14)], now), 1);
    });

    test('yesterday and today count 2', () {
      expect(countStreak([d(2026, 11, 13), d(2026, 11, 14)], now), 2);
    });

    test('a gap resets the streak', () {
      expect(
        countStreak([d(2026, 11, 10), d(2026, 11, 11), d(2026, 11, 14)], now),
        1,
      );
      expect(countStreak([d(2026, 11, 11), d(2026, 11, 12)], now), 0);
    });

    test('yesterday keeps the streak alive until today is marked', () {
      expect(countStreak([d(2026, 11, 12), d(2026, 11, 13)], now), 2);
    });

    test('times of day and duplicates do not matter', () {
      expect(
        countStreak([
          DateTime(2026, 11, 13, 23, 59),
          DateTime(2026, 11, 14, 0, 1),
          DateTime(2026, 11, 14, 12),
        ], now),
        2,
      );
    });

    test('runs across month and year boundaries', () {
      expect(
        countStreak([
          d(2026, 2, 27),
          d(2026, 2, 28),
          d(2026, 3, 1),
          d(2026, 3, 2),
        ], DateTime(2026, 3, 2, 9)),
        4,
      );
      expect(
        countStreak([
          d(2024, 2, 28),
          d(2024, 2, 29),
          d(2024, 3, 1),
        ], DateTime(2024, 3, 1)),
        3,
      );
      expect(
        countStreak([
          d(2026, 12, 30),
          d(2026, 12, 31),
          d(2027, 1, 1),
        ], DateTime(2027, 1, 1, 8)),
        3,
      );
      expect(
        countStreak([
          d(2026, 10, 30),
          d(2026, 10, 31),
          d(2026, 11, 1),
        ], DateTime(2026, 11, 1)),
        3,
      );
    });
  });

  group('week and history', () {
    test('marks Monday to Sunday of the current week', () {
      // 2026-11-14 is a Saturday; the week starts on Monday 9 November.
      final week = activeDaysOfWeek([
        d(2026, 11, 8), // last Sunday: not this week
        d(2026, 11, 9),
        d(2026, 11, 10),
        d(2026, 11, 14),
      ], DateTime(2026, 11, 14, 10));
      expect(week, [true, true, false, false, false, true, false]);
    });

    test('a Sunday belongs to the week that started on Monday', () {
      expect(weekStart(DateTime(2026, 11, 15, 23)), DateTime.utc(2026, 11, 9));
      expect(weekStart(DateTime(2026, 11, 9)), DateTime.utc(2026, 11, 9));
      expect(weekStart(DateTime(2026, 3, 1)), DateTime.utc(2026, 2, 23));
    });

    test('day keys round-trip and reject garbage', () {
      expect(dayKey(DateTime(2026, 3, 7, 22)), '2026-03-07');
      expect(parseDayKey('2026-03-07'), DateTime.utc(2026, 3, 7));
      expect(parseDayKey('2026-02-31'), isNull);
      expect(parseDayKey('yesterday'), isNull);
    });

    test('keeps only the newest days', () {
      final days = [
        for (var i = 0; i < 80; i++)
          DateTime(2026, 1, 1).add(Duration(days: i)),
      ];
      final kept = trimHistory(days.reversed);
      expect(kept, hasLength(streakHistoryLimit));
      expect(kept.first, DateTime.utc(2026, 1, 21));
      expect(kept.last, DateTime.utc(2026, 3, 21));
    });
  });

  group('streak storage', () {
    ProviderContainer container(DateTime now) {
      final container = ProviderContainer(
        overrides: [challengesClockProvider.overrideWithValue(() => now)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('opening the app marks today and continues a saved streak', () async {
      SharedPreferences.setMockInitialValues({
        streakPreferenceKey: ['2026-11-12', '2026-11-13', 'broken'],
      });
      final c = container(DateTime(2026, 11, 14, 9));
      expect(c.read(streakDaysProvider), 0);

      await c.read(streakHistoryProvider.notifier).markToday();

      expect(c.read(streakDaysProvider), 3);
      expect(c.read(streakWeekProvider), [
        false,
        false,
        false,
        true,
        true,
        true,
        false,
      ]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(streakPreferenceKey), [
        '2026-11-12',
        '2026-11-13',
        '2026-11-14',
      ]);
    });

    test('marking twice on the same day counts once', () async {
      SharedPreferences.setMockInitialValues({});
      final c = container(DateTime(2026, 11, 14, 9));
      await c.read(streakHistoryProvider.notifier).markToday();
      await c.read(streakHistoryProvider.notifier).markToday();
      expect(c.read(streakDaysProvider), 1);
    });

    test('a missed day starts over', () async {
      SharedPreferences.setMockInitialValues({
        streakPreferenceKey: ['2026-11-10', '2026-11-11'],
      });
      final c = container(DateTime(2026, 11, 14, 9));
      await c.read(streakHistoryProvider.notifier).markToday();
      expect(c.read(streakDaysProvider), 1);
    });
  });
}
