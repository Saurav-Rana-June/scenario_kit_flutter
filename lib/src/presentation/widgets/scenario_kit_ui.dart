// ignore_for_file: library_private_types_in_public_api

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/scenario_panel_theme.dart';

part 'scenario_kit_ui_body.dart';
part 'scenario_kit_ui_shell.dart';
part 'scenario_kit_ui_scenarios.dart';
part 'scenario_kit_ui_tests.dart';
part 'scenario_kit_ui_reports.dart';

class SkTheme extends InheritedWidget {
  const SkTheme({super.key, required this.data, required super.child});

  final ScenarioPanelThemeData data;

  static ScenarioPanelThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SkTheme>()?.data ??
      ScenarioPanelThemeData.light();

  @override
  bool updateShouldNotify(SkTheme oldWidget) => data != oldWidget.data;
}

extension SkColors on ScenarioPanelThemeData {
  Color tint(Color c, [int alpha = 30]) =>
      Color.alphaBlend(c.withAlpha(alpha), surfaceColor);

  Color deep(Color c) => Color.lerp(c, Colors.black, 0.35)!;

  Color get neutralBar =>
      Color.alphaBlend(subtitleColor.withAlpha(55), surfaceColor);
}

TextStyle _ts(Color c, double size,
        [FontWeight w = FontWeight.w500, double? h]) =>
    TextStyle(color: c, fontSize: size, fontWeight: w, height: h);

TextStyle _mono(Color c, [double size = 12.5]) => TextStyle(
      color: c,
      fontSize: size,
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Consolas', 'Courier New'],
      height: 1.4,
    );

String _fmtMs(int ms) =>
    ms >= 1000 ? '${(ms / 1000).toStringAsFixed(2)}s' : '${ms}ms';

bool _isCompact(double width) => width < 720;

ButtonStyle _filledStyle(ScenarioPanelThemeData t) => FilledButton.styleFrom(
      backgroundColor: t.primaryColor,
      foregroundColor: t.onPrimaryColor,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

ButtonStyle _outlinedStyle(ScenarioPanelThemeData t, {Color? color}) =>
    OutlinedButton.styleFrom(
      foregroundColor: color ?? t.textColor,
      side: BorderSide(color: color ?? t.borderColor),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

enum SkTab { scenarios, tests, reports }

enum SkStatus { idle, running, passed, failed, skipped }

enum SkStepState { idle, passed, failed, skipped }

class SkScenarioItem {
  const SkScenarioItem({
    required this.id,
    required this.name,
    required this.group,
    required this.description,
    this.metaCount = 0,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String group;
  final String description;
  final int metaCount;
  final bool isDefault;
}

class SkStep {
  const SkStep(this.text, {this.state = SkStepState.idle, this.durationMs});

  final String text;
  final SkStepState state;
  final int? durationMs;
}

class SkTestItem {
  const SkTestItem({
    required this.id,
    required this.name,
    required this.screen,
    required this.group,
    this.description = '',
    this.steps = const [],
    this.status = SkStatus.idle,
    this.durationMs,
    this.error,
    this.screenshot,
  });

  final String id;
  final String name;
  final String screen;
  final String group;
  final String description;
  final List<SkStep> steps;
  final SkStatus status;
  final int? durationMs;
  final String? error;
  final Widget? screenshot;

  int get failedStepIndex =>
      steps.indexWhere((s) => s.state == SkStepState.failed);
}

class SkRunProgress {
  const SkRunProgress({
    required this.currentName,
    required this.completed,
    required this.total,
    this.passed = 0,
    this.failed = 0,
    this.skipped = 0,
    this.elapsed = Duration.zero,
  });

  final String currentName;
  final int completed;
  final int total;
  final int passed;
  final int failed;
  final int skipped;
  final Duration elapsed;
}

class SkReportData {
  const SkReportData({
    required this.results,
    this.duration = Duration.zero,
    this.hint,
  });

  final List<SkTestItem> results;
  final Duration duration;
  final String? hint;

  int get total => results.length;
  int get passed => results.where((r) => r.status == SkStatus.passed).length;
  int get failed => results.where((r) => r.status == SkStatus.failed).length;
  int get skipped => results.where((r) => r.status == SkStatus.skipped).length;
}