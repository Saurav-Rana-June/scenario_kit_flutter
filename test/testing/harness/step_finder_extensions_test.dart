import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenario_kit_flutter/testing.dart';

void main() {
  group('StepFinderWidgetTesterExtension', () {
    testWidgets('converts byKey to KeyFinder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Hello', key: Key('test_key')),
          ),
        ),
      );

      final stepFinder = StepFinder.byKey(const Key('test_key'));
      final flutterFinder = stepFinder.toWidgetTesterFinder();

      expect(flutterFinder, findsOneWidget);
    });

    testWidgets('converts byText to textContaining finder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Hello World'),
          ),
        ),
      );

      final stepFinder = StepFinder.byText('World');
      final flutterFinder = stepFinder.toWidgetTesterFinder();

      expect(flutterFinder, findsOneWidget);
    });

    testWidgets('converts byWidgetType to TypeFinder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: null,
              child: Text('Submit'),
            ),
          ),
        ),
      );

      final stepFinder = StepFinder.byWidgetType(ElevatedButton);
      final flutterFinder = stepFinder.toWidgetTesterFinder();

      expect(flutterFinder, findsOneWidget);
    });

    testWidgets('converts byTooltip to TooltipFinder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Tooltip(
              message: 'Settings Tooltip',
              child: Icon(Icons.settings),
            ),
          ),
        ),
      );

      final stepFinder = StepFinder.byTooltip('Settings Tooltip');
      final flutterFinder = stepFinder.toWidgetTesterFinder();

      expect(flutterFinder, findsOneWidget);
    });

    testWidgets('converts byIcon to IconFinder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Icon(Icons.star),
          ),
        ),
      );

      final stepFinder = StepFinder.byIcon(Icons.star);
      final flutterFinder = stepFinder.toWidgetTesterFinder();

      expect(flutterFinder, findsOneWidget);
    });

    testWidgets('converts custom predicate StepFinder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Custom Target', semanticsLabel: 'unique_semantic'),
          ),
        ),
      );

      final stepFinder = StepFinder.custom(
        (element) =>
            element.widget is Text &&
            (element.widget as Text).semanticsLabel == 'unique_semantic',
        description: 'Semantic label finder',
      );
      final flutterFinder = stepFinder.toWidgetTesterFinder();

      expect(flutterFinder, findsOneWidget);
    });
  });
}
