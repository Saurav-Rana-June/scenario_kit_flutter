import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

/// Test double implementing [ScenarioStepContext] for unit testing steps and assertions.
class FakeScenarioStepContext implements ScenarioStepContext {
  FakeScenarioStepContext({this.testId = 'unit_test'});

  @override
  final String testId;

  final List<String> logs = [];
  final List<AssertionResult> _storedAssertions = [];
  final List<String> calls = [];

  final Set<String> existingFinders = {};
  final Set<String> visibleFinders = {};
  final Map<String, String> widgetTexts = {};

  @override
  Future<void> tap(StepFinder finder) async {
    calls.add('tap:${finder.description}');
  }

  @override
  Future<void> longPress(StepFinder finder,
      {Duration duration = const Duration(milliseconds: 500)}) async {
    calls.add('longPress:${finder.description}:${duration.inMilliseconds}ms');
  }

  @override
  Future<void> enterText(StepFinder finder, String text) async {
    calls.add('enterText:${finder.description}:$text');
    widgetTexts[finder.description] = text;
  }

  @override
  Future<void> clearText(StepFinder finder) async {
    calls.add('clearText:${finder.description}');
    widgetTexts.remove(finder.description);
  }

  @override
  Future<void> scroll(
    StepFinder finder, {
    required Offset offset,
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    calls.add('scroll:${finder.description}:${offset.dx},${offset.dy}');
  }

  @override
  Future<void> drag(
    StepFinder finder, {
    required Offset offset,
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    calls.add('drag:${finder.description}:${offset.dx},${offset.dy}');
  }

  @override
  Future<bool> exists(StepFinder finder) async {
    return existingFinders.contains(finder.description);
  }

  @override
  Future<bool> isVisible(StepFinder finder) async {
    return visibleFinders.contains(finder.description);
  }

  @override
  Future<String?> getText(StepFinder finder) async {
    return widgetTexts[finder.description];
  }

  @override
  Future<T?> getWidget<T extends Widget>(StepFinder finder) async {
    return null;
  }

  @override
  Future<void> pumpAndSettle(
      [Duration timeout = const Duration(seconds: 10)]) async {
    calls.add('pumpAndSettle');
  }

  @override
  Future<void> pump([Duration? duration]) async {
    calls.add('pump:${duration?.inMilliseconds}');
  }

  @override
  Future<void> wait(Duration duration) async {
    calls.add('wait:${duration.inMilliseconds}ms');
  }

  @override
  Future<void> waitFor(StepFinder finder,
      {Duration timeout = const Duration(seconds: 5)}) async {
    calls.add('waitFor:${finder.description}');
    if (!existingFinders.contains(finder.description)) {
      throw TimeoutException('Widget not found: ${finder.description}');
    }
  }

  @override
  Future<void> waitForAbsence(StepFinder finder,
      {Duration timeout = const Duration(seconds: 5)}) async {
    calls.add('waitForAbsence:${finder.description}');
  }

  @override
  void log(String message) {
    logs.add(message);
  }

  @override
  void recordAssertion(AssertionResult assertion) {
    _storedAssertions.add(assertion);
  }

  @override
  List<String> get recordedLogs => List.unmodifiable(logs);

  @override
  List<AssertionResult> get recordedAssertions =>
      List.unmodifiable(_storedAssertions);

  @override
  ScenarioController? resolveScenarioController() => null;
}
