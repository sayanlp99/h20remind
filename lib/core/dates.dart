/// Calendar helpers that operate on local, date-only [DateTime]s.
extension CalendarDate on DateTime {
  /// Midnight (local time) at the start of this day.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Midnight at the start of the following day. DST-safe because it relies
  /// on [DateTime]'s calendar normalisation rather than adding 24 hours.
  DateTime get nextMidnight => DateTime(year, month, day + 1);

  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

/// The last [count] calendar days ending on [today], newest first.
List<DateTime> recentDays(DateTime today, int count) => [
  for (var i = 0; i < count; i++)
    DateTime(today.year, today.month, today.day - i),
];
