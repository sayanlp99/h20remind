import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../domain/models/water_entry.dart';
import '../../common/status_views.dart';

/// Today's entries in a card, newest first. Swipe or tap delete to remove.
class WaterLogList extends StatelessWidget {
  const WaterLogList({
    super.key,
    required this.entries,
    required this.onDelete,
  });

  final List<WaterEntry> entries;
  final ValueChanged<WaterEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Card(
        child: EmptyState(
          icon: Icons.local_drink_outlined,
          title: 'Nothing logged yet today',
          message: 'Use Add water or a quick-add size to log a drink.',
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);

    return Card(
      child: Column(
        children: [
          for (final (index, entry) in entries.indexed) ...[
            if (index > 0) const Divider(height: 1, indent: 72),
            Dismissible(
              key: ValueKey(entry.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => onDelete(entry),
              background: ColoredBox(
                color: colors.errorContainer,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 24),
                    child: Icon(
                      Icons.delete_outline,
                      color: colors.onErrorContainer,
                    ),
                  ),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors.secondaryContainer,
                  foregroundColor: colors.onSecondaryContainer,
                  child: const Icon(Icons.water_drop_outlined),
                ),
                title: Text(formatMl(entry.amountMl)),
                subtitle: Text(
                  localizations.formatTimeOfDay(
                    TimeOfDay.fromDateTime(entry.loggedAt),
                    alwaysUse24HourFormat: use24h,
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(entry),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
