import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioTestReport', () {
    test('creates report from summaries and computes metrics accurately', () {
      final now = DateTime(2026, 11, 17, 14, 0, 0);
      final r1 = TestExecutionResult.passed(
        testId: 't1',
        name: 'Test 1',
        screen: 'LoginScreen',
        duration: const Duration(seconds: 1),
        assertions: [
          AssertionResult.success(description: 'Title visible'),
        ],
        screenshots: [
          ScenarioScreenshot(
            name: 'shot_1',
            bytes: Uint8List.fromList([1, 2, 3]),
            timestamp: now,
          ),
        ],
      );

      final r2 = TestExecutionResult.failed(
        testId: 't2',
        name: 'Test 2',
        screen: 'LoginScreen',
        duration: const Duration(seconds: 1),
        errorMessage: 'Button missing',
      );

      final summary = ScreenExecutionSummary.fromResults(
        screenName: 'LoginScreen',
        executionMode: ExecutionMode.screen,
        results: [r1, r2],
        startTime: now,
        endTime: now.add(const Duration(seconds: 2)),
      );

      final report = ScenarioTestReport.fromSummaries(
        title: 'CI Test Run',
        summaries: [summary],
        environment: const {'Flutter': '3.22.0', 'Platform': 'Windows'},
      );

      expect(report.title, 'CI Test Run');
      expect(report.totalTests, 2);
      expect(report.passedCount, 1);
      expect(report.failedCount, 1);
      expect(report.skippedCount, 0);
      expect(report.successRate, 50.0);
      expect(report.isSuccess, isFalse);
      expect(report.allResults.length, 2);
      expect(report.allScreenshots.length, 1);
      expect(report.allAssertions.length, 1);
      expect(report.environment['Flutter'], '3.22.0');

      final json = report.toJson();
      expect(json['title'], 'CI Test Run');
      expect(json['totalTests'], 2);
      expect(json['passedCount'], 1);
      expect(json['failedCount'], 1);
      expect(json['successRate'], 50.0);
      expect(json['summaries'].length, 1);
    });

    test('creates report directly from results', () {
      final r1 = TestExecutionResult.passed(
        testId: 't1',
        name: 'Test 1',
        duration: const Duration(milliseconds: 50),
      );

      final report = ScenarioTestReport.fromResults(
        results: [r1],
        screenName: 'HomeScreen',
      );

      expect(report.totalTests, 1);
      expect(report.isSuccess, isTrue);
      expect(report.summaries.first.screenName, 'HomeScreen');
    });
  });
}
