import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/reminder_scheduler.dart';

enum ReminderToggleResult { updated, permissionDenied, failed }

/// State for user preferences: the daily goal and device reminders.
class SettingsController extends ChangeNotifier {
  SettingsController({required this._goals, required this._reminders}) {
    _goalSubscription = _goals.watchDailyGoal().listen((goal) {
      _goalMl = goal;
      notifyListeners();
    }, onError: (Object e) => debugPrint('Goal stream failed: $e'));
    unawaited(_loadReminderState());
  }

  final GoalRepository _goals;
  final ReminderScheduler _reminders;
  late final StreamSubscription<int> _goalSubscription;

  int? _goalMl;
  bool _remindersEnabled = false;
  bool _reminderBusy = false;
  bool _disposed = false;

  /// `null` until the goal has loaded.
  int? get goalMl => _goalMl;
  bool get remindersSupported => _reminders.isSupported;
  bool get remindersEnabled => _remindersEnabled;
  bool get reminderBusy => _reminderBusy;

  Future<void> setGoal(int millilitres) => _goals.setDailyGoal(millilitres);

  Future<ReminderToggleResult> setRemindersEnabled(bool enabled) async {
    if (_reminderBusy) return ReminderToggleResult.updated;
    _reminderBusy = true;
    _notify();
    try {
      if (enabled) {
        final granted = await _reminders.enable();
        _remindersEnabled = granted;
        return granted
            ? ReminderToggleResult.updated
            : ReminderToggleResult.permissionDenied;
      }
      await _reminders.disable();
      _remindersEnabled = false;
      return ReminderToggleResult.updated;
    } on Object catch (e) {
      debugPrint('Failed to update reminders: $e');
      return ReminderToggleResult.failed;
    } finally {
      _reminderBusy = false;
      _notify();
    }
  }

  Future<void> _loadReminderState() async {
    try {
      _remindersEnabled = await _reminders.isEnabled();
      _notify();
    } on Object catch (e) {
      debugPrint('Failed to read reminder state: $e');
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_goalSubscription.cancel());
    super.dispose();
  }
}
