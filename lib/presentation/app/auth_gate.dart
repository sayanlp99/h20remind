import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/app_logo.dart';
import '../home/home_shell.dart';
import '../sign_in/sign_in_screen.dart';
import 'session_controller.dart';
import 'user_scope.dart';

/// Shows the splash, sign-in or signed-in experience based on the session.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final user = session.user;
    final Widget child = switch (session.status) {
      SessionStatus.unknown => const _Splash(),
      SessionStatus.signedOut => const SignInScreen(),
      SessionStatus.signedIn => UserScope(
        key: ValueKey(user!.id),
        user: user,
        child: const HomeShell(),
      ),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(key: ValueKey(session.status), child: child),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: AppLogo()));
}
