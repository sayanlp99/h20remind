import 'package:flutter_test/flutter_test.dart';
import 'package:h20remind/domain/models/water_entry.dart';
import 'package:h20remind/presentation/common/load_status.dart';
import 'package:h20remind/presentation/history/history_controller.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 28, 12);
  final entries = <WaterEntry>[
    for (var day = 0; day < 10; day++)
      for (var i = 0; i < 8; i++)
        entry('$day-$i', 250, DateTime(2026, 9, 28 - day, 8 + i)),
  ];

  for (final (label, threshold) in [
    ('inline', 1 << 30),
    ('on an isolate', 0),
  ]) {
    test('aggregates the window $label', () async {
      final controller = HistoryController(
        waterLog: InMemoryWaterLog(entries),
        goals: InMemoryGoals(2000),
        clock: () => now,
        windowDays: 14,
        isolateThreshold: threshold,
      );
      addTearDown(controller.dispose);

      while (controller.status == LoadStatus.loading) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(controller.totals, hasLength(14));
      expect(controller.totals.first.day, DateTime(2026, 9, 28));
      expect(
        controller.totals.take(10).every((t) => t.totalMl == 2000),
        isTrue,
      );
      expect(controller.totals.skip(10).every((t) => t.totalMl == 0), isTrue);
      expect(controller.weekStats.goalMetDays, 7);
      expect(controller.windowStats.streakDays, 10);
    });
  }
}
