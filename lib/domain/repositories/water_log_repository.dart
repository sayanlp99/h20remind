import '../models/water_entry.dart';

/// Reads and writes the signed-in user's drink log.
abstract interface class WaterLogRepository {
  /// Maximum number of days [watchEntriesForDays] accepts in a single call.
  static const int maxDaysPerQuery = 30;

  Stream<List<WaterEntry>> watchEntriesForDay(DateTime day);

  /// Entries for any of [days], at most [maxDaysPerQuery] of them.
  Stream<List<WaterEntry>> watchEntriesForDays(List<DateTime> days);

  Future<void> addEntry({required int amountMl, required DateTime loggedAt});

  Future<void> deleteEntry(String id);

  /// Re-inserts a previously deleted entry with its original id (for undo).
  Future<void> restoreEntry(WaterEntry entry);
}
