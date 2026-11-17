import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/testing.dart';

void main() {
  group('Scenario Testing Utilities', () {
    late ScenarioRegistry registry;
    late Scenario sLoading;
    late Scenario sSuccess;

    setUp(() {
      sLoading = Scenario.loading(
        id: 'loading',
        group: 'Product',
        builder: (c) => const Text('Loading Product View'),
      );
      sSuccess = Scenario.success(
        id: 'success',
        group: 'Product',
        isDefault: true,
        builder: (c) => const Text('Success Product View'),
      );

      registry = ScenarioRegistry([sLoading, sSuccess]);
    });

    tearDown(() {
      registry.dispose();
    });

    test('scenario matchers verify registry configurations', () {
      expect(registry, containsScenario('loading'));
      expect(registry, containsScenario('success'));
      expect(registry, isNot(containsScenario('unknown_id')));

      expect(registry, hasDefaultScenario('success'));
      expect(registry, isNot(hasDefaultScenario('loading')));

      expect(registry, containsScenarioGroup('Product'));
      expect(registry, isNot(containsScenarioGroup('NonExistentGroup')));

      // Matcher also works on List<Scenario>
      expect(registry.scenarios, containsScenario('loading'));
    });

    testWidgets('pumpScenario renders scenario directly', (tester) async {
      await tester.pumpScenario(sLoading);

      expect(find.text('Loading Product View'), findsOneWidget);
    });

    testWidgets('pumpScenarioById resolves and renders scenario from registry',
        (tester) async {
      await tester.pumpScenarioById(
        registry: registry,
        id: 'success',
      );

      expect(find.text('Success Product View'), findsOneWidget);
    });

    testWidgets('switchScenario helper switches scenario and settles',
        (tester) async {
      final controller = ScenarioController(registry: registry);

      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioViewer(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Success Product View'), findsOneWidget);

      await tester.switchScenario(controller, 'loading');

      expect(find.text('Loading Product View'), findsOneWidget);
      expect(find.text('Success Product View'), findsNothing);

      controller.dispose();
    });

    testWidgets('pumpScenarioKit renders full ScenarioKit harness',
        (tester) async {
      await tester.pumpScenarioKit(
        ScenarioKit(
          scenarios: [sSuccess],
        ),
      );

      expect(find.text('Success Product View'), findsOneWidget);
      expect(find.byType(ScenarioFloatingTrigger), findsOneWidget);
    });
  });
}
