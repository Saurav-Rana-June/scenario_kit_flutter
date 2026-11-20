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
      expect(find.byKey(const Key('go_to_tests_tab_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('go_to_tests_tab_button')));
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
            duration: Duration.zero,
            errorMessage: 'not found',
          ),
          StepExecutionResult.skipped(
            stepId: 's2',
            description: 'Assert Key("password_input") exists',
          ),
        ],
        screenshots: [
          ScenarioScreenshot(
            name: 'failure',
            bytes: Uint8List.fromList([1, 2, 3]),
            timestamp: DateTime.now(),
          ),
        ],
      );

      final passedResult = TestExecutionResult.passed(
        testId: 'test_kpi',
        name: 'Dashboard KPI Verification',
        screen: 'Login Screen',
        duration: const Duration(milliseconds: 120),
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

      expect(find.textContaining('1/2'), findsOneWidget);
      expect(find.text('1 test failed'), findsOneWidget);

      expect(find.byKey(const Key('report_filter_failed')), findsOneWidget);
      expect(find.byKey(const Key('report_filter_passed')), findsOneWidget);

      expect(find.text('Export HTML'), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);

      expect(find.text('Verify Login UI Elements'), findsOneWidget);
      expect(find.text('Dashboard KPI Verification'), findsOneWidget);

      await tester.tap(find.byKey(const Key('report_filter_failed')));
      await tester.pumpAndSettle();

      expect(find.text('Verify Login UI Elements'), findsOneWidget);
      expect(find.text('Dashboard KPI Verification'), findsNothing);

      await tester.tap(find.byKey(const Key('report_filter_passed')));
      await tester.pumpAndSettle();

      expect(find.text('Verify Login UI Elements'), findsNothing);
      expect(find.text('Dashboard KPI Verification'), findsOneWidget);

      await tester.tap(find.byKey(const Key('report_filter_all')));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Verify Login UI Elements'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('AssertionException: Expected widget matching'),
        findsOneWidget,
      );
      expect(find.text('Assert Key("email_input") exists'), findsOneWidget);
      expect(find.text('View screenshot'), findsOneWidget);
    });
  });
}