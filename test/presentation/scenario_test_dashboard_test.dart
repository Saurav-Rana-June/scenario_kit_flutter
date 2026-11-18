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

    Widget buildDashboardApp({ScenarioTestRegistry? reg}) {
      return MaterialApp(
        home: Scaffold(
          body: ScenarioTestDashboard(
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

      expect(find.text('Test Mode'), findsOneWidget);
      expect(find.text('Valid Login'), findsOneWidget);
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('LoginScreen'), findsOneWidget);
      expect(find.text('Auth'), findsWidgets);
      expect(find.text('Recovery'), findsWidgets);
      expect(find.byKey(const ValueKey('run_all_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('run_selected_button')), findsOneWidget);
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

      expect(find.text('Email Format Validation'), findsOneWidget);
      expect(find.text('Password Strength Check'), findsOneWidget);

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

      expect(find.text('Select All (0/2)'), findsOneWidget);

      // Tap select all
      await tester.tap(find.byKey(const ValueKey('select_all_checkbox')));
      await tester.pumpAndSettle();

      expect(find.text('Select All (2/2)'), findsOneWidget);
      expect(find.text('Run Selected (2)'), findsOneWidget);

      // Tap again to deselect
      await tester.tap(find.byKey(const ValueKey('select_all_checkbox')));
      await tester.pumpAndSettle();

      expect(find.text('Select All (0/2)'), findsOneWidget);
    });

    testWidgets('executes single test and triggers View Report dialog',
        (tester) async {
      final test1 = ScenarioTest(
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
      );
      registry.registerTest(test1);

      await tester.pumpWidget(buildDashboardApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('view_report_button')), findsNothing);

      // Run single test
      await tester.tap(find.byKey(const ValueKey('run_single_t_single')));
      await tester.pumpAndSettle();

      // View Report button should now appear
      expect(find.byKey(const ValueKey('view_report_button')), findsOneWidget);

      // Tap View Report
      await tester.tap(find.byKey(const ValueKey('view_report_button')));
      await tester.pumpAndSettle();

      expect(find.text('In-App Test Report'), findsOneWidget);
      expect(find.text('Single Unit Verification'), findsWidgets);
    });

    testWidgets(
        'ScenarioPanel switches seamlessly between Scenarios and Test Mode',
        (tester) async {
      final scenario = Scenario(
        name: 'Default Screen',
        builder: (_) => const Text('Screen Content'),
      );
      final controller =
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
              controller: controller,
              testRegistry: registry,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Scenarios tab
      expect(find.text('Default Screen'), findsOneWidget);
      expect(find.byKey(const ValueKey('panel_tab_tests')), findsOneWidget);

      // Switch to Tests tab
      await tester.tap(find.byKey(const ValueKey('panel_tab_tests')));
      await tester.pumpAndSettle();

      expect(find.text('Test Mode'), findsOneWidget);
      expect(find.text('Panel Test Case'), findsOneWidget);

      // Switch back to Scenarios tab
      await tester.tap(find.byKey(const ValueKey('panel_tab_scenarios')));
      await tester.pumpAndSettle();

      expect(find.text('Default Screen'), findsOneWidget);
    });

    testWidgets('auto-selects active screen when currentScreenName is set',
        (tester) async {
      registry.registerTest(
        ScenarioTest(id: 'dash_t', name: 'Dashboard Test', screen: 'Dashboard Screen'),
      );
      registry.registerTest(
        ScenarioTest(id: 'login_t', name: 'Login Test', screen: 'Login Screen'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScenarioTestDashboard(
              registry: registry,
              currentScreenName: 'Dashboard Screen',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Test'), findsOneWidget);
      expect(find.text('Login Test'), findsNothing);
      expect(find.text('(Active)'), findsOneWidget);
    });

    testWidgets('shows mismatch banner and invokes onNavigateToScreen',
        (tester) async {
      registry.registerTest(
        ScenarioTest(id: 'dash_t', name: 'Dashboard Test', screen: 'Dashboard Screen'),
      );
      registry.registerTest(
        ScenarioTest(id: 'login_t', name: 'Login Test', screen: 'Login Screen'),
      );

      String? navigatedTo;
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScenarioTestDashboard(
              registry: registry,
              currentScreenName: 'Dashboard Screen',
              onNavigateToScreen: (name) => navigatedTo = name,
              onClose: () => closed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Login Screen'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('You are currently viewing "Dashboard Screen"'),
        findsOneWidget,
      );

      await tester.tap(find.text('Go to Screen'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(navigatedTo, 'Login Screen');
    });
  });
}
