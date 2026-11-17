import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioTestRunner Dual Execution Modes', () {
    late ScenarioTestRegistry registry;
    late ScenarioTestRunner runner;

    setUp(() {
      registry = ScenarioTestRegistry();
      runner = ScenarioTestRunner(registry: registry);
    });

    tearDown(() {
      ScenarioTestRegistry.resetInstance();
    });

    Widget buildTestApp() {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Dashboard', key: ValueKey('dashboard_title')),
          ),
        ),
      );
    }

    testWidgets('Mode A: runFunctionalityTest executes individual test',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      final element = tester.element(find.byType(Scaffold));

      final test1 = ScenarioTest(
        id: 'dash_01',
        name: 'Verify Title',
        screen: 'DashboardScreen',
        steps: [
          ScenarioTestStep.assertExists(
              StepFinder.byKeyString('dashboard_title')),
        ],
      );
      registry.registerTest(test1);

      final result = await runner.runFunctionalityTest(
        'dash_01',
        context: element,
      );

      expect(result.testId, 'dash_01');
      expect(result.isPassed, isTrue);
    });

    testWidgets('Mode A: runSelectedTests runs only selected subset in order',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      final element = tester.element(find.byType(Scaffold));

      final t1 = ScenarioTest(
        id: 't1',
        name: 'Test 1',
        screen: 'ScreenA',
        steps: [
          ScenarioTestStep.assertExists(
              StepFinder.byKeyString('dashboard_title')),
        ],
      );
      final t2 = ScenarioTest(
        id: 't2',
        name: 'Test 2 (unselected)',
        screen: 'ScreenA',
        steps: [
          ScenarioTestStep.assertExists(
              StepFinder.byKeyString('missing_widget')),
        ],
      );
      final t3 = ScenarioTest(
        id: 't3',
        name: 'Test 3',
        screen: 'ScreenB',
        steps: [
          ScenarioTestStep.assertExists(
              StepFinder.byKeyString('dashboard_title')),
        ],
      );

      registry.registerAllTests([t1, t2, t3]);

      // Only execute t3, then t1 (custom subset and order)
      final summary = await runner.runSelectedTests(
        ['t3', 't1'],
        context: element,
      );

      expect(summary.executionMode, ExecutionMode.functionality);
      expect(summary.totalTests, 2);
      expect(summary.results.map((r) => r.testId).toList(), ['t3', 't1']);
      expect(summary.isSuccess, isTrue);
      expect(summary.passedCount, 2);
      expect(summary.failedCount, 0);
    });

    testWidgets('Mode B: runScreenTests executes all tests for a given screen',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      final element = tester.element(find.byType(Scaffold));

      final suite = ScenarioTestSuite(
        screenName: 'LoginScreen',
        tests: [
          ScenarioTest(
            id: 'login_01',
            name: 'Check Header',
            steps: [
              ScenarioTestStep.assertExists(
                  StepFinder.byKeyString('dashboard_title')),
            ],
          ),
          ScenarioTest(
            id: 'login_02',
            name: 'Check Subtitle',
            steps: [
              ScenarioTestStep.assertExists(
                  StepFinder.byKeyString('dashboard_title')),
            ],
          ),
        ],
      );
      registry.registerSuite(suite);

      final summary = await runner.runScreenTests(
        'LoginScreen',
        context: element,
      );

      expect(summary.executionMode, ExecutionMode.screen);
      expect(summary.screenName, 'LoginScreen');
      expect(summary.totalTests, 2);
      expect(summary.passedCount, 2);
      expect(summary.isSuccess, isTrue);
    });

    testWidgets('Mode B: runScreenTests with group filter executes group only',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      final element = tester.element(find.byType(Scaffold));

      final suite = ScenarioTestSuite(
        screenName: 'SettingsScreen',
        tests: [
          ScenarioTest(
            id: 'set_auth_01',
            name: 'Auth Setting',
            group: 'Security',
            steps: [
              ScenarioTestStep.assertExists(
                  StepFinder.byKeyString('dashboard_title')),
            ],
          ),
          ScenarioTest(
            id: 'set_pref_01',
            name: 'Theme Setting',
            group: 'Preferences',
            steps: [
              ScenarioTestStep.assertExists(
                  StepFinder.byKeyString('dashboard_title')),
            ],
          ),
        ],
      );
      registry.registerSuite(suite);

      final summary = await runner.runScreenTests(
        'SettingsScreen',
        group: 'Security',
        context: element,
      );

      expect(summary.totalTests, 1);
      expect(summary.results.first.testId, 'set_auth_01');
      expect(summary.passedCount, 1);
    });

    testWidgets('progressNotifier emits updates throughout test run',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      final element = tester.element(find.byType(Scaffold));

      final progressSnapshots = <TestExecutionProgress>[];
      runner.progressNotifier.addListener(() {
        progressSnapshots.add(runner.progressNotifier.value);
      });

      final test1 = ScenarioTest(
        id: 'prog_01',
        name: 'Progress Check',
        screen: 'ScreenA',
        steps: [
          ScenarioTestStep.assertExists(
              StepFinder.byKeyString('dashboard_title')),
        ],
      );
      registry.registerTest(test1);

      await runner.runFunctionalityTest('prog_01', context: element);

      expect(progressSnapshots.isNotEmpty, isTrue);
      expect(progressSnapshots.any((p) => p.isRunning), isTrue);
      expect(progressSnapshots.last.isRunning, isFalse);
    });
  });
}
