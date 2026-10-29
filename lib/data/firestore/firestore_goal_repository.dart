import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/goal_repository.dart';
import 'water_entry_codec.dart';

/// Stores the goal as `{"goal": "3000"}` in a `goal` document alongside the
/// user's entries, matching v1 of the app.
class FirestoreGoalRepository implements GoalRepository {
  FirestoreGoalRepository(CollectionReference<Map<String, dynamic>> collection)
    : _doc = collection.doc(_docId);

  static const String _docId = 'goal';
  static const String _field = 'goal';

  final DocumentReference<Map<String, dynamic>> _doc;

  @override
  Stream<int> watchDailyGoal() => _doc.snapshots().map(
    (snapshot) =>
        WaterEntryCodec.parseMillilitres(snapshot.data()?[_field]) ??
        GoalRepository.defaultGoalMl,
  );

  @override
  Future<void> setDailyGoal(int millilitres) =>
      // Stored as a string for compatibility with v1 clients.
      _doc.set({_field: millilitres.toString()});
}
