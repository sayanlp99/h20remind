import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h20remind/data/health/health_connect_sync.dart';
import 'package:h20remind/domain/repositories/health_sync.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('h20remind/health_connect');
  final calls = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'getStatus' => 'updateRequired',
            'hasPermissions' || 'requestPermissions' => true,
            'sync' => {'inserted': 1, 'deleted': 2},
            _ => null,
          };
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps platform status', () async {
    expect(
      await HealthConnectSync().status(),
      HealthPlatformStatus.updateRequired,
    );
  });

  test('sends account-scoped entries with time and zone offset', () async {
    final loggedAt = DateTime(2026, 9, 28, 9, 30);
    final result = await HealthConnectSync().sync(
      ownerId: 'uid-1',
      from: DateTime(2026, 9, 1),
      to: DateTime(2026, 9, 29),
      entries: [entry('e1', 250, loggedAt)],
    );

    expect(result, (inserted: 1, deleted: 2));
    final args = calls.single.arguments as Map<Object?, Object?>;
    expect(args['prefix'], 'uid-1:');
    expect(args['startMs'], DateTime(2026, 9, 1).millisecondsSinceEpoch);
    expect(args['endMs'], DateTime(2026, 9, 29).millisecondsSinceEpoch);
    expect(args['entries'], [
      {
        'id': 'e1',
        'ml': 250,
        'timeMs': loggedAt.millisecondsSinceEpoch,
        'offsetSeconds': loggedAt.timeZoneOffset.inSeconds,
      },
    ]);
  });

  test('treats access as revoked for the rest of the session', () async {
    final sync = HealthConnectSync();
    expect(await sync.hasPermissions(), isTrue);
    await sync.revokePermissions();
    expect(await sync.hasPermissions(), isFalse);
    expect(await sync.requestPermissions(), isTrue);
    expect(await sync.hasPermissions(), isTrue);
  });

  test('is a no-op off Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final sync = HealthConnectSync();
    expect(sync.isSupported, isFalse);
    expect(await sync.status(), HealthPlatformStatus.unavailable);
    expect(calls, isEmpty);
  });
}
