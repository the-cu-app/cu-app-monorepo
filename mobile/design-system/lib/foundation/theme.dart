import 'package:flutter/widgets.dart';
import 'colors.dart';

/// Credit Union Theme Data - Zero Material Design
///
/// Central theme configuration for CU applications.

class CUThemeData {
  final CUColorScheme colorScheme;
  final bool isDark;

  const CUThemeData({
    required this.colorScheme,
    required this.isDark,
  });

  static const CUThemeData light = CUThemeData(
    colorScheme: CUColorScheme.light,
    isDark: false,
  );

  static const CUThemeData dark = CUThemeData(
    colorScheme: CUColorScheme.dark,
    isDark: true,
  );
}

/// Credit Union Theme Inherited Widget
///
/// Provides theme data to the widget tree using InheritedWidget.

class CUTheme extends InheritedWidget {
  final CUThemeData themeData;

  const CUTheme({
    Key? key,
    required this.themeData,
    required Widget child,
  }) : super(key: key, child: child);

  static CUThemeData of(BuildContext context) {
    final CUTheme? theme =
        context.dependOnInheritedWidgetOfExactType<CUTheme>();
    return theme?.themeData ?? CUThemeData.light;
  }

  @override
  bool updateShouldNotify(CUTheme oldWidget) {
    return themeData != oldWidget.themeData;
  }
}
