import 'package:flutter/widgets.dart';

import '../assertions/assertion_result.dart';
import '../definitions/step_finder.dart';

/// Context interface provided to [ScenarioTestStep] during execution.
///
/// Implementations handle dispatching interactions either to a live in-app
/// Flutter widget tree or through a headless `WidgetTester` test driver.
abstract class ScenarioStepContext {
  /// Current test ID being executed.
  String get testId;

  /// Simulates a tap/click gesture on the widget located by [finder].
  Future<void> tap(StepFinder finder);

  /// Simulates a long-press gesture on the widget located by [finder].
  Future<void> longPress(StepFinder finder,
      {Duration duration = const Duration(milliseconds: 500)});

  /// Enters [text] into the editable widget located by [finder].
  Future<void> enterText(StepFinder finder, String text);

  /// Clears text in the editable widget located by [finder].
  Future<void> clearText(StepFinder finder);

  /// Scrolls the widget located by [finder] by [offset].
  Future<void> scroll(
    StepFinder finder, {
    required Offset offset,
    Duration duration = const Duration(milliseconds: 300),
  });

  /// Drags the widget located by [finder] by [offset].
  Future<void> drag(
    StepFinder finder, {
    required Offset offset,
    Duration duration = const Duration(milliseconds: 300),
  });

  /// Checks whether at least one widget matching [finder] exists in the tree.
  Future<bool> exists(StepFinder finder);

  /// Checks whether the widget matching [finder] is visible and non-zero sized.
  Future<bool> isVisible(StepFinder finder);

  /// Retrieves the string text content of the widget matching [finder], or null.
  Future<String?> getText(StepFinder finder);

  /// Retrieves the first [Widget] of type [T] matching [finder], or null.
  Future<T?> getWidget<T extends Widget>(StepFinder finder);

  /// Waits until all scheduled animations and asynchronous microtasks settle.
  Future<void> pumpAndSettle([Duration timeout = const Duration(seconds: 10)]);

  /// Pumps a single frame, optionally advancing the clock by [duration].
  Future<void> pump([Duration? duration]);

  /// Asynchronously pauses execution for [duration].
  Future<void> wait(Duration duration);

  /// Polls until a widget matching [finder] appears in the tree, or throws on timeout.
  Future<void> waitFor(StepFinder finder,
      {Duration timeout = const Duration(seconds: 5)});

  /// Polls until a widget matching [finder] disappears from the tree, or throws on timeout.
  Future<void> waitForAbsence(StepFinder finder,
      {Duration timeout = const Duration(seconds: 5)});

  /// Records an execution log entry.
  void log(String message);

  /// Records an evaluated assertion result.
  void recordAssertion(AssertionResult assertion);
}
