import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../domain/models/daily_total.dart';
import '../common/account_button.dart';
import '../common/load_status.dart';
import '../common/status_views.dart';
import 'history_controller.dart';
import 'widgets/weekly_chart.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HistoryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: const [AccountButton()],
      ),
      body: switch (controller.status) {
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.failure => ErrorState(onRetry: controller.retry),
        LoadStatus.ready => _HistoryBody(controller: controller),
      },
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.controller});

  final HistoryController controller;

  @override
  Widget build(BuildContext context) {
    final week = controller.lastWeek;
    final weekStats = controller.weekStats;
    final loggedDays = controller.totals.where((t) => t.totalMl > 0).toList();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last 7 days',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    WeeklyChart(
                      days: week.reversed.toList(),
                      goalMl: controller.goalMl,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _Metric(
                          label: 'Daily average',
                          value: formatMl(weekStats.averageMl),
                        ),
                        _Metric(
                          label: 'Goal reached',
                          value:
                              '${weekStats.goalMetDays} of ${week.length} days',
                        ),
                        _Metric(
                          label: 'Streak',
                          value:
                              '${controller.windowStats.streakDays} '
                              '${controller.windowStats.streakDays == 1 ? 'day' : 'days'}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SectionHeader('Past ${controller.windowDays} days'),
            if (loggedDays.isEmpty)
              const Card(
                child: EmptyState(
                  icon: Icons.insights_outlined,
                  title: 'No history yet',
                  message: 'Days you log water will show up here.',
                ),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (final (index, total) in loggedDays.indexed) ...[
                      if (index > 0)
                        const Divider(height: 1, indent: 24, endIndent: 24),
                      _DayTile(
                        total: total,
                        goalMl: controller.goalMl,
                        today: controller.today,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.total,
    required this.goalMl,
    required this.today,
  });

  final DailyTotal total;
  final DateTime today;
  final int goalMl;

  String _label(BuildContext context) {
    if (total.day == today) return 'Today';
    if (total.day == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday';
    }
    return MaterialLocalizations.of(context).formatMediumDate(total.day);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = goalMl <= 0
        ? 0.0
        : (total.totalMl / goalMl).clamp(0.0, 1.0);
    final metGoal = total.totalMl >= goalMl;

    return ListTile(
      title: Text(_label(context)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          backgroundColor: colors.surfaceContainerHighest,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatMl(total.totalMl)),
          const SizedBox(width: 8),
          Icon(
            metGoal ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: metGoal ? colors.primary : colors.outlineVariant,
            semanticLabel: metGoal ? 'Goal reached' : 'Goal not reached',
          ),
        ],
      ),
    );
  }
}
