import 'package:flutter/foundation.dart';

enum TwoFactorMethod {
  sms('SMS', 'Receive codes via text message'),
  email('Email', 'Receive codes via email'),
  authenticator('Authenticator App', 'Use Google Authenticator or similar');

  final String displayName;
  final String description;
  const TwoFactorMethod(this.displayName, this.description);
}

enum BiometricType {
  faceId('Face ID'),
  touchId('Touch ID'),
  fingerprint('Fingerprint'),
  iris('Iris Scan');

  final String displayName;
  const BiometricType(this.displayName);
}

enum SecurityLevel {
  low('Low', 0.0, 0.33),
  medium('Medium', 0.34, 0.66),
  high('High', 0.67, 1.0);

  final String displayName;
  final double minScore;
  final double maxScore;
  const SecurityLevel(this.displayName, this.minScore, this.maxScore);

  static SecurityLevel fromScore(double score) {
    if (score <= 0.33) return low;
    if (score <= 0.66) return medium;
    return high;
  }
}

class SecuritySettings {
  final bool twoFactorEnabled;
  final TwoFactorMethod? twoFactorMethod;
  final bool biometricEnabled;
  final Set<BiometricType> enabledBiometrics;
  final bool biometricForAppLaunch;
  final bool biometricForTransactions;
  final bool biometricForSensitiveData;
  final bool loginNotificationsEnabled;
  final bool accountActivityAlertsEnabled;
  final bool rememberDevice;
  final List<String> backupCodes;
  final DateTime? lastPasswordChange;
  final List<SecurityQuestion> securityQuestions;
  final List<ActiveSession> activeSessions;
  final List<LoginActivity> recentLoginActivity;

  SecuritySettings({
    required this.twoFactorEnabled,
    this.twoFactorMethod,
    required this.biometricEnabled,
    required this.enabledBiometrics,
    required this.biometricForAppLaunch,
    required this.biometricForTransactions,
    required this.biometricForSensitiveData,
    required this.loginNotificationsEnabled,
    required this.accountActivityAlertsEnabled,
    required this.rememberDevice,
    required this.backupCodes,
    this.lastPasswordChange,
    required this.securityQuestions,
    required this.activeSessions,
    required this.recentLoginActivity,
  });

  double get securityScore {
    double score = 0.0;
    
    // Base security features (50%)
    if (twoFactorEnabled) score += 0.20;
    if (biometricEnabled) score += 0.15;
    if (securityQuestions.isNotEmpty) score += 0.10;
    if (lastPasswordChange != null && 
        DateTime.now().difference(lastPasswordChange!).inDays < 90) {
      score += 0.05;
    }
    
    // Enhanced features (30%)
    if (biometricForTransactions) score += 0.10;
    if (biometricForSensitiveData) score += 0.10;
    if (loginNotificationsEnabled) score += 0.05;
    if (accountActivityAlertsEnabled) score += 0.05;
    
    // Advanced security (20%)
    if (twoFactorMethod == TwoFactorMethod.authenticator) score += 0.10;
    if (activeSessions.length == 1) score += 0.10;
    
    return score.clamp(0.0, 1.0);
  }

  SecurityLevel get securityLevel => SecurityLevel.fromScore(securityScore);

  SecuritySettings copyWith({
    bool? twoFactorEnabled,
    TwoFactorMethod? twoFactorMethod,
    bool? biometricEnabled,
    Set<BiometricType>? enabledBiometrics,
    bool? biometricForAppLaunch,
    bool? biometricForTransactions,
    bool? biometricForSensitiveData,
    bool? loginNotificationsEnabled,
    bool? accountActivityAlertsEnabled,
    bool? rememberDevice,
    List<String>? backupCodes,
    DateTime? lastPasswordChange,
    List<SecurityQuestion>? securityQuestions,
    List<ActiveSession>? activeSessions,
    List<LoginActivity>? recentLoginActivity,
  }) {
    return SecuritySettings(
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      twoFactorMethod: twoFactorMethod ?? this.twoFactorMethod,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      enabledBiometrics: enabledBiometrics ?? this.enabledBiometrics,
      biometricForAppLaunch: biometricForAppLaunch ?? this.biometricForAppLaunch,
      biometricForTransactions: biometricForTransactions ?? this.biometricForTransactions,
      biometricForSensitiveData: biometricForSensitiveData ?? this.biometricForSensitiveData,
      loginNotificationsEnabled: loginNotificationsEnabled ?? this.loginNotificationsEnabled,
      accountActivityAlertsEnabled: accountActivityAlertsEnabled ?? this.accountActivityAlertsEnabled,
      rememberDevice: rememberDevice ?? this.rememberDevice,
      backupCodes: backupCodes ?? this.backupCodes,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      securityQuestions: securityQuestions ?? this.securityQuestions,
      activeSessions: activeSessions ?? this.activeSessions,
      recentLoginActivity: recentLoginActivity ?? this.recentLoginActivity,
    );
  }

  factory SecuritySettings.empty() {
    return SecuritySettings(
      twoFactorEnabled: false,
      biometricEnabled: false,
      enabledBiometrics: {},
      biometricForAppLaunch: false,
      biometricForTransactions: false,
      biometricForSensitiveData: false,
      loginNotificationsEnabled: true,
      accountActivityAlertsEnabled: true,
      rememberDevice: false,
      backupCodes: [],
      securityQuestions: [],
      activeSessions: [],
      recentLoginActivity: [],
    );
  }
}

class SecurityQuestion {
  final String id;
  final String question;
  final String? answer;

  SecurityQuestion({
    required this.id,
    required this.question,
    this.answer,
  });
}

class ActiveSession {
  final String sessionId;
  final String deviceName;
  final String deviceType;
  final String location;
  final DateTime lastActive;
  final bool isCurrent;

  ActiveSession({
    required this.sessionId,
    required this.deviceName,
    required this.deviceType,
    required this.location,
    required this.lastActive,
    required this.isCurrent,
  });
}

class LoginActivity {
  final String id;
  final DateTime timestamp;
  final String deviceName;
  final String location;
  final bool wasSuccessful;
  final String? failureReason;

  LoginActivity({
    required this.id,
    required this.timestamp,
    required this.deviceName,
    required this.location,
    required this.wasSuccessful,
    this.failureReason,
  });
}

class SecurityRecommendation {
  final String id;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onAction;
  final double scoreImpact;

  SecurityRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.onAction,
    required this.scoreImpact,
  });
}