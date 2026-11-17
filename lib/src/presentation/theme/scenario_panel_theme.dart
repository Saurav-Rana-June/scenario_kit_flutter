import 'package:flutter/material.dart';

/// Styling configuration for ScenarioKit developer UI panels.
@immutable
class ScenarioPanelThemeData {
  /// Creates a [ScenarioPanelThemeData].
  const ScenarioPanelThemeData({
    required this.backgroundColor,
    required this.surfaceColor,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.chipColor,
    required this.activeItemColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.panelElevation = 8.0,
  });

  /// Factory for sleek dark developer theme (default).
  factory ScenarioPanelThemeData.dark() {
    return const ScenarioPanelThemeData(
      backgroundColor: Color(0xFF141419),
      surfaceColor: Color(0xFF1E1E26),
      primaryColor: Color(0xFF6366F1),
      onPrimaryColor: Colors.white,
      textColor: Color(0xFFF3F4F6),
      subtitleColor: Color(0xFF9CA3AF),
      borderColor: Color(0xFF2E2E38),
      chipColor: Color(0xFF282834),
      activeItemColor: Color(0x266366F1),
      borderRadius: BorderRadius.all(Radius.circular(16)),
      panelElevation: 10.0,
    );
  }

  /// Factory for clean light developer theme.
  factory ScenarioPanelThemeData.light() {
    return const ScenarioPanelThemeData(
      backgroundColor: Color(0xFFF9FAFB),
      surfaceColor: Colors.white,
      primaryColor: Color(0xFF4F46E5),
      onPrimaryColor: Colors.white,
      textColor: Color(0xFF111827),
      subtitleColor: Color(0xFF6B7280),
      borderColor: Color(0xFFE5E7EB),
      chipColor: Color(0xFFF3F4F6),
      activeItemColor: Color(0x1A4F46E5),
      borderRadius: BorderRadius.all(Radius.circular(16)),
      panelElevation: 6.0,
    );
  }

  /// Background color of the panel container.
  final Color backgroundColor;

  /// Background color for cards and elevated surfaces.
  final Color surfaceColor;

  /// Accent / primary brand color.
  final Color primaryColor;

  /// Contrast text color placed on [primaryColor].
  final Color onPrimaryColor;

  /// Primary text color.
  final Color textColor;

  /// Secondary/subtitle text color.
  final Color subtitleColor;

  /// Border and divider color.
  final Color borderColor;

  /// Chip and code badge background color.
  final Color chipColor;

  /// Highlight background color for currently active scenario item.
  final Color activeItemColor;

  /// Border radius for panels and cards.
  final BorderRadius borderRadius;

  /// Shadow elevation for floating panels.
  final double panelElevation;

  /// Creates a copy of this theme with given overrides.
  ScenarioPanelThemeData copyWith({
    Color? backgroundColor,
    Color? surfaceColor,
    Color? primaryColor,
    Color? onPrimaryColor,
    Color? textColor,
    Color? subtitleColor,
    Color? borderColor,
    Color? chipColor,
    Color? activeItemColor,
    BorderRadius? borderRadius,
    double? panelElevation,
  }) {
    return ScenarioPanelThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      primaryColor: primaryColor ?? this.primaryColor,
      onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
      textColor: textColor ?? this.textColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      borderColor: borderColor ?? this.borderColor,
      chipColor: chipColor ?? this.chipColor,
      activeItemColor: activeItemColor ?? this.activeItemColor,
      borderRadius: borderRadius ?? this.borderRadius,
      panelElevation: panelElevation ?? this.panelElevation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScenarioPanelThemeData &&
        other.backgroundColor == backgroundColor &&
        other.surfaceColor == surfaceColor &&
        other.primaryColor == primaryColor &&
        other.onPrimaryColor == onPrimaryColor &&
        other.textColor == textColor &&
        other.subtitleColor == subtitleColor &&
        other.borderColor == borderColor &&
        other.chipColor == chipColor &&
        other.activeItemColor == activeItemColor &&
        other.borderRadius == borderRadius &&
        other.panelElevation == panelElevation;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        surfaceColor,
        primaryColor,
        onPrimaryColor,
        textColor,
        subtitleColor,
        borderColor,
        chipColor,
        activeItemColor,
        borderRadius,
        panelElevation,
      );
}
