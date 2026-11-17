import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioPanel Widget Tests', () {
    late ScenarioController controller;

    setUp(() {
      controller = ScenarioController.fromScenarios([
        Scenario(
          id: 'auth_login',
          name: 'Login Screen',
          description: 'Standard login view with fields',
          group: 'Auth',
          isDefault: true,
          metadata: const {'user_id': 123},
          builder: (c) => const Text('Login'),
        ),
        Scenario(
          id: 'auth_error',
          name: 'Login Error',
          description: 'Login failed invalid credentials',
          group: 'Auth',
          builder: (c) => const Text('Login Error'),
        ),
        Scenario(
          id: 'feed_empty',
          name: 'Empty Feed',
          description: 'Feed with no posts',
          group: 'Feed',
          builder: (c) => const Text('Empty Feed'),
        ),
      ]);
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders all scenarios and group filter chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScenarioPanel(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
      expect(find.text('Login Error'), findsOneWidget);
      expect(find.text('Empty Feed'), findsOneWidget);

      expect(find.byKey(const ValueKey('filter_chip_All')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_chip_Auth')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_chip_Feed')), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);
    });

    testWidgets('filters scenarios via search bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScenarioPanel(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Feed');
      await tester.pumpAndSettle();

      expect(find.text('Empty Feed'), findsOneWidget);
      expect(find.text('Login Screen'), findsNothing);
      expect(find.text('Login Error'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
      expect(find.text('Empty Feed'), findsOneWidget);
    });

    testWidgets('filters scenarios by tapping group chip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScenarioPanel(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Auth' group chip
      await tester.tap(find.byKey(const ValueKey('filter_chip_Auth')));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
      expect(find.text('Login Error'), findsOneWidget);
      expect(find.text('Empty Feed'), findsNothing);

      // Tap 'All' group chip
      await tester.tap(find.byKey(const ValueKey('filter_chip_All')));
      await tester.pumpAndSettle();

      expect(find.text('Empty Feed'), findsOneWidget);
    });

    testWidgets('selects scenario on tapping card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScenarioPanel(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(controller.selectedId, 'auth_login');

      // Tap Login Error card
      await tester.tap(find.text('Login Error'));
      await tester.pumpAndSettle();

      expect(controller.selectedId, 'auth_error');
    });

    testWidgets('resets to default scenario via header reset button',
        (tester) async {
      controller.selectById('feed_empty');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScenarioPanel(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(controller.selectedId, 'feed_empty');

      await tester.tap(find.byIcon(Icons.restart_alt_rounded));
      await tester.pumpAndSettle();

      expect(controller.selectedId, 'auth_login');
    });

    testWidgets('opens metadata dialog when metadata chip is clicked',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScenarioPanel(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('meta (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen Metadata'), findsOneWidget);
      expect(find.textContaining('123'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen Metadata'), findsNothing);
    });
  });
}
