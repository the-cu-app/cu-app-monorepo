import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorBlindnessType {
  none,
  protanopia, // Red-blind
  deuteranopia, // Green-blind
  tritanopia, // Blue-blind
  monochromacy, // Total color blindness
}

class AccessibilityService extends ChangeNotifier {
  static const String _colorBlindnessKey = 'color_blindness_type';
  static const String _useColorIndicatorsKey = 'use_color_indicators';
  static const String _highContrastKey = 'high_contrast_mode';

  ColorBlindnessType _colorBlindnessType = ColorBlindnessType.none;
  bool _useColorIndicators = false;
  bool _highContrastMode = false;

  ColorBlindnessType get colorBlindnessType => _colorBlindnessType;
  bool get useColorIndicators => _useColorIndicators;
  bool get highContrastMode => _highContrastMode;

  AccessibilityService() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    final typeIndex = prefs.getInt(_colorBlindnessKey) ?? 0;
    _colorBlindnessType = ColorBlindnessType.values[typeIndex];
    
    _useColorIndicators = prefs.getBool(_useColorIndicatorsKey) ?? false;
    _highContrastMode = prefs.getBool(_highContrastKey) ?? false;
    
    notifyListeners();
  }

  Future<void> setColorBlindnessType(ColorBlindnessType type) async {
    _colorBlindnessType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorBlindnessKey, type.index);
    notifyListeners();
  }

  Future<void> setUseColorIndicators(bool value) async {
    _useColorIndicators = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useColorIndicatorsKey, value);
    notifyListeners();
  }

  Future<void> setHighContrastMode(bool value) async {
    _highContrastMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
    notifyListeners();
  }

  // Color transformation methods for different types of color blindness
  Color transformColor(Color color) {
    switch (_colorBlindnessType) {
      case ColorBlindnessType.protanopia:
        return _protanopiaTransform(color);
      case ColorBlindnessType.deuteranopia:
        return _deuteranopiaTransform(color);
      case ColorBlindnessType.tritanopia:
        return _tritanopiaTransform(color);
      case ColorBlindnessType.monochromacy:
        return _monochromacyTransform(color);
      case ColorBlindnessType.none:
      default:
        return color;
    }
  }

  // Protanopia (red-blind) transformation
  Color _protanopiaTransform(Color color) {
    final r = color.red;
    final g = color.green;
    final b = color.blue;

    // Transformation matrix for protanopia
    final newR = (0.567 * r + 0.433 * g).round().clamp(0, 255);
    final newG = (0.558 * r + 0.442 * g).round().clamp(0, 255);
    final newB = (0.0 * r + 0.242 * g + 0.758 * b).round().clamp(0, 255);

    return Color.fromARGB(color.alpha, newR, newG, newB);
  }

  // Deuteranopia (green-blind) transformation
  Color _deuteranopiaTransform(Color color) {
    final r = color.red;
    final g = color.green;
    final b = color.blue;

    // Transformation matrix for deuteranopia
    final newR = (0.625 * r + 0.375 * g).round().clamp(0, 255);
    final newG = (0.7 * r + 0.3 * g).round().clamp(0, 255);
    final newB = (0.0 * r + 0.3 * g + 0.7 * b).round().clamp(0, 255);

    return Color.fromARGB(color.alpha, newR, newG, newB);
  }

  // Tritanopia (blue-blind) transformation
  Color _tritanopiaTransform(Color color) {
    final r = color.red;
    final g = color.green;
    final b = color.blue;

    // Transformation matrix for tritanopia
    final newR = (0.95 * r + 0.05 * g).round().clamp(0, 255);
    final newG = (0.0 * r + 0.433 * g + 0.567 * b).round().clamp(0, 255);
    final newB = (0.0 * r + 0.475 * g + 0.525 * b).round().clamp(0, 255);

    return Color.fromARGB(color.alpha, newR, newG, newB);
  }

  // Monochromacy (total color blindness) transformation
  Color _monochromacyTransform(Color color) {
    // Convert to grayscale using luminosity method
    final gray = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue).round();
    return Color.fromARGB(color.alpha, gray, gray, gray);
  }

  // Get accessible color for positive/negative values
  Color getBalanceColor(double balance, {required bool isDarkMode}) {
    if (!_useColorIndicators) {
      return isDarkMode ? Colors.white : Colors.black;
    }

    Color baseColor;
    if (balance >= 0) {
      // Positive balance - use green variants
      baseColor = isDarkMode ? Colors.green.shade300 : Colors.green.shade700;
    } else {
      // Negative balance - use red variants
      baseColor = isDarkMode ? Colors.red.shade300 : Colors.red.shade700;
    }

    // Apply color transformation for color blindness
    return transformColor(baseColor);
  }

  // Get semantic label for balance
  String getBalanceSemanticLabel(double balance, String formattedAmount) {
    final status = balance >= 0 ? 'positive' : 'negative';
    return 'Balance: $formattedAmount, $status';
  }

  // Get high contrast color
  Color getHighContrastColor(Color color, {required bool isDarkMode}) {
    if (!_highContrastMode) return color;
    
    // Increase contrast for better visibility
    if (isDarkMode) {
      // Make light colors lighter in dark mode
      final hsl = HSLColor.fromColor(color);
      return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
    } else {
      // Make dark colors darker in light mode
      final hsl = HSLColor.fromColor(color);
      return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
    }
  }
}