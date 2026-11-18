import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/scenario_controller.dart';

import '../../presentation/scenario_scope.dart';
import '../assertions/assertion_result.dart';
import '../definitions/step_finder.dart';
import '../steps/scenario_step_context.dart';
import 'in_app_pointer_events.dart';

/// Concrete [ScenarioStepContext] that executes test steps directly against
/// a live, rendered in-app Flutter widget tree using the [rootContext].
class InAppStepContext implements ScenarioStepContext {
  /// Creates an [InAppStepContext].
  InAppStepContext({
    required this.rootContext,
    required this.testId,
    List<String>? logs,
    List<AssertionResult>? recordedAssertions,
  })  : _logs = logs ?? [],
        _recordedAssertions = recordedAssertions ?? [];

  /// The root context anchoring the application or screen under test.
  final BuildContext rootContext;

  @override
  final String testId;

  final List<String> _logs;
  final List<AssertionResult> _recordedAssertions;

  /// Collected diagnostic logs for this execution run.
  List<String> get logs => List.unmodifiable(_logs);

  @override
  List<String> get recordedLogs => logs;

  /// All assertions recorded during execution.
  List<AssertionResult> get assertions =>
      List.unmodifiable(_recordedAssertions);

  @override
  List<AssertionResult> get recordedAssertions => assertions;

  @override
  ScenarioController? resolveScenarioController() =>
      ScenarioScope.maybeOf(rootContext);

  @override
  void log(String message) {
    _logs.add('[${DateTime.now().toIso8601String()}] $message');
  }

  @override
  void recordAssertion(AssertionResult assertion) {
    _recordedAssertions.add(assertion);
  }

  /// Traverses the element tree to locate the first [Element] matching [finder].
  Element? findFirstElement(StepFinder finder) {
    Element? match;
    void visitor(Element element) {
      if (match != null) return;
      if (finder.matchesElement(element)) {
        match = element;
        return;
      }
      element.visitChildElements(visitor);
    }

    if (!rootContext.mounted) return null;
    final root = rootContext as Element;
    if (finder.matchesElement(root)) return root;
    root.visitChildElements(visitor);
    if (match != null) return match;

    if (_isAutomatedTestBinding) {
      final appRoot = WidgetsBinding.instance.rootElement;
      if (appRoot != null && appRoot != root) {
        if (finder.matchesElement(appRoot)) return appRoot;
        appRoot.visitChildElements(visitor);
      }
    }
    return match;
  }

  /// Traverses the element tree to locate all [Element] instances matching [finder].
  List<Element> findAllElements(StepFinder finder) {
    final matches = <Element>[];
    void visitor(Element element) {
      if (finder.matchesElement(element)) {
        matches.add(element);
      }
      element.visitChildElements(visitor);
    }

    if (rootContext.mounted) {
      final root = rootContext as Element;
      if (finder.matchesElement(root)) matches.add(root);
      root.visitChildElements(visitor);
    }

    if (matches.isEmpty && _isAutomatedTestBinding) {
      final appRoot = WidgetsBinding.instance.rootElement;
      if (appRoot != null) {
        if (finder.matchesElement(appRoot)) matches.add(appRoot);
        appRoot.visitChildElements(visitor);
      }
    }
    return matches;
  }

  @override
  Future<bool> exists(StepFinder finder) async {
    return findFirstElement(finder) != null;
  }

  @override
  Future<bool> isVisible(StepFinder finder) async {
    final element = findFirstElement(finder);
    if (element == null) return false;
    final renderBox = element.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return false;
    final size = renderBox.size;
    if (size.width <= 0 || size.height <= 0) return false;

    // Check if the widget is within visible bounds of the screen
    final position = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.maybeOf(rootContext)?.size;
    if (screenSize != null) {
      final rect =
          Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
      final screenRect = Offset.zero & screenSize;
      return rect.overlaps(screenRect);
    }
    return true;
  }

