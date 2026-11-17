import 'package:flutter/foundation.dart';

/// Represents the identifiable outcome of a single assertion evaluation.
@immutable
class AssertionResult {
  /// Creates an [AssertionResult].
  AssertionResult({
    required this.description,
    required this.isSuccess,
    this.expectedValue,
    this.actualValue,
    this.failureMessage,
    this.testId,
    DateTime? timestamp,
    this.duration = Duration.zero,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a successful assertion result.
  factory AssertionResult.success({
    required String description,
    dynamic expectedValue,
    dynamic actualValue,
    String? testId,
    Duration duration = Duration.zero,
  }) {
    return AssertionResult(
      description: description,
      isSuccess: true,
      expectedValue: expectedValue,
      actualValue: actualValue,
      testId: testId,
      duration: duration,
    );
  }

  /// Creates a failed assertion result.
  factory AssertionResult.failure({
    required String description,
    required String failureMessage,
    dynamic expectedValue,
    dynamic actualValue,
    String? testId,
    Duration duration = Duration.zero,
  }) {
    return AssertionResult(
      description: description,
      isSuccess: false,
      expectedValue: expectedValue,
      actualValue: actualValue,
      failureMessage: failureMessage,
      testId: testId,
      duration: duration,
    );
  }

  /// Clear description of what was verified.
  final String description;

  /// Whether the assertion succeeded.
  final bool isSuccess;

  /// Expected value or matcher representation.
  final dynamic expectedValue;

  /// Actual value observed at execution time.
  final dynamic actualValue;

  /// Error message explaining why the assertion failed, if applicable.
  final String? failureMessage;

  /// Associated [ScenarioTest.id], if available.
  final String? testId;

  /// Exact time when this assertion was evaluated.
  final DateTime timestamp;

  /// Duration taken to evaluate this assertion.
  final Duration duration;

  /// Whether this assertion failed.
  bool get isFailure => !isSuccess;

  /// Serializes this assertion result to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'isSuccess': isSuccess,
      'expectedValue': expectedValue?.toString(),
      'actualValue': actualValue?.toString(),
      'failureMessage': failureMessage,
      'testId': testId,
      'timestamp': timestamp.toIso8601String(),
      'durationMs': duration.inMilliseconds,
    };
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'AssertionResult.success($description)';
    }
    return 'AssertionResult.failure($description: $failureMessage, expected: $expectedValue, actual: $actualValue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssertionResult &&
        other.description == description &&
        other.isSuccess == isSuccess &&
        '${other.expectedValue}' == '$expectedValue' &&
        '${other.actualValue}' == '$actualValue' &&
        other.failureMessage == failureMessage &&
        other.testId == testId;
  }

  @override
  int get hashCode => Object.hash(
        description,
        isSuccess,
        '$expectedValue',
        '$actualValue',
        failureMessage,
        testId,
      );
}

/// Exception thrown when a scenario test assertion evaluates to false.
class AssertionException implements Exception {
  /// Creates an [AssertionException] wrapping an [AssertionResult].
  const AssertionException(this.result);

  /// The underlying failed assertion result.
  final AssertionResult result;

  /// Informative error message.
  String get message =>
      result.failureMessage ?? 'Assertion failed: ${result.description}';

  @override
  String toString() => 'AssertionException: $message';
}
