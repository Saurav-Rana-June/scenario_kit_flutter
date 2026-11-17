import 'package:flutter/widgets.dart';

import '../core/scenario.dart';
import '../core/scenario_controller.dart';

/// Provides a [ScenarioController] down the widget tree.
class ScenarioScope extends InheritedNotifier<ScenarioController> {
  /// Creates a [ScenarioScope].
  const ScenarioScope({
    super.key,
    required ScenarioController super.notifier,
    required super.child,
  });

  /// The provided [ScenarioController].
  ScenarioController get controller => notifier!;

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
        ?.notifier;
  }

  /// Convenience accessor returning the currently selected [Scenario] from the
  /// closest ancestor [ScenarioScope], or `null`.
  static Scenario? selectedScenarioOf(BuildContext context) {
    return maybeOf(context)?.selectedScenario;
  }
}
