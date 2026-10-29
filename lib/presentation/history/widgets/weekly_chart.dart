import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../domain/models/daily_total.dart';

/// Seven-day bar chart with a goal line. [days] must be oldest first.
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({
    super.key,
    required this.days,
    required this.goalMl,
    this.height = 180,
  });

  final List<DailyTotal> days;
  final int goalMl;
  final double height;

  static const double _labelHeight = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final peak = days.fold<int>(
      goalMl,
      (max, d) => d.totalMl > max ? d.totalMl : max,
    );
    // Headroom so the tallest bar never touches the top edge.
    final scale = peak <= 0 ? 1.0 : 1 / (peak * 1.1);

    return Semantics(
      label:
          'Last seven days: ${[for (final d in days) '${localizations.formatMediumDate(d.day)} ${formatMl(d.totalMl)}'].join(', ')}',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final plotHeight = constraints.maxHeight - _labelHeight;
            final goalY = plotHeight * (1 - goalMl * scale);
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: goalY,
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(height: 1, color: colors.outline),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Goal',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final day in days)
                      Expanded(
                        child: _Bar(
                          day: day,
                          height: plotHeight * day.totalMl * scale,
                          metGoal: day.totalMl >= goalMl,
                          label:
                              localizations.narrowWeekdays[day.day.weekday % 7],
                        ),
                      ),
                    // Reserve space for the "Goal" label.
                    const SizedBox(width: 32),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.height,
    required this.metGoal,
    required this.label,
  });

  final DailyTotal day;
  final double height;
  final bool metGoal;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Tooltip(
          message: formatMl(day.totalMl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            width: 20,
            // Keep a visible stub for empty days.
            height: height < 4 ? 4 : height,
            decoration: BoxDecoration(
              color: metGoal ? colors.primary : colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        SizedBox(
          height: WeeklyChart._labelHeight,
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
