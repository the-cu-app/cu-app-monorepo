import 'package:flutter/widgets.dart';
import 'colors.dart';

/// Credit Union Elevation System - Zero Material Design
///
/// Consistent shadow/elevation system for depth and hierarchy.

class CUElevation {
  static const double none = 0.0;
  static const double low = 2.0;
  static const double medium = 4.0;
  static const double high = 8.0;
  static const double max = 16.0;

  static List<BoxShadow> getShadow(double elevation, {Color? shadowColor}) {
    if (elevation == none) return [];

    final color = shadowColor ?? CUColorScheme.light.shadow;

    return [
      BoxShadow(
        color: color,
        blurRadius: elevation,
        offset: Offset(0, elevation / 2),
      ),
    ];
  }
}
