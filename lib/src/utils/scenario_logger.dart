import 'package:flutter/foundation.dart';

import '../core/scenario_controller.dart';

/// Lightweight debugging logger for ScenarioKit operations.
class ScenarioLogger {
  const ScenarioLogger._();

  /// Whether debug console logging is enabled. Defaults to `false`.
  static bool enabled = false;

  /// Custom log printer callback. Defaults to [debugPrint].
  static void Function(String message) printer = debugPrint;

  /// Logs a formatted message if [enabled] is `true`.
  static void log(String message) {
    if (enabled) {
      printer('[ScenarioKit] $message');
    }
  }

  /// Attaches a logger listener to [controller] that prints active scenario changes.
  ///
  /// Returns a callback that detaches the listener.
  static VoidCallback attach(ScenarioController controller) {
    void listener() {
      final scenario = controller.selectedScenario;
      if (scenario != null) {
        log('Active scenario: "${scenario.name}" (id: ${scenario.id})');
      } else {
        log('Active scenario: none');
      }
    }

    controller.addListener(listener);
    return () => controller.removeListener(listener);
  }
}
