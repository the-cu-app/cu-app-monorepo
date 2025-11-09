// Design Tokens for CU.APP - Credit Union Banking Platform
// This file provides a comprehensive design system that can be customized
// for any credit union's brand identity

import 'package:flutter/material.dart';

/// Design tokens for responsive breakpoints
class Breakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double wide = 1440;
  static const double ultraWide = 1920;
}

/// Design tokens for spacing
class Spacing {
  // Base spacing unit (8px)
  static const double xs = 4.0; // 0.5x
  static const double sm = 8.0; // 1x
  static const double md = 16.0; // 2x
  static const double lg = 24.0; // 3x
  static const double xl = 32.0; // 4x
  static const double xxl = 48.0; // 6x
  static const double xxxl = 64.0; // 8x

  // Component-specific spacing
  static const double cardPadding = 16.0;
  static const double screenPadding = 24.0;
  static const double sectionSpacing = 32.0;
  static const double headerSpacing = 48.0;
}

/// Design tokens for typography
class Typography {
  // Font families
  static const String primaryFont = 'Geist';
  static const String secondaryFont = 'GeistMono';

  // Font sizes
  static const double xs = 12.0;
  static const double sm = 14.0;
  static const double base = 16.0;
  static const double lg = 18.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double display = 48.0;

  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Line heights
  static const double tight = 1.2;
  static const double normal = 1.5;
  static const double relaxed = 1.75;
}

/// Design tokens for border radius
class RadiusTokens {
  static const double none = 0.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  // Component-specific radius
  static const double button = 8.0;
  static const double card = 12.0;
  static const double modal = 16.0;
  static const double input = 8.0;
}

/// Design tokens for elevation/shadows
class Elevation {
  static const double none = 0.0;
  static const double sm = 1.0;
  static const double md = 2.0;
  static const double lg = 4.0;
  static const double xl = 8.0;
  static const double xxl = 16.0;

  // Component-specific elevations
  static const double card = 2.0;
  static const double modal = 8.0;
  static const double dropdown = 4.0;
  static const double fab = 6.0;
}

/// Design tokens for animation durations
class AnimationDuration {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Component-specific durations
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration buttonPress = Duration(milliseconds: 150);
  static const Duration modalOpen = Duration(milliseconds: 400);
  static const Duration toast = Duration(milliseconds: 200);
}

/// Design tokens for animation curves
class AnimationCurves {
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve elastic = Curves.elasticOut;

  // Component-specific curves
  static const Curve pageTransition = Curves.easeInOut;
  static const Curve buttonPress = Curves.easeOut;
  static const Curve modalOpen = Curves.easeOutBack;
  static const Curve toast = Curves.easeInOut;
}

/// Credit Union Brand Colors
/// This can be customized per credit union
class CreditUnionColors {
  // Primary brand colors
  static const Color primary = Color(0xFF1E40AF); // Navy Blue
  static const Color primaryLight = Color(0xFF3B82F6); // Light Blue
  static const Color primaryDark = Color(0xFF1E3A8A); // Dark Blue

  // Secondary colors
  static const Color secondary = Color(0xFF059669); // Green
  static const Color secondaryLight = Color(0xFF10B981); // Light Green
  static const Color secondaryDark = Color(0xFF047857); // Dark Green

  // Accent colors
  static const Color accent = Color(0xFFDC2626); // Red
  static const Color accentLight = Color(0xFFEF4444); // Light Red
  static const Color accentDark = Color(0xFFB91C1C); // Dark Red

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Financial colors
  static const Color positive = Color(0xFF10B981); // Green for gains
  static const Color negative = Color(0xFFEF4444); // Red for losses
  static const Color neutral = Color(0xFF6B7280); // Gray for neutral
}

