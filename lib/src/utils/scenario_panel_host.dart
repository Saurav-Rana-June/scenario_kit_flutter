import 'package:flutter/material.dart';

import '../presentation/scenario_kit_bindings.dart';

/// Resolves a [BuildContext] that can present ScenarioKit modals (bottom sheets, dialogs).
abstract final class ScenarioPanelHost {
  /// Returns a context with a valid [Overlay] for [showModalBottomSheet] / [showDialog].
  ///
  /// Prefers [ScenarioKitBindings.navigatorKey], then the root navigator, then the
  /// nearest navigator.
  static BuildContext modalContext(BuildContext context) {
    final bindings = ScenarioKitBindings.maybeOf(context) ??
        context.getInheritedWidgetOfExactType<ScenarioKitBindings>();

    final keyContext = bindings?.navigatorKey?.currentContext;
    if (keyContext != null && _hasOverlay(keyContext)) {
      return keyContext;
    }

    final rootNav = Navigator.maybeOf(context, rootNavigator: true);
    if (rootNav != null && rootNav.overlay != null) {
      return rootNav.context;
    }

    final nav = Navigator.maybeOf(context);
    if (nav != null && nav.overlay != null) {
      return nav.context;
    }

    if (Overlay.maybeOf(context, rootOverlay: true) != null ||
        Overlay.maybeOf(context) != null) {
      return context;
    }

    assert(() {
      throw FlutterError(
        'ScenarioKit could not find an Overlay to present the developer panel.\n\n'
        'Wrap your app with MaterialApp (or CupertinoApp) and place ScenarioKit '
        'inside MaterialApp.builder so it sits above the navigator overlay:\n\n'
        'MaterialApp(\n'
        '  navigatorKey: rootNavigatorKey, // optional, pass to ScenarioKit too\n'
        '  builder: (context, child) => ScenarioKit(\n'
        '    navigatorKey: rootNavigatorKey,\n'
        '    scenarios: myScenarios,\n'
        '    child: child,\n'
        '  ),\n'
        '  home: const MyHomeScreen(),\n'
        ')\n',
      );
    }());
    return context;
  }

  static bool _hasOverlay(BuildContext context) {
    return Overlay.maybeOf(context) != null;
  }
}