import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

void main() {
  group('ScenarioKit Developer Container Tests', () {
    testWidgets('renders ScenarioViewer when child is omitted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioKit(
            scenarios: [
              Scenario(
                id: 'home',
                name: 'Home Screen',
                builder: (c) => const Text('Scenario Content Here'),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Scenario Content Here'), findsOneWidget);
      expect(find.byType(ScenarioFloatingTrigger), findsOneWidget);
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('renders wrapped child when child is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioKit(
            scenarios: [
              Scenario(
                id: 'test',
                name: 'Test Scenario',
                builder: (c) => const Text('Preview Content'),
              ),
            ],
            child: const Text('Production App Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Production App Content'), findsOneWidget);
      expect(find.byType(ScenarioFloatingTrigger), findsOneWidget);
    });

    testWidgets('hides floating trigger when enabled is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScenarioKit(
            enabled: false,
            child: Text('Production Screen'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Production Screen'), findsOneWidget);
      expect(find.byType(ScenarioFloatingTrigger), findsNothing);
    });

    testWidgets(
        'floating trigger opens ScenarioPanel bottom sheet and switches scenario',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioKit(
            scenarios: [
              Scenario(
                id: 'screen_a',
                name: 'Screen A',
                builder: (c) => const Text('Screen A Active'),
              ),
              Scenario(
                id: 'screen_b',
                name: 'Screen B',
                builder: (c) => const Text('Screen B Active'),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Screen A Active'), findsOneWidget);

      // Tap floating trigger
      await tester
          .tap(find.byKey(const Key('scenario_floating_trigger_button')));
      await tester.pumpAndSettle();

      // Panel is now displayed as bottom sheet
      expect(find.byType(ScenarioPanel), findsOneWidget);
      expect(find.text('Screen B'), findsOneWidget);

      // Tap Screen B to switch
      await tester.tap(find.text('Screen B'));
      await tester.pumpAndSettle();

      // Close sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Screen B is now active
      expect(find.text('Screen B Active'), findsOneWidget);
      expect(find.text('Screen A Active'), findsNothing);
    });
  });
}
