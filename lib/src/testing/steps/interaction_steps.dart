import 'dart:async';

import 'package:flutter/widgets.dart';

import '../definitions/scenario_test_step.dart';
import '../definitions/step_finder.dart';
import 'scenario_step_context.dart';

/// Step that simulates tapping a target widget.
class TapStep extends ScenarioTestStep {
  /// Creates a [TapStep].
  TapStep({
    required this.finder,
    String? id,
    String? description,
    super.captureScreenshot,
    super.timeout,
    this.settle = true,
  }) : super(
          id: id ?? 'tap_${finder.description}',
          description: description ?? 'Tap ${finder.description}',
        );

  /// Locator for the widget to tap.
  final StepFinder finder;

  /// Whether to wait for animations and frame settling after the tap.
  final bool settle;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    context.log('Executing tap on ${finder.description}');
    await context.tap(finder);
    if (settle) {
      await context.pumpAndSettle();
    }
  }
}

/// Step that simulates a long-press gesture on a target widget.
class LongPressStep extends ScenarioTestStep {
  /// Creates a [LongPressStep].
  LongPressStep({
    required this.finder,
    this.pressDuration = const Duration(milliseconds: 500),
    String? id,
    String? description,
    super.captureScreenshot,
    super.timeout,
    this.settle = true,
  }) : super(
          id: id ?? 'long_press_${finder.description}',
          description: description ?? 'Long press ${finder.description}',
        );

  /// Locator for the widget to long press.
  final StepFinder finder;

  /// Duration to hold the press down.
  final Duration pressDuration;

  /// Whether to wait for animations and frame settling after the gesture.
  final bool settle;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    context.log('Executing long press on ${finder.description}');
    await context.longPress(finder, duration: pressDuration);
    if (settle) {
      await context.pumpAndSettle();
    }
  }
}

/// Step that enters text into an editable widget.
class EnterTextStep extends ScenarioTestStep {
  /// Creates an [EnterTextStep].
  EnterTextStep({
    required this.finder,
    required this.text,
    String? id,
    String? description,
    super.captureScreenshot,
    super.timeout,
    this.settle = true,
  }) : super(
          id: id ?? 'enter_text_${finder.description}',
          description:
              description ?? 'Enter "$text" into ${finder.description}',
        );

  /// Locator for the editable widget.
  final StepFinder finder;

  /// The text string to insert.
  final String text;

  /// Whether to wait for animations and frame settling after entering text.
  final bool settle;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    context.log('Entering "$text" into ${finder.description}');
    await context.enterText(finder, text);
    if (settle) {
      await context.pumpAndSettle();
    }
  }
}

/// Step that clears text from an editable widget.
class ClearTextStep extends ScenarioTestStep {
  /// Creates a [ClearTextStep].
  ClearTextStep({
    required this.finder,
    String? id,
    String? description,
    super.captureScreenshot,
    super.timeout,
    this.settle = true,
  }) : super(
          id: id ?? 'clear_text_${finder.description}',
          description: description ?? 'Clear text in ${finder.description}',
        );

  /// Locator for the editable widget.
  final StepFinder finder;

  /// Whether to wait for animations and frame settling after clearing text.
  final bool settle;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    context.log('Clearing text in ${finder.description}');
    await context.clearText(finder);
    if (settle) {
      await context.pumpAndSettle();
    }
  }
}

/// Step that scrolls a scrollable widget by a specified [offset].
class ScrollStep extends ScenarioTestStep {
  /// Creates a [ScrollStep].
  ScrollStep({
    required this.finder,
    required this.offset,
    this.scrollDuration = const Duration(milliseconds: 300),
    String? id,
    String? description,
    super.captureScreenshot,
    super.timeout,
    this.settle = true,
  }) : super(
          id: id ?? 'scroll_${finder.description}',
          description: description ??
              'Scroll ${finder.description} by dx=${offset.dx}, dy=${offset.dy}',
        );

  /// Locator for the scrollable container.
  final StepFinder finder;

  /// Delta offset to scroll.
  final Offset offset;

  /// Gesture drag duration.
  final Duration scrollDuration;

  /// Whether to wait for animations and frame settling after scrolling.
  final bool settle;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    context.log('Scrolling ${finder.description} by $offset');
    await context.scroll(finder, offset: offset, duration: scrollDuration);
    if (settle) {
      await context.pumpAndSettle();
    }
  }
}

/// Step that drags a widget by a specified [offset].
class DragStep extends ScenarioTestStep {
  /// Creates a [DragStep].
  DragStep({
    required this.finder,
    required this.offset,
    this.dragDuration = const Duration(milliseconds: 300),
    String? id,
    String? description,
    super.captureScreenshot,
    super.timeout,
    this.settle = true,
  }) : super(
          id: id ?? 'drag_${finder.description}',
          description: description ??
              'Drag ${finder.description} by dx=${offset.dx}, dy=${offset.dy}',
        );

  /// Locator for the draggable widget.
  final StepFinder finder;

  /// Delta offset to drag.
  final Offset offset;

  /// Duration over which to perform the drag gesture.
  final Duration dragDuration;

  /// Whether to wait for animations and frame settling after dragging.
  final bool settle;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    context.log('Dragging ${finder.description} by $offset');
    await context.drag(finder, offset: offset, duration: dragDuration);
    if (settle) {
      await context.pumpAndSettle();
    }
  }
}

/// Step that pauses execution for a fixed duration.
class WaitStep extends ScenarioTestStep {
  /// Creates a [WaitStep].
  WaitStep({
    required this.duration,
    String? id,
    String? description,
    super.captureScreenshot,
  }) : super(
          id: id ?? 'wait_${duration.inMilliseconds}ms',
          description: description ?? 'Wait for ${duration.inMilliseconds}ms',
        );

  /// Duration to wait.
  final Duration duration;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    context.log('Waiting for ${duration.inMilliseconds}ms');
    await context.wait(duration);
  }
}

/// Step that polls until a widget matching [finder] appears in the tree.
class WaitForWidgetStep extends ScenarioTestStep {
  /// Creates a [WaitForWidgetStep].
  WaitForWidgetStep({
    required this.finder,
    this.waitTimeout = const Duration(seconds: 5),
    String? id,
    String? description,
    super.captureScreenshot,
  }) : super(
          id: id ?? 'wait_for_${finder.description}',
          description: description ??
              'Wait for ${finder.description} (timeout: ${waitTimeout.inSeconds}s)',
        );

  /// Locator for the widget being waited on.
  final StepFinder finder;

  /// Maximum time to poll before throwing an exception.
  final Duration waitTimeout;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    context.log(
        'Waiting for ${finder.description} up to ${waitTimeout.inSeconds}s');
    await context.waitFor(finder, timeout: waitTimeout);
  }
}

/// Step that executes an arbitrary developer-provided asynchronous action callback.
class CustomStep extends ScenarioTestStep {
  /// Creates a [CustomStep].
  const CustomStep({
    required super.id,
    required super.description,
    required this.action,
    super.captureScreenshot,
    super.timeout,
  });

  /// The custom asynchronous execution callback.
  final FutureOr<void> Function(ScenarioStepContext context) action;

  @override
  Future<void> execute(ScenarioStepContext context) async {
    context.log('Executing custom step "$description"');
    await action(context);
  }
}
