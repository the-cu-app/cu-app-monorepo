import 'package:flutter/material.dart';

// Spacing tokens for SUPAHYPER design system - 8px grid
class DSSpacing {
  // Base unit
  static const double unit = 8.0;
  
  // Spacing scale
  static const double space0 = 0;
  static const double space1 = 4.0;   // 0.5x
  static const double space2 = 8.0;   // 1x
  static const double space3 = 12.0;  // 1.5x
  static const double space4 = 16.0;  // 2x
  static const double space5 = 20.0;  // 2.5x
  static const double space6 = 24.0;  // 3x
  static const double space7 = 28.0;  // 3.5x
  static const double space8 = 32.0;  // 4x
  static const double space9 = 36.0;  // 4.5x
  static const double space10 = 40.0; // 5x
  static const double space11 = 44.0; // 5.5x
  static const double space12 = 48.0; // 6x
  static const double space14 = 56.0; // 7x
  static const double space16 = 64.0; // 8x
  static const double space20 = 80.0; // 10x
  static const double space24 = 96.0; // 12x
  static const double space28 = 112.0; // 14x
  static const double space32 = 128.0; // 16x
  static const double space36 = 144.0; // 18x
  static const double space40 = 160.0; // 20x
  static const double space44 = 176.0; // 22x
  static const double space48 = 192.0; // 24x
  static const double space52 = 208.0; // 26x
  static const double space56 = 224.0; // 28x
  static const double space60 = 240.0; // 30x
  static const double space64 = 256.0; // 32x
  static const double space72 = 288.0; // 36x
  static const double space80 = 320.0; // 40x
  static const double space96 = 384.0; // 48x
  
  // Insets
  static const EdgeInsets insetXs = EdgeInsets.all(space1);
  static const EdgeInsets insetSm = EdgeInsets.all(space2);
  static const EdgeInsets insetMd = EdgeInsets.all(space4);
  static const EdgeInsets insetLg = EdgeInsets.all(space6);
  static const EdgeInsets insetXl = EdgeInsets.all(space8);
  static const EdgeInsets inset2xl = EdgeInsets.all(space12);
  static const EdgeInsets inset3xl = EdgeInsets.all(space16);
  
  // Page padding
  static const EdgeInsets pagePadding = EdgeInsets.all(space6);
  static const EdgeInsets pagePaddingMobile = EdgeInsets.all(space4);
  static const EdgeInsets pagePaddingTablet = EdgeInsets.all(space6);
  static const EdgeInsets pagePaddingDesktop = EdgeInsets.all(space8);
  
  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(space4);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(space3);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(space6);
  
  // List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: space4,
    vertical: space3,
  );
  
  // Button padding
  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(
    horizontal: space3,
    vertical: space2,
  );
  static const EdgeInsets buttonPaddingMedium = EdgeInsets.symmetric(
    horizontal: space4,
    vertical: space3,
  );
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(
    horizontal: space6,
    vertical: space4,
  );
  
  // Icon sizes (based on spacing grid)
  static const double iconXs = 16.0;  // space4
  static const double iconSm = 20.0;  // space5
  static const double iconMd = 24.0;  // space6
  static const double iconLg = 32.0;  // space8
  static const double iconXl = 40.0;  // space10
  static const double icon2xl = 48.0; // space12
  static const double icon3xl = 64.0; // space16
}