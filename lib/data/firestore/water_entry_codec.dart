import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/water_entry.dart';

/// Maps [WaterEntry] to and from Firestore documents.
///
/// The document shape is inherited from v1 of the app and must stay
/// readable by it:
///
/// ```json
/// { "drank": "250", "date": "28-09-2026", "time": "3:45 PM", "createdAt": <Timestamp> }
/// ```
///
/// `createdAt` was added in v2; older documents fall back to `date` + `time`.
abstract final class WaterEntryCodec {
  static const String amountField = 'drank';
  static const String dayField = 'date';
  static const String timeField = 'time';
  static const String createdAtField = 'createdAt';

  /// Returns `null` for documents that aren't drink entries (e.g. the goal)
  /// or are too malformed to use.
  static WaterEntry? decode(String id, Map<String, Object?> data) {
    final amount = parseMillilitres(data[amountField]);
    final dayValue = data[dayField];
    final day = dayValue is String ? DayKey.parse(dayValue) : null;
    if (amount == null || day == null) return null;

    final createdAt = data[createdAtField];
    final timeValue = data[timeField];
    final loggedAt = createdAt is Timestamp
        ? createdAt.toDate()
        : _combine(
            day,
            timeValue is String ? LegacyTime.parse(timeValue) : null,
          );

    return WaterEntry(id: id, amountMl: amount, day: day, loggedAt: loggedAt);
  }

  static Map<String, Object?> encode(WaterEntry entry) => {
    // Stored as a string for compatibility with v1 clients.
    amountField: entry.amountMl.toString(),
    dayField: DayKey.format(entry.day),
    timeField: LegacyTime.format(entry.loggedAt),
    createdAtField: Timestamp.fromDate(entry.loggedAt),
  };

  /// Accepts ints, doubles and numeric strings such as `"250"` or `"250.0"`.
  static int? parseMillilitres(Object? value) {
    final number = switch (value) {
      num() => value,
      String() => num.tryParse(value.trim()),
      _ => null,
    };
    if (number == null || !number.isFinite || number <= 0) return null;
    return number.round();
  }

  static DateTime _combine(DateTime day, Duration? timeOfDay) =>
      timeOfDay == null ? day : day.add(timeOfDay);
}

/// The `dd-MM-yyyy` string used to bucket entries by day.
abstract final class DayKey {
  static String format(DateTime day) =>
      '${_two(day.day)}-${_two(day.month)}-${day.year.toString().padLeft(4, '0')}';

  static DateTime? parse(String key) {
    final match = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$')
        .firstMatch(key.trim());
    if (match == null) return null;
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    // Reject values that DateTime silently normalises, like 31-02-2026.
    return date.day == day && date.month == month ? date : null;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

/// The `h:mm AM` time string written by v1 of the app (intl's `jm` pattern).
abstract final class LegacyTime {
  static String format(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Offset from midnight, or `null` if [value] isn't in the expected format.
  static Duration? parse(String value) {
    // Newer CLDR data uses narrow/no-break spaces before the AM/PM marker.
    final normalised = value.replaceAll(RegExp('[  ]'), ' ').trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp])[Mm]$')
        .firstMatch(normalised);
    if (match == null) return null;
    final hour12 = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    if (hour12 < 1 || hour12 > 12 || minute > 59) return null;
    final isPm = match[3]!.toUpperCase() == 'P';
    final hour = hour12 % 12 + (isPm ? 12 : 0);
    return Duration(hours: hour, minutes: minute);
  }
}
