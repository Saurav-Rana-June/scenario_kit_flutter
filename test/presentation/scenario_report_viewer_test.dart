import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioReportViewerDialog Widget Tests', () {
    testWidgets('renders KPI cards, environment, and test details',
        (tester) async {
      final now = DateTime(2026, 11, 17, 10, 0, 0);

      final r1 = TestExecutionResult.passed(
        testId: 'auth_01',
        name: 'Valid Login',
        screen: 'LoginScreen',
        duration: const Duration(milliseconds: 120),
        stepResults: [
          StepExecutionResult.passed(
            stepId: 'step_1',
            description: 'Enter email address',
            duration: const Duration(milliseconds: 20),
          ),
        ],
        assertions: [
          AssertionResult.success(description: 'Profile avatar visible'),
        ],
        screenshots: [
          ScenarioScreenshot(
            name: 'success_shot',
            bytes: Uint8List.fromList([1, 2, 3]),
            timestamp: now,
          ),
        ],
      );

      final r2 = TestExecutionResult.failed(
        testId: 'auth_02',
        name: 'Invalid Password',
        screen: 'LoginScreen',
        duration: const Duration(milliseconds: 60),
        errorMessage: 'Invalid credentials error missing',
      );

      final report = ScenarioTestReport.fromResults(
        results: [r1, r2],
        title: 'Release QA Suite',
        screenName: 'LoginScreen',
        environment: const {'OS': 'Android', 'Platform': 'Emulator'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  ScenarioReportViewerDialog.show(context, report: report);
                },
                child: const Text('Open Report'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Report'));
      await tester.pumpAndSettle();

      // Verify header and KPI summary
      expect(find.text('Release QA Suite'), findsOneWidget);
      expect(find.text('TOTAL'), findsOneWidget);
      expect(find.text('PASSED'), findsWidgets);
      expect(find.text('FAILED'), findsWidgets);
      expect(find.text('SKIPPED'), findsOneWidget);

      // Verify environment diagnostics
      expect(find.text('ENVIRONMENT'), findsOneWidget);
      expect(find.text('OS: Android'), findsOneWidget);

      // Verify test cards
      expect(find.text('Valid Login'), findsOneWidget);
      expect(find.text('Invalid Password'), findsOneWidget);
      expect(find.text('Error: Invalid credentials error missing'),
          findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Release QA Suite'), findsNothing);
    });
  });
}
