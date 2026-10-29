import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import 'progress_ring.dart';

/// Hero card with the progress ring and today's key numbers.
class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({
    super.key,
    required this.totalMl,
    required this.goalMl,
    required this.remainingMl,
    required this.progress,
  });

  final int totalMl;
  final int goalMl;
  final int remainingMl;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final percent = (progress * 100).round();
    final goalReached = remainingMl == 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          children: [
            Semantics(
              label:
                  '${formatMl(totalMl)} of ${formatMl(goalMl)}, $percent percent',
              excludeSemantics: true,
              child: ProgressRing(
                progress: progress,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      goalReached
                          ? Icons.check_circle_rounded
                          : Icons.water_drop_rounded,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatThousands(totalMl),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'of ${formatMl(goalMl)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _Stat(label: 'Progress', value: '$percent%'),
                ),
                Expanded(
                  child: _Stat(
                    label: goalReached ? 'Goal' : 'Remaining',
                    value: goalReached ? 'Reached' : formatMl(remainingMl),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
