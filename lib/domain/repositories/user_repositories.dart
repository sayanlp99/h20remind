import '../models/app_user.dart';
import 'goal_repository.dart';
import 'water_log_repository.dart';

/// The repositories scoped to a single signed-in user.
typedef UserRepositories = ({
  WaterLogRepository waterLog,
  GoalRepository goals,
});

typedef UserRepositoriesFactory = UserRepositories Function(AppUser user);
