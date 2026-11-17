import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('HtmlReportExporter', () {
    test('exports self-contained HTML report with embedded styles and data',
        () {
      final now = DateTime.now();
      final screenshotBytes = Uint8List.fromList(utf8.encode('png_mock_data'));

      final step1 = StepExecutionResult.passed(
        stepId: 'step_enter_email',
        description: 'Enter email in text field',
        duration: const Duration(milliseconds: 30),
      );

      final r1 = TestExecutionResult.passed(
        testId: 'auth_01',
        name: 'Valid Login Credentials',
        screen: 'LoginScreen',
        group: 'Authentication',
        duration: const Duration(milliseconds: 150),
        stepResults: [step1],
        assertions: [
          AssertionResult.success(description: 'Profile avatar visible'),
        ],
        screenshots: [
          ScenarioScreenshot(
            name: 'login_success_shot',
            bytes: screenshotBytes,
            timestamp: now,
          ),
        ],
        logs: const ['Log 1: field focused', 'Log 2: submit tapped'],
      );

      final r2 = TestExecutionResult.failed(
        testId: 'auth_02',
        name: 'Invalid Password Error',
        screen: 'LoginScreen',
        group: 'Authentication',
        duration: const Duration(milliseconds: 80),
        errorMessage: 'Expected error message was absent',
        stackTrace: StackTrace.current,
      );

      final report = ScenarioTestReport.fromResults(
        results: [r1, r2],
        title: 'Release QA Test Run',
        screenName: 'LoginScreen',
        environment: const {
          'OS': 'Windows 11',
          'Flutter': '3.22.0',
        },
      );

      const exporter = HtmlReportExporter();
      final html = exporter.export(report);

      // Validate core HTML structure
      expect(html, startsWith('<!DOCTYPE html>'));
      expect(html, contains('Release QA Test Run'));
      expect(html, contains('Valid Login Credentials'));
      expect(html, contains('Invalid Password Error'));
      expect(html, contains('Enter email in text field'));
      expect(html, contains('Profile avatar visible'));
      expect(html, contains('Expected error message was absent'));
      expect(html, contains('Windows 11'));
      expect(html, contains('LoginScreen'));

      // Validate Base64 screenshot embedding
      expect(html, contains('data:image/png;base64,'));
      final expectedBase64 = base64Encode(screenshotBytes);
      expect(html, contains(expectedBase64));

      // Validate self-contained styling and JS modal script
      expect(html, contains('<style>'));
      expect(html, contains('<script>'));
      expect(html, contains('openModal'));
      expect(html, contains('closeModal'));
    });
  });
}
