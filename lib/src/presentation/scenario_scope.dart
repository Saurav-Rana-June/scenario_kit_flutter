import 'package:flutter/widgets.dart';

import '../core/scenario.dart';
import '../core/scenario_controller.dart';

/// Provides a [ScenarioController] down the widget tree without coupling rebuilds
/// to [ScenarioController] notifications (use [AnimatedBuilder] for reactive UI).
class ScenarioScope extends InheritedWidget {
  /// Creates a [ScenarioScope].
  const ScenarioScope({
    super.key,
    required this.controller,
    required super.child,
  });

  /// The provided [ScenarioController].
  final ScenarioController controller;

  /// Returns the closest [ScenarioController] ancestor in the widget tree,
  /// or throws a [FlutterError] if not found.
  static ScenarioController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(() {
      if (controller == null) {
        throw FlutterError(
          'ScenarioScope.of() called with a context that does not contain a ScenarioScope.\n'
          'No ScenarioScope ancestor could be found starting from the context that was passed to '
          'ScenarioScope.of(). Ensure that the widget is enclosed within a ScenarioScope or ScenarioViewer.',
        );
      }
      return true;
    }());
    return controller!;
  }

  /// Returns the closest [ScenarioController] ancestor in the widget tree,
  /// or `null` if none is found.
  static ScenarioController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ScenarioScope>()
        ?.controller;
  }

  /// Convenience accessor returning the currently selected [Scenario] from the
  /// closest ancestor [ScenarioScope], or `null`.
  static Scenario? selectedScenarioOf(BuildContext context) {
    return maybeOf(context)?.selectedScenario;
  }

  @override
  bool updateShouldNotify(covariant ScenarioScope oldWidget) {
    return oldWidget.controller != controller;
  }
}
