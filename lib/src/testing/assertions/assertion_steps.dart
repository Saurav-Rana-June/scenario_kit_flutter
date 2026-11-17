import 'dart:async';

import '../definitions/scenario_test_step.dart';
import '../definitions/step_finder.dart';
import '../steps/scenario_step_context.dart';
import 'assertion_result.dart';

/// Base class for all assertion steps that evaluate conditions and record identifiable [AssertionResult]s.
abstract class ScenarioAssertionStep extends ScenarioTestStep {
  /// Creates a [ScenarioAssertionStep].
  const ScenarioAssertionStep({
    required super.id,
    required super.description,
    super.captureScreenshot,
    super.timeout,
  });

  /// Evaluates the assertion and throws [AssertionException] if it fails.
  @override
  Future<void> execute(ScenarioStepContext context);
}

/// Asserts that a widget matching [finder] exists in the widget tree.
class AssertExistsStep extends ScenarioAssertionStep {
  /// Creates an [AssertExistsStep].
  AssertExistsStep({
    required this.finder,
    String? id,
    String? description,
    super.captureScreenshot,
  }) : super(
          id: id ?? 'assert_exists_${finder.description}',
          description: description ?? 'Assert ${finder.description} exists',
        );

  /// Target widget finder.
  final StepFinder finder;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    final stopwatch = Stopwatch()..start();
    final exists = await context.exists(finder);
    stopwatch.stop();

    final result = exists
        ? AssertionResult.success(
            description: description,
            expectedValue: 'Widget exists',
            actualValue: 'Widget found in tree',
            testId: context.testId,
            duration: stopwatch.elapsed,
          )
        : AssertionResult.failure(
            description: description,
            failureMessage:
                'Expected widget matching ${finder.description} to exist, but none was found.',
            expectedValue: 'Widget exists',
            actualValue: 'Widget not found',
            testId: context.testId,
            duration: stopwatch.elapsed,
          );

    context.recordAssertion(result);
    if (!result.isSuccess) {
      throw AssertionException(result);
    }
  }
}

/// Asserts that a widget matching [finder] does NOT exist in the widget tree.
class AssertNotExistsStep extends ScenarioAssertionStep {
  /// Creates an [AssertNotExistsStep].
  AssertNotExistsStep({
    required this.finder,
    String? id,
    String? description,
    super.captureScreenshot,
  }) : super(
          id: id ?? 'assert_not_exists_${finder.description}',
          description:
              description ?? 'Assert ${finder.description} does not exist',
        );

  /// Target widget finder.
  final StepFinder finder;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    final stopwatch = Stopwatch()..start();
    final exists = await context.exists(finder);
    stopwatch.stop();

    final result = !exists
        ? AssertionResult.success(
            description: description,
            expectedValue: 'Widget does not exist',
            actualValue: 'Widget absent from tree',
            testId: context.testId,
            duration: stopwatch.elapsed,
          )
        : AssertionResult.failure(
            description: description,
            failureMessage:
                'Expected widget matching ${finder.description} to be absent, but it was found in tree.',
            expectedValue: 'Widget does not exist',
            actualValue: 'Widget found in tree',
            testId: context.testId,
            duration: stopwatch.elapsed,
          );

    context.recordAssertion(result);
    if (!result.isSuccess) {
      throw AssertionException(result);
    }
  }
}

/// Match type for text assertions.
enum TextMatchType {
  /// Matches text exactly.
  exact,

  /// Matches if the text contains substring.
  contains,

  /// Matches text against a regular expression.
  regex,
}

/// Asserts that text content on a target widget matches expected criteria.
class AssertTextStep extends ScenarioAssertionStep {
  /// Creates an [AssertTextStep].
  AssertTextStep({
    required this.finder,
    required this.expectedText,
    this.matchType = TextMatchType.exact,
    String? id,
    String? description,
    super.captureScreenshot,
  }) : super(
          id: id ?? 'assert_text_${finder.description}',
          description: description ??
              'Assert ${finder.description} has text "$expectedText" (${matchType.name})',
        );

  /// Target widget finder.
  final StepFinder finder;

  /// Expected string or pattern.
  final String expectedText;

  /// Matching strategy.
  final TextMatchType matchType;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    final stopwatch = Stopwatch()..start();
    final actualText = await context.getText(finder);
    stopwatch.stop();

