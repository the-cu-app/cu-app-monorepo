import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accessibilityService = context.watch<AccessibilityService>();
    final theme = CUTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
          ),
          child: CustomScrollView(
            slivers: [
              // Header with back button
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Accessibility Settings',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customize visual preferences and color settings',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Visual Preferences Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    'Visual Preferences',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      fontFamily: 'Geist',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildSwitchCard(
                        context,
                        theme: theme,
                        icon: Icons.palette,
                        iconColor: Colors.blue,
                        title: 'Use Color Indicators',
                        description: 'Show positive balances in green and negative in red',
                        value: accessibilityService.useColorIndicators,
                        onChanged: (value) => accessibilityService.setUseColorIndicators(value),
                      ),
                      const SizedBox(height: 12),
                      _buildSwitchCard(
                        context,
                        theme: theme,
                        icon: Icons.contrast,
                        iconColor: Colors.orange,
                        title: 'High Contrast Mode',
                        description: 'Increase contrast for better visibility',
                        value: accessibilityService.highContrastMode,
                        onChanged: (value) => accessibilityService.setHighContrastMode(value),
                      ),
                    ],
                  ),
                ),
              ),

              // Color Blindness Support Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Text(
                    'Color Blindness Support',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      fontFamily: 'Geist',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildRadioCard(
                        context,
                        theme: theme,
                        title: 'None',
                        subtitle: 'Standard color scheme',
                        isSelected: accessibilityService.colorBlindnessType == ColorBlindnessType.none,
                        onTap: () => accessibilityService.setColorBlindnessType(ColorBlindnessType.none),
                      ),
                      const SizedBox(height: 12),
                      _buildRadioCard(
                        context,
                        theme: theme,
                        title: 'Protanopia',
                        subtitle: 'Red color blindness',
                        isSelected: accessibilityService.colorBlindnessType == ColorBlindnessType.protanopia,
                        onTap: () => accessibilityService.setColorBlindnessType(ColorBlindnessType.protanopia),
                      ),
                      const SizedBox(height: 12),
                      _buildRadioCard(
                        context,
                        theme: theme,
                        title: 'Deuteranopia',
                        subtitle: 'Green color blindness',
                        isSelected: accessibilityService.colorBlindnessType == ColorBlindnessType.deuteranopia,
                        onTap: () => accessibilityService.setColorBlindnessType(ColorBlindnessType.deuteranopia),
                      ),
                      const SizedBox(height: 12),
                      _buildRadioCard(
                        context,
                        theme: theme,
                        title: 'Tritanopia',
                        subtitle: 'Blue color blindness',
                        isSelected: accessibilityService.colorBlindnessType == ColorBlindnessType.tritanopia,
                        onTap: () => accessibilityService.setColorBlindnessType(ColorBlindnessType.tritanopia),
                      ),
                      const SizedBox(height: 12),
                      _buildRadioCard(
                        context,
                        theme: theme,
                        title: 'Monochromacy',
                        subtitle: 'Complete color blindness',
                        isSelected: accessibilityService.colorBlindnessType == ColorBlindnessType.monochromacy,
                        onTap: () => accessibilityService.setColorBlindnessType(ColorBlindnessType.monochromacy),
                      ),
                    ],
                  ),
                ),
              ),

              // Color Preview Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Text(
                    'Color Preview',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      fontFamily: 'Geist',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: _buildColorPreview(context, accessibilityService, theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchCard(
    BuildContext context, {
    required CUThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CUOutlinedCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: value
                    ? theme.colorScheme.primary
                    : Colors.grey.shade300,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioCard(
    BuildContext context, {
    required CUThemeData theme,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return CUOutlinedCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
                width: 2,
              ),
              color: Colors.white,
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                    color: isSelected ? theme.colorScheme.primary : Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.visibility,
            color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildColorPreview(BuildContext context, AccessibilityService service, CUThemeData theme) {
    final isDarkMode = theme.isDark;

    final positiveBalance = 1234.56;
    final negativeBalance = -567.89;

    final positiveColor = service.getBalanceColor(positiveBalance, isDarkMode: isDarkMode);
    final negativeColor = service.getBalanceColor(negativeBalance, isDarkMode: isDarkMode);

    return CUOutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Positive Balance:',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Geist',
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '\$1,234.56',
                style: TextStyle(
                  color: service.useColorIndicators ? positiveColor : Colors.grey.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Negative Balance:',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Geist',
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '-\$567.89',
                style: TextStyle(
                  color: service.useColorIndicators ? negativeColor : Colors.grey.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Color Transformation Preview:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 12),
          _buildColorSwatch(context, service, theme),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(BuildContext context, AccessibilityService service, CUThemeData theme) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.grey.shade700,
      Colors.grey.shade400,
      Colors.grey.shade200,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: colors.map((color) {
        final transformedColor = service.transformColor(color);
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: transformedColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        );
      }).toList(),
    );
  }
}
