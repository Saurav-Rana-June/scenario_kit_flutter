import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../assertions/assertion_result.dart';
import '../executor/test_execution_result.dart';
import '../runner/execution_mode.dart';
import '../runner/screen_execution_summary.dart';

/// Aggregated, comprehensive test report encapsulating one or more test execution runs.
@immutable
class ScenarioTestReport {
  /// Creates a [ScenarioTestReport].
  const ScenarioTestReport({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.summaries,
    this.environment = const {},
  });

  /// Factory constructor compiling a report from a list of [ScreenExecutionSummary] instances.
  factory ScenarioTestReport.fromSummaries({
    required List<ScreenExecutionSummary> summaries,
    String title = 'ScenarioKit Functional Test Report',
    Map<String, dynamic> environment = const {},
    DateTime? startTime,
    DateTime? endTime,
  }) {
    DateTime calculatedStart = startTime ?? DateTime.now();
    DateTime calculatedEnd = endTime ?? DateTime.now();

    if (summaries.isNotEmpty) {
      calculatedStart = summaries
          .map((s) => s.startTime)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      calculatedEnd = summaries
          .map((s) => s.endTime)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    return ScenarioTestReport(
      title: title,
      startTime: calculatedStart,
      endTime: calculatedEnd,
      duration: calculatedEnd.difference(calculatedStart),
      summaries: List.unmodifiable(summaries),
      environment: Map.unmodifiable(environment),
    );
  }

  /// Factory constructor compiling a report directly from a list of [TestExecutionResult]s.
  factory ScenarioTestReport.fromResults({
    required List<TestExecutionResult> results,
    String title = 'ScenarioKit Functional Test Report',
    String? screenName,
    Map<String, dynamic> environment = const {},
    DateTime? startTime,
    DateTime? endTime,
  }) {
    final start = startTime ??
        (results.isNotEmpty ? results.first.timestamp : DateTime.now());
    final end = endTime ??
        (results.isNotEmpty
            ? results.last.timestamp.add(results.last.duration)
            : DateTime.now());

    final summary = ScreenExecutionSummary.fromResults(
      screenName: screenName,
      executionMode: screenName != null
          ? ExecutionMode.screen
          : ExecutionMode.functionality,
      results: results,
      startTime: start,
      endTime: end,
    );

    return ScenarioTestReport.fromSummaries(
      title: title,
      summaries: [summary],
      environment: environment,
      startTime: start,
      endTime: end,
    );
  }

  /// Report title or run descriptor.
  final String title;

  /// Wall-clock time when the first test commenced.
  final DateTime startTime;

  /// Wall-clock time when the final test concluded.
  final DateTime endTime;

  /// Overall execution duration.
  final Duration duration;

  /// All screen or functionality execution summaries included in this report.
  final List<ScreenExecutionSummary> summaries;

  /// Metadata detailing the environment (e.g. Flutter SDK, platform, OS, device info).
  final Map<String, dynamic> environment;

  /// All individual [TestExecutionResult]s across all summaries in execution order.
  List<TestExecutionResult> get allResults {
    final list = <TestExecutionResult>[];
    for (final s in summaries) {
      list.addAll(s.results);
    }
    return UnmodifiableListView(list);
  }

  /// All screenshots captured during execution.
  List<ScenarioScreenshot> get allScreenshots {
    final list = <ScenarioScreenshot>[];
    for (final r in allResults) {
      list.addAll(r.screenshots);
    }
    return UnmodifiableListView(list);
  }

  /// All assertions recorded during execution.
  List<AssertionResult> get allAssertions {
    final list = <AssertionResult>[];
    for (final r in allResults) {
      list.addAll(r.assertions);
    }
    return UnmodifiableListView(list);
  }

  /// Total count of tests executed.
  int get totalTests => allResults.length;

  /// Count of tests that passed.
  int get passedCount => allResults.where((r) => r.isPassed).length;

  /// Count of tests that failed.
  int get failedCount => allResults.where((r) => r.isFailed).length;

  /// Count of tests that were skipped.
  int get skippedCount => allResults.where((r) => r.isSkipped).length;

  /// Overall success rate percentage from 0.0 to 100.0.
  double get successRate =>
      totalTests == 0 ? 0.0 : (passedCount / totalTests) * 100.0;

  /// Whether the entire test run succeeded with zero test failures.
  bool get isSuccess => failedCount == 0 && passedCount > 0;

  /// Serializes the complete report to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'environment': environment,
      'totalTests': totalTests,
      'passedCount': passedCount,
      'failedCount': failedCount,
      'skippedCount': skippedCount,
      'successRate': double.parse(successRate.toStringAsFixed(1)),
      'isSuccess': isSuccess,
      'summaries': summaries.map((s) => s.toJson()).toList(),
      'screenshots': allScreenshots.map((s) => s.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'ScenarioTestReport(title: $title, passed: $passedCount/$totalTests, failed: $failedCount, rate: ${successRate.toStringAsFixed(1)}%)';
}
