import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatters.dart';
import '../../../domain/repositories/goal_repository.dart';

/// Asks for a new daily goal. Resolves to the goal in ml, or `null` if
/// cancelled.
Future<int?> showGoalDialog(
  BuildContext context, {
  required int? initialGoalMl,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _GoalDialog(initialGoalMl: initialGoalMl),
  );
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({required this.initialGoalMl});

  final int? initialGoalMl;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _goal = TextEditingController(
    text: '${widget.initialGoalMl ?? GoalRepository.defaultGoalMl}',
  );

  @override
  void dispose() {
    _goal.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final goal = int.tryParse(value ?? '');
    if (goal == null ||
        goal < GoalRepository.minGoalMl ||
        goal > GoalRepository.maxGoalMl) {
      return 'Enter ${formatThousands(GoalRepository.minGoalMl)}–'
          '${formatMl(GoalRepository.maxGoalMl)}';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(int.parse(_goal.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.flag_outlined),
      title: const Text('Daily goal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Most adults need about 2,000–3,000 ml a day.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _goal,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              decoration: const InputDecoration(
                labelText: 'Goal',
                suffixText: 'ml',
              ),
              validator: _validate,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
