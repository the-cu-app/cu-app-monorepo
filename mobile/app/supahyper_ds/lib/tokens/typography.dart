import 'package:flutter/material.dart';

// Typography tokens for SUPAHYPER design system
class DSTypography {
  // Font families
  static const String fontFamilyPrimary = 'Geist';
  static const String fontFamilyMono = 'GeistMono';
  
  // Font weights (only 4 as specified)
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;
  
  // Display styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 57,
    fontWeight: weightBold,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 45,
    fontWeight: weightBold,
    letterSpacing: 0,
    height: 1.16,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 36,
    fontWeight: weightSemiBold,
    letterSpacing: 0,
    height: 1.22,
  );
  
  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 32,
    fontWeight: weightSemiBold,
    letterSpacing: 0,
    height: 1.25,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 28,
    fontWeight: weightSemiBold,
    letterSpacing: 0,
    height: 1.29,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 24,
    fontWeight: weightMedium,
    letterSpacing: 0,
    height: 1.33,
  );
  
  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 22,
    fontWeight: weightMedium,
    letterSpacing: 0,
    height: 1.27,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 16,
    fontWeight: weightMedium,
    letterSpacing: 0.15,
    height: 1.50,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 14,
    fontWeight: weightMedium,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 16,
    fontWeight: weightRegular,
    letterSpacing: 0.5,
    height: 1.50,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 14,
    fontWeight: weightRegular,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 12,
    fontWeight: weightRegular,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 14,
    fontWeight: weightMedium,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 12,
    fontWeight: weightMedium,
    letterSpacing: 0.5,
    height: 1.33,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 11,
    fontWeight: weightMedium,
    letterSpacing: 0.5,
    height: 1.45,
  );
  
  // Mono styles for numbers and codes
  static const TextStyle monoLarge = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 16,
    fontWeight: weightRegular,
    letterSpacing: 0,
    height: 1.50,
  );
  
  static const TextStyle monoMedium = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 14,
    fontWeight: weightRegular,
    letterSpacing: 0,
    height: 1.43,
  );
  
  static const TextStyle monoSmall = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 12,
    fontWeight: weightRegular,
    letterSpacing: 0,
    height: 1.33,
  );
}