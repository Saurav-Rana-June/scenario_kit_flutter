import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioController', () {
    late Scenario s1;
    late Scenario s2;
    late Scenario sDefault;

    setUp(() {
      s1 = Scenario(
          id: 's1', name: 'Scenario 1', builder: (c) => const SizedBox());
      s2 = Scenario(
          id: 's2', name: 'Scenario 2', builder: (c) => const SizedBox());
      sDefault = Scenario(
        id: 's_def',
        name: 'Default Scenario',
        isDefault: true,
        builder: (c) => const SizedBox(),
      );
    });

    test('initializes with default scenario if no initial id is given', () {
      final controller = ScenarioController.fromScenarios([s1, sDefault, s2]);

      expect(controller.selectedScenario, sDefault);
      expect(controller.selectedId, 's_def');
      expect(controller.isSelected(sDefault), isTrue);
      expect(controller.isSelectedId('s_def'), isTrue);
      expect(controller.isSelected(s1), isFalse);

      controller.dispose();
    });

    test('initializes with initialScenarioId if provided and available', () {
      final controller = ScenarioController.fromScenarios(
        [s1, sDefault, s2],
        initialScenarioId: 's2',
      );

      expect(controller.selectedScenario, s2);
      expect(controller.selectedId, 's2');
      controller.dispose();
    });

    test('selects scenario and notifies listeners', () {
      final controller = ScenarioController.fromScenarios([s1, s2]);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.selectById('s2');

      expect(controller.selectedScenario, s2);
      expect(notifications, 1);

      // Selecting already selected does not notify again
      controller.selectById('s2');
      expect(notifications, 1);

      controller.dispose();
    });

    test('select registers unknown scenario automatically', () {
      final controller = ScenarioController.fromScenarios([s1]);
      final newScenario =
          Scenario(id: 's_new', name: 'New', builder: (c) => const SizedBox());

      controller.select(newScenario);

      expect(controller.registry.hasScenario('s_new'), isTrue);
      expect(controller.selectedScenario, newScenario);

      controller.dispose();
    });

    test(
        'trySelectById returns true for existing scenario and false for unknown',
        () {
      final controller = ScenarioController.fromScenarios([s1]);

      expect(controller.trySelectById('s1'), isTrue);
      expect(controller.trySelectById('non_existent'), isFalse);

      controller.dispose();
    });

    test(
        'selectById throws ScenarioNotFoundException for non-existent scenario',
        () {
      final controller = ScenarioController.fromScenarios([s1]);

      expect(
        () => controller.selectById('unknown'),
        throwsA(isA<ScenarioNotFoundException>()),
      );

      controller.dispose();
    });

    test('resetToDefault restores default scenario', () {
      final controller = ScenarioController.fromScenarios([s1, sDefault, s2]);
      controller.selectById('s2');
      expect(controller.selectedScenario, s2);

      controller.resetToDefault();
      expect(controller.selectedScenario, sDefault);

      controller.dispose();
    });

    test('adapts when active scenario is unregistered from registry', () {
      final registry = ScenarioRegistry([s1, sDefault, s2]);
      final controller = ScenarioController(registry: registry);

      controller.selectById('s2');
      expect(controller.selectedScenario, s2);

      // Remove s2 from registry
      registry.unregister('s2');

      // Controller should fall back to default scenario
      expect(controller.selectedScenario, sDefault);

      controller.dispose();
      registry.dispose();
    });

    test('adapts when active scenario is updated in registry', () {
      final registry = ScenarioRegistry([s1]);
      final controller = ScenarioController(registry: registry);

      expect(controller.selectedScenario?.name, 'Scenario 1');

      // Update scenario in registry
      final updatedS1 = s1.copyWith(name: 'Scenario 1 Updated');
      registry.unregister('s1');
      registry.register(updatedS1);

      expect(controller.selectedScenario?.name, 'Scenario 1 Updated');

      controller.dispose();
      registry.dispose();
    });
  });
}
