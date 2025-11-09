import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:provider/provider.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../services/accessibility_service.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            title: 'Visual Preferences',
            children: [
              SwitchListTile(
                title: const Text('Use Color Indicators'),
                subtitle: const Text('Show positive balances in green and negative in red'),
                value: accessibilityService.useColorIndicators,
                onChanged: (value) {
                  accessibilityService.setUseColorIndicators(value);
                },
                secondary: Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SwitchListTile(
                title: const Text('High Contrast Mode'),
                subtitle: const Text('Increase contrast for better visibility'),
                value: accessibilityService.highContrastMode,
                onChanged: (value) {
                  accessibilityService.setHighContrastMode(value);
                },
                secondary: Icon(
                  Icons.contrast,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'Color Blindness Support',
            children: [
              _buildColorBlindnessOption(
                context,
                title: 'None',
                subtitle: 'Standard color scheme',
                type: ColorBlindnessType.none,
                currentType: accessibilityService.colorBlindnessType,
                onChanged: (type) {
                  accessibilityService.setColorBlindnessType(type!);
                },
              ),
              _buildColorBlindnessOption(
                context,
                title: 'Protanopia',
                subtitle: 'Red color blindness',
                type: ColorBlindnessType.protanopia,
                currentType: accessibilityService.colorBlindnessType,
                onChanged: (type) {
                  accessibilityService.setColorBlindnessType(type!);
                },
              ),
              _buildColorBlindnessOption(
                context,
                title: 'Deuteranopia',
                subtitle: 'Green color blindness',
                type: ColorBlindnessType.deuteranopia,
                currentType: accessibilityService.colorBlindnessType,
                onChanged: (type) {
                  accessibilityService.setColorBlindnessType(type!);
                },
              ),
              _buildColorBlindnessOption(
                context,
                title: 'Tritanopia',
                subtitle: 'Blue color blindness',
                type: ColorBlindnessType.tritanopia,
                currentType: accessibilityService.colorBlindnessType,
                onChanged: (type) {
                  accessibilityService.setColorBlindnessType(type!);
                },
              ),
              _buildColorBlindnessOption(
                context,
                title: 'Monochromacy',
                subtitle: 'Complete color blindness',
                type: ColorBlindnessType.monochromacy,
                currentType: accessibilityService.colorBlindnessType,
                onChanged: (type) {
                  accessibilityService.setColorBlindnessType(type!);
                },
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'Color Preview',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildColorPreview(context, accessibilityService),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildColorBlindnessOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required ColorBlindnessType type,
    required ColorBlindnessType currentType,
    required ValueChanged<ColorBlindnessType?> onChanged,
  }) {
    return RadioListTile<ColorBlindnessType>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: type,
      groupValue: currentType,
      onChanged: onChanged,
      secondary: Icon(
        Icons.visibility,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildColorPreview(BuildContext context, AccessibilityService service) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final positiveBalance = 1234.56;
    final negativeBalance = -567.89;
    
    final positiveColor = service.getBalanceColor(positiveBalance, isDarkMode: isDarkMode);
    final negativeColor = service.getBalanceColor(negativeBalance, isDarkMode: isDarkMode);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Positive Balance:'),
              Text(
                '\$1,234.56',
                style: TextStyle(
                  color: service.useColorIndicators ? positiveColor : null,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Negative Balance:'),
              Text(
                '-\$567.89',
                style: TextStyle(
                  color: service.useColorIndicators ? negativeColor : null,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildColorSwatch(context, service),
        ],
      ),
    );
  }
  
  Widget _buildColorSwatch(BuildContext context, AccessibilityService service) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color Transformation Preview:', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: colors.map((color) {
            final transformedColor = service.transformColor(color);
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: transformedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}