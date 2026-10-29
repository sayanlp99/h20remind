import '../../core/dates.dart';
import '../models/daily_total.dart';
import '../models/water_entry.dart';

/// Input for [totalsByDay]. A record so it can be sent to another isolate.
typedef TotalsByDayRequest = ({List<WaterEntry> entries, List<DateTime> days});

/// Sums [TotalsByDayRequest.entries] into one [DailyTotal] per requested day,
/// preserving the order of `days`.
///
/// Pure and top-level so it can run on a background isolate via `compute`.
List<DailyTotal> totalsByDay(TotalsByDayRequest request) {
  final sums = <DateTime, int>{};
  for (final entry in request.entries) {
    final day = entry.day.dateOnly;
    sums[day] = (sums[day] ?? 0) + entry.amountMl;
  }
  return [
    for (final day in request.days)
      DailyTotal(day: day.dateOnly, totalMl: sums[day.dateOnly] ?? 0),
  ];
}

/// Aggregate figures for a run of days. [totals] must be newest first.
class HydrationStats {
  factory HydrationStats.from(List<DailyTotal> totals, {required int goalMl}) {
    if (totals.isEmpty) return const HydrationStats._(0, 0, 0);

    final sum = totals.fold<int>(0, (acc, t) => acc + t.totalMl);
    final goalMetDays = totals.where((t) => t.totalMl >= goalMl).length;

    // Today still counts as "in progress", so a streak isn't broken just
    // because the goal hasn't been reached yet today.
    var streak = 0;
    for (final (index, total) in totals.indexed) {
      if (total.totalMl >= goalMl) {
        streak++;
      } else if (index > 0) {
        break;
      }
    }

    return HydrationStats._((sum / totals.length).round(), goalMetDays, streak);
  }

  const HydrationStats._(this.averageMl, this.goalMetDays, this.streakDays);

  final int averageMl;
  final int goalMetDays;
  final int streakDays;
}
