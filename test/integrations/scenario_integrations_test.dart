import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

sealed class TestState {
  const TestState();
}

class TestLoadingState extends TestState {
  const TestLoadingState();
}

class TestSuccessState extends TestState {
  const TestSuccessState(this.data);
  final List<String> data;
}

void main() {
  group('Scenario Framework Integrations', () {
    late Scenario loadingScenario;
    late Scenario successScenario;
    late ScenarioController controller;

    setUp(() {
      loadingScenario = Scenario.loading(
        id: 'loading',
        metadata: const {
          ScenarioMockExtensions.defaultMockKey: TestLoadingState(),
        },
        builder: (c) => const SizedBox(),
      );

      successScenario = Scenario.success(
        id: 'success',
        metadata: const {
          ScenarioMockExtensions.defaultMockKey:
              TestSuccessState(['item1', 'item2']),
        },
        builder: (c) => const SizedBox(),
      );

      controller = ScenarioController.fromScenarios([
        loadingScenario,
        successScenario,
      ]);
    });

    tearDown(() {
      controller.dispose();
    });

    test('ScenarioStateAdapter emits derived states and notifies listeners',
        () {
      final adapter = ScenarioStateAdapter<TestState>(
        controller: controller,
      );

      // Initially on default scenario (successScenario has isDefault: true)
      expect(adapter.value, isA<TestSuccessState>());
      expect((adapter.value as TestSuccessState).data, ['item1', 'item2']);

      var notifications = 0;
      adapter.addListener(() => notifications++);

      // Switch to loading
      controller.selectById('loading');

      expect(adapter.value, isA<TestLoadingState>());
      expect(notifications, 1);

      adapter.dispose();
    });

    test('ScenarioStateAdapter supports custom stateMapper', () {
      final adapter = ScenarioStateAdapter<String>(
        controller: controller,
        stateMapper: (scenario) => 'state_${scenario?.id}',
      );

      expect(adapter.value, 'state_success');

      controller.selectById('loading');
      expect(adapter.value, 'state_loading');

      adapter.dispose();
    });

    testWidgets(
        'ScenarioStateBuilder rebuilds reactively with new mapped state',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioScope(
            controller: controller,
            child: ScenarioStateBuilder<TestState>(
              builder: (context, state) {
                if (state is TestLoadingState) {
                  return const Text('State: Loading');
                }
                if (state is TestSuccessState) {
                  return Text('State: Success (${state.data.length})');
                }
                return const Text('State: Unknown');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('State: Success (2)'), findsOneWidget);

      // Change scenario via controller
      controller.selectById('loading');
      await tester.pumpAndSettle();

      expect(find.text('State: Loading'), findsOneWidget);
      expect(find.text('State: Success (2)'), findsNothing);
    });
  });
}
