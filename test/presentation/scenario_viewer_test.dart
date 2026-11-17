import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioViewer Widget Tests', () {
    testWidgets('renders default scenario widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioViewer(
            scenarios: [
              Scenario(
                id: 'loading',
                name: 'Loading State',
                builder: (context) => const Text('Loading Spinner View'),
              ),
              Scenario(
                id: 'success',
                name: 'Success State',
                isDefault: true,
                builder: (context) => const Text('Success Product List View'),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Success Product List View'), findsOneWidget);
      expect(find.text('Loading Spinner View'), findsNothing);
    });

    testWidgets('switches between scenarios reactively with animation',
        (tester) async {
      final controller = ScenarioController.fromScenarios([
        Scenario(
          id: 'loading',
          name: 'Loading State',
          builder: (context) => const Text('State: Loading'),
        ),
        Scenario(
          id: 'error',
          name: 'Error State',
          builder: (context) => const Text('State: Error'),
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioViewer(
            controller: controller,
            animationDuration: const Duration(milliseconds: 100),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('State: Loading'), findsOneWidget);
      expect(find.text('State: Error'), findsNothing);

      // Switch scenario
      controller.selectById('error');
      await tester.pump(); // start animation
      await tester.pumpAndSettle(); // finish animation

      expect(find.text('State: Error'), findsOneWidget);
      expect(find.text('State: Loading'), findsNothing);

      controller.dispose();
    });

    testWidgets('renders custom emptyBuilder when no scenarios exist',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioViewer(
            scenarios: const [],
            emptyBuilder: (context) => const Text('Custom Empty Placeholder'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Custom Empty Placeholder'), findsOneWidget);
    });

    testWidgets('renders default fallback empty view when no scenarios exist',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScenarioViewer(
            scenarios: [],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Scenario Available'), findsOneWidget);
    });

    testWidgets('provides ScenarioScope down the tree to access controller',
        (tester) async {
      late ScenarioController capturedController;

      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioViewer(
            scenarios: [
              Scenario(
                id: 'view_a',
                name: 'View A',
                builder: (context) {
                  capturedController = ScenarioScope.of(context);
                  return const Text('View A Content');
                },
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(capturedController.selectedId, 'view_a');
      expect(find.text('View A Content'), findsOneWidget);
    });

    testWidgets('respects initialScenarioId parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioViewer(
            initialScenarioId: 'two',
            scenarios: [
              Scenario(
                id: 'one',
                name: 'One',
                isDefault: true,
                builder: (context) => const Text('Screen One'),
              ),
              Scenario(
                id: 'two',
                name: 'Two',
                builder: (context) => const Text('Screen Two'),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Screen Two'), findsOneWidget);
      expect(find.text('Screen One'), findsNothing);
    });
  });
}
