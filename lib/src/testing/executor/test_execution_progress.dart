import 'package:flutter/foundation.dart';

import '../definitions/scenario_test.dart';
import '../definitions/scenario_test_step.dart';

/// Progress information emitted during live scenario test execution.
@immutable
class TestExecutionProgress {
  /// Creates a [TestExecutionProgress].
  const TestExecutionProgress({
    required this.totalTests,
    required this.currentTestIndex,
    required this.passedCount,
    required this.failedCount,
    required this.skippedCount,
    required this.elapsed,
    required this.isRunning,
    this.currentTest,
    this.currentStepIndex = 0,
    this.totalStepsInCurrentTest = 0,
    this.currentStep,
  });

  /// Factory constructor for initial idle state.
  factory TestExecutionProgress.idle() {
    return const TestExecutionProgress(
      totalTests: 0,
      currentTestIndex: 0,
      passedCount: 0,
      failedCount: 0,
      skippedCount: 0,
      elapsed: Duration.zero,
      isRunning: false,
    );
  }

  /// Total number of tests queued for this execution run.
  final int totalTests;

  /// 0-based index of the currently executing test.
  final int currentTestIndex;

  /// The [ScenarioTest] currently being executed.
  final ScenarioTest? currentTest;

  /// 0-based index of the step currently executing within [currentTest].
  final int currentStepIndex;

  /// Total number of steps in [currentTest].
  final int totalStepsInCurrentTest;

  /// The [ScenarioTestStep] currently executing.
  final ScenarioTestStep? currentStep;

  /// Number of tests that have passed so far.
  final int passedCount;

  /// Number of tests that have failed so far.
  final int failedCount;

  /// Number of tests that were skipped.
  final int skippedCount;

  /// Total wall-clock time elapsed since execution began.
  final Duration elapsed;

  /// Whether tests are currently executing.
  final bool isRunning;

  /// Overall completion percentage from `0.0` to `1.0`.
  double get percentage {
    if (totalTests == 0) return 0.0;
    final completed = passedCount + failedCount + skippedCount;
    return (completed / totalTests).clamp(0.0, 1.0);
  }

  /// Total tests completed so far.
  int get completedCount => passedCount + failedCount + skippedCount;

  /// Creates a copy of this progress with updated fields.
  TestExecutionProgress copyWith({
    int? totalTests,
    int? currentTestIndex,
    ScenarioTest? currentTest,
    int? currentStepIndex,
    int? totalStepsInCurrentTest,
    ScenarioTestStep? currentStep,
    int? passedCount,
    int? failedCount,
    int? skippedCount,
    Duration? elapsed,
    bool? isRunning,
  }) {
    return TestExecutionProgress(
      totalTests: totalTests ?? this.totalTests,
      currentTestIndex: currentTestIndex ?? this.currentTestIndex,
      currentTest: currentTest ?? this.currentTest,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      totalStepsInCurrentTest:
          totalStepsInCurrentTest ?? this.totalStepsInCurrentTest,
      currentStep: currentStep ?? this.currentStep,
      passedCount: passedCount ?? this.passedCount,
      failedCount: failedCount ?? this.failedCount,
      skippedCount: skippedCount ?? this.skippedCount,
      elapsed: elapsed ?? this.elapsed,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  @override
  String toString() =>
      'TestExecutionProgress(running: $isRunning, progress: ${(percentage * 100).toStringAsFixed(1)}%, passed: $passedCount, failed: $failedCount, skipped: $skippedCount)';
}
