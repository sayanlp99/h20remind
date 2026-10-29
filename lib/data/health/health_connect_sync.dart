import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/models/water_entry.dart';
import '../../domain/repositories/health_sync.dart';

/// [HealthSync] backed by Android Health Connect through a platform channel
/// (see `HealthConnectBridge.kt`).
class HealthConnectSync implements HealthSync {
  HealthConnectSync({
    this._channel = const MethodChannel('h20remind/health_connect'),
  });

  final MethodChannel _channel;

  /// Health Connect only applies revocation once the app process restarts,
  /// so remember it for the rest of this session.
  bool _revokedThisSession = false;

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<HealthPlatformStatus> status() async {
    if (!isSupported) return HealthPlatformStatus.unavailable;
    return switch (await _channel.invokeMethod<String>('getStatus')) {
      'available' => HealthPlatformStatus.available,
      'updateRequired' => HealthPlatformStatus.updateRequired,
      _ => HealthPlatformStatus.unavailable,
    };
  }

  @override
  Future<bool> hasPermissions() async {
    if (!isSupported || _revokedThisSession) return false;
    return await _channel.invokeMethod<bool>('hasPermissions') ?? false;
  }

  @override
  Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    final granted =
        await _channel.invokeMethod<bool>('requestPermissions') ?? false;
    if (granted) _revokedThisSession = false;
    return granted;
  }

  @override
  Future<void> revokePermissions() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('revokePermissions');
    _revokedThisSession = true;
  }

  @override
  Future<void> openInstallPage() =>
      _channel.invokeMethod<void>('openInstallPage');

  @override
  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');

  @override
  Future<HealthSyncResult> sync({
    required String ownerId,
    required DateTime from,
    required DateTime to,
    required List<WaterEntry> entries,
  }) async {
    final result = await _channel.invokeMapMethod<String, int>('sync', {
      // Scopes records to this account so switching accounts on a shared
      // device never touches another account's data.
      'prefix': '$ownerId:',
      'startMs': from.millisecondsSinceEpoch,
      'endMs': to.millisecondsSinceEpoch,
      'entries': [
        for (final entry in entries)
          {
            'id': entry.id,
            'ml': entry.amountMl,
            'timeMs': entry.loggedAt.millisecondsSinceEpoch,
            'offsetSeconds': entry.loggedAt.timeZoneOffset.inSeconds,
          },
      ],
    });
    return (
      inserted: result?['inserted'] ?? 0,
      deleted: result?['deleted'] ?? 0,
    );
  }
}
