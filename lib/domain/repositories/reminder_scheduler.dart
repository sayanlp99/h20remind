/// Schedules the recurring "drink some water" reminder on this device.
abstract interface class ReminderScheduler {
  /// Whether this platform can deliver recurring reminders at all.
  bool get isSupported;

  Future<bool> isEnabled();

  /// Asks for notification permission if needed, then schedules the reminder.
  /// Returns `false` if the user denied permission.
  Future<bool> enable();

  Future<void> disable();
}
