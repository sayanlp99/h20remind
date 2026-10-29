import 'package:flutter/foundation.dart';

/// A single drink logged by the user.
@immutable
class WaterEntry {
  const WaterEntry({
    required this.id,
    required this.amountMl,
    required this.day,
    required this.loggedAt,
  });

  final String id;
  final int amountMl;

  /// Local calendar day (midnight) the entry counts towards.
  final DateTime day;

  /// When the drink was logged.
  final DateTime loggedAt;

  @override
  bool operator ==(Object other) =>
      other is WaterEntry &&
      other.id == id &&
      other.amountMl == amountMl &&
      other.day == day &&
      other.loggedAt == loggedAt;

  @override
  int get hashCode => Object.hash(id, amountMl, day, loggedAt);
}
