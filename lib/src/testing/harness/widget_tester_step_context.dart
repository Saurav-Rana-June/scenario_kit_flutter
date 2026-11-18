import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/scenario_controller.dart';
import '../../presentation/scenario_scope.dart';
import '../assertions/assertion_result.dart';
import '../definitions/step_finder.dart';
import '../steps/scenario_step_context.dart';
import 'step_finder_extensions.dart';

/// Implementation of [ScenarioStepContext] that dispatches interaction and
/// assertion steps through a headless or device-attached [WidgetTester].
///
/// This context is used when executing [ScenarioTest] test cases in automated
/// `testWidgets` or `integration_test` harnesses.
class WidgetTesterStepContext implements ScenarioStepContext {
  /// Creates a [WidgetTesterStepContext].
  WidgetTesterStepContext({
    required this.tester,
    required this.testId,
    List<String>? logs,
    List<AssertionResult>? recordedAssertions,
  })  : _logs = logs ?? <String>[],
        _recordedAssertions = recordedAssertions ?? <AssertionResult>[];

  /// The active [WidgetTester] driving the automated test.
  final WidgetTester tester;

  @override
  final String testId;

  final List<String> _logs;
  final List<AssertionResult> _recordedAssertions;

  /// Collected diagnostic logs for this execution run.
  List<String> get logs => List.unmodifiable(_logs);

  /// All assertions recorded during execution.
  List<AssertionResult> get assertions =>
      List.unmodifiable(_recordedAssertions);

  @override
  List<String> get recordedLogs => logs;

  @override
  List<AssertionResult> get recordedAssertions => assertions;

  @override
  ScenarioController? resolveScenarioController() {
    try {
      final scopeFinder = find.byType(ScenarioScope, skipOffstage: false);
      if (scopeFinder.evaluate().isEmpty) return null;
      return ScenarioScope.maybeOf(tester.element(scopeFinder.first));
    } catch (_) {
      return null;
    }
  }

  Finder _resolve(StepFinder finder) => finder.toWidgetTesterFinder();

  @override
  void log(String message) {
    _logs.add('[${DateTime.now().toIso8601String()}] $message');
  }

  @override
  void recordAssertion(AssertionResult assertion) {
    _recordedAssertions.add(assertion);
  }

  @override
  Future<void> tap(StepFinder finder) async {
    final target = _resolve(finder);
    if (target.evaluate().isEmpty) {
      throw StateError(
          'Cannot tap: Widget matching "${finder.description}" not found in widget tree.');
    }
    await tester.tap(target.first);
    await tester.pump();
    log('Tapped widget matching "${finder.description}".');
  }

