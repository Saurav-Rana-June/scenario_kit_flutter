import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/scenario.dart';
import '../core/scenario_controller.dart';
import '../core/scenario_registry.dart';
import '../presentation/scenario_kit.dart';
import '../presentation/scenario_viewer.dart';

/// Extension methods on Flutter's [WidgetTester] to simplify testing UI scenarios.
extension ScenarioWidgetTesterExtensions on WidgetTester {
  /// Pumps a single [Scenario] wrapped in a test harness with [MaterialApp].
  Future<void> pumpScenario(
    Scenario scenario, {
    ThemeData? theme,
    Widget Function(Widget child)? wrapper,
  }) async {
    Widget content = ScenarioViewer(
      scenarios: [scenario],
    );

    if (wrapper != null) {
      content = wrapper(content);
    }

    await pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: content),
      ),
    );
    await pumpAndSettle();
  }

  /// Looks up scenario with [id] in [registry] and pumps it in a test harness.
  Future<void> pumpScenarioById({
    required ScenarioRegistry registry,
    required String id,
    ThemeData? theme,
    Widget Function(Widget child)? wrapper,
  }) async {
    final scenario = registry.requireById(id);
    await pumpScenario(
      scenario,
      theme: theme,
      wrapper: wrapper,
    );
  }

  /// Pumps a [ScenarioKit] instance inside [MaterialApp].
  Future<void> pumpScenarioKit(
    ScenarioKit scenarioKit, {
    ThemeData? theme,
  }) async {
    await pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: scenarioKit),
      ),
    );
    await pumpAndSettle();
  }

  /// Programmatically switches the active scenario on [controller] to [id]
  /// and settles animations.
  Future<void> switchScenario(
    ScenarioController controller,
    String id,
  ) async {
    controller.selectById(id);
    await pumpAndSettle();
  }
}
