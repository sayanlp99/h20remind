import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/repositories/reminder_scheduler.dart';

/// Hourly reminder backed by the OS notification scheduler.
///
/// The OS persists the schedule, so "enabled" is derived from the pending
/// notification list rather than stored separately.
class LocalNotificationReminderScheduler implements ReminderScheduler {
  LocalNotificationReminderScheduler(this._plugin);

  static const int _reminderId = 1;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'hydration_reminders',
      'Hydration reminders',
      channelDescription: 'Hourly reminders to drink water',
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(),
  );

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;

  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> isEnabled() async {
    if (!isSupported) return false;
    await _ensureInitialized();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((request) => request.id == _reminderId);
  }

  @override
  Future<bool> enable() async {
    if (!isSupported) return false;
    await _ensureInitialized();
    if (!await _requestPermission()) return false;

    await _plugin.periodicallyShow(
      id: _reminderId,
      title: 'Time for some water',
      body: 'A glass now keeps you on track for your daily goal.',
      repeatInterval: RepeatInterval.hourly,
      notificationDetails: _details,
      // Exact timing isn't needed and would require an extra permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return true;
  }

  @override
  Future<void> disable() async {
    if (!isSupported) return;
    await _ensureInitialized();
    await _plugin.cancel(id: _reminderId);
  }

  Future<void> _ensureInitialized() => _initialization ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_water'),
      // Permission is requested when the user turns reminders on, not at launch.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

  Future<bool> _requestPermission() async {
    final granted = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission(),
      TargetPlatform.iOS =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true, badge: true),
      _ => false,
    };
    return granted ?? false;
  }
}
