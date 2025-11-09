import 'package:flutter/material.dart';

// Motion tokens for SUPAHYPER design system
class DSMotion {
  // Duration scales
  static const Duration durationInstant = Duration(milliseconds: 0);
  static const Duration durationFast = Duration(milliseconds: 100);
  static const Duration durationBase = Duration(milliseconds: 200);
  static const Duration durationModerate = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 400);
  static const Duration durationSlower = Duration(milliseconds: 600);
  static const Duration durationSlowest = Duration(milliseconds: 800);
  
  // Page transitions
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration pageTransitionSlow = Duration(milliseconds: 500);
  
  // Micro interactions
  static const Duration microInteraction = Duration(milliseconds: 150);
  static const Duration hover = Duration(milliseconds: 200);
  static const Duration ripple = Duration(milliseconds: 400);
  
  // Animation curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve linear = Curves.linear;
  
  // Material curves
  static const Curve standard = Curves.fastOutSlowIn;
  static const Curve decelerate = Curves.decelerate;
  static const Curve accelerate = Curves.easeInQuad;
  
  // Custom curves
  static const Curve smooth = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve sharp = Cubic(0.4, 0.0, 0.6, 1.0);
  static const Curve bounce = Curves.bounceOut;
  static const Curve elastic = Curves.elasticOut;
  static const Curve spring = Curves.easeOutBack;
  
  // Stagger animations
  static const Duration staggerDelay = Duration(milliseconds: 50);
  static const Duration staggerDelayFast = Duration(milliseconds: 30);
  static const Duration staggerDelaySlow = Duration(milliseconds: 100);
  
  // Loading states
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Duration spinnerDuration = Duration(milliseconds: 1000);
  static const Duration pulseDuration = Duration(milliseconds: 2000);
}