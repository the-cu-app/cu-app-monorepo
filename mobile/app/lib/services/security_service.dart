import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/security_model.dart' as models;

class SecurityService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const _storage = FlutterSecureStorage();
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Storage keys
  static const String _securitySettingsKey = 'security_settings';
  static const String _backupCodesKey = 'backup_codes';
  static const String _twoFactorSecretKey = '2fa_secret';
  static const String _sessionsKey = 'active_sessions';
  static const String _loginActivityKey = 'login_activity';

  // Get current security settings
  Future<models.SecuritySettings> getSecuritySettings() async {
    try {
      final settingsJson = await _storage.read(key: _securitySettingsKey);
      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson);
        return _parseSecuritySettings(settings);
      }
      return models.SecuritySettings.empty();
    } catch (e) {
      return models.SecuritySettings.empty();
    }
  }

  // Update security settings
  Future<void> updateSecuritySettings(models.SecuritySettings settings) async {
    final settingsJson = _serializeSecuritySettings(settings);
    await _storage.write(
      key: _securitySettingsKey,
      value: jsonEncode(settingsJson),
    );
  }

  // Enable two-factor authentication
  Future<Map<String, String>> enableTwoFactor(models.TwoFactorMethod method) async {
    switch (method) {
      case models.TwoFactorMethod.authenticator:
        return await _setupAuthenticatorApp();
      case models.TwoFactorMethod.sms:
      case models.TwoFactorMethod.email:
        await _sendVerificationCode(method);
        return {'status': 'verification_sent'};
    }
  }

  // Setup authenticator app
  Future<Map<String, String>> _setupAuthenticatorApp() async {
    // Generate secret
    final secret = _generateSecret();
    await _storage.write(key: _twoFactorSecretKey, value: secret);
    
    // Generate QR code data
    final user = _supabase.auth.currentUser;
    final issuer = 'SUPAHYPER';
    final accountName = user?.email ?? 'user';
    final uri = 'otpauth://totp/$issuer:$accountName?secret=$secret&issuer=$issuer';
    
    return {
      'secret': secret,
      'qrCode': uri,
    };
  }

  // Generate secret for 2FA
  String _generateSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Send verification code
  Future<void> _sendVerificationCode(models.TwoFactorMethod method) async {
    final code = _generateVerificationCode();
    
    // In a real app, you would send this via SMS/Email
    // For demo, we'll store it securely
    await _storage.write(key: 'temp_verification_code', value: code);
    
    // TODO: Implement actual SMS/Email sending
  }

  // Generate verification code
  String _generateVerificationCode() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Verify two-factor code
  Future<bool> verifyTwoFactorCode(String code) async {
    // For demo purposes, check against stored code
    final storedCode = await _storage.read(key: 'temp_verification_code');
    if (storedCode == code) {
      await _storage.delete(key: 'temp_verification_code');
      return true;
    }
    
    // TODO: Implement TOTP verification for authenticator apps
    return false;
  }

  // Generate backup codes
  Future<List<String>> generateBackupCodes() async {
    final codes = List.generate(8, (index) => _generateBackupCode());
    await _storage.write(key: _backupCodesKey, value: jsonEncode(codes));
    return codes;
  }

  // Generate single backup code
  String _generateBackupCode() {
    final random = Random.secure();
    return List.generate(4, (index) => 
      (1000 + random.nextInt(9000)).toString()
    ).join('-');
  }

  // Check biometric availability
  Future<Map<String, dynamic>> checkBiometricAvailability() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      return {
        'available': canCheckBiometrics && isDeviceSupported,
        'types': _mapBiometricTypes(availableBiometrics),
      };
    } catch (e) {
      return {
        'available': false,
        'types': <models.BiometricType>[],
      };
    }
  }

  // Map platform biometric types to our enum
  List<models.BiometricType> _mapBiometricTypes(List<BiometricType> platformTypes) {
    final types = <models.BiometricType>[];
    
    for (final type in platformTypes) {
      switch (type) {
        case BiometricType.face:
          types.add(models.BiometricType.faceId);
          break;
        case BiometricType.fingerprint:
          types.add(models.BiometricType.fingerprint);
          break;
        case BiometricType.iris:
          types.add(models.BiometricType.iris);
          break;
        case BiometricType.strong:
        case BiometricType.weak:
          // Handle generic biometric types
          if (!types.contains(models.BiometricType.touchId)) {
            types.add(models.BiometricType.touchId);
          }
          break;
      }
    }
    
    return types;
  }

  // Authenticate with biometric
  Future<bool> authenticateWithBiometric(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // Get active sessions
  Future<List<models.ActiveSession>> getActiveSessions() async {
    try {
      final sessionsJson = await _storage.read(key: _sessionsKey);
      if (sessionsJson != null) {
        final sessions = jsonDecode(sessionsJson) as List;
        return sessions.map((s) => _parseActiveSession(s)).toList();
      }
      
      // Return at least the current session
      return [_getCurrentSession()];
    } catch (e) {
      return [_getCurrentSession()];
    }
  }

  // Get current session
  models.ActiveSession _getCurrentSession() {
    return models.ActiveSession(
      sessionId: _supabase.auth.currentSession?.accessToken ?? 'current',
      deviceName: 'Current Device',
      deviceType: 'Mobile',
      location: 'Current Location',
      lastActive: DateTime.now(),
      isCurrent: true,
    );
  }

  // Logout other devices
  Future<void> logoutOtherDevices() async {
    // In a real app, this would invalidate other sessions on the server
    await _storage.write(key: _sessionsKey, value: jsonEncode([_getCurrentSession()]));
  }

  // Get login activity
  Future<List<models.LoginActivity>> getLoginActivity({int limit = 10}) async {
    try {
      final activityJson = await _storage.read(key: _loginActivityKey);
      if (activityJson != null) {
        final activities = jsonDecode(activityJson) as List;
        return activities
            .map((a) => _parseLoginActivity(a))
            .take(limit)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Log login attempt
  Future<void> logLoginAttempt({
    required bool wasSuccessful,
    String? failureReason,
  }) async {
    final activities = await getLoginActivity(limit: 100);
    final newActivity = models.LoginActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      deviceName: 'Current Device',
      location: 'Current Location',
      wasSuccessful: wasSuccessful,
      failureReason: failureReason,
    );
    
    activities.insert(0, newActivity);
    
    // Keep only last 100 activities
    if (activities.length > 100) {
      activities.removeRange(100, activities.length);
    }
    
    await _storage.write(
      key: _loginActivityKey,
      value: jsonEncode(activities.map(_serializeLoginActivity).toList()),
    );
  }

  // Get security recommendations
  List<models.SecurityRecommendation> getSecurityRecommendations(models.SecuritySettings settings) {
    final recommendations = <models.SecurityRecommendation>[];
    
    if (!settings.twoFactorEnabled) {
      recommendations.add(models.SecurityRecommendation(
        id: 'enable_2fa',
        title: 'Enable Two-Factor Authentication',
        description: 'Add an extra layer of security to your account',
        actionLabel: 'Enable 2FA',
        scoreImpact: 0.20,
      ));
    }
    
    if (!settings.biometricEnabled) {
      recommendations.add(models.SecurityRecommendation(
        id: 'enable_biometric',
        title: 'Enable Biometric Authentication',
        description: 'Use Face ID or Touch ID for quick and secure access',
        actionLabel: 'Enable Biometric',
        scoreImpact: 0.15,
      ));
    }
    
    if (settings.biometricEnabled && !settings.biometricForTransactions) {
      recommendations.add(models.SecurityRecommendation(
        id: 'biometric_transactions',
        title: 'Use Biometric for Transactions',
        description: 'Require biometric authentication for all transactions',
        actionLabel: 'Enable',
        scoreImpact: 0.10,
      ));
    }
    
    if (settings.lastPasswordChange == null ||
        DateTime.now().difference(settings.lastPasswordChange!).inDays > 90) {
      recommendations.add(models.SecurityRecommendation(
        id: 'change_password',
        title: 'Update Your Password',
        description: 'It\'s been over 90 days since your last password change',
        actionLabel: 'Change Password',
        scoreImpact: 0.05,
      ));
    }
    
    if (settings.securityQuestions.isEmpty) {
      recommendations.add(models.SecurityRecommendation(
        id: 'add_security_questions',
        title: 'Add Security Questions',
        description: 'Set up security questions for account recovery',
        actionLabel: 'Add Questions',
        scoreImpact: 0.10,
      ));
    }
    
    return recommendations;
  }

  // Helper methods for serialization
  Map<String, dynamic> _serializeSecuritySettings(models.SecuritySettings settings) {
    return {
      'twoFactorEnabled': settings.twoFactorEnabled,
      'twoFactorMethod': settings.twoFactorMethod?.name,
      'biometricEnabled': settings.biometricEnabled,
      'enabledBiometrics': settings.enabledBiometrics.map((e) => e.name).toList(),
      'biometricForAppLaunch': settings.biometricForAppLaunch,
      'biometricForTransactions': settings.biometricForTransactions,
      'biometricForSensitiveData': settings.biometricForSensitiveData,
      'loginNotificationsEnabled': settings.loginNotificationsEnabled,
      'accountActivityAlertsEnabled': settings.accountActivityAlertsEnabled,
      'rememberDevice': settings.rememberDevice,
      'backupCodes': settings.backupCodes,
      'lastPasswordChange': settings.lastPasswordChange?.toIso8601String(),
      'securityQuestions': settings.securityQuestions.map(_serializeSecurityQuestion).toList(),
    };
  }

  models.SecuritySettings _parseSecuritySettings(Map<String, dynamic> data) {
    return models.SecuritySettings(
      twoFactorEnabled: data['twoFactorEnabled'] ?? false,
      twoFactorMethod: data['twoFactorMethod'] != null
          ? models.TwoFactorMethod.values.firstWhere((e) => e.name == data['twoFactorMethod'])
          : null,
      biometricEnabled: data['biometricEnabled'] ?? false,
      enabledBiometrics: (data['enabledBiometrics'] as List?)
          ?.map((e) => models.BiometricType.values.firstWhere((b) => b.name == e))
          .toSet() ?? {},
      biometricForAppLaunch: data['biometricForAppLaunch'] ?? false,
      biometricForTransactions: data['biometricForTransactions'] ?? false,
      biometricForSensitiveData: data['biometricForSensitiveData'] ?? false,
      loginNotificationsEnabled: data['loginNotificationsEnabled'] ?? true,
      accountActivityAlertsEnabled: data['accountActivityAlertsEnabled'] ?? true,
      rememberDevice: data['rememberDevice'] ?? false,
      backupCodes: List<String>.from(data['backupCodes'] ?? []),
      lastPasswordChange: data['lastPasswordChange'] != null
          ? DateTime.parse(data['lastPasswordChange'])
          : null,
      securityQuestions: (data['securityQuestions'] as List?)
          ?.map((q) => _parseSecurityQuestion(q))
          .toList() ?? [],
      activeSessions: [],
      recentLoginActivity: [],
    );
  }

  Map<String, dynamic> _serializeSecurityQuestion(models.SecurityQuestion question) {
    return {
      'id': question.id,
      'question': question.question,
      'answer': question.answer,
    };
  }

  models.SecurityQuestion _parseSecurityQuestion(Map<String, dynamic> data) {
    return models.SecurityQuestion(
      id: data['id'],
      question: data['question'],
      answer: data['answer'],
    );
  }

  models.ActiveSession _parseActiveSession(Map<String, dynamic> data) {
    return models.ActiveSession(
      sessionId: data['sessionId'],
      deviceName: data['deviceName'],
      deviceType: data['deviceType'],
      location: data['location'],
      lastActive: DateTime.parse(data['lastActive']),
      isCurrent: data['isCurrent'] ?? false,
    );
  }

  Map<String, dynamic> _serializeLoginActivity(models.LoginActivity activity) {
    return {
      'id': activity.id,
      'timestamp': activity.timestamp.toIso8601String(),
      'deviceName': activity.deviceName,
      'location': activity.location,
      'wasSuccessful': activity.wasSuccessful,
      'failureReason': activity.failureReason,
    };
  }

  models.LoginActivity _parseLoginActivity(Map<String, dynamic> data) {
    return models.LoginActivity(
      id: data['id'],
      timestamp: DateTime.parse(data['timestamp']),
      deviceName: data['deviceName'],
      location: data['location'],
      wasSuccessful: data['wasSuccessful'],
      failureReason: data['failureReason'],
    );
  }
}