  @override
  Future<void> longPress(
    StepFinder finder, {
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    final target = _resolve(finder);
    if (target.evaluate().isEmpty) {
      throw StateError(
          'Cannot longPress: Widget matching "${finder.description}" not found in widget tree.');
    }
    await tester.longPress(target.first);
    await tester.pump();
    log('Long pressed widget matching "${finder.description}".');
  }

  @override
  Future<void> enterText(StepFinder finder, String text) async {
    final target = _resolve(finder);
    if (target.evaluate().isEmpty) {
      throw StateError(
          'Cannot enter text: Widget matching "${finder.description}" not found in widget tree.');
    }
    final editable = find.descendant(
      of: target.first,
      matching: find.byType(EditableText),
    );
    final effectiveTarget =
        editable.evaluate().isNotEmpty ? editable.first : target.first;
    await tester.enterText(effectiveTarget, text);
    await tester.pump();
    log('Entered text "$text" into widget matching "${finder.description}".');
  }

  @override
  Future<void> clearText(StepFinder finder) async {
    final target = _resolve(finder);
    if (target.evaluate().isEmpty) {
      throw StateError(
          'Cannot clear text: Widget matching "${finder.description}" not found in widget tree.');
    }
    final editable = find.descendant(
      of: target.first,
      matching: find.byType(EditableText),
    );
    final effectiveTarget =
        editable.evaluate().isNotEmpty ? editable.first : target.first;
    await tester.enterText(effectiveTarget, '');
    await tester.pump();
    log('Cleared text in widget matching "${finder.description}".');
  }

  @override
  Future<void> scroll(
    StepFinder finder, {
    required Offset offset,
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    final target = _resolve(finder);
    if (target.evaluate().isEmpty) {
      throw StateError(
          'Cannot scroll: Widget matching "${finder.description}" not found in widget tree.');
    }
    await tester.drag(target.first, offset);
    await tester.pump();
    log('Scrolled widget matching "${finder.description}" by offset $offset.');
  }

  @override
  Future<void> drag(
    StepFinder finder, {
    required Offset offset,
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    final target = _resolve(finder);
    if (target.evaluate().isEmpty) {
      throw StateError(
          'Cannot drag: Widget matching "${finder.description}" not found in widget tree.');
    }
    await tester.drag(target.first, offset);
    await tester.pump();
    log('Dragged widget matching "${finder.description}" by offset $offset.');
  }

  @override
  Future<bool> exists(StepFinder finder) async {
    final target = _resolve(finder);
    return target.evaluate().isNotEmpty;
  }

  @override
  Future<bool> isVisible(StepFinder finder) async {
    final target = _resolve(finder);
    final elements = target.evaluate();
    if (elements.isEmpty) return false;

    final element = elements.first;
    final renderBox = element.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return false;

    final size = renderBox.size;
    if (size.width <= 0 || size.height <= 0) return false;

    // Check if the widget is inside an inactive Offstage subtree
    final offstageAncestor = find.ancestor(
      of: target.first,
      matching: find.byWidgetPredicate((w) => w is Offstage && w.offstage),
    );
    if (offstageAncestor.evaluate().isNotEmpty) return false;

    return true;
  }

  @override
  Future<String?> getText(StepFinder finder) async {
    final target = _resolve(finder);
    final elements = target.evaluate();
    if (elements.isEmpty) return null;

    final widget = elements.first.widget;
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

    // Inspect child EditableText descendants (e.g. inside TextField or TextFormField)
    final editableChildren =
        find.descendant(of: target.first, matching: find.byType(EditableText));
    if (editableChildren.evaluate().isNotEmpty) {
      final childWidget =
          editableChildren.evaluate().first.widget as EditableText;
      return childWidget.controller.text;
    }

    // Inspect child Text descendants if the target is a button or card
    final childText =
        find.descendant(of: target.first, matching: find.byType(Text));
    if (childText.evaluate().isNotEmpty) {
      final childWidget = childText.evaluate().first.widget as Text;
      return childWidget.data ?? childWidget.textSpan?.toPlainText();
    }

    return null;
  }

  @override
  Future<T?> getWidget<T extends Widget>(StepFinder finder) async {
    final target = _resolve(finder);
    final elements = target.evaluate();
    for (final el in elements) {
      if (el.widget is T) {
        return el.widget as T;
      }
    }
    return null;
  }

  @override
  Future<void> pumpAndSettle(
      [Duration timeout = const Duration(seconds: 3)]) async {
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        timeout,
      );
    } catch (_) {
      // Gracefully advance a frame if continuous animations prevent settling
      await tester.pump();
    }
  }

  @override
  Future<void> pump([Duration? duration]) async {
    await tester.pump(duration);
  }

  @override
  Future<void> wait(Duration duration) async {
    await tester.pump(duration);
  }

  @override
  Future<void> waitFor(
    StepFinder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      if (await exists(finder)) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
    throw TimeoutException(
      'Timed out waiting for widget matching "${finder.description}" after ${timeout.inSeconds}s.',
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
      if (!await exists(finder)) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
    throw TimeoutException(
      'Timed out waiting for absence of widget matching "${finder.description}" after ${timeout.inSeconds}s.',
      timeout,
    );
  }
}
