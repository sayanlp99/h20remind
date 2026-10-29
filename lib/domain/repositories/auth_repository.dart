import '../models/app_user.dart';

abstract interface class AuthRepository {
  /// Emits the current user immediately, then on every sign-in or sign-out.
  Stream<AppUser?> authStateChanges();

  /// Throws [AuthCancelledException] if the user dismisses the flow and
  /// [AuthException] for any other failure.
  Future<void> signInWithGoogle();

  Future<void> signOut();
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class AuthCancelledException extends AuthException {
  const AuthCancelledException() : super('Sign-in was cancelled.');
}
