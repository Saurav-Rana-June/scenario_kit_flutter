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
    this.cardColor,
    this.successColor = const Color(0xFF10B981),
    this.errorColor = const Color(0xFFEF4444),
    this.warningColor = const Color(0xFFF59E0B),
  });

  /// Factory for dark developer theme.
  factory ScenarioPanelThemeData.dark() {
    return const ScenarioPanelThemeData(
      backgroundColor: Color(0xFF0F1117),
      surfaceColor: Color(0xFF181B24),
      primaryColor: Color(0xFF6366F1),
      onPrimaryColor: Colors.white,
      textColor: Color(0xFFF8FAFC),
      subtitleColor: Color(0xFF94A3B8),
      borderColor: Color(0xFF282D3D),
      chipColor: Color(0xFF222736),
      activeItemColor: Color(0x2E6366F1),
      cardColor: Color(0xFF1B1E2B),
      successColor: Color(0xFF10B981),
      errorColor: Color(0xFFEF4444),
      warningColor: Color(0xFFF59E0B),
      borderRadius: BorderRadius.all(Radius.circular(16)),
      panelElevation: 12.0,
    );
  }

  /// Factory for clean light developer theme (default studio design).
  factory ScenarioPanelThemeData.light() {
    return const ScenarioPanelThemeData(
      backgroundColor: Color(0xFFF7F7FB),
      surfaceColor: Colors.white,
      primaryColor: Color(0xFF4F46E5),
      onPrimaryColor: Colors.white,
      textColor: Color(0xFF14142B),
      subtitleColor: Color(0xFF4A4A63),
      borderColor: Color(0xFFE6E6F0),
      chipColor: Color(0xFFEEEEF6),
      activeItemColor: Color(0xFFF1F2FF),
      cardColor: Color(0xFFFFFFFF),
      successColor: Color(0xFF0B6B43),
      errorColor: Color(0xFFB42318),
      warningColor: Color(0xFF8A4B08),
      borderRadius: BorderRadius.all(Radius.circular(20)),
      panelElevation: 24.0,
    );
  }

  /// Background color of the panel container.
  final Color backgroundColor;

  /// Background color for elevated surfaces and header.
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

  /// Optional background color for individual cards (defaults to [surfaceColor] if null).
  final Color? cardColor;

  /// Resolved card surface color.
  Color get effectiveCardColor => cardColor ?? surfaceColor;

  /// Color representing passed tests and success states.
  final Color successColor;

  /// Color representing failed tests and error states.
  final Color errorColor;

  /// Color representing skipped tests and warnings.
  final Color warningColor;

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
    Color? cardColor,
    Color? successColor,
    Color? errorColor,
    Color? warningColor,
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
      cardColor: cardColor ?? this.cardColor,
      successColor: successColor ?? this.successColor,
      errorColor: errorColor ?? this.errorColor,
      warningColor: warningColor ?? this.warningColor,
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
        other.panelElevation == panelElevation &&
        other.cardColor == cardColor &&
        other.successColor == successColor &&
        other.errorColor == errorColor &&
        other.warningColor == warningColor;
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
        cardColor,
        successColor,
        errorColor,
        warningColor,
      );
}
