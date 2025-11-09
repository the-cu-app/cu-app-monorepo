import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter/services.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../models/security_model.dart';
import '../services/security_service.dart';
import '../widgets/security_score_widget.dart';
import '../widgets/consistent_list_tile.dart';
import 'two_factor_setup_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final SecurityService _securityService = SecurityService();
  SecuritySettings _settings = SecuritySettings.empty();
  List<ActiveSession> _activeSessions = [];
  List<LoginActivity> _loginActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecurityData();
  }

  Future<void> _loadSecurityData() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await _securityService.getSecuritySettings();
      final sessions = await _securityService.getActiveSessions();
      final activity = await _securityService.getLoginActivity();
      
      setState(() {
        _settings = settings;
        _activeSessions = sessions;
        _loginActivity = activity;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load security settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showSecurityHelp,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSecurityData,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1200 : double.infinity,
                  ),
                  child: CustomScrollView(
                    slivers: [
                      // Security Score Card
                      SliverPadding(
                        padding: EdgeInsets.all(isDesktop ? 40.0 : 16.0),
                        sliver: SliverToBoxAdapter(
                          child: SecurityScoreWidget(
                            score: _settings.securityScore,
                            level: _settings.securityLevel,
                            onTap: _showRecommendations,
                          ),
                        ),
                      ),

                      // Two-Factor Authentication Section
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 40.0 : 16.0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildSection(
                            title: 'Two-Factor Authentication',
                            icon: Icons.phonelink_lock,
                            children: [
                              _buildSettingCard(
                                title: '2FA Status',
                                subtitle: _settings.twoFactorEnabled
                                    ? 'Enabled via ${_settings.twoFactorMethod?.displayName ?? "Unknown"}'
                                    : 'Not enabled',
                                trailing: Switch(
                                  value: _settings.twoFactorEnabled,
                                  onChanged: _toggle2FA,
                                ),
                              ),
                              if (_settings.twoFactorEnabled) ...[
                                _buildSettingCard(
                                  title: 'Backup Codes',
                                  subtitle: '${_settings.backupCodes.length} codes available',
                                  onTap: _showBackupCodes,
                                ),
                                _buildSettingCard(
                                  title: 'Change 2FA Method',
                                  subtitle: 'Switch to a different method',
                                  onTap: _change2FAMethod,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Biometric Security Section
                      SliverPadding(
                        padding: EdgeInsets.all(isDesktop ? 40.0 : 16.0),
                        sliver: SliverToBoxAdapter(
                          child: _buildSection(
                            title: 'Biometric Security',
                            icon: Icons.fingerprint,
                            children: [
                              _buildSettingCard(
                                title: 'Biometric Authentication',
                                subtitle: 'Use Face ID, Touch ID, or Fingerprint',
                                trailing: Switch(
                                  value: _settings.biometricEnabled,
                                  onChanged: _toggleBiometric,
                                ),
                              ),
                              if (_settings.biometricEnabled) ...[
                                _buildSettingCard(
                                  title: 'App Launch',
                                  subtitle: 'Require biometric to open the app',
                                  trailing: Switch(
                                    value: _settings.biometricForAppLaunch,
                                    onChanged: _toggleBiometricForAppLaunch,
                                  ),
                                ),
                                _buildSettingCard(
                                  title: 'Transactions',
                                  subtitle: 'Require biometric for all transactions',
                                  trailing: Switch(
                                    value: _settings.biometricForTransactions,
                                    onChanged: _toggleBiometricForTransactions,
                                  ),
                                ),
                                _buildSettingCard(
                                  title: 'Sensitive Data',
                                  subtitle: 'Require biometric to view account details',
                                  trailing: Switch(
                                    value: _settings.biometricForSensitiveData,
                                    onChanged: _toggleBiometricForSensitiveData,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Session Management Section
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 40.0 : 16.0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildSection(
                            title: 'Session Management',
                            icon: Icons.devices,
                            children: [
                              ..._activeSessions.map((session) => _buildSessionCard(session)),
                              if (_activeSessions.length > 1)
                                _buildActionCard(
                                  title: 'Sign Out Other Devices',
                                  subtitle: 'End all sessions except this one',
                                  icon: Icons.logout,
                                  onTap: _logoutOtherDevices,
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Account Security Section
                      SliverPadding(
                        padding: EdgeInsets.all(isDesktop ? 40.0 : 16.0),
                        sliver: SliverToBoxAdapter(
                          child: _buildSection(
                            title: 'Account Security',
                            icon: Icons.lock_outline,
                            children: [
                              _buildSettingCard(
                                title: 'Change Password',
                                subtitle: _settings.lastPasswordChange != null
                                    ? 'Last changed ${_formatDate(_settings.lastPasswordChange!)}'
                                    : 'Never changed',
                                onTap: _changePassword,
                              ),
                              _buildSettingCard(
                                title: 'Change PIN',
                                subtitle: 'Update your 4-digit PIN',
                                onTap: _changePIN,
                              ),
                              _buildSettingCard(
                                title: 'Security Questions',
                                subtitle: '${_settings.securityQuestions.length} questions set',
                                onTap: _manageSecurityQuestions,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Notifications Section
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 40.0 : 16.0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildSection(
                            title: 'Security Alerts',
                            icon: Icons.notifications_active,
                            children: [
                              _buildSettingCard(
                                title: 'Login Notifications',
                                subtitle: 'Get notified of new logins',
                                trailing: Switch(
                                  value: _settings.loginNotificationsEnabled,
                                  onChanged: _toggleLoginNotifications,
                                ),
                              ),
                              _buildSettingCard(
                                title: 'Account Activity Alerts',
                                subtitle: 'Suspicious activity notifications',
                                trailing: Switch(
                                  value: _settings.accountActivityAlertsEnabled,
                                  onChanged: _toggleActivityAlerts,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Recent Activity Section
                      SliverPadding(
                        padding: EdgeInsets.all(isDesktop ? 40.0 : 16.0),
                        sliver: SliverToBoxAdapter(
                          child: _buildSection(
                            title: 'Recent Login Activity',
                            icon: Icons.history,
                            children: [
                              if (_loginActivity.isEmpty)
                                _buildEmptyActivityCard()
                              else
                                ..._loginActivity.take(5).map((activity) =>
                                    _buildActivityCard(activity)),
                              if (_loginActivity.length > 5)
                                _buildActionCard(
                                  title: 'View All Activity',
                                  subtitle: 'See complete login history',
                                  icon: Icons.arrow_forward,
                                  onTap: _viewAllActivity,
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Add bottom padding
                      const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ConsistentListTile(
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        title: ConsistentListTileTitle(text: title),
        subtitle: ConsistentListTileSubtitle(text: subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSessionCard(ActiveSession session) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ConsistentListTile(
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        leading: ConsistentListTileLeading(
          icon: _getDeviceIcon(session.deviceType),
          backgroundColor: session.isCurrent
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceVariant,
          iconColor: session.isCurrent
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Row(
          children: [
            Text(session.deviceName),
            if (session.isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Current',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.location),
            Text('Last active: ${_formatDate(session.lastActive)}'),
          ],
        ),
        trailing: !session.isCurrent
            ? IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _logoutSession(session),
              )
            : null,
      ),
    );
  }

  Widget _buildActivityCard(LoginActivity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ConsistentListTile(
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        leading: ConsistentListTileLeading(
          icon: activity.wasSuccessful ? Icons.check : Icons.close,
          backgroundColor: activity.wasSuccessful
              ? Colors.green.withOpacity(0.2)
              : Theme.of(context).colorScheme.error.withOpacity(0.2),
          iconColor: activity.wasSuccessful
                ? Colors.green
                : Theme.of(context).colorScheme.error,
        ),
        title: Text(
          activity.wasSuccessful ? 'Successful Login' : 'Failed Login Attempt',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity.deviceName),
            Text(activity.location),
            Text(_formatDate(activity.timestamp)),
            if (!activity.wasSuccessful && activity.failureReason != null)
              Text(
                activity.failureReason!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No recent login activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ConsistentListTile(
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        leading: ConsistentListTileLeading(
          icon: icon,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        title: ConsistentListTileTitle(text: title),
        subtitle: ConsistentListTileSubtitle(text: subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet;
      case 'desktop':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Action Methods
  Future<void> _toggle2FA(bool value) async {
    if (value) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TwoFactorSetupScreen(),
        ),
      );
      if (result == true) {
        await _loadSecurityData();
      }
    } else {
      _showConfirmationDialog(
        title: 'Disable Two-Factor Authentication?',
        message: 'This will make your account less secure. Are you sure?',
        onConfirm: () async {
          await _updateSettings(_settings.copyWith(twoFactorEnabled: false));
          _showSuccessSnackBar('Two-factor authentication disabled');
        },
      );
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final availability = await _securityService.checkBiometricAvailability();
      if (!availability['available']) {
        _showErrorSnackBar('Biometric authentication not available on this device');
        return;
      }

      final authenticated = await _securityService.authenticateWithBiometric(
        'Enable biometric authentication for SUPAHYPER',
      );

      if (authenticated) {
        await _updateSettings(_settings.copyWith(
          biometricEnabled: true,
          enabledBiometrics: Set.from(availability['types']),
        ));
        _showSuccessSnackBar('Biometric authentication enabled');
      }
    } else {
      await _updateSettings(_settings.copyWith(biometricEnabled: false));
      _showSuccessSnackBar('Biometric authentication disabled');
    }
  }

  Future<void> _toggleBiometricForAppLaunch(bool value) async {
    await _updateSettings(_settings.copyWith(biometricForAppLaunch: value));
    _showSuccessSnackBar(
      value ? 'Biometric required for app launch' : 'Biometric for app launch disabled',
    );
  }

  Future<void> _toggleBiometricForTransactions(bool value) async {
    await _updateSettings(_settings.copyWith(biometricForTransactions: value));
    _showSuccessSnackBar(
      value ? 'Biometric required for transactions' : 'Biometric for transactions disabled',
    );
  }

  Future<void> _toggleBiometricForSensitiveData(bool value) async {
    await _updateSettings(_settings.copyWith(biometricForSensitiveData: value));
    _showSuccessSnackBar(
      value ? 'Biometric required for sensitive data' : 'Biometric for sensitive data disabled',
    );
  }

  Future<void> _toggleLoginNotifications(bool value) async {
    await _updateSettings(_settings.copyWith(loginNotificationsEnabled: value));
    _showSuccessSnackBar(
      value ? 'Login notifications enabled' : 'Login notifications disabled',
    );
  }

  Future<void> _toggleActivityAlerts(bool value) async {
    await _updateSettings(_settings.copyWith(accountActivityAlertsEnabled: value));
    _showSuccessSnackBar(
      value ? 'Activity alerts enabled' : 'Activity alerts disabled',
    );
  }

  Future<void> _updateSettings(SecuritySettings settings) async {
    try {
      await _securityService.updateSecuritySettings(settings);
      setState(() => _settings = settings);
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Failed to update settings');
    }
  }

  void _showBackupCodes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Codes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Save these codes in a safe place. Each code can only be used once.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _settings.backupCodes
                    .map((code) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: _generateNewBackupCodes,
            icon: const Icon(Icons.refresh),
            label: const Text('Generate New'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateNewBackupCodes() async {
    try {
      final codes = await _securityService.generateBackupCodes();
      await _updateSettings(_settings.copyWith(backupCodes: codes));
      Navigator.pop(context);
      _showBackupCodes();
      _showSuccessSnackBar('New backup codes generated');
    } catch (e) {
      _showErrorSnackBar('Failed to generate backup codes');
    }
  }

  void _change2FAMethod() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TwoFactorSetupScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadSecurityData();
      }
    });
  }

  Future<void> _logoutSession(ActiveSession session) async {
    _showConfirmationDialog(
      title: 'End Session?',
      message: 'This will sign out the device "${session.deviceName}".',
      onConfirm: () async {
        // In a real app, this would end the specific session
        _showSuccessSnackBar('Session ended');
        await _loadSecurityData();
      },
    );
  }

  Future<void> _logoutOtherDevices() async {
    _showConfirmationDialog(
      title: 'Sign Out Other Devices?',
      message: 'This will end all sessions except the current one.',
      onConfirm: () async {
        await _securityService.logoutOtherDevices();
        await _loadSecurityData();
        _showSuccessSnackBar('All other devices signed out');
      },
    );
  }

  void _changePassword() {
    // Navigate to password change screen
    _showInfoSnackBar('Password change coming soon');
  }

  void _changePIN() {
    // Navigate to PIN change screen
    _showInfoSnackBar('PIN change coming soon');
  }

  void _manageSecurityQuestions() {
    // Navigate to security questions screen
    _showInfoSnackBar('Security questions management coming soon');
  }

  void _viewAllActivity() {
    // Navigate to full activity screen
    _showInfoSnackBar('Activity history coming soon');
  }

  void _showRecommendations() {
    final recommendations = _securityService.getSecurityRecommendations(_settings);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security Recommendations',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final rec = recommendations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ConsistentListTile(
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        title: ConsistentListTileTitle(text: rec.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            ConsistentListTileSubtitle(text: rec.description),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+${(rec.scoreImpact * 100).toInt()}% security score',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            rec.onAction?.call();
                          },
                          child: Text(rec.actionLabel),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSecurityHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Help'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security Score',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Your security score is calculated based on enabled security features. A higher score means better protection for your account.',
              ),
              SizedBox(height: 16),
              Text(
                'Two-Factor Authentication',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Adds an extra layer of security by requiring a second form of verification when signing in.',
              ),
              SizedBox(height: 16),
              Text(
                'Biometric Security',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Use your fingerprint or face to quickly and securely access your account and authorize transactions.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
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

  void _showInfoSnackBar(String message) {
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(message)),

          );
  }
}