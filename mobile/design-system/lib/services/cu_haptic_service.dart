/// CU Haptic Feedback Service
///
/// Centralized haptic feedback for all interactions
/// Federated token-based system for consistent feedback patterns
/// Zero Material dependencies
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../foundation/theme.dart';

/// Haptic patterns for consistent feedback across the app
enum CUHapticPattern {
  login,
  success,
  error,
  transaction,
  navigation,
}

/// Haptic feedback types
enum CUHapticFeedbackType {
  success,
  warning,
  error,
}

/// CU Haptic Service
///
/// Usage:
/// ```dart
/// final haptic = CUHapticService();
/// await haptic.lightImpact();
/// await haptic.vibratePattern(CUHapticPattern.login);
/// ```
class CUHapticService {
  static final CUHapticService _instance = CUHapticService._internal();
  factory CUHapticService() => _instance;
  CUHapticService._internal();

  static const String _hapticsEnabledKey = 'cu_haptics_enabled';
  bool _enabled = true;

  /// Initialize haptics service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_hapticsEnabledKey) ?? true;
    } catch (e) {
      _enabled = true;
    }
  }

  /// Check if haptics are enabled
  bool get isEnabled => _enabled;

  /// Enable/disable haptics
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticsEnabledKey, enabled);
    } catch (e) {
      // Ignore storage errors
    }
  }

  /// Light impact - for button taps, list selections
  Future<void> lightImpact() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium impact - for important actions
  Future<void> mediumImpact() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for destructive actions, errors
  Future<void> heavyImpact() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection click - for toggles, switches, checkboxes
  Future<void> selectionClick() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Notification feedback - for success, completion
  Future<void> notificationFeedback({CUHapticFeedbackType type = CUHapticFeedbackType.success}) async {
    if (!_enabled) return;
    switch (type) {
      case CUHapticFeedbackType.success:
        await HapticFeedback.lightImpact();
        break;
      case CUHapticFeedbackType.warning:
        await HapticFeedback.mediumImpact();
        break;
      case CUHapticFeedbackType.error:
        await HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Vibrate pattern - custom patterns for specific events
  Future<void> vibratePattern(CUHapticPattern pattern) async {
    if (!_enabled) return;
    switch (pattern) {
      case CUHapticPattern.login:
        await HapticFeedback.mediumImpact();
        break;
      case CUHapticPattern.success:
        await HapticFeedback.lightImpact();
        break;
      case CUHapticPattern.error:
        await HapticFeedback.heavyImpact();
        break;
      case CUHapticPattern.transaction:
        await HapticFeedback.lightImpact();
        break;
      case CUHapticPattern.navigation:
        await HapticFeedback.selectionClick();
        break;
    }
  }

  /// Check if haptics enabled from theme context
  static bool isEnabledFromTheme(CUThemeData? theme) {
    if (theme == null) return true;
    return theme.hapticsEnabled && _instance._enabled;
  }
}