    bool matched = false;
    if (actualText != null) {
      switch (matchType) {
        case TextMatchType.exact:
          matched = actualText == expectedText;
          break;
        case TextMatchType.contains:
          matched = actualText.contains(expectedText);
          break;
        case TextMatchType.regex:
          matched = RegExp(expectedText).hasMatch(actualText);
          break;
      }
    }

    final result = matched
        ? AssertionResult.success(
            description: description,
            expectedValue: expectedText,
            actualValue: actualText,
            testId: context.testId,
            duration: stopwatch.elapsed,
          )
        : AssertionResult.failure(
            description: description,
            failureMessage: actualText == null
                ? 'Target widget matching ${finder.description} was not found or contained no text.'
                : 'Text mismatch: expected "$expectedText" (${matchType.name}), but found "$actualText".',
            expectedValue: expectedText,
            actualValue: actualText,
            testId: context.testId,
            duration: stopwatch.elapsed,
          );

    context.recordAssertion(result);
    if (!result.isSuccess) {
      throw AssertionException(result);
    }
  }
}

/// Asserts that a target widget is visible on screen.
class AssertVisibleStep extends ScenarioAssertionStep {
  /// Creates an [AssertVisibleStep].
  AssertVisibleStep({
    required this.finder,
    String? id,
    String? description,
    super.captureScreenshot,
  }) : super(
          id: id ?? 'assert_visible_${finder.description}',
          description: description ?? 'Assert ${finder.description} is visible',
        );

  /// Target widget finder.
  final StepFinder finder;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    final stopwatch = Stopwatch()..start();
    final isVisible = await context.isVisible(finder);
    stopwatch.stop();

    final result = isVisible
        ? AssertionResult.success(
            description: description,
            expectedValue: 'Widget is visible',
            actualValue: 'Widget is visible',
            testId: context.testId,
            duration: stopwatch.elapsed,
          )
        : AssertionResult.failure(
            description: description,
            failureMessage:
                'Expected ${finder.description} to be visible, but it was offscreen or zero-sized.',
            expectedValue: 'Widget is visible',
            actualValue: 'Widget is not visible',
            testId: context.testId,
            duration: stopwatch.elapsed,
          );

    context.recordAssertion(result);
    if (!result.isSuccess) {
      throw AssertionException(result);
    }
  }
}

/// Asserts that a custom developer-defined condition evaluates to true.
class AssertCustomStep extends ScenarioAssertionStep {
  /// Creates an [AssertCustomStep].
  const AssertCustomStep({
    required super.id,
    required super.description,
    required this.assertion,
    this.expectedValue = true,
    super.captureScreenshot,
  });

  /// Assertion callback returning either a boolean or an [AssertionResult].
  final FutureOr<dynamic> Function(ScenarioStepContext context) assertion;

  /// Expected value for documentation.
  final dynamic expectedValue;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    final stopwatch = Stopwatch()..start();
    dynamic actual;
    bool isSuccess = false;
    String? failureMsg;

    try {
      final raw = await assertion(context);
      actual = raw;
      if (raw is bool) {
        isSuccess = raw;
        if (!isSuccess) {
          failureMsg = 'Custom assertion "$description" returned false.';
        }
      } else if (raw is AssertionResult) {
        isSuccess = raw.isSuccess;
        failureMsg = raw.failureMessage;
        actual = raw.actualValue;
      } else {
        isSuccess = raw != null && raw != false;
      }
    } catch (e) {
      isSuccess = false;
      actual = e.toString();
      failureMsg = 'Custom assertion "$description" threw an exception: $e';
    } finally {
      stopwatch.stop();
    }

    final result = isSuccess
        ? AssertionResult.success(
            description: description,
            expectedValue: expectedValue,
            actualValue: actual,
            testId: context.testId,
            duration: stopwatch.elapsed,
          )
        : AssertionResult.failure(
            description: description,
            failureMessage:
                failureMsg ?? 'Custom assertion "$description" failed.',
            expectedValue: expectedValue,
            actualValue: actual,
            testId: context.testId,
            duration: stopwatch.elapsed,
          );

    context.recordAssertion(result);
    if (!result.isSuccess) {
      throw AssertionException(result);
    }
  }
}
