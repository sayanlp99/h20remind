import '../models/water_entry.dart';

enum HealthPlatformStatus {
  /// The health platform is installed and usable.
  available,

  /// The provider app must be installed or updated first.
  updateRequired,

  /// Not supported on this device or platform.
  unavailable,
}

/// Mirrors the water log into the device's health platform (Health Connect
/// on Android), where apps such as Google Fit can read it.
abstract interface class HealthSync {
  /// Whether this platform has a health store integration at all.
  bool get isSupported;

  Future<HealthPlatformStatus> status();

  Future<bool> hasPermissions();

  /// Shows the system permission prompt. Returns whether access was granted.
  Future<bool> requestPermissions();

  Future<void> revokePermissions();

  Future<void> openInstallPage();

  /// Opens the health platform's own settings, where the user manages data
  /// and which apps can read it.
  Future<void> openSettings();

  /// Makes the health store's records for [ownerId] within `[from, to)` match
  /// [entries]: adds missing ones and removes ones that no longer exist.
  Future<HealthSyncResult> sync({
    required String ownerId,
    required DateTime from,
    required DateTime to,
    required List<WaterEntry> entries,
  });
}

typedef HealthSyncResult = ({int inserted, int deleted});
