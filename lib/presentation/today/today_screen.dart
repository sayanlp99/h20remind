import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/breakpoints.dart';
import '../../core/formatters.dart';
import '../../domain/models/water_entry.dart';
import '../common/account_button.dart';
import '../common/load_status.dart';
import '../common/status_views.dart';
import '../settings/settings_controller.dart';
import 'today_controller.dart';
import 'widgets/add_water_sheet.dart';
import 'widgets/quick_add_row.dart';
import 'widgets/reminder_prompt_card.dart';
import 'widgets/today_summary_card.dart';
import 'widgets/water_log_list.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _reminderPromptDismissed = false;

  TodayController get _controller => context.read<TodayController>();

  Future<void> _add(int amountMl) async {
    try {
      await _controller.addWater(amountMl);
    } on Object {
      if (mounted) showMessage(context, "Couldn't add water. Try again.");
    }
  }

  Future<void> _openAddSheet() async {
    final amount = await showAddWaterSheet(
      context,
      presetsMl: TodayController.quickAddAmountsMl,
    );
    if (amount != null) await _add(amount);
  }

  Future<void> _delete(WaterEntry entry) async {
    final controller = _controller;
    showMessage(
      context,
      '${formatMl(entry.amountMl)} removed',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => unawaited(controller.restoreEntry(entry)),
      ),
    );
    try {
      await controller.deleteEntry(entry);
    } on Object {
      if (mounted) showMessage(context, "Couldn't remove entry. Try again.");
    }
  }

  Future<void> _enableReminders() async {
    final result = await context.read<SettingsController>().setRemindersEnabled(
      true,
    );
    if (!mounted) return;
    showMessage(context, switch (result) {
      ReminderToggleResult.updated =>
        "Reminders on. We'll nudge you every hour.",
      ReminderToggleResult.permissionDenied => 'Allow notifications for h20remind in system settings to get reminders.',
      ReminderToggleResult.failed => "Couldn't turn on reminders. Try again.",
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TodayController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: const [AccountButton()],
      ),
      floatingActionButton: controller.status == LoadStatus.ready
          ? FloatingActionButton.extended(
              onPressed: () => unawaited(_openAddSheet()),
              icon: const Icon(Icons.add),
              label: const Text('Add water'),
            )
          : null,
      body: switch (controller.status) {
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.failure => ErrorState(onRetry: controller.retry),
        LoadStatus.ready => LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= Breakpoints.expanded
              ? _buildTwoPane(controller)
              : _buildSinglePane(controller),
        ),
      },
    );
  }

  Widget _buildSinglePane(TodayController controller) {
    return ListView(
      // Leave room for the extended FAB.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        ..._overview(controller),
        const SectionHeader('Log'),
        WaterLogList(entries: controller.entries, onDelete: _delete),
      ],
    );
  }

  Widget _buildTwoPane(TodayController controller) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 12, 96),
                children: _overview(controller),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 24, 96),
                children: [
                  const SectionHeader('Log'),
                  WaterLogList(entries: controller.entries, onDelete: _delete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _overview(TodayController controller) {
    final settings = context.watch<SettingsController>();
    final showReminderPrompt =
        settings.remindersSupported &&
        !settings.remindersEnabled &&
        !_reminderPromptDismissed;

    return [
      TodaySummaryCard(
        totalMl: controller.totalMl,
        goalMl: controller.goalMl,
        remainingMl: controller.remainingMl,
        progress: controller.progress,
      ),
      if (showReminderPrompt) ...[
        const SizedBox(height: 16),
        ReminderPromptCard(
          busy: settings.reminderBusy,
          onEnable: () => unawaited(_enableReminders()),
          onDismiss: () => setState(() => _reminderPromptDismissed = true),
        ),
      ],
      const SectionHeader('Quick add'),
      QuickAddRow(
        amountsMl: TodayController.quickAddAmountsMl,
        onAdd: (amount) => unawaited(_add(amount)),
      ),
    ];
  }
}
