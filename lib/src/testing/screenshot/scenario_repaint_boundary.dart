import 'package:flutter/widgets.dart';

/// A widget that wraps its [child] in a [RepaintBoundary] identified by a [GlobalKey]
/// to enable high-fidelity screenshot capture by ScenarioKit's test engine.
class ScenarioRepaintBoundary extends StatelessWidget {
  /// Creates a [ScenarioRepaintBoundary].
  const ScenarioRepaintBoundary({
    required this.boundaryKey,
    required this.child,
    super.key,
  });

  /// The [GlobalKey] anchoring the boundary.
  final GlobalKey boundaryKey;

  /// The child subtree to be captured.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: child,
    );
  }
}
