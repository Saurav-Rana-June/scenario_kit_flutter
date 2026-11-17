import 'package:flutter/foundation.dart';

import '../executor/test_execution_result.dart';
import 'execution_mode.dart';

/// Consolidated summary representing the aggregate outcome of a screen-level
/// or functionality-level test run.
@immutable
class ScreenExecutionSummary {
  /// Creates a [ScreenExecutionSummary].
  const ScreenExecutionSummary({
    required this.executionMode,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.results,
    this.screenName,
  });

  /// Factory constructor that computes counts and duration automatically.
  factory ScreenExecutionSummary.fromResults({
    required ExecutionMode executionMode,
    required List<TestExecutionResult> results,
    required DateTime startTime,
    required DateTime endTime,
    String? screenName,
  }) {
    return ScreenExecutionSummary(
      screenName: screenName,
      executionMode: executionMode,
      startTime: startTime,
      endTime: endTime,
      duration: endTime.difference(startTime),
      results: List.unmodifiable(results),
    );
  }

  /// The name of the screen tested, if running in [ExecutionMode.screen].
  final String? screenName;

  /// The execution mode used for this run.
  final ExecutionMode executionMode;

  /// Wall-clock timestamp when execution began.
  final DateTime startTime;

  /// Wall-clock timestamp when execution completed.
  final DateTime endTime;

  /// Total duration of the test run.
  final Duration duration;

  /// Individual execution results for all executed tests in order.
  final List<TestExecutionResult> results;

  /// Total number of tests executed.
  int get totalTests => results.length;

  /// Number of tests that passed.
  int get passedCount => results.where((r) => r.isPassed).length;

  /// Number of tests that failed.
  int get failedCount => results.where((r) => r.isFailed).length;

  /// Number of tests that were skipped.
  int get skippedCount => results.where((r) => r.isSkipped).length;

  /// Whether all executed tests passed with zero failures.
  bool get isSuccess => failedCount == 0 && passedCount > 0;

  /// List of only the failed test results for easy inspection.
  List<TestExecutionResult> get failures =>
      results.where((r) => r.isFailed).toList();

  /// Serializes the summary to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'screenName': screenName,
      'executionMode': executionMode.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'totalTests': totalTests,
      'passedCount': passedCount,
      'failedCount': failedCount,
      'skippedCount': skippedCount,
      'isSuccess': isSuccess,
      'results': results.map((r) => r.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'ScreenExecutionSummary(screen: $screenName, mode: ${executionMode.name}, passed: $passedCount/$totalTests, failed: $failedCount, duration: ${duration.inMilliseconds}ms)';
}
