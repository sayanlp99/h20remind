import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/session_controller.dart';
import '../settings/settings_screen.dart';
import 'user_avatar.dart';

/// Avatar in the top app bar that opens the account sheet.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionController s) => s.user);
    if (user == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: IconButton(
        tooltip: 'Account',
        onPressed: () => unawaited(_showAccountSheet(context)),
        icon: UserAvatar(user: user),
      ),
    );
  }

  Future<void> _showAccountSheet(BuildContext context) {
    final session = context.read<SessionController>();
    final user = session.user!;
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(user: user, radius: 36),
              const SizedBox(height: 12),
              Text(user.label, style: theme.textTheme.titleLarge),
              if (user.email != null && user.email != user.label)
                Text(
                  user.email!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 16),
              const Divider(indent: 24, endIndent: 24),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(SettingsScreen.open(context));
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Sign out'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(session.signOut());
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
