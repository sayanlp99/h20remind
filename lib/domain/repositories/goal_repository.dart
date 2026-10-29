/// Reads and writes the signed-in user's daily hydration goal.
abstract interface class GoalRepository {
  static const int defaultGoalMl = 3000;
  static const int minGoalMl = 500;
  static const int maxGoalMl = 10000;

  /// Emits [defaultGoalMl] when the user has not set a goal.
  Stream<int> watchDailyGoal();

  Future<void> setDailyGoal(int millilitres);
}
