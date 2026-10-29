import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/dates.dart';
import '../../domain/models/water_entry.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/water_log_repository.dart';
import '../common/load_status.dart';

/// State for the Today screen: today's entries measured against the goal.
///
/// Follows the calendar: at midnight, or when the app resumes on a new day,
/// it switches to the new day automatically.
class TodayController extends ChangeNotifier {
  TodayController({
    required this._waterLog,
    required this._goals,
    this._clock = DateTime.now,
  }) : _day = _clock().dateOnly {
    _lifecycle = AppLifecycleListener(onResume: _syncDay);
    _goalSubscription = _goals.watchDailyGoal().listen((goal) {
      _goalMl = goal;
      notifyListeners();
    }, onError: (Object e) => debugPrint('Goal stream failed: $e'));
    _watchDay();
  }

  static const List<int> quickAddAmountsMl = [150, 250, 500, 750];

  final WaterLogRepository _waterLog;
  final GoalRepository _goals;
  final DateTime Function() _clock;

  late final AppLifecycleListener _lifecycle;
  late final StreamSubscription<int> _goalSubscription;
  StreamSubscription<List<WaterEntry>>? _entriesSubscription;
  Timer? _midnightTimer;

  DateTime _day;
  LoadStatus _status = LoadStatus.loading;
  List<WaterEntry> _entries = const [];

  /// Entries deleted locally whose removal hasn't reached the stream yet.
  /// Hiding them immediately keeps swipe-to-delete from flickering back.
  final Set<String> _pendingDeletes = {};
  int _goalMl = GoalRepository.defaultGoalMl;

  DateTime get day => _day;
  LoadStatus get status => _status;

  /// Newest first.
  List<WaterEntry> get entries => _pendingDeletes.isEmpty
      ? _entries
      : _entries.where((e) => !_pendingDeletes.contains(e.id)).toList();
  int get goalMl => _goalMl;
  int get totalMl => entries.fold(0, (sum, e) => sum + e.amountMl);
  int get remainingMl => math.max(0, _goalMl - totalMl);
  bool get goalReached => totalMl >= _goalMl;

  /// Fraction of the goal reached. Can exceed 1.
  double get progress => _goalMl <= 0 ? 0 : totalMl / _goalMl;

  Future<void> addWater(int amountMl) =>
      _waterLog.addEntry(amountMl: amountMl, loggedAt: _clock());

  Future<void> deleteEntry(WaterEntry entry) async {
    _pendingDeletes.add(entry.id);
    notifyListeners();
    try {
      await _waterLog.deleteEntry(entry.id);
    } on Object {
      _pendingDeletes.remove(entry.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> restoreEntry(WaterEntry entry) {
    if (_pendingDeletes.remove(entry.id)) notifyListeners();
    return _waterLog.restoreEntry(entry);
  }

  void retry() => _watchDay();

  void _watchDay() {
    unawaited(_entriesSubscription?.cancel());
    _status = LoadStatus.loading;
    notifyListeners();

    _entriesSubscription = _waterLog
        .watchEntriesForDay(_day)
        .listen(
          (entries) {
            _entries = entries;
            _pendingDeletes.retainWhere((id) => entries.any((e) => e.id == id));
            _status = LoadStatus.ready;
            notifyListeners();
          },
          onError: (Object e) {
            debugPrint('Entries stream failed: $e');
            _status = LoadStatus.failure;
            notifyListeners();
          },
        );

    _midnightTimer?.cancel();
    _midnightTimer = Timer(_day.nextMidnight.difference(_clock()), _syncDay);
  }

  void _syncDay() {
    final today = _clock().dateOnly;
    if (today == _day) return;
    _day = today;
    _entries = const [];
    _watchDay();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _midnightTimer?.cancel();
    unawaited(_goalSubscription.cancel());
    unawaited(_entriesSubscription?.cancel());
    super.dispose();
  }
}
