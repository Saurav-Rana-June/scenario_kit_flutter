import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioTestDashboard Widget Tests', () {
    late ScenarioTestRegistry registry;

    setUp(() {
      registry = ScenarioTestRegistry();
    });

    tearDown(() {
      ScenarioTestRegistry.resetInstance();
    });

    Widget buildDashboardApp({ScenarioTestRegistry? reg, ScenarioTestDashboard? dashboard}) {
      return MaterialApp(
        home: Scaffold(
          body: dashboard ??
              ScenarioTestDashboard(
                registry: reg ?? registry,
              ),
        ),
      );
    }

    testWidgets('renders test list, screen filters, and action controls',
        (tester) async {
      registry.registerTest(
        ScenarioTest(
          id: 'test_1',
          name: 'Valid Login',
          screen: 'LoginScreen',
          group: 'Auth',
          steps: [
            ScenarioTestStep.assertExists(StepFinder.byKeyString('dummy')),
          ],
        ),
      );
      registry.registerTest(
        ScenarioTest(
          id: 'test_2',
          name: 'Reset Password',
          screen: 'LoginScreen',
          group: 'Recovery',
          steps: [
            ScenarioTestStep.assertExists(StepFinder.byKeyString('dummy')),
          ],
        ),
      );

      await tester.pumpWidget(buildDashboardApp());
      await tester.pumpAndSettle();

      expect(find.text('Valid Login'), findsOneWidget);
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('LoginScreen'), findsWidgets);
      expect(find.text('Auth'), findsWidgets);
      expect(find.text('Recovery'), findsWidgets);
      expect(find.text('Run all'), findsOneWidget);
      expect(find.textContaining('Run selected'), findsOneWidget);
    });

    testWidgets('filters test cases via search input', (tester) async {
      registry.registerTest(
        ScenarioTest(
          id: 't_email',
          name: 'Email Format Validation',
          screen: 'AuthScreen',
        ),
      );
      registry.registerTest(
        ScenarioTest(
          id: 't_pass',
          name: 'Password Strength Check',
          screen: 'AuthScreen',
        ),
      );

      await tester.pumpWidget(buildDashboardApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'strength');
      await tester.pumpAndSettle();

      expect(find.text('Email Format Validation'), findsNothing);
      expect(find.text('Password Strength Check'), findsOneWidget);
    });

    testWidgets('select all checkbox toggles selection state', (tester) async {
      registry.registerTest(
        ScenarioTest(id: 't1', name: 'Test 1', screen: 'ScreenA'),
      );
      registry.registerTest(
        ScenarioTest(id: 't2', name: 'Test 2', screen: 'ScreenA'),
      );

      await tester.pumpWidget(buildDashboardApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Select all (0/2)'), findsOneWidget);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Select all (2/2)'), findsOneWidget);
      expect(find.textContaining('Run selected (2)'), findsOneWidget);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Select all (0/2)'), findsOneWidget);
    });

    testWidgets('executes single test via per-tile run', (tester) async {
      registry.registerTest(
        ScenarioTest(
          id: 't_single',
          name: 'Single Unit Verification',
          screen: 'HomeScreen',
          steps: [
            ScenarioTestStep.custom(
              id: 'c1',
              description: 'Simple success',
              action: (_) async {},
            ),
          ],
        ),
      );

      await tester.pumpWidget(buildDashboardApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Run this test'));
      await tester.pumpAndSettle();

      expect(find.text('PASSED'), findsOneWidget);
    });

    testWidgets(
        'ScenarioPanel switches seamlessly between Scenarios and Test Mode',
        (tester) async {
      final scenario = Scenario(
        name: 'Default Screen',
        builder: (_) => const Text('Screen Content'),
      );
      final scenarioController =
          ScenarioController(registry: ScenarioRegistry([scenario]));

      registry.registerTest(
        ScenarioTest(
          id: 'test_panel_integration',
          name: 'Panel Test Case',
          screen: 'Default Screen',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScenarioPanel(
              controller: scenarioController,
              testRegistry: registry,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Default Screen'), findsOneWidget);

      await tester.tap(find.byKey(const Key('panel_tab_tests')));
      await tester.pumpAndSettle();

      expect(find.text('Panel Test Case'), findsOneWidget);

      await tester.tap(find.byKey(const Key('panel_tab_scenarios')));
      await tester.pumpAndSettle();

      expect(find.text('Default Screen'), findsOneWidget);

      scenarioController.dispose();
    });

    testWidgets('pre-selects active screen filter chip', (tester) async {
      registry.registerTest(
        ScenarioTest(id: 'dash_t', name: 'Dashboard Test', screen: 'Dashboard Screen'),
      );
      registry.registerTest(
        ScenarioTest(id: 'login_t', name: 'Login Test', screen: 'Login Screen'),
      );

      await tester.pumpWidget(
        buildDashboardApp(
          dashboard: ScenarioTestDashboard(
            registry: registry,
            currentScreenName: 'Dashboard Screen',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Test'), findsOneWidget);
      expect(find.text('Login Test'), findsNothing);
    });

    testWidgets('shows mismatch dialog when running on wrong screen',
        (tester) async {
      registry.registerTest(
        ScenarioTest(id: 'login_t', name: 'Login Test', screen: 'Login Screen'),
      );

      await tester.pumpWidget(
        buildDashboardApp(
          dashboard: ScenarioTestDashboard(
            registry: registry,
            currentScreenName: 'Dashboard Screen',
            onNavigateToScreen: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Run this test'));
      await tester.pumpAndSettle();

      expect(find.text('Switch Screen to Run Test'), findsOneWidget);
    });
  });
}