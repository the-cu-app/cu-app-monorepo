import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter/cupertino.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

/// Personalization screen with settings preferences
class PersonalizationScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const PersonalizationScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  
  // Preferences
  bool _enableNotifications = true;
  bool _enableBiometric = true;
  bool _enableLocationServices = false;
  bool _enableDataSync = true;
  bool _enableMarketingEmails = false;
  String _selectedTheme = 'auto';
  String _selectedCurrency = 'USD';

  final List<_SettingSection> _sections = [
    _SettingSection(
      title: 'Security & Privacy',
      icon: Icons.security,
      color: const Color(0xFF6B5B95),
      settings: [
        _SettingItem(
          title: 'Biometric Authentication',
          subtitle: 'Use Face ID or Touch ID to sign in',
          icon: Icons.fingerprint,
          type: _SettingType.toggle,
          key: 'biometric',
        ),
        _SettingItem(
          title: 'Transaction Notifications',
          subtitle: 'Get alerts for all account activity',
          icon: Icons.notifications,
          type: _SettingType.toggle,
          key: 'notifications',
        ),
        _SettingItem(
          title: 'Location Services',
          subtitle: 'Enhanced security based on location',
          icon: Icons.location_on,
          type: _SettingType.toggle,
          key: 'location',
        ),
      ],
    ),
    _SettingSection(
      title: 'Display & Preferences',
      icon: Icons.palette,
      color: const Color(0xFF4ECDC4),
      settings: [
        _SettingItem(
          title: 'App Theme',
          subtitle: 'Choose your preferred appearance',
          icon: Icons.dark_mode,
          type: _SettingType.selection,
          key: 'theme',
          options: ['Light', 'Dark', 'Auto'],
        ),
        _SettingItem(
          title: 'Currency',
          subtitle: 'Set your default currency',
          icon: Icons.attach_money,
          type: _SettingType.selection,
          key: 'currency',
          options: ['USD', 'EUR', 'GBP', 'CAD'],
        ),
      ],
    ),
    _SettingSection(
      title: 'Data & Sync',
      icon: Icons.sync,
      color: const Color(0xFFFF6B6B),
      settings: [
        _SettingItem(
          title: 'Auto-sync Accounts',
          subtitle: 'Keep your connected accounts updated',
          icon: Icons.cloud_sync,
          type: _SettingType.toggle,
          key: 'datasync',
        ),
        _SettingItem(
          title: 'Marketing Communications',
          subtitle: 'Receive offers and updates',
          icon: Icons.mail,
          type: _SettingType.toggle,
          key: 'marketing',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _sections.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 500 + (index * 100)),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();

    // Start animations
    for (var controller in _controllers) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        
        // Title
        const Text(
          'Personalize Your Experience',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can change these anytime in Settings',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        
        // Settings tip
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1DB954).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1DB954).withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF1DB954),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Access Settings from your profile icon in the top-right corner',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Settings sections
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              return FadeTransition(
                opacity: _animations[index],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(_animations[index]),
                  child: _buildSettingSection(_sections[index]),
                ),
              );
            },
          ),
        ),
        
        // Continue button
        Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: widget.onNext,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingSection(_SettingSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            section.color.withOpacity(0.2),
            section.color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: section.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: section.color.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  section.icon,
                  color: section.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  section.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Settings items
          ...section.settings.map((setting) {
            return _buildSettingItem(setting, section.color);
          }),
        ],
      ),
    );
  }

  Widget _buildSettingItem(_SettingItem item, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildSettingControl(item),
        ],
      ),
    );
  }

  Widget _buildSettingControl(_SettingItem item) {
    switch (item.type) {
      case _SettingType.toggle:
        bool value = false;
        switch (item.key) {
          case 'biometric':
            value = _enableBiometric;
            break;
          case 'notifications':
            value = _enableNotifications;
            break;
          case 'location':
            value = _enableLocationServices;
            break;
          case 'datasync':
            value = _enableDataSync;
            break;
          case 'marketing':
            value = _enableMarketingEmails;
            break;
        }
        
        return CupertinoSwitch(
          value: value,
          activeColor: const Color(0xFF1DB954),
          onChanged: (newValue) {
            setState(() {
              switch (item.key) {
                case 'biometric':
                  _enableBiometric = newValue;
                  break;
                case 'notifications':
                  _enableNotifications = newValue;
                  break;
                case 'location':
                  _enableLocationServices = newValue;
                  break;
                case 'datasync':
                  _enableDataSync = newValue;
                  break;
                case 'marketing':
                  _enableMarketingEmails = newValue;
                  break;
              }
            });
          },
        );
        
      case _SettingType.selection:
        String value = '';
        switch (item.key) {
          case 'theme':
            value = _selectedTheme;
            break;
          case 'currency':
            value = _selectedCurrency;
            break;
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text(
                value.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        );
    }
  }
}

class _SettingSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<_SettingItem> settings;

  _SettingSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.settings,
  });
}

class _SettingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final _SettingType type;
  final String key;
  final List<String>? options;

  _SettingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.key,
    this.options,
  });
}

enum _SettingType { toggle, selection }