  @override
  Future<String?> getText(StepFinder finder) async {
    final element = findFirstElement(finder);
    if (element == null) return null;

    final widget = element.widget;
    if (widget is Text) {
      return widget.data ?? widget.textSpan?.toPlainText();
    }
    if (widget is RichText) {
      return widget.text.toPlainText();
    }
    if (widget is EditableText) {
      return widget.controller.text;
    }
    if (widget is TextField) {
      return widget.controller?.text;
    }

    // Inspect child text and editable elements if target is a container
    String? childText;
    void visitor(Element el) {
      if (childText != null) return;
      final w = el.widget;
      if (w is Text) {
        childText = w.data ?? w.textSpan?.toPlainText();
        return;
      }
      if (w is RichText) {
        childText = w.text.toPlainText();
        return;
      }
      if (w is EditableText) {
        childText = w.controller.text;
        return;
      }
      if (w is TextField) {
        childText = w.controller?.text;
        return;
      }
      el.visitChildElements(visitor);
    }

    element.visitChildElements(visitor);
    return childText;
  }

  @override
  Future<T?> getWidget<T extends Widget>(StepFinder finder) async {
    final element = findFirstElement(finder);
    if (element == null) return null;
    if (element.widget is T) {
      return element.widget as T;
    }
    return null;
  }

  @override
  Future<void> tap(StepFinder finder) async {
    final element = findFirstElement(finder);
    if (element == null) {
      throw StateError(
          'Cannot tap: Target widget ${finder.description} was not found.');
    }

    final renderBox = element.findRenderObject();
    if (renderBox is! RenderBox) {
      throw StateError(
          'Cannot tap: Target widget ${finder.description} does not have a RenderBox.');
    }

    if (_invokeDirectTap(element.widget)) {
      await pumpAndSettle();
      return;
    }

    final activated =
        Actions.maybeInvoke(element, const ActivateIntent());
    if (activated == true) {
      await pumpAndSettle();
      return;
    }

    if (_isAutomatedTestBinding) {
      throw StateError(
        'Cannot tap: Target widget ${finder.description} has no supported '
        'onPressed handler in widget tests.',
      );
    }

    final center = renderBox.localToGlobal(renderBox.size.center(Offset.zero));
    await InAppPointerEvents.tapAt(center);
    await pumpAndSettle();
  }

  bool _invokeDirectTap(Widget widget) {
    if (widget is ElevatedButton) {
      widget.onPressed?.call();
      return widget.onPressed != null;
    }
    if (widget is TextButton) {
      widget.onPressed?.call();
      return widget.onPressed != null;
    }
    if (widget is OutlinedButton) {
      widget.onPressed?.call();
      return widget.onPressed != null;
    }
    if (widget is FilledButton) {
      widget.onPressed?.call();
      return widget.onPressed != null;
    }
    if (widget is IconButton) {
      widget.onPressed?.call();
      return widget.onPressed != null;
    }
    if (widget is InkWell && widget.onTap != null) {
      widget.onTap!();
      return true;
    }
    return false;
  }

