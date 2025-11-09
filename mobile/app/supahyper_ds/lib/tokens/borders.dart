import 'package:flutter/material.dart';
import 'colors.dart';

// Border tokens for SUPAHYPER design system
class DSBorders {
  // Border widths
  static const double widthNone = 0.0;
  static const double widthThin = 1.0;
  static const double widthMedium = 2.0;
  static const double widthThick = 3.0;
  static const double widthHeavy = 4.0;
  
  // Border radius scale
  static const double radiusNone = 0.0;
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radius2xl = 20.0;
  static const double radius3xl = 24.0;
  static const double radiusFull = 9999.0;
  
  // Component specific radius
  static const double buttonRadius = radiusLg;
  static const double cardRadius = radiusXl;
  static const double inputRadius = radiusMd;
  static const double chipRadius = radiusFull;
  static const double dialogRadius = radius2xl;
  static const double sheetRadius = radius3xl;
  
  // BorderRadius objects
  static const BorderRadius borderRadiusNone = BorderRadius.zero;
  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadius2xl = BorderRadius.all(Radius.circular(radius2xl));
  static const BorderRadius borderRadius3xl = BorderRadius.all(Radius.circular(radius3xl));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));
  
  // Top only radius
  static const BorderRadius topRadiusLg = BorderRadius.only(
    topLeft: Radius.circular(radiusLg),
    topRight: Radius.circular(radiusLg),
  );
  static const BorderRadius topRadiusXl = BorderRadius.only(
    topLeft: Radius.circular(radiusXl),
    topRight: Radius.circular(radiusXl),
  );
  static const BorderRadius topRadius2xl = BorderRadius.only(
    topLeft: Radius.circular(radius2xl),
    topRight: Radius.circular(radius2xl),
  );
  
  // Border styles
  static Border borderThin = Border.all(
    color: DSColors.border,
    width: widthThin,
  );
  
  static Border borderMedium = Border.all(
    color: DSColors.border,
    width: widthMedium,
  );
  
  static Border borderThick = Border.all(
    color: DSColors.border,
    width: widthThick,
  );
  
  static Border borderPrimary = Border.all(
    color: DSColors.primary,
    width: widthMedium,
  );
  
  static Border borderError = Border.all(
    color: DSColors.error,
    width: widthMedium,
  );
  
  static Border borderSuccess = Border.all(
    color: DSColors.success,
    width: widthMedium,
  );
  
  // Outline input borders
  static OutlineInputBorder inputBorder = OutlineInputBorder(
    borderRadius: borderRadiusMd,
    borderSide: BorderSide(
      color: DSColors.border,
      width: widthThin,
    ),
  );
  
  static OutlineInputBorder inputBorderFocused = OutlineInputBorder(
    borderRadius: borderRadiusMd,
    borderSide: BorderSide(
      color: DSColors.primary,
      width: widthMedium,
    ),
  );
  
  static OutlineInputBorder inputBorderError = OutlineInputBorder(
    borderRadius: borderRadiusMd,
    borderSide: BorderSide(
      color: DSColors.error,
      width: widthMedium,
    ),
  );
}