import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../runner/screen_execution_summary.dart';

/// In-memory session store that records completed test execution summaries
/// and makes them accessible to the ScenarioKit Reports tab and export utilities.
class ScenarioReportStore extends ChangeNotifier {
  ScenarioReportStore._();

  static ScenarioReportStore _instance = ScenarioReportStore._();

  /// Ambient singleton instance of [ScenarioReportStore] for the current app session.
  static ScenarioReportStore get instance => _instance;

  /// Resets the ambient instance (primarily for test isolation).
  @visibleForTesting
  static void resetInstance() {
    _instance.dispose();
    _instance = ScenarioReportStore._();
  }

  final List<ScreenExecutionSummary> _runs = [];

  /// Chronological list of completed execution summaries (newest first).
  List<ScreenExecutionSummary> get runs => UnmodifiableListView(_runs);

  /// The most recent execution summary, if any test has run.
  ScreenExecutionSummary? get latestSummary =>
      _runs.isNotEmpty ? _runs.first : null;

  /// Total count of tests executed across all session runs.
  int get totalTestsExecuted =>
      _runs.fold(0, (acc, r) => acc + r.totalTests);

  /// Total count of failed tests across all session runs.
  int get totalFailures =>
      _runs.fold(0, (acc, r) => acc + r.failedCount);

  /// Total count of passed tests across all session runs.
  int get totalPassed =>
      _runs.fold(0, (acc, r) => acc + r.passedCount);

  /// Records a newly completed test execution summary.
  void recordSummary(ScreenExecutionSummary summary) {
    _runs.insert(0, summary);
    notifyListeners();
  }

  /// Clears all recorded test run summaries for this session.
  void clear() {
    _runs.clear();
    notifyListeners();
  }
}
