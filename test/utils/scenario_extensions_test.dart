import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('Scenario Extensions', () {
    test('retrieves typed mock data directly or from MockData container', () {
      final scenario = Scenario(
        name: 'Mock Test',
        metadata: const {
          'mock_data': MockData<List<String>>.value(['x', 'y']),
          'raw_number': 42,
          'simulated_delay': Duration(milliseconds: 200),
        },
        builder: (c) => const SizedBox(),
      );

      expect(scenario.hasMock(), isTrue);
      expect(scenario.getMock<List<String>>(), ['x', 'y']);
      expect(scenario.getMock<int>('raw_number'), 42);
      expect(scenario.getMock<String>('missing'), isNull);
      expect(scenario.simulatedDelay, const Duration(milliseconds: 200));

      final container = scenario.getMockContainer<List<String>>();
      expect(container, isNotNull);
      expect(container?.value, ['x', 'y']);
    });

    testWidgets(
        'BuildContext extension provides scenarioController and currentScenario',
        (tester) async {
      late ScenarioController capturedController;
      late Scenario? capturedScenario;

      final scenario = Scenario(
        id: 'home',
        name: 'Home',
        builder: (context) {
          capturedController = context.scenarioController;
          capturedScenario = context.currentScenario;
          return const Text('Home View');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioViewer(
            scenarios: [scenario],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(capturedController.selectedId, 'home');
      expect(capturedScenario?.id, 'home');
    });
  });
}
