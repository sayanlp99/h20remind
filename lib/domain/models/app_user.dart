import 'package:flutter/foundation.dart';

/// The signed-in person, independent of the authentication provider.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// Best available human-readable name.
  String get label => displayName ?? email ?? 'Signed in';

  /// Up to two initials for avatar fallbacks.
  String get initials {
    final words = label.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.email == email &&
      other.displayName == displayName &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(id, email, displayName, photoUrl);
}
