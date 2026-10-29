import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app.dart';
import 'data/auth/firebase_auth_repository.dart';
import 'data/firestore/firestore_user_repositories.dart';
import 'data/health/health_connect_sync.dart';
import 'data/notifications/local_notification_reminder_scheduler.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  runApp(
    H20RemindApp(
      authRepository: FirebaseAuthRepository(FirebaseAuth.instance),
      reminderScheduler: LocalNotificationReminderScheduler(
        FlutterLocalNotificationsPlugin(),
      ),
      healthSync: HealthConnectSync(),
      userRepositories: (user) => firestoreUserRepositories(firestore, user),
    ),
  );
}
