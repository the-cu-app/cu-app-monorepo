import 'package:flutter/material.dart';
import 'colors.dart';

// Shadow/elevation tokens for SUPAHYPER design system
class DSShadows {
  // Elevation levels
  static const List<BoxShadow> elevation0 = [];
  
  static const List<BoxShadow> elevation1 = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> elevation2 = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> elevation3 = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> elevation4 = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> elevation5 = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 12),
      blurRadius: 32,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 6),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
  
  // Functional shadows
  static const List<BoxShadow> cardShadow = elevation2;
  static const List<BoxShadow> buttonShadow = elevation1;
  static const List<BoxShadow> modalShadow = elevation5;
  static const List<BoxShadow> dropdownShadow = elevation3;
  static const List<BoxShadow> fabShadow = elevation4;
  
  // Inner shadows
  static const List<BoxShadow> innerShadowLight = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, -1),
      blurRadius: 2,
      spreadRadius: -1,
    ),
  ];
  
  static const List<BoxShadow> innerShadowMedium = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, -2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];
  
  // Glow effects
  static const List<BoxShadow> glowPrimary = [
    BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 0),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> glowAccent = [
    BoxShadow(
      color: Color(0x333B82F6),
      offset: Offset(0, 0),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> glowSuccess = [
    BoxShadow(
      color: Color(0x3310B981),
      offset: Offset(0, 0),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];
}