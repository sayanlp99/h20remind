import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h20remind/domain/repositories/health_sync.dart';
import 'package:h20remind/presentation/health/health_sync_controller.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 28, 12);
  late FakeHealthSync health;
  late InMemoryWaterLog waterLog;

  setUp(() {
    health = FakeHealthSync();
    waterLog = InMemoryWaterLog([
      entry('a', 250, DateTime(2026, 9, 28, 9)),
      entry('old', 500, DateTime(2026, 8, 1, 9)),
    ]);
  });

  HealthSyncController create() {
    final controller = HealthSyncController(
      health: health,
      waterLog: waterLog,
      ownerId: 'uid-1',
      clock: () => now,
      debounce: Duration.zero,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('is unsupported without a health platform', () async {
    health = FakeHealthSync(isSupported: false);
    final controller = create();
    await pumpEventQueue();
    expect(controller.state, HealthSyncState.unsupported);
  });

  test('sends the user to install Health Connect when missing', () async {
    health.platformStatus = HealthPlatformStatus.updateRequired;
    final controller = create();
    await pumpEventQueue();
    expect(controller.state, HealthSyncState.needsInstall);

    expect(
      await controller.setEnabled(true),
      HealthSyncToggleResult.installRequired,
    );
    expect(health.installPageOpens, 1);
  });

  test('enabling syncs the 30-day window for this user', () async {
    final controller = create();
    await pumpEventQueue();
    expect(controller.state, HealthSyncState.off);
    expect(health.syncCalls, isEmpty);

    expect(await controller.setEnabled(true), HealthSyncToggleResult.updated);
    await pumpEventQueue();

    expect(controller.state, HealthSyncState.on);
    final call = health.syncCalls.single;
    expect(call.ownerId, 'uid-1');
    expect(call.from, DateTime(2026, 8, 30));
    expect(call.to, DateTime(2026, 9, 29));
    expect(call.entries.map((e) => e.id), ['a']);
    expect(controller.lastSyncedAt, now);
  });

  test('re-syncs after changes and stops once disabled', () async {
    health.granted = true;
    final controller = create();
    await pumpEventQueue();
    expect(controller.state, HealthSyncState.on);
    expect(health.syncCalls, hasLength(1));

    await waterLog.addEntry(amountMl: 330, loggedAt: now);
    await pumpEventQueue();
    expect(health.syncCalls, hasLength(2));
    expect(health.syncCalls.last.entries, hasLength(2));

    await controller.setEnabled(false);
    await waterLog.addEntry(amountMl: 100, loggedAt: now);
    await pumpEventQueue();
    expect(controller.state, HealthSyncState.off);
    expect(health.syncCalls, hasLength(2));
  });

  test('denied permission leaves sync off', () async {
    health.grantOnRequest = false;
    final controller = create();
    await pumpEventQueue();
    expect(
      await controller.setEnabled(true),
      HealthSyncToggleResult.permissionDenied,
    );
    expect(controller.state, HealthSyncState.off);
  });

  test('turns off when access is revoked from Health Connect', () async {
    health
      ..granted = true
      ..nextSyncError = PlatformException(code: 'permission_denied');
    final controller = create();
    await pumpEventQueue();
    expect(controller.state, HealthSyncState.off);
    expect(controller.syncFailed, isTrue);
  });
}
