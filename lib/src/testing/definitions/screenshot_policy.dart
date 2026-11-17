import 'package:flutter/foundation.dart';

/// Configuration policy determining when screenshots should be captured
/// during [ScenarioTest] execution.
@immutable
class ScreenshotPolicy {
  /// Creates a [ScreenshotPolicy].
  const ScreenshotPolicy({
    this.captureOnFailure = true,
    this.captureOnSuccess = false,
    this.captureBeforeTest = false,
    this.captureAfterSteps = false,
  });

  /// Captures screenshots only when an error or assertion failure occurs.
  const ScreenshotPolicy.onFailureOnly()
      : captureOnFailure = true,
        captureOnSuccess = false,
        captureBeforeTest = false,
        captureAfterSteps = false;

  /// Captures screenshots at all lifecycle checkpoints.
  const ScreenshotPolicy.all()
      : captureOnFailure = true,
        captureOnSuccess = true,
        captureBeforeTest = true,
        captureAfterSteps = true;

  /// Completely disables screenshot capture.
  const ScreenshotPolicy.disabled()
      : captureOnFailure = false,
        captureOnSuccess = false,
        captureBeforeTest = false,
        captureAfterSteps = false;

  /// Whether to capture a screenshot automatically when a test or assertion fails.
  final bool captureOnFailure;

  /// Whether to capture a screenshot when a test completes successfully.
  final bool captureOnSuccess;

  /// Whether to capture a screenshot immediately before test steps execute.
  final bool captureBeforeTest;

  /// Whether to capture a screenshot after each individual test step completes.
  final bool captureAfterSteps;

  /// Whether any screenshot capture is enabled by this policy.
  bool get hasAnyCapture =>
      captureOnFailure ||
      captureOnSuccess ||
      captureBeforeTest ||
      captureAfterSteps;

  /// Creates a copy of this policy with specified fields replaced.
  ScreenshotPolicy copyWith({
    bool? captureOnFailure,
    bool? captureOnSuccess,
    bool? captureBeforeTest,
    bool? captureAfterSteps,
  }) {
    return ScreenshotPolicy(
      captureOnFailure: captureOnFailure ?? this.captureOnFailure,
      captureOnSuccess: captureOnSuccess ?? this.captureOnSuccess,
      captureBeforeTest: captureBeforeTest ?? this.captureBeforeTest,
      captureAfterSteps: captureAfterSteps ?? this.captureAfterSteps,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenshotPolicy &&
        other.captureOnFailure == captureOnFailure &&
        other.captureOnSuccess == captureOnSuccess &&
        other.captureBeforeTest == captureBeforeTest &&
        other.captureAfterSteps == captureAfterSteps;
  }

  @override
  int get hashCode => Object.hash(
        captureOnFailure,
        captureOnSuccess,
        captureBeforeTest,
        captureAfterSteps,
      );

  @override
  String toString() =>
      'ScreenshotPolicy(onFailure: $captureOnFailure, onSuccess: $captureOnSuccess, beforeTest: $captureBeforeTest, afterSteps: $captureAfterSteps)';
}
