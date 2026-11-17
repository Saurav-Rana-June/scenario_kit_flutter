import 'package:flutter/foundation.dart';

import '../assertions/assertion_result.dart';
import '../definitions/test_status.dart';
import '../steps/step_execution_result.dart';

/// Represents a captured screenshot associated with a test case and execution step.
@immutable
class ScenarioScreenshot {
  /// Creates a [ScenarioScreenshot].
  const ScenarioScreenshot({
    required this.name,
    required this.bytes,
    required this.timestamp,
    this.stepId,
    this.stepDescription,
    this.deviceWidth,
    this.deviceHeight,
    this.pixelRatio,
  });

  /// Name or label for this screenshot.
  final String name;

  /// Raw PNG image bytes.
  final Uint8List bytes;

  /// Timestamp when captured.
  final DateTime timestamp;

  /// Step ID after which this screenshot was taken, if applicable.
  final String? stepId;

  /// Description of the step, if applicable.
  final String? stepDescription;

  /// Rendered screen width in logical pixels.
  final double? deviceWidth;

  /// Rendered screen height in logical pixels.
  final double? deviceHeight;

  /// Device pixel ratio when captured.
  final double? pixelRatio;

  /// Serializes screenshot metadata to a JSON map (excludes raw bytes).
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'stepId': stepId,
      'stepDescription': stepDescription,
      'deviceWidth': deviceWidth,
      'deviceHeight': deviceHeight,
      'pixelRatio': pixelRatio,
      'byteLength': bytes.lengthInBytes,
    };
  }

  @override
  String toString() =>
      'ScenarioScreenshot(name: $name, size: ${bytes.lengthInBytes} bytes)';
}

/// Consolidated execution outcome and diagnostic summary for an entire [ScenarioTest].
@immutable
class TestExecutionResult {
  /// Creates a [TestExecutionResult].
  const TestExecutionResult({
    required this.testId,
    required this.name,
    required this.status,
    required this.duration,
    required this.timestamp,
    this.screen,
    this.group,
    this.stepResults = const [],
    this.assertions = const [],
    this.screenshots = const [],
    this.logs = const [],
    this.errorMessage,
    this.stackTrace,
  });

  /// Factory constructor for a passed test.
  factory TestExecutionResult.passed({
    required String testId,
    required String name,
    required Duration duration,
    String? screen,
    String? group,
    List<StepExecutionResult> stepResults = const [],
    List<AssertionResult> assertions = const [],
    List<ScenarioScreenshot> screenshots = const [],
    List<String> logs = const [],
    DateTime? timestamp,
  }) {
    return TestExecutionResult(
      testId: testId,
      name: name,
      screen: screen,
      group: group,
      status: TestStatus.passed,
      duration: duration,
      timestamp: timestamp ?? DateTime.now(),
      stepResults: stepResults,
      assertions: assertions,
      screenshots: screenshots,
      logs: logs,
    );
  }

  /// Factory constructor for a failed test.
  factory TestExecutionResult.failed({
    required String testId,
    required String name,
    required Duration duration,
    required String errorMessage,
    StackTrace? stackTrace,
    String? screen,
    String? group,
    List<StepExecutionResult> stepResults = const [],
    List<AssertionResult> assertions = const [],
    List<ScenarioScreenshot> screenshots = const [],
    List<String> logs = const [],
    DateTime? timestamp,
  }) {
    return TestExecutionResult(
      testId: testId,
      name: name,
      screen: screen,
      group: group,
      status: TestStatus.failed,
      duration: duration,
      timestamp: timestamp ?? DateTime.now(),
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      stepResults: stepResults,
      assertions: assertions,
      screenshots: screenshots,
      logs: logs,
    );
  }

  /// Factory constructor for a skipped test.
  factory TestExecutionResult.skipped({
    required String testId,
    required String name,
    String? screen,
    String? group,
    String? skipReason,
    DateTime? timestamp,
  }) {
    return TestExecutionResult(
      testId: testId,
      name: name,
      screen: screen,
      group: group,
      status: TestStatus.skipped,
      duration: Duration.zero,
      timestamp: timestamp ?? DateTime.now(),
      errorMessage: skipReason,
    );
  }

  /// Unique identifier of the executed test.
  final String testId;

  /// Name of the executed test.
  final String name;

  /// Associated screen name.
  final String? screen;

  /// Associated category group.
  final String? group;

  /// Final terminal execution status.
  final TestStatus status;

  /// Total duration taken to execute the test including setup and teardown.
  final Duration duration;

  /// Timestamp when test execution began or concluded.
  final DateTime timestamp;

  /// Execution results for each individual step.
  final List<StepExecutionResult> stepResults;

  /// All assertions evaluated across all steps in this test.
  final List<AssertionResult> assertions;

  /// All screenshots captured during test execution.
  final List<ScenarioScreenshot> screenshots;

  /// Diagnostic execution logs recorded during the test.
  final List<String> logs;

  /// Error message if this test failed or was skipped.
  final String? errorMessage;

  /// Stack trace if an unhandled exception occurred.
  final StackTrace? stackTrace;

  /// Whether the test completed successfully.
  bool get isPassed => status == TestStatus.passed;

  /// Whether the test failed.
  bool get isFailed => status == TestStatus.failed;

  /// Whether the test was skipped.
  bool get isSkipped => status == TestStatus.skipped;

  /// Count of steps that passed.
  int get passedStepCount => stepResults.where((s) => s.isPassed).length;

  /// Count of steps that failed.
  int get failedStepCount => stepResults.where((s) => s.isFailed).length;

  /// Count of passed assertions.
  int get passedAssertionCount => assertions.where((a) => a.isSuccess).length;

  /// Count of failed assertions.
  int get failedAssertionCount => assertions.where((a) => a.isFailure).length;

  /// Serializes test execution results to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'name': name,
      'screen': screen,
      'group': group,
      'status': status.name,
      'durationMs': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'errorMessage': errorMessage,
      'stepResults': stepResults.map((s) => s.toJson()).toList(),
      'assertions': assertions.map((a) => a.toJson()).toList(),
      'screenshots': screenshots.map((s) => s.toJson()).toList(),
      'logs': logs,
    };
  }

  @override
  String toString() =>
      'TestExecutionResult(testId: $testId, status: ${status.name}, duration: ${duration.inMilliseconds}ms)';
}
