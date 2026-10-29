import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/water_entry.dart';
import '../../domain/repositories/water_log_repository.dart';
import 'water_entry_codec.dart';

/// Stores entries as documents in the user's collection (see [WaterEntryCodec]).
class FirestoreWaterLogRepository implements WaterLogRepository {
  FirestoreWaterLogRepository(this._collection);

  final CollectionReference<Map<String, dynamic>> _collection;

  @override
  Stream<List<WaterEntry>> watchEntriesForDay(DateTime day) => _collection
      .where(WaterEntryCodec.dayField, isEqualTo: DayKey.format(day))
      .snapshots()
      .map(_decode);

  @override
  Stream<List<WaterEntry>> watchEntriesForDays(List<DateTime> days) {
    if (days.isEmpty) return Stream.value(const []);
    if (days.length > WaterLogRepository.maxDaysPerQuery) {
      throw ArgumentError.value(
        days.length,
        'days',
        'At most ${WaterLogRepository.maxDaysPerQuery} days per query',
      );
    }
    return _collection
        .where(
          WaterEntryCodec.dayField,
          whereIn: days.map(DayKey.format).toList(),
        )
        .snapshots()
        .map(_decode);
  }

  @override
  Future<void> addEntry({required int amountMl, required DateTime loggedAt}) {
    final doc = _collection.doc();
    return doc.set(
      WaterEntryCodec.encode(
        WaterEntry(
          id: doc.id,
          amountMl: amountMl,
          day: DateTime(loggedAt.year, loggedAt.month, loggedAt.day),
          loggedAt: loggedAt,
        ),
      ),
    );
  }

  @override
  Future<void> deleteEntry(String id) => _collection.doc(id).delete();

  @override
  Future<void> restoreEntry(WaterEntry entry) =>
      _collection.doc(entry.id).set(WaterEntryCodec.encode(entry));

  /// Newest first.
  static List<WaterEntry> _decode(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final entries = [
      for (final doc in snapshot.docs)
        ?WaterEntryCodec.decode(doc.id, doc.data()),
    ];
    entries.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return entries;
  }
}
