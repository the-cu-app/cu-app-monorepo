import 'package:flutter/widgets.dart';

/// Credit Union Color Scheme - Zero Material Design
///
/// Professional, trust-building colors specifically designed for
/// credit union financial applications.

class CUColorScheme {
  final Color primary;
  final Color primaryVariant;
  final Color secondary;
  final Color secondaryVariant;
  final Color background;
  final Color surface;
  final Color error;
  final Color success;
  final Color warning;
  final Color info;

  // Text colors
  final Color onPrimary;
  final Color onSecondary;
  final Color onBackground;
  final Color onSurface;
  final Color onError;

  // Financial-specific colors
  final Color positive;
  final Color negative;
  final Color neutral;

  // Borders and dividers
  final Color border;
  final Color divider;

  // Overlays
  final Color overlay;
  final Color shadow;

  const CUColorScheme({
    required this.primary,
    required this.primaryVariant,
    required this.secondary,
    required this.secondaryVariant,
    required this.background,
    required this.surface,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
    required this.onPrimary,
    required this.onSecondary,
    required this.onBackground,
    required this.onSurface,
    required this.onError,
    required this.positive,
    required this.negative,
    required this.neutral,
    required this.border,
    required this.divider,
    required this.overlay,
    required this.shadow,
  });

  /// Default light color scheme for credit unions
  static const CUColorScheme light = CUColorScheme(
    primary: Color(0xFF000000), // Black
    primaryVariant: Color(0xFF424242), // Dark gray
    secondary: Color(0xFF9E9E9E), // Gray
    secondaryVariant: Color(0xFF757575), // Darker gray
    background: Color(0xFFFFFFFF), // White
    surface: Color(0xFFFFFFFF), // White
    error: Color(0xFFFF0000), // Red
    success: Color(0xFF388E3C), // Green
    warning: Color(0xFFF57C00), // Orange
    info: Color(0xFF1976D2), // Blue
    onPrimary: Color(0xFFFFFFFF), // White on black
    onSecondary: Color(0xFFFFFFFF), // White on gray
    onBackground: Color(0xFF000000), // Black on white
    onSurface: Color(0xFF000000), // Black on white
    onError: Color(0xFFFFFFFF), // White on red
    positive: Color(0xFF00C851), // Green
    negative: Color(0xFFFF4444), // Red
    neutral: Color(0xFF757575), // Gray
    border: Color(0xFFE0E0E0), // Light gray
    divider: Color(0xFFBDBDBD), // Medium gray
    overlay: Color(0x66000000), // Semi-transparent black
    shadow: Color(0x33000000), // Subtle shadow
  );

  /// Default dark color scheme for credit unions
  static const CUColorScheme dark = CUColorScheme(
    primary: Color(0xFFFFFFFF), // White
    primaryVariant: Color(0xFFE0E0E0), // Light gray
    secondary: Color(0xFF9E9E9E), // Gray
    secondaryVariant: Color(0xFFBDBDBD), // Light gray
    background: Color(0xFF000000), // Black
    surface: Color(0xFF000000), // Black
    error: Color(0xFFFF0000), // Red
    success: Color(0xFF66BB6A), // Green
    warning: Color(0xFFFF9800), // Orange
    info: Color(0xFF64B5F6), // Blue
    onPrimary: Color(0xFF000000), // Black on white
    onSecondary: Color(0xFF000000), // Black on gray
    onBackground: Color(0xFFFFFFFF), // White on black
    onSurface: Color(0xFFFFFFFF), // White on black
    onError: Color(0xFFFFFFFF), // White on red
    positive: Color(0xFF00E676), // Green
    negative: Color(0xFFFF5252), // Red
    neutral: Color(0xFFBDBDBD), // Light gray
    border: Color(0xFF424242), // Dark gray
    divider: Color(0xFF616161), // Gray
    overlay: Color(0x66FFFFFF), // Semi-transparent white
    shadow: Color(0x66000000), // Stronger shadow
  );
}
