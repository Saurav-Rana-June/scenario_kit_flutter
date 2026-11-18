import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioReportsTab Widget Tests', () {
    late ScenarioReportStore store;

    setUp(() {
      ScenarioReportStore.resetInstance();
      store = ScenarioReportStore.instance;
    });

    tearDown(() {
      ScenarioReportStore.resetInstance();
    });

    testWidgets('renders empty state when no test runs have occurred',
        (tester) async {
      var switchedToTests = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScenarioReportsTab(
              reportStore: store,
              onSwitchToTests: () => switchedToTests = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No test runs yet'), findsOneWidget);
      expect(
        find.text(
          'Run tests from the Tests tab to inspect execution results, step traces, and exports here.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('go_to_tests_tab_button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('go_to_tests_tab_button')));
      await tester.pumpAndSettle();

      expect(switchedToTests, isTrue);
    });

    testWidgets('renders test runs, filter chips, and expands step detail',
        (tester) async {
      final failedResult = TestExecutionResult.failed(
        testId: 'test_login',
        name: 'Verify Login UI Elements',
        screen: 'Login Screen',
        group: 'Smoke',
        duration: const Duration(milliseconds: 195),
        errorMessage:
            'AssertionException: Expected widget matching Key("email_input") to exist, but none was found.',
        stepResults: [
          StepExecutionResult.failed(
            stepId: 's1',
            description: 'Assert Key("email_input") exists',
            duration: const Duration(milliseconds: 50),
            errorMessage: 'Key("email_input") not found',
          ),
          StepExecutionResult.passed(
            stepId: 's2',
            description: 'Assert Key("password_input") exists',
            duration: const Duration(milliseconds: 30),
          ),
        ],
        screenshots: [
          ScenarioScreenshot(
            name: 'failure_step_s1',
            bytes: Uint8List.fromList([0, 1, 2, 3]),
            timestamp: DateTime.now(),
          ),
        ],
      );

      final passedResult = TestExecutionResult.passed(
        testId: 'test_dashboard',
        name: 'Dashboard KPI Verification',
        screen: 'Dashboard Screen',
        group: 'Analytics',
        duration: const Duration(milliseconds: 120),
        stepResults: [
          StepExecutionResult.passed(
            stepId: 's1',
            description: 'Assert KPI card is displayed',
            duration: const Duration(milliseconds: 40),
          ),
        ],
      );

      final summary = ScreenExecutionSummary.fromResults(
        executionMode: ExecutionMode.screen,
        screenName: 'Login Screen',
        startTime: DateTime.now().subtract(const Duration(seconds: 1)),
        endTime: DateTime.now(),
        results: [failedResult, passedResult],
      );

      store.recordSummary(summary);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScenarioReportsTab(reportStore: store),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header summary
      expect(find.text('Login Screen'), findsWidgets);
      expect(find.textContaining('1/2 Passed (50%)'), findsOneWidget);

      // Verify filter chips
      expect(find.byKey(const ValueKey('report_filter_all')), findsOneWidget);
      expect(find.byKey(const ValueKey('report_filter_failed')), findsOneWidget);
      expect(find.byKey(const ValueKey('report_filter_passed')), findsOneWidget);

      // Verify action buttons
      expect(find.byKey(const ValueKey('copy_json_report_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('copy_html_report_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('view_full_report_button')), findsOneWidget);

      // Both tests are initially visible under 'All'
      expect(find.text('Verify Login UI Elements'), findsOneWidget);
      expect(find.text('Dashboard KPI Verification'), findsOneWidget);

      // Filter by Failed
      await tester.tap(find.byKey(const ValueKey('report_filter_failed')));
      await tester.pumpAndSettle();

      expect(find.text('Verify Login UI Elements'), findsOneWidget);
      expect(find.text('Dashboard KPI Verification'), findsNothing);

      // Filter by Passed
      await tester.tap(find.byKey(const ValueKey('report_filter_passed')));
      await tester.pumpAndSettle();

      expect(find.text('Verify Login UI Elements'), findsNothing);
      expect(find.text('Dashboard KPI Verification'), findsOneWidget);

      // Switch back to All and expand failed test card
      await tester.tap(find.byKey(const ValueKey('report_filter_all')));
      await tester.pumpAndSettle();

      // Tap failed test card to expand
      await tester.tap(find.text('Verify Login UI Elements'));
      await tester.pumpAndSettle();

      // Verify error banner and steps
      expect(find.textContaining('Error: AssertionException: Expected widget matching'), findsOneWidget);
      expect(find.text('STEPS'), findsOneWidget);
      expect(find.text('Assert Key("email_input") exists'), findsOneWidget);
      expect(find.text('Assert Key("password_input") exists'), findsOneWidget);
      expect(find.text('SCREENSHOT'), findsOneWidget);
    });
  });
}
