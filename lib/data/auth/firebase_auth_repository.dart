import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  static const _cancelledCodes = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'web-context-canceled',
    'web-context-cancelled',
    'canceled',
    'cancelled',
  };

  @override
  Stream<AppUser?> authStateChanges() => _auth.userChanges().map(_toAppUser);

  @override
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(provider);
      } else {
        await _auth.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      if (_cancelledCodes.contains(e.code)) {
        throw const AuthCancelledException();
      }
      debugPrint('Google sign-in failed [${e.code}]: ${e.message}');
      throw AuthException(_messageFor(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  static AppUser? _toAppUser(User? user) => user == null
      ? null
      : AppUser(
          id: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );

  static String _messageFor(FirebaseAuthException e) => switch (e.code) {
    'network-request-failed' => 'Check your internet connection and try again.',
    'popup-blocked' => 'Allow pop-ups for this site to sign in.',
    'user-disabled' => 'This account has been disabled.',
    // Misconfigured Firebase project (e.g. Google provider not enabled).
    'operation-not-allowed' ||
    'invalid-cert-hash' ||
    'app-not-authorized' => 'Google sign-in isn\'t set up for this app yet.',
    _ => "Couldn't sign in. Please try again.",
  };
}
