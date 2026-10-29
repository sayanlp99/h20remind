import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/dates.dart';
import '../../domain/models/water_entry.dart';
import '../../domain/repositories/health_sync.dart';
import '../../domain/repositories/water_log_repository.dart';

enum HealthSyncState {
  /// Still checking the platform.
  checking,

  /// No health platform on this device.
  unsupported,

  /// Health Connect must be installed or updated before syncing.
  needsInstall,
  off,
  on,
}

enum HealthSyncToggleResult {
  updated,
  permissionDenied,
  installRequired,
  failed,
}

/// Keeps the health platform in step with the water log while sync is on.
///
/// Whether sync is on is the permission grant itself, so there's no separate
/// preference to drift out of date. While on, it watches the recent window of
/// entries and reconciles after each change, which also picks up entries
/// logged on other devices.
class HealthSyncController extends ChangeNotifier {
  HealthSyncController({
    required this._health,
    required this._waterLog,
    required this._ownerId,
    this._clock = DateTime.now,
    this.windowDays = WaterLogRepository.maxDaysPerQuery,
    this.debounce = const Duration(seconds: 2),
  }) {
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(refresh()));
    unawaited(refresh());
  }

  final HealthSync _health;
  final WaterLogRepository _waterLog;
  final String _ownerId;
  final DateTime Function() _clock;

  /// How many days back are kept in sync.
  final int windowDays;

  /// Quiet period after a change before syncing, so bursts of edits sync once.
  final Duration debounce;

  late final AppLifecycleListener _lifecycle;
  StreamSubscription<List<WaterEntry>>? _entriesSubscription;
  Timer? _debounceTimer;
  List<DateTime> _days = const [];

  HealthSyncState _state = HealthSyncState.checking;
  bool _busy = false;
  bool _syncFailed = false;
  DateTime? _lastSyncedAt;
  bool _disposed = false;

  HealthSyncState get state => _state;
  bool get busy => _busy;
  bool get syncFailed => _syncFailed;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  /// Re-reads platform availability and permissions. Runs on resume because
  /// both can change in system settings while the app is in the background.
  Future<void> refresh() async {
    if (!_health.isSupported) return _setState(HealthSyncState.unsupported);
    try {
      final status = await _health.status();
      final next = switch (status) {
        HealthPlatformStatus.unavailable => HealthSyncState.unsupported,
        HealthPlatformStatus.updateRequired => HealthSyncState.needsInstall,
        HealthPlatformStatus.available =>
          await _health.hasPermissions()
              ? HealthSyncState.on
              : HealthSyncState.off,
      };
      _setState(next);
    } on PlatformException catch (e) {
      debugPrint('Health Connect status check failed: $e');
      _setState(HealthSyncState.off);
    }
  }

  Future<HealthSyncToggleResult> setEnabled(bool enabled) async {
    if (_busy) return HealthSyncToggleResult.updated;
    if (enabled && _state == HealthSyncState.needsInstall) {
      await _health.openInstallPage();
      return HealthSyncToggleResult.installRequired;
    }
    _busy = true;
    _notify();
    try {
      if (enabled) {
        final granted = await _health.requestPermissions();
        _setState(granted ? HealthSyncState.on : HealthSyncState.off);
        return granted
            ? HealthSyncToggleResult.updated
            : HealthSyncToggleResult.permissionDenied;
      }
      await _health.revokePermissions();
      _setState(HealthSyncState.off);
      return HealthSyncToggleResult.updated;
    } on PlatformException catch (e) {
      debugPrint('Failed to update Health Connect access: $e');
      return HealthSyncToggleResult.failed;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> openInstallPage() => _health.openInstallPage();

  Future<void> openSettings() => _health.openSettings();

  void _setState(HealthSyncState next) {
    final wasOn = _state == HealthSyncState.on;
    _state = next;
    if (next == HealthSyncState.on) {
      // Re-subscribe on every refresh so the window follows the calendar.
      _watch();
    } else if (wasOn) {
      _stopWatching();
    }
    _notify();
  }

  void _watch() {
    _stopWatching();
    _days = recentDays(_clock(), windowDays);
    _entriesSubscription = _waterLog
        .watchEntriesForDays(_days)
        .listen(
          _scheduleSync,
          onError: (Object e) =>
              debugPrint('Health sync entries stream failed: $e'),
        );
  }

  void _stopWatching() {
    _debounceTimer?.cancel();
    unawaited(_entriesSubscription?.cancel());
    _entriesSubscription = null;
  }

  void _scheduleSync(List<WaterEntry> entries) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(_sync(entries)));
  }

  Future<void> _sync(List<WaterEntry> entries) async {
    if (_state != HealthSyncState.on || _days.isEmpty) return;
    try {
      await _health.sync(
        ownerId: _ownerId,
        from: _days.last,
        to: _days.first.nextMidnight,
        entries: entries,
      );
      _syncFailed = false;
      _lastSyncedAt = _clock();
    } on PlatformException catch (e) {
      debugPrint('Health Connect sync failed: $e');
      _syncFailed = true;
      // Access was revoked from Health Connect's own settings.
      if (e.code == 'permission_denied') return _setState(HealthSyncState.off);
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _lifecycle.dispose();
    _stopWatching();
    super.dispose();
  }
}
