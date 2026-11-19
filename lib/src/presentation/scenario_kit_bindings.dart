import 'package:flutter/widgets.dart';

import '../testing/screenshot/scenario_screenshot_service.dart';

/// Supplies ScenarioKit services (screenshots, test run state) to descendants.
class ScenarioKitBindings extends InheritedWidget {
  const ScenarioKitBindings({
    super.key,
    required super.child,
    required this.screenshotBoundaryKey,
    required this.appContentKey,
    required this.screenshotService,
    required this.testsRunning,
    this.navigatorKey,
  });

  /// When set (usually the same key as [MaterialApp.navigatorKey]), modals use this
  /// navigator so the panel works with nested routers and `MaterialApp.builder`.
  final GlobalKey<NavigatorState>? navigatorKey;

  final GlobalKey screenshotBoundaryKey;

  /// Anchors the live application UI tree used for in-app functional tests.
  final GlobalKey appContentKey;

  final ScenarioScreenshotService screenshotService;
  final ValueNotifier<bool> testsRunning;

  static ScenarioKitBindings? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ScenarioKitBindings>();
  }

  /// Context of the app UI under test, when mounted.
  BuildContext? get appContentContext => appContentKey.currentContext;

  /// Resolves a [BuildContext] suitable for executing tests against the app UI.
  static BuildContext resolveExecutionContext(BuildContext context) {
    final bindings = maybeOf(context) ??
        context.getInheritedWidgetOfExactType<ScenarioKitBindings>();
    final app = bindings?.appContentContext;
    if (app != null && app.mounted) return app;
    return context;
  }

  @override
  bool updateShouldNotify(covariant ScenarioKitBindings oldWidget) {
    return screenshotBoundaryKey != oldWidget.screenshotBoundaryKey ||
        appContentKey != oldWidget.appContentKey ||
        screenshotService != oldWidget.screenshotService ||
        navigatorKey != oldWidget.navigatorKey;
  }
}
