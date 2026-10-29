import 'package:flutter/foundation.dart';

/// Total water drunk on one calendar day.
@immutable
class DailyTotal {
  const DailyTotal({required this.day, required this.totalMl});

  final DateTime day;
  final int totalMl;

  @override
  bool operator ==(Object other) =>
      other is DailyTotal && other.day == day && other.totalMl == totalMl;

  @override
  int get hashCode => Object.hash(day, totalMl);
}
