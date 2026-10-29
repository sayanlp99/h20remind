import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h20remind/presentation/common/load_status.dart';
import 'package:h20remind/presentation/today/today_controller.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late InMemoryWaterLog waterLog;
  late InMemoryGoals goals;
  late TodayController controller;

  setUp(() {
    now = DateTime(2026, 9, 28, 10);
    waterLog = InMemoryWaterLog([
      entry('a', 250, DateTime(2026, 9, 28, 8)),
      entry('b', 500, DateTime(2026, 9, 28, 9)),
      entry('yesterday', 1000, DateTime(2026, 9, 27, 20)),
    ]);
    goals = InMemoryGoals(2000);
    controller = TodayController(
      waterLog: waterLog,
      goals: goals,
      clock: () => now,
    );
  });

  tearDown(() => controller.dispose());

  test("shows only today's entries, newest first", () async {
    await pumpEventQueue();
    expect(controller.status, LoadStatus.ready);
    expect(controller.entries.map((e) => e.id), ['b', 'a']);
    expect(controller.totalMl, 750);
    expect(controller.remainingMl, 1250);
    expect(controller.progress, closeTo(0.375, 1e-9));
  });

  test('adding water updates totals and goal changes are reflected', () async {
    await controller.addWater(1500);
    await goals.setDailyGoal(2250);
    await pumpEventQueue();
    expect(controller.totalMl, 2250);
    expect(controller.goalMl, 2250);
    expect(controller.goalReached, isTrue);
    expect(controller.remainingMl, 0);
  });

  test('delete hides the entry immediately and undo restores it', () async {
    await pumpEventQueue();
    final target = controller.entries.first;

    final deletion = controller.deleteEntry(target);
    expect(controller.entries.map((e) => e.id), ['a'], reason: 'optimistic');
    await deletion;

    await controller.restoreEntry(target);
    await pumpEventQueue();
    expect(controller.entries.map((e) => e.id), ['b', 'a']);
  });

  test('rolls over to the new day on resume', () async {
    await pumpEventQueue();
    now = DateTime(2026, 9, 29, 7);
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(state);
    }
    await pumpEventQueue();
    expect(controller.day, DateTime(2026, 9, 29));
    expect(controller.entries, isEmpty);
  });
}
