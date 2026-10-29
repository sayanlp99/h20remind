import 'package:flutter/material.dart';

/// Suggests turning on hourly reminders.
class ReminderPromptCard extends StatelessWidget {
  const ReminderPromptCard({
    super.key,
    required this.onEnable,
    required this.onDismiss,
    this.busy = false,
  });

  final VoidCallback onEnable;
  final VoidCallback onDismiss;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: colors.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get hourly reminders',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A quick nudge each hour makes it easier to hit your goal.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Not now'),
                  ),
                  TextButton(
                    onPressed: busy ? null : onEnable,
                    child: const Text('Turn on'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
