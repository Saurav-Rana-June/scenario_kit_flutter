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
    this.screenName,
    this.onNavigateToScreen,
  });

  /// The provided [ScenarioController].
  final ScenarioController controller;

  /// Human-readable name of the screen wrapped by this [ScenarioKit] instance.
  final String? screenName;

  /// Invoked when Test Mode requests navigation to another registered screen.
  final void Function(String screenName)? onNavigateToScreen;

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

  /// Returns the active screen name from the nearest [ScenarioScope], if set.
  static String? maybeActiveScreenNameOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<ScenarioScope>()
        ?.screenName;
  }

  /// Returns the navigation hook from the nearest [ScenarioScope], if set.
  static void Function(String screenName)? maybeNavigateToScreenOf(
    BuildContext context,
  ) {
    return context
        .getInheritedWidgetOfExactType<ScenarioScope>()
        ?.onNavigateToScreen;
  }

  @override
  bool updateShouldNotify(covariant ScenarioScope oldWidget) {
    return oldWidget.controller != controller ||
        oldWidget.screenName != screenName ||
        oldWidget.onNavigateToScreen != onNavigateToScreen;
  }
}
