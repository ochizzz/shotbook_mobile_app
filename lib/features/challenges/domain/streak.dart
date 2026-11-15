/// Day arithmetic for the streak: pure functions, no storage.
///
/// A day is the device's local calendar date. It is kept as a UTC midnight
/// value so that stepping a day back is always exactly 24 h, whatever the
/// daylight-saving rules of the device's time zone.
library;

/// How many active days are kept in storage. Enough for the week row and a
/// long streak; older dates are dropped.
const streakHistoryLimit = 60;

/// [time]'s local calendar date.
DateTime calendarDay(DateTime time) =>
    DateTime.utc(time.year, time.month, time.day);

/// "2026-11-14".
String dayKey(DateTime day) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${day.year.toString().padLeft(4, '0')}-${two(day.month)}-'
      '${two(day.day)}';
}

/// The day written by [dayKey]; null for anything else.
DateTime? parseDayKey(String key) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key.trim());
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime.utc(year, month, day);
  // Reject dates that roll over, like 2026-02-31.
  if (date.month != month || date.day != day) return null;
  return date;
}

const _oneDay = Duration(days: 1);

/// Consecutive active days that end today. Until today is marked the streak
/// still counts from yesterday, so it does not drop to 0 in the morning
/// before the app was opened.
int countStreak(Iterable<DateTime> activeDays, DateTime now) {
  final days = activeDays.map(calendarDay).toSet();
  var day = calendarDay(now);
  if (!days.contains(day)) day = day.subtract(_oneDay);
  var count = 0;
  while (days.contains(day)) {
    count++;
    day = day.subtract(_oneDay);
  }
  return count;
}

/// Monday of the week [now] falls in.
DateTime weekStart(DateTime now) {
  final today = calendarDay(now);
  return today.subtract(Duration(days: today.weekday - DateTime.monday));
}

/// Seven flags, Monday to Sunday of the current week: was the app used?
List<bool> activeDaysOfWeek(Iterable<DateTime> activeDays, DateTime now) {
  final days = activeDays.map(calendarDay).toSet();
  final monday = weekStart(now);
  return [
    for (var i = 0; i < DateTime.daysPerWeek; i++)
      days.contains(monday.add(Duration(days: i))),
  ];
}

/// The newest [limit] days, oldest first.
List<DateTime> trimHistory(
  Iterable<DateTime> activeDays, {
  int limit = streakHistoryLimit,
}) {
  final days = activeDays.map(calendarDay).toSet().toList()..sort();
  return days.length <= limit ? days : days.sublist(days.length - limit);
}
