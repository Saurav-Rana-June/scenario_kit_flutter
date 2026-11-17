import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScreenExecutionSummary', () {
    test('computes totals, duration, and success flag accurately', () {
      final start = DateTime(2026, 11, 17, 10, 0, 0);
      final end = DateTime(2026, 11, 17, 10, 0, 2);

      final r1 = TestExecutionResult.passed(
        testId: 't1',
        name: 'Test 1',
        duration: const Duration(seconds: 1),
      );
      final r2 = TestExecutionResult.failed(
        testId: 't2',
        name: 'Test 2',
        duration: const Duration(seconds: 1),
        errorMessage: 'Assertion failed',
      );
      final r3 = TestExecutionResult.skipped(
        testId: 't3',
        name: 'Test 3',
        skipReason: 'Disabled',
      );

      final summary = ScreenExecutionSummary.fromResults(
        screenName: 'LoginScreen',
        executionMode: ExecutionMode.screen,
        results: [r1, r2, r3],
        startTime: start,
        endTime: end,
      );

      expect(summary.screenName, 'LoginScreen');
      expect(summary.executionMode, ExecutionMode.screen);
      expect(summary.totalTests, 3);
      expect(summary.passedCount, 1);
      expect(summary.failedCount, 1);
      expect(summary.skippedCount, 1);
      expect(summary.duration, const Duration(seconds: 2));
      expect(summary.isSuccess, isFalse);
      expect(summary.failures, [r2]);
    });

    test('isSuccess is true when all tests pass', () {
      final now = DateTime.now();
      final r1 = TestExecutionResult.passed(
        testId: 't1',
        name: 'Test 1',
        duration: const Duration(milliseconds: 100),
      );

      final summary = ScreenExecutionSummary.fromResults(
        executionMode: ExecutionMode.functionality,
        results: [r1],
        startTime: now,
        endTime: now.add(const Duration(milliseconds: 100)),
      );

      expect(summary.isSuccess, isTrue);
      expect(summary.failures, isEmpty);
    });

    test('serializes to JSON accurately', () {
      final start = DateTime(2026, 11, 17, 12, 0, 0);
      final end = DateTime(2026, 11, 17, 12, 0, 1);

      final r1 = TestExecutionResult.passed(
        testId: 't1',
        name: 'Test 1',
        duration: const Duration(seconds: 1),
      );

      final summary = ScreenExecutionSummary.fromResults(
        screenName: 'HomeScreen',
        executionMode: ExecutionMode.screen,
        results: [r1],
        startTime: start,
        endTime: end,
      );

      final json = summary.toJson();
      expect(json['screenName'], 'HomeScreen');
      expect(json['executionMode'], 'screen');
      expect(json['totalTests'], 1);
      expect(json['passedCount'], 1);
      expect(json['failedCount'], 0);
      expect(json['isSuccess'], isTrue);
      expect(summary.toString(), contains('HomeScreen'));
    });
  });
}
