import 'package:flutter/widgets.dart';

import '../core/scenario.dart';
import '../core/scenario_controller.dart';
import '../presentation/scenario_scope.dart';
import '../utils/scenario_extensions.dart';
import 'scenario_state_adapter.dart';

/// Widget that derives a state object [T] from the active [Scenario]
/// and rebuilds whenever the scenario changes.
class ScenarioStateBuilder<T> extends StatelessWidget {
  /// Creates a [ScenarioStateBuilder].
  ///
  /// If [controller] is omitted, resolves from [ScenarioScope.of(context)].
  /// If [stateMapper] is omitted, extracts mock data of type [T] from the active scenario.
  const ScenarioStateBuilder({
    super.key,
    required this.builder,
    this.controller,
    this.stateMapper,
  });

  /// Builder invoked with the derived state [T] and [BuildContext].
  final Widget Function(BuildContext context, T? state) builder;

  /// Explicit controller. If omitted, resolves from [ScenarioScope.of(context)].
  final ScenarioController? controller;

  /// Function mapping a scenario into state [T]. Defaults to extracting mock data.
  final ScenarioStateMapper<T>? stateMapper;

  static T? _defaultMapper<T>(Scenario? scenario) {
    if (scenario == null) return null;
    return scenario.getMock<T>();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? ScenarioScope.of(context);
    final mapper = stateMapper ?? _defaultMapper<T>;

    return AnimatedBuilder(
      animation: effectiveController,
      builder: (context, _) {
        final state = mapper(effectiveController.selectedScenario);
        return builder(context, state);
      },
    );
  }
}