/// Credit Union Theme Configuration
class CreditUnionTheme {
  static ThemeData lightTheme({
    Color? primaryColor,
    Color? secondaryColor,
    String? fontFamily,
  }) {
    final primary = primaryColor ?? CreditUnionColors.primary;
    final secondary = secondaryColor ?? CreditUnionColors.secondary;
    final fontFamilyName = fontFamily ?? Typography.primaryFont;

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamilyName,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: CreditUnionColors.white,
        surfaceContainer: CreditUnionColors.gray50,
        error: CreditUnionColors.error,
      ),
      textTheme: _buildTextTheme(fontFamilyName),
      elevatedButtonTheme: _buildElevatedButtonTheme(primary),
      filledButtonTheme: _buildFilledButtonTheme(primary),
      outlinedButtonTheme: _buildOutlinedButtonTheme(primary),
      cardTheme: _buildCardTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(primary),
      appBarTheme: _buildAppBarTheme(primary),
      navigationRailTheme: _buildNavigationRailTheme(primary),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(primary),
    );
  }

  static ThemeData darkTheme({
    Color? primaryColor,
    Color? secondaryColor,
    String? fontFamily,
  }) {
    final primary = primaryColor ?? CreditUnionColors.primaryLight;
    final secondary = secondaryColor ?? CreditUnionColors.secondaryLight;
    final fontFamilyName = fontFamily ?? Typography.primaryFont;

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamilyName,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: secondary,
        surface: CreditUnionColors.gray800,
        surfaceContainer: CreditUnionColors.gray900,
        error: CreditUnionColors.error,
      ),
      textTheme: _buildTextTheme(fontFamilyName),
      elevatedButtonTheme: _buildElevatedButtonTheme(primary),
      filledButtonTheme: _buildFilledButtonTheme(primary),
      outlinedButtonTheme: _buildOutlinedButtonTheme(primary),
      cardTheme: _buildCardTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(primary),
      appBarTheme: _buildAppBarTheme(primary),
      navigationRailTheme: _buildNavigationRailTheme(primary),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(primary),
    );
  }

  static TextTheme _buildTextTheme(String fontFamily) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.display,
        fontWeight: Typography.bold,
        height: Typography.tight,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.xxxl,
        fontWeight: Typography.bold,
        height: Typography.tight,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.xxl,
        fontWeight: Typography.semibold,
        height: Typography.tight,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.xl,
        fontWeight: Typography.semibold,
        height: Typography.normal,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.lg,
        fontWeight: Typography.medium,
        height: Typography.normal,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.base,
        fontWeight: Typography.medium,
        height: Typography.normal,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.lg,
        fontWeight: Typography.semibold,
        height: Typography.normal,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.base,
        fontWeight: Typography.medium,
        height: Typography.normal,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.sm,
        fontWeight: Typography.medium,
        height: Typography.normal,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.base,
        fontWeight: Typography.regular,
        height: Typography.normal,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.sm,
        fontWeight: Typography.regular,
        height: Typography.normal,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.xs,
        fontWeight: Typography.regular,
        height: Typography.normal,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.sm,
        fontWeight: Typography.medium,
        height: Typography.normal,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.xs,
        fontWeight: Typography.medium,
        height: Typography.normal,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: Typography.xs,
        fontWeight: Typography.regular,
        height: Typography.normal,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(Color primary) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: CreditUnionColors.white,
        elevation: Elevation.sm,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.all(Radius.circular(RadiusTokens.button)),
        ),
        textStyle: const TextStyle(
          fontSize: Typography.base,
          fontWeight: Typography.medium,
        ),
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(Color primary) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: CreditUnionColors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.all(Radius.circular(RadiusTokens.button)),
        ),
        textStyle: const TextStyle(
          fontSize: Typography.base,
          fontWeight: Typography.medium,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(Color primary) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.all(Radius.circular(RadiusTokens.button)),
        ),
        textStyle: const TextStyle(
          fontSize: Typography.base,
          fontWeight: Typography.medium,
        ),
      ),
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      elevation: Elevation.card,
      shape: RoundedRectangleBorder(
        borderRadius: RadiusTokens.all(Radius.circular(RadiusTokens.card)),
      ),
      margin: const EdgeInsets.all(Spacing.sm),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(Color primary) {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: RadiusTokens.all(Radius.circular(RadiusTokens.input)),
        borderSide: BorderSide(color: CreditUnionColors.gray300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: RadiusTokens.all(Radius.circular(RadiusTokens.input)),
        borderSide: BorderSide(color: CreditUnionColors.gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: RadiusTokens.all(Radius.circular(RadiusTokens.input)),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: RadiusTokens.all(Radius.circular(RadiusTokens.input)),
        borderSide: BorderSide(color: CreditUnionColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.md,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(Color primary) {
    return AppBarTheme(
      backgroundColor: primary,
      foregroundColor: CreditUnionColors.white,
      elevation: Elevation.sm,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: Typography.lg,
        fontWeight: Typography.semibold,
      ),
    );
  }

  static NavigationRailThemeData _buildNavigationRailTheme(Color primary) {
    return NavigationRailThemeData(
      backgroundColor: CreditUnionColors.gray50,
      selectedIconTheme: IconThemeData(color: primary),
      selectedLabelTextStyle: TextStyle(color: primary),
      unselectedIconTheme:
          const IconThemeData(color: CreditUnionColors.gray500),
      unselectedLabelTextStyle:
          const TextStyle(color: CreditUnionColors.gray500),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme(
      Color primary) {
    return BottomNavigationBarThemeData(
      backgroundColor: CreditUnionColors.white,
      selectedItemColor: primary,
      unselectedItemColor: CreditUnionColors.gray500,
      type: BottomNavigationBarType.fixed,
      elevation: Elevation.sm,
    );
  }
}

/// Responsive helper utilities
class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.tablet;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.tablet && width < Breakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.desktop;
  }

  static bool isWide(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.wide;
  }

  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? wide,
  }) {
    if (isWide(context) && wide != null) return wide;
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  static double responsiveWidth(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? wide,
  }) {
    return responsive(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      wide: wide,
    );
  }

  static EdgeInsets responsivePadding(
    BuildContext context, {
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
    EdgeInsets? wide,
  }) {
    return responsive(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      wide: wide,
    );
  }
}

/// Animation helper utilities
class AnimationHelper {
  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
    Duration duration = AnimationDuration.normal,
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    Offset begin = const Offset(0, 1),
    Offset end = Offset.zero,
    Duration duration = AnimationDuration.normal,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: AnimationCurves.easeOut,
      )),
      child: child,
    );
  }

  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    double begin = 0.8,
    double end = 1.0,
    Duration duration = AnimationDuration.normal,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      )),
      child: child,
    );
  }

  static Widget heroTransition({
    required Widget child,
    required String tag,
    Duration duration = AnimationDuration.pageTransition,
  }) {
    return Hero(
      tag: tag,
      child: child,
      transitionOnUserGestures: true,
    );
  }
}