  @override
  Future<void> longPress(
    StepFinder finder, {
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    final element = findFirstElement(finder);
    if (element == null) {
      throw StateError(
          'Cannot long-press: Target widget ${finder.description} was not found.');
    }

    final renderBox = element.findRenderObject();
    if (renderBox is! RenderBox) {
      throw StateError(
          'Cannot long-press: Target widget ${finder.description} does not have a RenderBox.');
    }

    final center = renderBox.localToGlobal(renderBox.size.center(Offset.zero));
    await InAppPointerEvents.longPressAt(center, duration: duration);
  }

  EditableTextState? _findEditableTextState(Element element) {
    EditableTextState? state;

    void visitor(Element el) {
      if (state != null) return;
      if (el is StatefulElement && el.state is EditableTextState) {
        state = el.state as EditableTextState;
        return;
      }
      el.visitChildElements(visitor);
    }

    if (element is StatefulElement && element.state is EditableTextState) {
      return element.state as EditableTextState;
    }

    visitor(element);
    if (state != null) return state;

    // Check ancestor elements
    element.visitAncestorElements((el) {
      if (el is StatefulElement && el.state is EditableTextState) {
        state = el.state as EditableTextState;
        return false;
      }
      return true;
    });

    return state;
  }

  @override
  Future<void> enterText(StepFinder finder, String text) async {
    final element = findFirstElement(finder);
    if (element == null) {
      throw StateError(
          'Cannot enter text: Target widget ${finder.description} was not found.');
    }

    final editable = _findEditableTextState(element);
    if (editable == null) {
      throw StateError(
          'Cannot enter text: Target widget ${finder.description} contains no EditableTextState.');
    }

    final controller = editable.widget.controller;
    controller.text = text;
    controller.selection = TextSelection.collapsed(offset: text.length);
  }

  @override
  Future<void> clearText(StepFinder finder) async {
    final element = findFirstElement(finder);
    if (element == null) {
      throw StateError(
          'Cannot clear text: Target widget ${finder.description} was not found.');
    }

    final editable = _findEditableTextState(element);
    if (editable == null) {
      throw StateError(
          'Cannot clear text: Target widget ${finder.description} contains no EditableTextState.');
    }

    editable.widget.controller.clear();
  }

  @override
  Future<void> scroll(
    StepFinder finder, {
    required Offset offset,
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    final element = findFirstElement(finder);
    if (element == null) {
      throw StateError(
          'Cannot scroll: Target widget ${finder.description} was not found.');
    }

    final scrollable = Scrollable.maybeOf(element);
    if (scrollable != null) {
      final targetPixels = scrollable.position.pixels - offset.dy;
      scrollable.position.jumpTo(targetPixels.clamp(
        scrollable.position.minScrollExtent,
        scrollable.position.maxScrollExtent,
      ));
      await pumpAndSettle();
    } else {
      await drag(finder, offset: offset, duration: duration);
    }
  }

  @override
  Future<void> drag(
    StepFinder finder, {
    required Offset offset,
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    final element = findFirstElement(finder);
    if (element == null) {
      throw StateError(
          'Cannot drag: Target widget ${finder.description} was not found.');
    }

    final renderBox = element.findRenderObject();
    if (renderBox is! RenderBox) {
      throw StateError(
          'Cannot drag: Target widget ${finder.description} has no RenderBox.');
    }

    final start = renderBox.localToGlobal(renderBox.size.center(Offset.zero));
    final end = start + offset;
    await InAppPointerEvents.dragLine(start, end, duration: duration);
  }

  @override
  bool get _isAutomatedTestBinding {
    final name = WidgetsBinding.instance.runtimeType.toString();
    return name.contains('AutomatedTest');
  }

  Future<void> pumpAndSettle(
      [Duration timeout = const Duration(seconds: 10)]) async {
    if (_isAutomatedTestBinding) {
      await Future<void>.value();
      return;
    }
    final settleBudget = timeout > const Duration(milliseconds: 320)
        ? const Duration(milliseconds: 320)
        : timeout;
    await Future<void>.delayed(settleBudget);
  }

  @override
  Future<void> pump([Duration? duration]) async {
    if (_isAutomatedTestBinding) {
      await Future<void>.value();
      return;
    }
    if (duration != null && duration > Duration.zero) {
      await Future<void>.delayed(duration);
    } else {
      await Future<void>.value();
    }
  }

  @override
  Future<void> wait(Duration duration) async {
    if (duration > Duration.zero) {
      await Future<void>.delayed(duration);
    } else {
      await Future<void>.value();
    }
  }

  @override
  Future<void> waitFor(
    StepFinder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      if (await exists(finder)) {
        return;
      }
      await pump(const Duration(milliseconds: 50));
    }
    throw TimeoutException(
      'Timed out waiting for ${finder.description} to appear within ${timeout.inSeconds}s.',
      timeout,
    );
  }

  @override
  Future<void> waitForAbsence(
    StepFinder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      if (!await exists(finder)) {
        return;
      }
      await pump(const Duration(milliseconds: 50));
    }
    throw TimeoutException(
      'Timed out waiting for ${finder.description} to disappear within ${timeout.inSeconds}s.',
      timeout,
    );
  }
}
