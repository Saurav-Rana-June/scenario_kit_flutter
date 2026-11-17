import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioScreenshot', () {
    test('creates screenshot model with metadata', () {
      final now = DateTime.now();
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final screenshot = ScenarioScreenshot(
        name: 'login_screen',
        bytes: bytes,
        timestamp: now,
        stepId: 'step_tap',
        stepDescription: 'Tap login button',
        deviceWidth: 412,
        deviceHeight: 915,
        pixelRatio: 2.625,
      );

      expect(screenshot.name, 'login_screen');
      expect(screenshot.bytes, bytes);
      expect(screenshot.timestamp, now);
      expect(screenshot.stepId, 'step_tap');
      expect(screenshot.stepDescription, 'Tap login button');
      expect(screenshot.deviceWidth, 412);
      expect(screenshot.deviceHeight, 915);
      expect(screenshot.pixelRatio, 2.625);

      final json = screenshot.toJson();
      expect(json['name'], 'login_screen');
      expect(json['byteLength'], 4);
      expect(json['deviceWidth'], 412);
      expect(screenshot.toString(), contains('4 bytes'));
    });
  });

  group('TestExecutionResult', () {
    test('creates passed result with step statistics', () {
      final step1 = StepExecutionResult.passed(
        stepId: 's1',
        description: 'Step 1',
        duration: const Duration(milliseconds: 10),
      );
      final step2 = StepExecutionResult.passed(
        stepId: 's2',
        description: 'Step 2',
        duration: const Duration(milliseconds: 20),
      );

      final result = TestExecutionResult.passed(
        testId: 'test_1',
        name: 'Valid Login',
        screen: 'LoginScreen',
        group: 'Auth',
        duration: const Duration(milliseconds: 30),
        stepResults: [step1, step2],
        logs: const ['Log 1', 'Log 2'],
      );

      expect(result.isPassed, isTrue);
      expect(result.isFailed, isFalse);
      expect(result.isSkipped, isFalse);
      expect(result.passedStepCount, 2);
      expect(result.failedStepCount, 0);
      expect(result.duration, const Duration(milliseconds: 30));

      final json = result.toJson();
      expect(json['testId'], 'test_1');
      expect(json['status'], 'passed');
      expect(json['logs'], ['Log 1', 'Log 2']);
      expect(json['stepResults'].length, 2);
    });

    test('creates failed result with error diagnostics', () {
      final step1 = StepExecutionResult.passed(
        stepId: 's1',
        description: 'Step 1',
        duration: const Duration(milliseconds: 5),
      );
      final step2 = StepExecutionResult.failed(
        stepId: 's2',
        description: 'Step 2',
        duration: const Duration(milliseconds: 15),
        errorMessage: 'Widget not found',
      );

      final result = TestExecutionResult.failed(
        testId: 'test_fail',
        name: 'Invalid Login',
        duration: const Duration(milliseconds: 20),
        errorMessage: 'Widget not found',
        stepResults: [step1, step2],
      );

      expect(result.isPassed, isFalse);
      expect(result.isFailed, isTrue);
      expect(result.passedStepCount, 1);
      expect(result.failedStepCount, 1);
      expect(result.errorMessage, 'Widget not found');
    });

    test('creates skipped result with reason', () {
      final result = TestExecutionResult.skipped(
        testId: 'test_skip',
        name: 'Smoke Test',
        skipReason: 'Disabled by user',
      );

      expect(result.isSkipped, isTrue);
      expect(result.isPassed, isFalse);
      expect(result.errorMessage, 'Disabled by user');
      expect(result.duration, Duration.zero);
    });
  });
}
