import 'package:flutter/material.dart';

/// Strategy used by a [StepFinder] to locate widgets.
enum StepFinderType {
  /// Locates widget by its [Key].
  byKey,

  /// Locates widget by matching text.
  byText,

  /// Locates widget by [Type].
  byType,

  /// Locates widget by tooltip message.
  byTooltip,

  /// Locates widget by [IconData].
  byIcon,

  /// Custom element predicate.
  custom,

  /// Locates widget by semantics label.
  bySemanticsLabel,
}

/// Declarative widget locator abstraction compatible with both in-app runtime
/// test execution and automated `WidgetTester` integration tests.
@immutable
class StepFinder {
  const StepFinder._({
    required this.type,
    required this.description,
    this.key,
    this.text,
    this.widgetType,
    this.tooltip,
    this.icon,
    this.predicate,
    this.semanticsLabel,
    this.findRichText = true,
  });

  /// Locates a widget matching [key].
  factory StepFinder.byKey(Key key, {String? description}) {
    return StepFinder._(
      type: StepFinderType.byKey,
      key: key,
      description: description ?? 'Key("$key")',
    );
  }

  /// Convenience constructor locating a widget with a [ValueKey<String>].
  factory StepFinder.byKeyString(String keyString, {String? description}) {
    return StepFinder.byKey(
      ValueKey<String>(keyString),
      description: description ?? 'Key("$keyString")',
    );
  }

  /// Locates a widget displaying [text].
  factory StepFinder.byText(
    String text, {
    bool findRichText = true,
    String? description,
  }) {
    return StepFinder._(
      type: StepFinderType.byText,
      text: text,
      findRichText: findRichText,
      description: description ?? 'Text("$text")',
    );
  }

  /// Locates a widget of runtime type [type].
  factory StepFinder.byWidgetType(Type type, {String? description}) {
    return StepFinder._(
      type: StepFinderType.byType,
      widgetType: type,
      description: description ?? 'Type($type)',
    );
  }

  /// Locates a widget displaying tooltip [tooltip].
  factory StepFinder.byTooltip(String tooltip, {String? description}) {
    return StepFinder._(
      type: StepFinderType.byTooltip,
      tooltip: tooltip,
      description: description ?? 'Tooltip("$tooltip")',
    );
  }

  /// Locates a widget displaying [icon].
  factory StepFinder.byIcon(IconData icon, {String? description}) {
    return StepFinder._(
      type: StepFinderType.byIcon,
      icon: icon,
      description: description ?? 'Icon(${icon.codePoint})',
    );
  }

  /// Locates a widget matching a custom element [predicate].
  factory StepFinder.custom(
    bool Function(Element element) predicate, {
    required String description,
  }) {
    return StepFinder._(
      type: StepFinderType.custom,
      predicate: predicate,
      description: description,
    );
  }

  /// Locates a widget with accessibility label [semanticsLabel].
  factory StepFinder.bySemanticsLabel(
    String semanticsLabel, {
    String? description,
  }) {
    return StepFinder._(
      type: StepFinderType.bySemanticsLabel,
      semanticsLabel: semanticsLabel,
      description: description ?? 'SemanticsLabel("$semanticsLabel")',
    );
  }

  /// The finding strategy.
  final StepFinderType type;

  /// Human-readable description of what this finder targets.
  final String description;

  /// The target [Key], if [type] is [StepFinderType.byKey].
  final Key? key;

  /// The target text, if [type] is [StepFinderType.byText].
  final String? text;

  /// Whether to inspect [TextSpan] rich text when matching text.
  final bool findRichText;

  /// The target [Type], if [type] is [StepFinderType.byType].
  final Type? widgetType;

  /// The target tooltip string, if [type] is [StepFinderType.byTooltip].
  final String? tooltip;

  /// The target [IconData], if [type] is [StepFinderType.byIcon].
  final IconData? icon;

  /// Custom element predicate, if [type] is [StepFinderType.custom].
  final bool Function(Element element)? predicate;

  /// Semantics label when [type] is [StepFinderType.bySemanticsLabel].
  final String? semanticsLabel;

  /// Evaluates whether a given Flutter [Element] matches this finder's criteria.
  bool matchesElement(Element element) {
    switch (type) {
      case StepFinderType.byKey:
        return element.widget.key == key;

      case StepFinderType.byText:
        final widget = element.widget;
        if (widget is Text) {
          if (widget.data != null && widget.data!.contains(text!)) {
            return true;
          }
          if (findRichText && widget.textSpan != null) {
            return widget.textSpan!.toPlainText().contains(text!);
          }
        }
        if (findRichText && widget is RichText) {
          return widget.text.toPlainText().contains(text!);
        }
        return false;

      case StepFinderType.byType:
        return element.widget.runtimeType == widgetType;

      case StepFinderType.byTooltip:
        final widget = element.widget;
        if (widget is Tooltip) {
          return widget.message == tooltip;
        }
        return false;

      case StepFinderType.byIcon:
        final widget = element.widget;
        if (widget is Icon) {
          return widget.icon == icon;
        }
        return false;

      case StepFinderType.custom:
        return predicate != null && predicate!(element);

      case StepFinderType.bySemanticsLabel:
        final widget = element.widget;
        if (widget is Semantics) {
          return widget.properties.label == semanticsLabel;
        }
        if (widget is Text) {
          return widget.semanticsLabel == semanticsLabel;
        }
        return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StepFinder &&
        other.type == type &&
        other.key == key &&
        other.text == text &&
        other.widgetType == widgetType &&
        other.tooltip == tooltip &&
        other.icon == icon &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(
        type,
        key,
        text,
        widgetType,
        tooltip,
        icon,
        description,
      );

  @override
  String toString() => 'StepFinder($description)';
}
