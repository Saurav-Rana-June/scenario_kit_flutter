/// Execution status of a [ScenarioTest].
enum TestStatus {
  /// Test is waiting to be executed.
  pending,

  /// Test is actively running.
  running,

  /// Test completed successfully with all assertions passing.
  passed,

  /// Test failed due to an assertion violation, timeout, or uncaught exception.
  failed,

  /// Test was skipped or disabled.
  skipped;

  /// Whether the test has finished running.
  bool get isCompleted =>
      this == TestStatus.passed ||
      this == TestStatus.failed ||
      this == TestStatus.skipped;

  /// Whether the test was successful.
  bool get isPassed => this == TestStatus.passed;

  /// Whether the test failed.
  bool get isFailed => this == TestStatus.failed;
}

/// Execution status of an individual [ScenarioTestStep].
enum StepStatus {
  /// Step is waiting to be executed.
  pending,

  /// Step is actively executing.
  running,

  /// Step completed successfully.
  passed,

  /// Step failed.
  failed,

  /// Step was skipped.
  skipped;

  /// Whether the step has finished running.
  bool get isCompleted =>
      this == StepStatus.passed ||
      this == StepStatus.failed ||
      this == StepStatus.skipped;
}
