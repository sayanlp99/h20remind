import 'package:flutter_test/flutter_test.dart';
import 'package:h20remind/core/dates.dart';
import 'package:h20remind/core/formatters.dart';
import 'package:h20remind/domain/models/daily_total.dart';
import 'package:h20remind/domain/services/hydration_summary.dart';

import '../support/fakes.dart';

void main() {
  final today = DateTime(2026, 9, 28);
  final days = recentDays(today, 3);

  test('recentDays is newest first and crosses month boundaries', () {
    expect(recentDays(DateTime(2026, 3, 1), 2), [
      DateTime(2026, 3, 1),
      DateTime(2026, 2, 28),
    ]);
  });

  test('totalsByDay sums per day, fills gaps and ignores other days', () {
    final totals = totalsByDay((
      entries: [
        entry('a', 250, today.add(const Duration(hours: 9))),
        entry('b', 500, today.add(const Duration(hours: 14))),
        entry('c', 300, DateTime(2026, 9, 26, 10)),
        entry('d', 999, DateTime(2026, 9, 1, 10)),
      ],
      days: days,
    ));
    expect(totals, [
      DailyTotal(day: today, totalMl: 750),
      DailyTotal(day: DateTime(2026, 9, 27), totalMl: 0),
      DailyTotal(day: DateTime(2026, 9, 26), totalMl: 300),
    ]);
  });

  group('HydrationStats', () {
    List<DailyTotal> totals(List<int> amounts) => [
      for (final (i, ml) in amounts.indexed)
        DailyTotal(day: DateTime(2026, 9, 28 - i), totalMl: ml),
    ];

    test('average, goal days and streak', () {
      final stats = HydrationStats.from(
        totals([2000, 2000, 2000, 500]),
        goalMl: 2000,
      );
      expect(stats.averageMl, 1625);
      expect(stats.goalMetDays, 3);
      expect(stats.streakDays, 3);
    });

    test('an unfinished today does not break the streak', () {
      final stats = HydrationStats.from(
        totals([800, 2500, 2100, 0, 3000]),
        goalMl: 2000,
      );
      expect(stats.streakDays, 2);
    });

    test('empty input', () {
      final stats = HydrationStats.from(const [], goalMl: 2000);
      expect(stats.averageMl, 0);
      expect(stats.streakDays, 0);
    });
  });

  test('formatMl groups thousands', () {
    expect(formatMl(0), '0 ml');
    expect(formatMl(999), '999 ml');
    expect(formatMl(1250), '1,250 ml');
    expect(formatMl(1234567), '1,234,567 ml');
    expect(formatThousands(-4500), '-4,500');
  });
}
