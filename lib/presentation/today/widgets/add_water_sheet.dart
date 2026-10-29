import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatters.dart';

/// Bottom sheet for logging a custom amount. Resolves to the amount in ml, or
/// `null` if dismissed.
Future<int?> showAddWaterSheet(
  BuildContext context, {
  required List<int> presetsMl,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddWaterSheet(presetsMl: presetsMl),
  );
}

class _AddWaterSheet extends StatefulWidget {
  const _AddWaterSheet({required this.presetsMl});

  final List<int> presetsMl;

  @override
  State<_AddWaterSheet> createState() => _AddWaterSheetState();
}

class _AddWaterSheetState extends State<_AddWaterSheet> {
  static const int _maxAmountMl = 5000;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount = _selectAll(
    TextEditingController(
      text: widget.presetsMl.length > 1 ? '${widget.presetsMl[1]}' : '',
    ),
  );

  /// Selects the prefilled amount so typing replaces it.
  static TextEditingController _selectAll(TextEditingController controller) =>
      controller
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final amount = int.tryParse(value ?? '');
    if (amount == null || amount <= 0) return 'Enter an amount in ml';
    if (amount > _maxAmountMl) return 'Enter ${formatMl(_maxAmountMl)} or less';
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(int.parse(_amount.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = int.tryParse(_amount.text);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add water', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in widget.presetsMl)
                  ChoiceChip(
                    label: Text(formatMl(preset)),
                    selected: selected == preset,
                    onSelected: (_) =>
                        setState(() => _selectAll(_amount..text = '$preset')),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount',
                suffixText: 'ml',
              ),
              validator: _validate,
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _submit, child: const Text('Add')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
