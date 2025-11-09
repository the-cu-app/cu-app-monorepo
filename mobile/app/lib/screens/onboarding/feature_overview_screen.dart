import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

/// Feature overview screen - simplified single view
class FeatureOverviewScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const FeatureOverviewScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<FeatureOverviewScreen> createState() => _FeatureOverviewScreenState();
}

class _FeatureOverviewScreenState extends State<FeatureOverviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final _mainFeature = _Feature(
    title: 'Modern Banking',
    description: 'Everything you need in one place',
    icon: Icons.account_balance,
    details: [
      'Connect all your accounts',
      'Track spending instantly',
      'Create virtual cards',
      'Transfer money easily',
    ],
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _animationController.value,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _mainFeature.icon,
                    size: 50,
                    color: theme.colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Title
                Text(
                  _mainFeature.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  _mainFeature.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Feature list
                ...(_mainFeature.details.map((detail) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        detail,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ))),
                
                const Spacer(),
                
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.onNext,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Feature {
  final String title;
  final String description;
  final IconData icon;
  final List<String> details;

  _Feature({
    required this.title,
    required this.description,
    required this.icon,
    required this.details,
  });
}