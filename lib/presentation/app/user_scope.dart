import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/health_sync.dart';
import '../../domain/repositories/reminder_scheduler.dart';
import '../../domain/repositories/user_repositories.dart';
import '../../domain/repositories/water_log_repository.dart';
import '../health/health_sync_controller.dart';
import '../history/history_controller.dart';
import '../settings/settings_controller.dart';
import '../today/today_controller.dart';

/// Provides the repositories and controllers that belong to [user].
///
/// Give it a key derived from the user so that switching accounts rebuilds
/// everything from scratch rather than leaking the previous user's state.
class UserScope extends StatelessWidget {
  const UserScope({super.key, required this.user, required this.child});

  final AppUser user;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final repositories = context.read<UserRepositoriesFactory>()(user);
    return MultiProvider(
      providers: [
        Provider<WaterLogRepository>.value(value: repositories.waterLog),
        Provider<GoalRepository>.value(value: repositories.goals),
        ChangeNotifierProvider(
          create: (context) =>
              TodayController(waterLog: context.read(), goals: context.read()),
        ),
        ChangeNotifierProvider(
          create: (context) => HistoryController(
            waterLog: context.read(),
            goals: context.read(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsController(
            goals: context.read(),
            reminders: context.read<ReminderScheduler>(),
          ),
        ),
        ChangeNotifierProvider(
          // Not lazy: sync should run in the background even if Settings
          // is never opened.
          lazy: false,
          create: (context) => HealthSyncController(
            health: context.read<HealthSync>(),
            waterLog: context.read(),
            ownerId: user.id,
          ),
        ),
      ],
      child: child,
    );
  }
}
