import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/health_sync.dart';
import 'domain/repositories/reminder_scheduler.dart';
import 'domain/repositories/user_repositories.dart';
import 'presentation/app/auth_gate.dart';
import 'presentation/app/session_controller.dart';

/// Root widget. Depends only on abstractions so tests can inject fakes.
class H20RemindApp extends StatelessWidget {
  const H20RemindApp({
    super.key,
    required this.authRepository,
    required this.reminderScheduler,
    required this.healthSync,
    required this.userRepositories,
  });

  final AuthRepository authRepository;
  final ReminderScheduler reminderScheduler;
  final HealthSync healthSync;
  final UserRepositoriesFactory userRepositories;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ReminderScheduler>.value(value: reminderScheduler),
        Provider<HealthSync>.value(value: healthSync),
        Provider<UserRepositoriesFactory>.value(value: userRepositories),
        ChangeNotifierProvider(
          create: (_) => SessionController(
            auth: authRepository,
            reminders: reminderScheduler,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'h20remind',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const AuthGate(),
      ),
    );
  }
}
