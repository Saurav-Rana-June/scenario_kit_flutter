import 'package:flutter/foundation.dart';

import '../assertions/assertion_result.dart';
import '../definitions/test_status.dart';

/// Represents the execution outcome and diagnostic data for an individual [ScenarioTestStep].
@immutable
class StepExecutionResult {
  /// Creates a [StepExecutionResult].
  const StepExecutionResult({
    required this.stepId,
    required this.description,
    required this.status,
    required this.duration,
    required this.timestamp,
    this.errorMessage,
    this.stackTrace,
    this.assertions = const [],
    this.screenshotBytes,
    this.screenshotPath,
  });

  /// Factory constructor for a passed step.
  factory StepExecutionResult.passed({
    required String stepId,
    required String description,
    required Duration duration,
    List<AssertionResult> assertions = const [],
    Uint8List? screenshotBytes,
    String? screenshotPath,
    DateTime? timestamp,
  }) {
    return StepExecutionResult(
      stepId: stepId,
      description: description,
      status: StepStatus.passed,
      duration: duration,
      timestamp: timestamp ?? DateTime.now(),
      assertions: assertions,
      screenshotBytes: screenshotBytes,
      screenshotPath: screenshotPath,
    );
  }

  /// Factory constructor for a failed step.
  factory StepExecutionResult.failed({
    required String stepId,
    required String description,
    required Duration duration,
    required String errorMessage,
    StackTrace? stackTrace,
    List<AssertionResult> assertions = const [],
    Uint8List? screenshotBytes,
    String? screenshotPath,
    DateTime? timestamp,
  }) {
    return StepExecutionResult(
      stepId: stepId,
      description: description,
      status: StepStatus.failed,
      duration: duration,
      timestamp: timestamp ?? DateTime.now(),
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      assertions: assertions,
      screenshotBytes: screenshotBytes,
      screenshotPath: screenshotPath,
    );
  }

  /// Factory constructor for a skipped step.
  factory StepExecutionResult.skipped({
    required String stepId,
    required String description,
    DateTime? timestamp,
  }) {
    return StepExecutionResult(
      stepId: stepId,
      description: description,
      status: StepStatus.skipped,
      duration: Duration.zero,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Unique identifier of the executed step.
  final String stepId;

  /// Clear description of what the step did.
  final String description;

  /// Terminal execution status of this step.
  final StepStatus status;

  /// Duration spent executing this step.
  final Duration duration;

  /// Timestamp when step execution began or concluded.
  final DateTime timestamp;

  /// Error message if this step failed.
  final String? errorMessage;

  /// Stack trace associated with an unhandled exception or failed assertion.
  final StackTrace? stackTrace;

  /// All assertion results evaluated during this step.
  final List<AssertionResult> assertions;

  /// Optional in-memory PNG screenshot captured at the conclusion of this step.
  final Uint8List? screenshotBytes;

  /// Optional disk or URL path to the captured screenshot.
  final String? screenshotPath;

  /// Whether this step succeeded.
  bool get isPassed => status == StepStatus.passed;

  /// Whether this step failed.
  bool get isFailed => status == StepStatus.failed;

  /// Whether this step was skipped.
  bool get isSkipped => status == StepStatus.skipped;

  /// Serializes this step execution result to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'stepId': stepId,
      'description': description,
      'status': status.name,
      'durationMs': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'errorMessage': errorMessage,
      'assertions': assertions.map((a) => a.toJson()).toList(),
      'hasScreenshot': screenshotBytes != null || screenshotPath != null,
      'screenshotPath': screenshotPath,
    };
  }

  @override
  String toString() =>
      'StepExecutionResult(stepId: $stepId, status: ${status.name}, duration: ${duration.inMilliseconds}ms)';
}
