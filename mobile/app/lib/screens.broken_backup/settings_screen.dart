import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter/services.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/banking_service.dart';
import '../services/sound_service.dart';
import 'accessibility_settings_screen.dart';
import 'security_settings_screen.dart';
import '../widgets/consistent_list_tile.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool)? onThemeToggle;
  final bool? currentTheme;

  const SettingsScreen({super.key, this.onThemeToggle, this.currentTheme});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  String _themeMode = 'system';
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _pilotModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.currentTheme == null ? 'system' : (widget.currentTheme! ? 'dark' : 'light');
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final biometricAvailable = await _authService.isBiometricAvailable;
      final biometricEnabled = await _authService.isBiometricEnabled;
      
      // Load pilot mode preference
      final prefs = await SharedPreferences.getInstance();
      final pilotMode = prefs.getBool('pilot_mode') ?? false;

      setState(() {
        _biometricEnabled = biometricEnabled && biometricAvailable;
        _pilotModeEnabled = pilotMode;
      });
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> _togglePilotMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pilot_mode', value);
    setState(() {
      _pilotModeEnabled = value;
    });
    
    // Show info about pilot mode
    if (value && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Pilot Mode enabled! Shake your device to send feedback.)),

          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
          ),
          child: ListView(
            padding: EdgeInsets.all(isDesktop ? 40.0 : 16.0),
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Account & Security'),
          _buildSettingTile(
            icon: Icons.person_outline,
            title: 'Profile Information',
            subtitle: 'Update your personal details',
            onTap: () => _showProfileDialog(context),
          ),
          _buildSettingTile(
            icon: Icons.security,
            title: 'Security Settings',
            subtitle: 'Password, 2FA, and security options',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SecuritySettingsScreen(),
              ),
            ),
          ),
          _buildSettingTile(
            icon: Icons.fingerprint,
            title: 'Biometric Authentication',
            subtitle: 'Use Face ID or Touch ID to sign in',
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: _biometricEnabled ? _toggleBiometric : null,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Banking & Accounts'),
          _buildSettingTile(
            icon: Icons.account_balance,
            title: 'Connect More Accounts',
            subtitle: 'Link additional bank accounts or credit cards',
            onTap: () => _navigateToConnectAccounts(context),
          ),
          _buildSettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('App & Display'),
          _buildSettingTile(
            icon: Icons.dark_mode,
            title: 'Theme',
            subtitle: _themeMode == 'system' ? 'System default' : (_themeMode == 'dark' ? 'Dark mode' : 'Light mode'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),
          _buildSettingTile(
            icon: Icons.accessibility_new,
            title: 'Accessibility',
            subtitle: 'Color blindness support and visual preferences',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccessibilitySettingsScreen(),
              ),
            ),
          ),
          _buildSettingTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English (US)',
            onTap: () => _showLanguageDialog(context),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Developer Options'),
          _buildSettingTile(
            icon: Icons.smart_toy,
            title: 'AI Account Setup (Demo)',
            subtitle: 'Try our AI-driven account creation experience',
            onTap: () => Navigator.of(context).pushNamed('/ai-signup'),
          ),
          _buildSettingTile(
            icon: Icons.account_tree,
            title: 'Browse Account Products',
            subtitle: 'View available banking and investment products',
            onTap: () => Navigator.of(context).pushNamed('/account-products'),
          ),
          _buildSettingTile(
            icon: Icons.bug_report_outlined,
            title: 'Pilot Mode',
            subtitle: 'Shake to give feedback',
            trailing: Switch(
              value: _pilotModeEnabled,
              onChanged: _togglePilotMode,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Support & About'),
          _buildSettingTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () => _showHelpDialog(context),
          ),
          _buildSettingTile(
            icon: Icons.info_outline,
            title: 'About CU.APP',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 24),
          _buildCertificationBadge(),
          const SizedBox(height: 32),
          _buildSignOutButton(),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ConsistentListTile(
        leading: ConsistentListTileLeading(
          icon: icon,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          iconColor: Theme.of(context).colorScheme.primary,
        ),
        title: ConsistentListTileTitle(text: title),
        subtitle: ConsistentListTileSubtitle(text: subtitle),
        trailing: trailing,
        onTap: onTap,
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
    );
  }

  Widget _buildCertificationBadge() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFraudEducationDialog(),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Certified No Cap App',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'OFFICIAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The secure way to keep your cash',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Learn more about fraud protection',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      if (value) {
        // For now, just show a dialog that biometric is enabled
        // In a real app, you'd need to get the user's credentials
        setState(() {
          _biometricEnabled = true;
        });
        HapticFeedback.lightImpact();
        _showInfoSnackBar('Biometric authentication enabled');
      } else {
        await _authService.disableBiometric();
        setState(() {
          _biometricEnabled = false;
        });
        HapticFeedback.lightImpact();
        _showInfoSnackBar('Biometric authentication disabled');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update biometric settings');
    }
  }

  void _navigateToConnectAccounts(BuildContext context) {
    Navigator.of(context).pushNamed('/plaid-link');
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Information'),
        content: const Text('Profile update functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Settings'),
        content: const Text('Security settings functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: const Text('Language selection functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text('Help and support functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System default'),
              value: 'system',
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() {
                  _themeMode = value!;
                });
                widget.onThemeToggle?.call(false); // Reset to system
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() {
                  _themeMode = value!;
                });
                widget.onThemeToggle?.call(false);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() {
                  _themeMode = value!;
                });
                widget.onThemeToggle?.call(true);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About CU.APP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CU.APP Core Banking Platform'),
            const SizedBox(height: 8),
            Text('Version 1.0.0', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            const Text(
                'White-label banking platform powered by Flutter and Supabase.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoSnackBar(String message) {
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(message)),

          );
  }

  void _showErrorSnackBar(String message) {
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(message)),

          );
  }

  void _showFraudEducationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.blue),
            SizedBox(width: 8),
            Text('Fraud Protection'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How We Protect You:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildProtectionItem('🔐', 'End-to-end encryption for all transactions'),
              _buildProtectionItem('🛡️', 'Real-time fraud monitoring 24/7'),
              _buildProtectionItem('👤', 'Biometric authentication'),
              _buildProtectionItem('🔔', 'Instant alerts for suspicious activity'),
              _buildProtectionItem('💳', 'Zero liability for unauthorized charges'),
              const SizedBox(height: 16),
              const Text(
                'Tips to Stay Safe:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildProtectionItem('✅', 'Never share your login credentials'),
              _buildProtectionItem('✅', 'Enable two-factor authentication'),
              _buildProtectionItem('✅', 'Review transactions regularly'),
              _buildProtectionItem('✅', 'Update your app regularly'),
              _buildProtectionItem('✅', 'Report suspicious activity immediately'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.phone, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report Fraud',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Contact your credit union',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to security settings
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecuritySettingsScreen(),
                ),
              );
            },
            child: const Text('Security Settings'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProtectionItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        SoundService().playButtonTap();
        showSearch(
          context: context,
          delegate: SettingsSearchDelegate(
            theme: theme,
          ),
        );
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark 
              ? Colors.grey.shade900.withOpacity(0.5)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search settings, help, or support...',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 16,
                  fontFamily: 'Geist',
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      // Check if there's an actual authenticated user
      final currentUser = _authService.currentUser;
      
      if (currentUser == null) {
        // If using demo mode, just navigate to login
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
        }
        return;
      }
      
      // Sign out from Supabase
      await _authService.signOut();
      
      if (mounted) {
        // Navigate to auth screen and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    } catch (e) {
      print('Sign out error: $e');
      _showErrorSnackBar('Failed to sign out: ${e.toString()}');
    }
  }
}

