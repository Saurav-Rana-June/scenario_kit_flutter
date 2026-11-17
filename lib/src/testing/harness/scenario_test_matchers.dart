import 'package:flutter_test/flutter_test.dart';

import '../executor/test_execution_result.dart';
import '../runner/screen_execution_summary.dart';

/// Asserts that a [TestExecutionResult] completed with status [TestStatus.passed].
const Matcher isTestPassed = _IsTestPassed();

/// Asserts that a [TestExecutionResult] completed with status [TestStatus.failed].
const Matcher isTestFailed = _IsTestFailed();

/// Asserts that a [TestExecutionResult] completed with status [TestStatus.skipped].
const Matcher isTestSkipped = _IsTestSkipped();

/// Asserts that a [ScreenExecutionSummary] completed with zero failed tests and at least one pass.
const Matcher isExecutionSuccess = _IsExecutionSuccess();

/// Creates a matcher asserting that a [TestExecutionResult] has exactly [count] passed steps.
Matcher hasPassedSteps(int count) => _HasPassedSteps(count);

/// Creates a matcher asserting that a [TestExecutionResult] has exactly [count] failed steps.
Matcher hasFailedSteps(int count) => _HasFailedSteps(count);

/// Creates a matcher asserting that a [ScreenExecutionSummary] has exactly [count] passed tests.
Matcher hasPassCount(int count) => _HasPassCount(count);

/// Creates a matcher asserting that a [ScreenExecutionSummary] has exactly [count] failed tests.
Matcher hasFailCount(int count) => _HasFailCount(count);

class _IsTestPassed extends Matcher {
  const _IsTestPassed();

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    return item is TestExecutionResult && item.isPassed;
  }

  @override
  Description describe(Description description) =>
      description.add('a TestExecutionResult with status passed');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is TestExecutionResult) {
      return mismatchDescription.add(
          'has status ${item.status.name} with error: ${item.errorMessage}');
    }
    return mismatchDescription.add('is not a TestExecutionResult ($item)');
  }
}

class _IsTestFailed extends Matcher {
  const _IsTestFailed();

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    return item is TestExecutionResult && item.isFailed;
  }

  @override
  Description describe(Description description) =>
      description.add('a TestExecutionResult with status failed');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is TestExecutionResult) {
      return mismatchDescription.add('has status ${item.status.name}');
    }
    return mismatchDescription.add('is not a TestExecutionResult ($item)');
  }
}

class _IsTestSkipped extends Matcher {
  const _IsTestSkipped();

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    return item is TestExecutionResult && item.isSkipped;
  }

  @override
  Description describe(Description description) =>
      description.add('a TestExecutionResult with status skipped');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is TestExecutionResult) {
      return mismatchDescription.add('has status ${item.status.name}');
    }
    return mismatchDescription.add('is not a TestExecutionResult ($item)');
  }
}

class _IsExecutionSuccess extends Matcher {
  const _IsExecutionSuccess();

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    return item is ScreenExecutionSummary && item.isSuccess;
  }

  @override
  Description describe(Description description) =>
      description.add('a ScreenExecutionSummary where isSuccess is true');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is ScreenExecutionSummary) {
      return mismatchDescription.add(
          'passed: ${item.passedCount}/${item.totalTests}, failed: ${item.failedCount}');
    }
    return mismatchDescription.add('is not a ScreenExecutionSummary ($item)');
  }
}

class _HasPassedSteps extends Matcher {
  const _HasPassedSteps(this.count);

  final int count;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! TestExecutionResult) return false;
    final passed = item.stepResults.where((s) => s.isPassed).length;
    return passed == count;
  }

  @override
  Description describe(Description description) =>
      description.add('a TestExecutionResult with $count passed steps');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is TestExecutionResult) {
      final passed = item.stepResults.where((s) => s.isPassed).length;
      return mismatchDescription
          .add('has $passed passed steps (expected $count)');
    }
    return mismatchDescription.add('is not a TestExecutionResult ($item)');
  }
}

class _HasFailedSteps extends Matcher {
  const _HasFailedSteps(this.count);

  final int count;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! TestExecutionResult) return false;
    final failed = item.stepResults.where((s) => s.isFailed).length;
    return failed == count;
  }

  @override
  Description describe(Description description) =>
      description.add('a TestExecutionResult with $count failed steps');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is TestExecutionResult) {
      final failed = item.stepResults.where((s) => s.isFailed).length;
      return mismatchDescription
          .add('has $failed failed steps (expected $count)');
    }
    return mismatchDescription.add('is not a TestExecutionResult ($item)');
  }
}

class _HasPassCount extends Matcher {
  const _HasPassCount(this.count);

  final int count;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    return item is ScreenExecutionSummary && item.passedCount == count;
  }

  @override
  Description describe(Description description) =>
      description.add('a ScreenExecutionSummary with $count passed tests');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is ScreenExecutionSummary) {
      return mismatchDescription
          .add('has ${item.passedCount} passed tests (expected $count)');
    }
    return mismatchDescription.add('is not a ScreenExecutionSummary ($item)');
  }
}

class _HasFailCount extends Matcher {
  const _HasFailCount(this.count);

  final int count;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    return item is ScreenExecutionSummary && item.failedCount == count;
  }

  @override
  Description describe(Description description) =>
      description.add('a ScreenExecutionSummary with $count failed tests');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is ScreenExecutionSummary) {
      return mismatchDescription
          .add('has ${item.failedCount} failed tests (expected $count)');
    }
    return mismatchDescription.add('is not a ScreenExecutionSummary ($item)');
  }
}
