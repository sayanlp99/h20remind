import 'dart:async';

import 'package:flutter/services.dart';

import 'package:h20remind/core/dates.dart';
import 'package:h20remind/domain/models/app_user.dart';
import 'package:h20remind/domain/models/water_entry.dart';
import 'package:h20remind/domain/repositories/auth_repository.dart';
import 'package:h20remind/domain/repositories/goal_repository.dart';
import 'package:h20remind/domain/repositories/health_sync.dart';
import 'package:h20remind/domain/repositories/reminder_scheduler.dart';
import 'package:h20remind/domain/repositories/water_log_repository.dart';

/// Emits the latest value to every new listener, then subsequent updates.
class _Latest<T> {
  _Latest(this.value);

  T value;
  final _controller = StreamController<T>.broadcast(sync: true);

  Stream<T> get stream => Stream.multi((listener) {
    listener.add(value);
    final sub = _controller.stream.listen(listener.add);
    listener.onCancel = sub.cancel;
  });

  void set(T newValue) {
    value = newValue;
    _controller.add(newValue);
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser, this.userOnSignIn = testUser})
    : _user = _Latest(initialUser);

  final _Latest<AppUser?> _user;
  final AppUser userOnSignIn;
  AuthException? nextSignInError;

  @override
  Stream<AppUser?> authStateChanges() => _user.stream;

  @override
  Future<void> signInWithGoogle() async {
    final error = nextSignInError;
    if (error != null) {
      nextSignInError = null;
      throw error;
    }
    _user.set(userOnSignIn);
  }

  @override
  Future<void> signOut() async => _user.set(null);
}

class InMemoryWaterLog implements WaterLogRepository {
  InMemoryWaterLog([List<WaterEntry> initial = const []])
    : _entries = _Latest(List.of(initial));

  final _Latest<List<WaterEntry>> _entries;
  var _nextId = 0;

  List<WaterEntry> get all => _entries.value;

  @override
  Stream<List<WaterEntry>> watchEntriesForDay(DateTime day) =>
      watchEntriesForDays([day]);

  @override
  Stream<List<WaterEntry>> watchEntriesForDays(List<DateTime> days) {
    final wanted = days.map((d) => d.dateOnly).toSet();
    return _entries.stream.map(
      (all) =>
          all.where((e) => wanted.contains(e.day)).toList()
            ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt)),
    );
  }

  @override
  Future<void> addEntry({
    required int amountMl,
    required DateTime loggedAt,
  }) async {
    _entries.set([
      ..._entries.value,
      WaterEntry(
        id: 'new-${_nextId++}',
        amountMl: amountMl,
        day: loggedAt.dateOnly,
        loggedAt: loggedAt,
      ),
    ]);
  }

  @override
  Future<void> deleteEntry(String id) async =>
      _entries.set(_entries.value.where((e) => e.id != id).toList());

  @override
  Future<void> restoreEntry(WaterEntry entry) async =>
      _entries.set([..._entries.value, entry]);
}

class InMemoryGoals implements GoalRepository {
  InMemoryGoals([int goal = GoalRepository.defaultGoalMl])
    : _goal = _Latest(goal);

  final _Latest<int> _goal;

  @override
  Stream<int> watchDailyGoal() => _goal.stream;

  @override
  Future<void> setDailyGoal(int millilitres) async => _goal.set(millilitres);
}

class FakeReminderScheduler implements ReminderScheduler {
  FakeReminderScheduler({this.isSupported = true, this.grantPermission = true});

  @override
  final bool isSupported;
  bool grantPermission;
  bool enabled = false;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<bool> enable() async => enabled = grantPermission;

  @override
  Future<void> disable() async => enabled = false;
}

const testUser = AppUser(
  id: 'uid-1',
  email: 'ada@example.com',
  displayName: 'Ada Lovelace',
);

WaterEntry entry(String id, int amountMl, DateTime loggedAt) => WaterEntry(
  id: id,
  amountMl: amountMl,
  day: loggedAt.dateOnly,
  loggedAt: loggedAt,
);

class FakeHealthSync implements HealthSync {
  FakeHealthSync({
    this.isSupported = true,
    this.platformStatus = HealthPlatformStatus.available,
    this.granted = false,
    this.grantOnRequest = true,
  });

  @override
  final bool isSupported;
  HealthPlatformStatus platformStatus;
  bool granted;
  bool grantOnRequest;
  int installPageOpens = 0;
  PlatformException? nextSyncError;
  final syncCalls =
      <
        ({String ownerId, DateTime from, DateTime to, List<WaterEntry> entries})
      >[];

  @override
  Future<HealthPlatformStatus> status() async => platformStatus;

  @override
  Future<bool> hasPermissions() async => granted;

  @override
  Future<bool> requestPermissions() async => granted = grantOnRequest;

  @override
  Future<void> revokePermissions() async => granted = false;

  @override
  Future<void> openInstallPage() async => installPageOpens++;

  @override
  Future<void> openSettings() async {}

  @override
  Future<HealthSyncResult> sync({
    required String ownerId,
    required DateTime from,
    required DateTime to,
    required List<WaterEntry> entries,
  }) async {
    final error = nextSyncError;
    if (error != null) {
      nextSyncError = null;
      throw error;
    }
    syncCalls.add((ownerId: ownerId, from: from, to: to, entries: entries));
    return (inserted: entries.length, deleted: 0);
  }
}
