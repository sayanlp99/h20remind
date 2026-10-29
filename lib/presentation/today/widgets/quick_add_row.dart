import 'package:flutter/material.dart';

import '../../../core/formatters.dart';

/// One-tap tiles for common drink sizes.
class QuickAddRow extends StatelessWidget {
  const QuickAddRow({super.key, required this.amountsMl, required this.onAdd});

  final List<int> amountsMl;
  final ValueChanged<int> onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, amount) in amountsMl.indexed) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: _QuickAddTile(amountMl: amount, onTap: () => onAdd(amount)),
          ),
        ],
      ],
    );
  }
}

class _QuickAddTile extends StatelessWidget {
  const _QuickAddTile({required this.amountMl, required this.onTap});

  final int amountMl;
  final VoidCallback onTap;

  IconData get _icon => switch (amountMl) {
    < 200 => Icons.coffee_outlined,
    < 400 => Icons.local_drink_outlined,
    _ => Icons.water_drop_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Tooltip(
      message: 'Add ${formatMl(amountMl)}',
      excludeFromSemantics: true,
      child: Material(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            button: true,
            label: 'Add ${formatMl(amountMl)}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(_icon, color: colors.onSecondaryContainer),
                  const SizedBox(height: 8),
                  Text(
                    formatMl(amountMl),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
