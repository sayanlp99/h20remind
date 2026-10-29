import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../app/session_controller.dart';
import '../common/status_views.dart';
import '../common/user_avatar.dart';
import '../health/health_sync_controller.dart';
import 'settings_controller.dart';
import 'widgets/goal_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Pushes the screen, carrying over the user-scoped [SettingsController]
  /// since routes are built above the scope that provides it.
  static Future<void> open(BuildContext context) {
    final controller = context.read<SettingsController>();
    final health = context.read<HealthSyncController>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: controller),
            ChangeNotifierProvider.value(value: health),
          ],
          child: const SettingsScreen(),
        ),
      ),
    );
  }

  Future<void> _editGoal(
    BuildContext context,
    SettingsController controller,
  ) async {
    final goal = await showGoalDialog(
      context,
      initialGoalMl: controller.goalMl,
    );
    if (goal == null || goal == controller.goalMl) return;
    try {
      await controller.setGoal(goal);
    } on Object {
      if (context.mounted) {
        showMessage(context, "Couldn't save your goal. Try again.");
      }
    }
  }

  Future<void> _toggleReminders(
    BuildContext context,
    SettingsController controller,
    bool enabled,
  ) async {
    final result = await controller.setRemindersEnabled(enabled);
    if (!context.mounted) return;
    switch (result) {
      case ReminderToggleResult.updated:
        break;
      case ReminderToggleResult.permissionDenied:
        showMessage(
          context,
          'Allow notifications for h20remind in system settings to get reminders.',
        );
      case ReminderToggleResult.failed:
        showMessage(context, "Couldn't update reminders. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final session = context.read<SessionController>();
    final user = context.select((SessionController s) => s.user);
    final goal = controller.goalMl;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            children: [
              const SectionHeader('Hydration'),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Daily goal'),
                subtitle: Text(goal == null ? 'Loading…' : formatMl(goal)),
                enabled: goal != null,
                onTap: () => unawaited(_editGoal(context, controller)),
              ),
              if (controller.remindersSupported)
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Hourly reminders'),
                  subtitle: const Text('Get a nudge every hour to drink water'),
                  value: controller.remindersEnabled,
                  onChanged: controller.reminderBusy
                      ? null
                      : (enabled) => unawaited(
                          _toggleReminders(context, controller, enabled),
                        ),
                )
              else
                const ListTile(
                  leading: Icon(Icons.notifications_off_outlined),
                  title: Text('Hourly reminders'),
                  subtitle: Text('Available in the Android and iOS apps'),
                  enabled: false,
                ),
              const _ConnectedAppsSection(),
              const SectionHeader('Account'),
              if (user != null)
                ListTile(
                  leading: UserAvatar(user: user, radius: 20),
                  title: Text(user.label),
                  subtitle: user.email == null ? null : Text(user.email!),
                ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Sign out'),
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  unawaited(session.signOut());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectedAppsSection extends StatelessWidget {
  const _ConnectedAppsSection();

  static const _description =
      'Share hydration with Google Fit and other health apps';

  Future<void> _toggle(
    BuildContext context,
    HealthSyncController health,
    bool enabled,
  ) async {
    final result = await health.setEnabled(enabled);
    if (!context.mounted) return;
    switch (result) {
      case HealthSyncToggleResult.updated:
        if (enabled) {
          showMessage(context, 'Syncing hydration with Health Connect');
        }
      case HealthSyncToggleResult.installRequired:
        break;
      case HealthSyncToggleResult.permissionDenied:
        showMessage(
          context,
          'Allow hydration access in Health Connect to sync.',
        );
      case HealthSyncToggleResult.failed:
        showMessage(
          context,
          "Couldn't update Health Connect access. Try again.",
        );
    }
  }

  String _statusLine(BuildContext context, HealthSyncController health) {
    if (health.syncFailed) {
      return "Couldn't sync. We'll try again automatically.";
    }
    final syncedAt = health.lastSyncedAt;
    if (syncedAt == null) return _description;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(syncedAt),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return 'Last synced $time';
  }

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthSyncController>();
    const icon = Icon(Icons.monitor_heart_outlined);

    final List<Widget> tiles = switch (health.state) {
      HealthSyncState.checking || HealthSyncState.unsupported => const [],
      HealthSyncState.needsInstall => [
        ListTile(
          leading: icon,
          title: const Text('Health Connect'),
          subtitle: const Text(
            'Install Health Connect to share hydration with Google Fit',
          ),
          trailing: TextButton(
            onPressed: () => unawaited(health.openInstallPage()),
            child: const Text('Install'),
          ),
        ),
      ],
      HealthSyncState.off || HealthSyncState.on => [
        SwitchListTile(
          secondary: icon,
          title: const Text('Sync with Health Connect'),
          subtitle: Text(
            health.state == HealthSyncState.on
                ? _statusLine(context, health)
                : _description,
          ),
          value: health.state == HealthSyncState.on,
          onChanged: health.busy
              ? null
              : (enabled) => unawaited(_toggle(context, health, enabled)),
        ),
        if (health.state == HealthSyncState.on)
          ListTile(
            leading: const SizedBox.shrink(),
            title: const Text('Manage in Health Connect'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => unawaited(health.openSettings()),
          ),
      ],
    };

    if (tiles.isEmpty) return const SizedBox.shrink();
    return Column(children: [const SectionHeader('Connected apps'), ...tiles]);
  }
}
