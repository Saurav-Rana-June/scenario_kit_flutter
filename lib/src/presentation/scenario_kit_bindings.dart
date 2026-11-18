import 'package:flutter/widgets.dart';

import '../testing/screenshot/scenario_screenshot_service.dart';

/// Supplies ScenarioKit services (screenshots, test run state) to descendants.
class ScenarioKitBindings extends InheritedWidget {
  const ScenarioKitBindings({
    super.key,
    required super.child,
    required this.screenshotBoundaryKey,
    required this.screenshotService,
    required this.testsRunning,
  });

  final GlobalKey screenshotBoundaryKey;
  final ScenarioScreenshotService screenshotService;
  final ValueNotifier<bool> testsRunning;

  static ScenarioKitBindings? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ScenarioKitBindings>();
  }

  @override
  bool updateShouldNotify(covariant ScenarioKitBindings oldWidget) {
    return screenshotBoundaryKey != oldWidget.screenshotBoundaryKey ||
        screenshotService != oldWidget.screenshotService ||
        testsRunning != oldWidget.testsRunning;
  }
}