// Settings Search Delegate
class SettingsSearchDelegate extends SearchDelegate {
  final ThemeData theme;

  SettingsSearchDelegate({required this.theme});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 18,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        border: InputBorder.none,
      ),
    );
  }

  @override
  String get searchFieldLabel => 'Search settings, help, support...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches(context);
    }
    return _buildSearchResults(context);
  }

  Widget _buildRecentSearches(BuildContext context) {
    final recentSearches = [
      'Dark mode',
      'Notifications',
      'Biometric authentication',
      'Security settings',
      'Help and support',
      'Language',
      'Accessibility',
    ];

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Recent Searches',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...recentSearches.map((search) => ListTile(
          leading: const Icon(Icons.history),
          title: Text(search),
          onTap: () {
            query = search;
            showResults(context);
          },
        )),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Quick Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('Toggle Dark Mode'),
          onTap: () {
            close(context, null);
            // Handle dark mode toggle
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notification Settings'),
          onTap: () {
            close(context, null);
            // Navigate to notifications
          },
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Security Settings'),
          onTap: () {
            close(context, null);
            // Navigate to security
          },
        ),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    // Filter results based on query
    final results = _getSearchResults(query);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          leading: Icon(result['icon'] as IconData),
          title: Text(result['title'] as String),
          subtitle: Text(result['subtitle'] as String),
          onTap: () {
            close(context, result);
            // Handle result tap
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getSearchResults(String query) {
    // Mock search results for settings
    final allResults = [
      {
        'title': 'Dark Mode',
        'subtitle': 'Toggle between light and dark themes',
        'icon': Icons.dark_mode,
      },
      {
        'title': 'Notifications',
        'subtitle': 'Manage your notification preferences',
        'icon': Icons.notifications,
      },
      {
        'title': 'Security Settings',
        'subtitle': 'Password, 2FA, and security options',
        'icon': Icons.security,
      },
      {
        'title': 'Biometric Authentication',
        'subtitle': 'Use Face ID or Touch ID to sign in',
        'icon': Icons.fingerprint,
      },
      {
        'title': 'Language',
        'subtitle': 'Select your preferred language',
        'icon': Icons.language,
      },
      {
        'title': 'Accessibility',
        'subtitle': 'Color blindness support and visual preferences',
        'icon': Icons.accessibility_new,
      },
      {
        'title': 'Help & Support',
        'subtitle': 'Get help and contact support',
        'icon': Icons.help_outline,
      },
    ];

    if (query.isEmpty) return allResults;
    
    return allResults.where((result) {
      final title = (result['title'] as String).toLowerCase();
      final subtitle = (result['subtitle'] as String).toLowerCase();
      final q = query.toLowerCase();
      return title.contains(q) || subtitle.contains(q);
    }).toList();
  }
}
