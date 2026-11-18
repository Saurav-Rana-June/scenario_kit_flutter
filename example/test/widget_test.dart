import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/testing.dart';

void main() {
  group('Example App Scenario Tests', () {
    testWidgets('boots with default success scenario and displays products', (
      tester,
    ) async {
      await tester.pumpWidget(const ScenarioKitExampleApp());
      await tester.pumpAndSettle();

      // Default scenario is Success
      expect(find.text('GearStore'), findsOneWidget);
      expect(find.text('Wireless Noise-Canceling Headphones'), findsOneWidget);
      expect(find.text('\$299.99'), findsOneWidget);

      // ScenarioKit floating trigger should be present
      expect(find.byType(ScenarioFloatingTrigger), findsOneWidget);
    });

    testWidgets(
      'interactively switches to Empty and Error scenarios from debug panel',
      (tester) async {
        await tester.pumpWidget(const ScenarioKitExampleApp());
        await tester.pumpAndSettle();

        // Open ScenarioKit debug panel via floating trigger
        await tester.tap(
          find.byKey(const Key('scenario_floating_trigger_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ScenarioPanel), findsOneWidget);

        // Select Empty State
        await tester.ensureVisible(find.text('Empty State'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Empty State'));
        await tester.pumpAndSettle();

        // Close bottom sheet
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // Verify Empty State is active
        expect(find.text('No Products Found'), findsOneWidget);
        expect(find.text('Reset Filters'), findsOneWidget);

        // Re-open and filter to Server Error 500 via search bar
        await tester.tap(
          find.byKey(const Key('scenario_floating_trigger_button')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Error');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Server Error (500)'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // Verify Error State is active
        expect(find.text('Error 500'), findsOneWidget);
        expect(find.text('Retry Connection'), findsOneWidget);
      },
    );

    testWidgets('uses testing utilities to test a scenario in isolation', (
      tester,
    ) async {
      final offlineScenario = Scenario.offline(
        builder: (c) => const ProductCatalogScreen(
          products: mockOfflineProducts,
          isOffline: true,
        ),
      );

      // Using ScenarioKit's pumpScenario test extension
      await tester.pumpScenario(offlineScenario);

      expect(
        find.text('You are offline. Showing cached catalog.'),
        findsOneWidget,
      );
      expect(find.text('Wireless Noise-Canceling Headphones'), findsOneWidget);
    });

    testWidgets(
      'interactively switches to Test Mode and views registered test cases',
      (tester) async {
        registerExampleFunctionalTests();
        await tester.pumpWidget(const ScenarioKitExampleApp());
        await tester.pumpAndSettle();

        // Open ScenarioKit debug panel via floating trigger
        await tester.tap(
          find.byKey(const Key('scenario_floating_trigger_button')),
        );
        await tester.pumpAndSettle();

        // Switch to Test Mode tab
        await tester.tap(find.byKey(const ValueKey('panel_tab_tests')));
        await tester.pumpAndSettle();

        expect(find.byType(ScenarioTestDashboard), findsOneWidget);
        expect(find.text('Product Catalog'), findsWidgets);
        expect(find.text('Verify Header & Catalog Branding'), findsOneWidget);
      },
    );

    testWidgets(
      'executes functional tests on example app via ScenarioTestHarness',
      (tester) async {
        final registry = ScenarioTestRegistry();
        registerExampleFunctionalTests(registry);

        final suite = registry.suites.first;
        final summary = await ScenarioTestHarness.runSuite(
          tester,
          suite,
          pumpApp: () => tester.pumpWidget(const ScenarioKitExampleApp()),
          resetBetweenTests: true,
        );

        expect(summary, isExecutionSuccess);
        expect(summary, hasPassCount(3));
        expect(summary, hasFailCount(0));
      },
    );

    testWidgets(
      'executes network scenario tests with requiredScenarioId',
      (tester) async {
        final registry = ScenarioTestRegistry();
        registerExampleFunctionalTests(registry);

        final networkSuite = registry.getSuite('Network & Errors')!;
        final summary = await ScenarioTestHarness.runSuite(
          tester,
          networkSuite,
          pumpApp: () => tester.pumpWidget(const ScenarioKitExampleApp()),
          resetBetweenTests: true,
        );

        expect(summary, isExecutionSuccess);
        expect(summary, hasPassCount(2));
      },
    );
  });
}
