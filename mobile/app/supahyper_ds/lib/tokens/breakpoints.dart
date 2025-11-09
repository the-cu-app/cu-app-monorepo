import 'package:flutter/material.dart';

// Responsive breakpoints for SUPAHYPER design system
class DSBreakpoints {
  // Breakpoint values
  static const double mobile = 0;
  static const double mobileLarge = 428;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;
  static const double desktopXl = 1920;
  
  // Check device type
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tablet;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }
  
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopLarge;
  }
  
  // Get current breakpoint
  static String getCurrentBreakpoint(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopXl) return 'desktop-xl';
    if (width >= desktopLarge) return 'desktop-large';
    if (width >= desktop) return 'desktop';
    if (width >= tablet) return 'tablet';
    if (width >= mobileLarge) return 'mobile-large';
    return 'mobile';
  }
  
  // Responsive value helper
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? mobileLarge,
    T? tablet,
    T? desktop,
    T? desktopLarge,
    T? desktopXl,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= DSBreakpoints.desktopXl && desktopXl != null) {
      return desktopXl;
    }
    if (width >= DSBreakpoints.desktopLarge && desktopLarge != null) {
      return desktopLarge;
    }
    if (width >= DSBreakpoints.desktop && desktop != null) {
      return desktop;
    }
    if (width >= DSBreakpoints.tablet && tablet != null) {
      return tablet;
    }
    if (width >= DSBreakpoints.mobileLarge && mobileLarge != null) {
      return mobileLarge;
    }
    return mobile;
  }
  
  // Grid columns
  static int getGridColumns(BuildContext context) {
    return responsive(
      context,
      mobile: 4,
      tablet: 8,
      desktop: 12,
      desktopLarge: 12,
    );
  }
  
  // Container widths
  static double getMaxWidth(BuildContext context) {
    return responsive(
      context,
      mobile: double.infinity,
      tablet: 768,
      desktop: 1024,
      desktopLarge: 1280,
      desktopXl: 1536,
    );
  }
}