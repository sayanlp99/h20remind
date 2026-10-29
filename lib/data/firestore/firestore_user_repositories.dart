import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/user_repositories.dart';
import 'firestore_goal_repository.dart';
import 'firestore_water_log_repository.dart';

/// Builds the Firestore-backed repositories for [user].
///
/// Data lives in a top-level collection named after the user's email address,
/// which is how v1 of the app stored it.
UserRepositories firestoreUserRepositories(
  FirebaseFirestore firestore,
  AppUser user,
) {
  final collection = firestore.collection(user.email ?? user.id);
  return (
    waterLog: FirestoreWaterLogRepository(collection),
    goals: FirestoreGoalRepository(collection),
  );
}
