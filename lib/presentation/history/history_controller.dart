import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../core/dates.dart';
import '../../domain/models/daily_total.dart';
import '../../domain/models/water_entry.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/water_log_repository.dart';
import '../../domain/services/hydration_summary.dart';
import '../common/load_status.dart';

/// State for the History screen: daily totals over a rolling window.
class HistoryController extends ChangeNotifier {
  HistoryController({
    required this._waterLog,
    required this._goals,
    this._clock = DateTime.now,
    this.windowDays = WaterLogRepository.maxDaysPerQuery,
    this.isolateThreshold = 400,
  }) {
    _lifecycle = AppLifecycleListener(onResume: _syncWindow);
    _goalSubscription = _goals.watchDailyGoal().listen((goal) {
      _goalMl = goal;
      notifyListeners();
    }, onError: (Object e) => debugPrint('Goal stream failed: $e'));
    _watchWindow();
  }

  /// Number of days covered, ending today.
  final int windowDays;

  /// Above this many entries, aggregation moves to a background isolate so a
  /// large snapshot can't cause jank. Below it, spawning an isolate costs
  /// more than it saves.
  final int isolateThreshold;

  final WaterLogRepository _waterLog;
  final GoalRepository _goals;
  final DateTime Function() _clock;

  late final AppLifecycleListener _lifecycle;
  late final StreamSubscription<int> _goalSubscription;
  StreamSubscription<List<WaterEntry>>? _entriesSubscription;

  List<DateTime> _days = const [];
  LoadStatus _status = LoadStatus.loading;
  List<DailyTotal> _totals = const [];
  int _goalMl = GoalRepository.defaultGoalMl;
  int _generation = 0;
  bool _disposed = false;

  LoadStatus get status => _status;

  /// The newest day in the window.
  DateTime get today => _days.isEmpty ? _clock().dateOnly : _days.first;
  int get goalMl => _goalMl;

  /// One entry per day in the window, newest first.
  List<DailyTotal> get totals => _totals;

  /// The last seven days, newest first.
  List<DailyTotal> get lastWeek => _totals.take(7).toList(growable: false);

  HydrationStats get weekStats =>
      HydrationStats.from(lastWeek, goalMl: _goalMl);

  HydrationStats get windowStats =>
      HydrationStats.from(_totals, goalMl: _goalMl);

  void retry() => _watchWindow();

  void _watchWindow() {
    unawaited(_entriesSubscription?.cancel());
    _days = recentDays(_clock(), windowDays);
    _status = LoadStatus.loading;
    notifyListeners();

    _entriesSubscription = _waterLog
        .watchEntriesForDays(_days)
        .listen(
          _onEntries,
          onError: (Object e) {
            debugPrint('History stream failed: $e');
            _status = LoadStatus.failure;
            notifyListeners();
          },
        );
  }

  Future<void> _onEntries(List<WaterEntry> entries) async {
    final generation = ++_generation;
    final request = (entries: entries, days: _days);
    final totals = entries.length >= isolateThreshold
        ? await compute(totalsByDay, request, debugLabel: 'totalsByDay')
        : totalsByDay(request);

    // A newer snapshot may have arrived while the isolate was working.
    if (_disposed || generation != _generation) return;
    _totals = totals;
    _status = LoadStatus.ready;
    notifyListeners();
  }

  void _syncWindow() {
    if (_days.isEmpty || _days.first == _clock().dateOnly) return;
    _watchWindow();
  }

  @override
  void dispose() {
    _disposed = true;
    _lifecycle.dispose();
    unawaited(_goalSubscription.cancel());
    unawaited(_entriesSubscription?.cancel());
    super.dispose();
  }
}
