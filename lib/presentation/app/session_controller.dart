import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/reminder_scheduler.dart';

enum SessionStatus { unknown, signedOut, signedIn }

/// Tracks who is signed in and drives the sign-in / sign-out flows.
class SessionController extends ChangeNotifier {
  SessionController({required this._auth, required this._reminders}) {
    _subscription = _auth.authStateChanges().listen(
      _onUserChanged,
      // Treat a broken auth stream as signed out rather than hanging on the
      // splash screen.
      onError: (Object _) => _onUserChanged(null),
    );
  }

  final AuthRepository _auth;
  final ReminderScheduler _reminders;
  late final StreamSubscription<AppUser?> _subscription;

  SessionStatus _status = SessionStatus.unknown;
  AppUser? _user;
  bool _isSigningIn = false;
  String? _errorMessage;

  SessionStatus get status => _status;
  AppUser? get user => _user;
  bool get isSigningIn => _isSigningIn;

  /// Why the last sign-in attempt failed, if it did.
  String? get errorMessage => _errorMessage;

  Future<void> signIn() async {
    if (_isSigningIn) return;
    _isSigningIn = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.signInWithGoogle();
    } on AuthCancelledException {
      // The user backed out; nothing to report.
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    // Reminders are per device; don't keep nagging someone who signed out.
    try {
      await _reminders.disable();
    } on Object catch (e, stack) {
      debugPrint('Failed to cancel reminders on sign-out: $e\n$stack');
    }
    await _auth.signOut();
  }

  void _onUserChanged(AppUser? user) {
    _user = user;
    _status = user == null ? SessionStatus.signedOut : SessionStatus.signedIn;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
