import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter/services.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'dart:typed_data';
import '../models/security_model.dart';
import '../services/security_service.dart';
import '../config/cu_config_service.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final SecurityService _securityService = SecurityService();
  final PageController _pageController = PageController();
  final TextEditingController _verificationCodeController = TextEditingController();
  
  TwoFactorMethod _selectedMethod = TwoFactorMethod.authenticator;
  int _currentStep = 0;
  bool _isLoading = false;
  String? _qrCodeData;
  String? _secretKey;
  List<String>? _backupCodes;

  @override
  void dispose() {
    _pageController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Two-Factor Authentication'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 600 : double.infinity,
          ),
          child: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(),
              
              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMethodSelection(),
                    _buildSetupStep(),
                    _buildVerificationStep(),
                    _buildBackupCodesStep(),
                    _buildCompletionStep(),
                  ],
                ),
              ),
              
              // Navigation Buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceVariant,
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (index < 4)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMethodSelection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your 2FA Method',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select how you want to receive your verification codes',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          ...TwoFactorMethod.values.map((method) => _buildMethodCard(method)),
        ],
      ),
    );
  }

  Widget _buildMethodCard(TwoFactorMethod method) {
    final isSelected = _selectedMethod == method;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () {
          setState(() => _selectedMethod = method);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getMethodIcon(method),
                size: 32,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Radio<TwoFactorMethod>(
                value: method,
                groupValue: _selectedMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMethod = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupStep() {
    switch (_selectedMethod) {
      case TwoFactorMethod.authenticator:
        return _buildAuthenticatorSetup();
      case TwoFactorMethod.sms:
        return _buildSMSSetup();
      case TwoFactorMethod.email:
        return _buildEmailSetup();
    }
  }

  Widget _buildAuthenticatorSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Up Authenticator App',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan this QR code with your authenticator app',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          
          // QR Code
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _qrCodeData != null
                  ? _buildQRCode(_qrCodeData!)
                  : const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Manual Entry Option
          Card(
            child: ExpansionTile(
              title: const Text('Can\'t scan? Enter manually'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account: SUPAHYPER',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _secretKey ?? 'Loading...',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: _secretKey != null
                                ? () {
                                    Clipboard.setData(ClipboardData(text: _secretKey!));
                                    _showSuccessSnackBar('Secret key copied');
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Supported Apps
          _buildSupportedApps(),
        ],
      ),
    );
  }

  Widget _buildSMSSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SMS Verification Setup',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll send verification codes to your registered phone number',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.phone_android,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Phone Number',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+1 (555) 123-4567',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showInfoSnackBar('Phone number update coming soon');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Change Phone Number'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Standard messaging rates may apply',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email Verification Setup',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll send verification codes to your registered email address',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.email,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Email Address',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'test.user@${CUConfigService().cuDomain}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showInfoSnackBar('Email update coming soon');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Change Email Address'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Make sure you have access to this email address',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify Your Setup',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _getVerificationInstructions(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          
          // Verification Code Input
          TextField(
            controller: _verificationCodeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
            decoration: InputDecoration(
              hintText: '000000',
              helperText: 'Enter 6-digit code',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Resend Option
          if (_selectedMethod != TwoFactorMethod.authenticator)
            Center(
              child: TextButton.icon(
                onPressed: _isLoading ? null : _resendCode,
                icon: const Icon(Icons.refresh),
                label: const Text('Resend Code'),
              ),
            ),
          
          const SizedBox(height: 32),
          
          // Help Card
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Having trouble?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTroubleshootingTips(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCodesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save Your Backup Codes',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep these codes safe. You can use them to access your account if you lose your 2FA device.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          
          // Backup Codes Display
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_backupCodes != null)
                    ..._backupCodes!.map((code) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                  else
                    const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyBackupCodes,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy All'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadBackupCodes,
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Warning Card
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Each code can only be used once. Store them securely and never share them with anyone.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 120,
            color: Colors.green,
          ),
          const SizedBox(height: 32),
          Text(
            'All Set!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Two-factor authentication is now enabled for your account',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 48),
          
          // Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Method',
                    _selectedMethod.displayName,
                    _getMethodIcon(_selectedMethod),
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Backup Codes',
                    '${_backupCodes?.length ?? 0} codes saved',
                    Icons.key,
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Security Score',
                    '+20% improvement',
                    Icons.trending_up,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text('Back'),
            )
          else
            const SizedBox(width: 80),
          const Spacer(),
          if (_currentStep < 4)
            FilledButton(
              onPressed: _isLoading ? null : _nextStep,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep == 3 ? 'Complete' : 'Continue'),
            )
          else
            FilledButton.icon(
              onPressed: _complete,
              icon: const Icon(Icons.check),
              label: const Text('Done'),
            ),
        ],
      ),
    );
  }

  Widget _buildQRCode(String data) {
    // In a real app, you would use a QR code generation library
    // For now, we'll show a placeholder
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code,
              size: 120,
              color: Colors.black87,
            ),
            const SizedBox(height: 8),
            Text(
              'QR Code',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportedApps() {
    final apps = [
      {'name': 'Google Authenticator', 'icon': Icons.key},
      {'name': 'Microsoft Authenticator', 'icon': Icons.security},
      {'name': 'Authy', 'icon': Icons.phone_android},
      {'name': '1Password', 'icon': Icons.password},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supported Apps',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: apps.map((app) => Chip(
                    avatar: Icon(
                      app['icon'] as IconData,
                      size: 18,
                    ),
                    label: Text(app['name'] as String),
                  )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon(TwoFactorMethod method) {
    switch (method) {
      case TwoFactorMethod.sms:
        return Icons.sms;
      case TwoFactorMethod.email:
        return Icons.email;
      case TwoFactorMethod.authenticator:
        return Icons.smartphone;
    }
  }

  String _getVerificationInstructions() {
    switch (_selectedMethod) {
      case TwoFactorMethod.sms:
        return 'Enter the 6-digit code we sent to your phone';
      case TwoFactorMethod.email:
        return 'Enter the 6-digit code we sent to your email';
      case TwoFactorMethod.authenticator:
        return 'Enter the 6-digit code from your authenticator app';
    }
  }

  String _getTroubleshootingTips() {
    switch (_selectedMethod) {
      case TwoFactorMethod.sms:
        return 'Check your phone for SMS messages. The code may take a few moments to arrive.';
      case TwoFactorMethod.email:
        return 'Check your spam folder if you don\'t see the email in your inbox.';
      case TwoFactorMethod.authenticator:
        return 'Make sure the time on your device is synchronized correctly.';
    }
  }

  Future<void> _nextStep() async {
    switch (_currentStep) {
      case 0:
        // Method selected, proceed to setup
        await _initializeSetup();
        break;
      case 1:
        // Setup completed, send verification code
        await _sendVerificationCode();
        break;
      case 2:
        // Verify the code
        await _verifyCode();
        break;
      case 3:
        // Generate backup codes
        await _generateBackupCodes();
        break;
    }
  }

  Future<void> _initializeSetup() async {
    setState(() => _isLoading = true);
    
    try {
      if (_selectedMethod == TwoFactorMethod.authenticator) {
        final result = await _securityService.enableTwoFactor(_selectedMethod);
        setState(() {
          _qrCodeData = result['qrCode'];
          _secretKey = result['secret'];
        });
      }
      
      setState(() {
        _currentStep++;
        _isLoading = false;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to initialize setup');
    }
  }

  Future<void> _sendVerificationCode() async {
    if (_selectedMethod != TwoFactorMethod.authenticator) {
      setState(() => _isLoading = true);
      
      try {
        await _securityService.enableTwoFactor(_selectedMethod);
        _showSuccessSnackBar('Verification code sent');
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to send verification code');
        return;
      }
      
      setState(() => _isLoading = false);
    }
    
    setState(() => _currentStep++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _verifyCode() async {
    final code = _verificationCodeController.text;
    
    if (code.length != 6) {
      _showErrorSnackBar('Please enter a 6-digit code');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final isValid = await _securityService.verifyTwoFactorCode(code);
      
      if (isValid) {
        setState(() {
          _currentStep++;
          _isLoading = false;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Invalid code. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to verify code');
    }
  }

  Future<void> _generateBackupCodes() async {
    setState(() => _isLoading = true);
    
    try {
      final codes = await _securityService.generateBackupCodes();
      setState(() {
        _backupCodes = codes;
        _currentStep++;
        _isLoading = false;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to generate backup codes');
    }
  }

  void _previousStep() {
    setState(() => _currentStep--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _complete() {
    Navigator.pop(context, true);
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    
    try {
      await _securityService.enableTwoFactor(_selectedMethod);
      _showSuccessSnackBar('New code sent');
    } catch (e) {
      _showErrorSnackBar('Failed to resend code');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyBackupCodes() {
    if (_backupCodes != null) {
      final codesText = _backupCodes!.join('\n');
      Clipboard.setData(ClipboardData(text: codesText));
      _showSuccessSnackBar('Backup codes copied to clipboard');
    }
  }

  void _downloadBackupCodes() {
    // In a real app, this would download a file
    _showInfoSnackBar('Download feature coming soon');
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