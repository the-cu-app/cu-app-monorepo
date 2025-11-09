class CUAuthenticationConfig {
  final String financialInstitutionId;
  final bool touchIdEnabled;
  final bool faceIdEnabled;
  final bool pinEnabled;
  final bool passwordEnabled;
  final int maxLoginAttempts;
  final int lockoutDuration;
  final List<String> allowedAuthMethods;
  final bool biometricFallbackEnabled;
  final bool rememberDeviceEnabled;
  final int sessionTimeout;
  final bool multiFactorRequired;
  final List<String> securityQuestions;
  final Map<String, dynamic> customConfig;

  const CUAuthenticationConfig({
    required this.financialInstitutionId,
    required this.touchIdEnabled,
    required this.faceIdEnabled,
    required this.pinEnabled,
    required this.passwordEnabled,
    required this.maxLoginAttempts,
    required this.lockoutDuration,
    required this.allowedAuthMethods,
    required this.biometricFallbackEnabled,
    required this.rememberDeviceEnabled,
    required this.sessionTimeout,
    required this.multiFactorRequired,
    required this.securityQuestions,
    required this.customConfig,
  });

  factory CUAuthenticationConfig.fromJson(Map<String, dynamic> json) {
    return CUAuthenticationConfig(
      financialInstitutionId: json['financialInstitutionId'] as String,
      touchIdEnabled: json['touchIdEnabled'] as bool,
      faceIdEnabled: json['faceIdEnabled'] as bool,
      pinEnabled: json['pinEnabled'] as bool,
      passwordEnabled: json['passwordEnabled'] as bool,
      maxLoginAttempts: json['maxLoginAttempts'] as int,
      lockoutDuration: json['lockoutDuration'] as int,
      allowedAuthMethods: List<String>.from(json['allowedAuthMethods'] as List),
      biometricFallbackEnabled: json['biometricFallbackEnabled'] as bool,
      rememberDeviceEnabled: json['rememberDeviceEnabled'] as bool,
      sessionTimeout: json['sessionTimeout'] as int,
      multiFactorRequired: json['multiFactorRequired'] as bool,
      securityQuestions: List<String>.from(json['securityQuestions'] as List),
      customConfig: Map<String, dynamic>.from(json['customConfig'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financialInstitutionId': financialInstitutionId,
      'touchIdEnabled': touchIdEnabled,
      'faceIdEnabled': faceIdEnabled,
      'pinEnabled': pinEnabled,
      'passwordEnabled': passwordEnabled,
      'maxLoginAttempts': maxLoginAttempts,
      'lockoutDuration': lockoutDuration,
      'allowedAuthMethods': allowedAuthMethods,
      'biometricFallbackEnabled': biometricFallbackEnabled,
      'rememberDeviceEnabled': rememberDeviceEnabled,
      'sessionTimeout': sessionTimeout,
      'multiFactorRequired': multiFactorRequired,
      'securityQuestions': securityQuestions,
      'customConfig': customConfig,
    };
  }

  CUAuthenticationConfig copyWith({
    String? financialInstitutionId,
    bool? touchIdEnabled,
    bool? faceIdEnabled,
    bool? pinEnabled,
    bool? passwordEnabled,
    int? maxLoginAttempts,
    int? lockoutDuration,
    List<String>? allowedAuthMethods,
    bool? biometricFallbackEnabled,
    bool? rememberDeviceEnabled,
    int? sessionTimeout,
    bool? multiFactorRequired,
    List<String>? securityQuestions,
    Map<String, dynamic>? customConfig,
  }) {
    return CUAuthenticationConfig(
      financialInstitutionId:
          financialInstitutionId ?? this.financialInstitutionId,
      touchIdEnabled: touchIdEnabled ?? this.touchIdEnabled,
      faceIdEnabled: faceIdEnabled ?? this.faceIdEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      passwordEnabled: passwordEnabled ?? this.passwordEnabled,
      maxLoginAttempts: maxLoginAttempts ?? this.maxLoginAttempts,
      lockoutDuration: lockoutDuration ?? this.lockoutDuration,
      allowedAuthMethods: allowedAuthMethods ?? this.allowedAuthMethods,
      biometricFallbackEnabled:
          biometricFallbackEnabled ?? this.biometricFallbackEnabled,
      rememberDeviceEnabled:
          rememberDeviceEnabled ?? this.rememberDeviceEnabled,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      multiFactorRequired: multiFactorRequired ?? this.multiFactorRequired,
      securityQuestions: securityQuestions ?? this.securityQuestions,
      customConfig: customConfig ?? this.customConfig,
    );
  }

  bool get hasBiometricAuth => touchIdEnabled || faceIdEnabled;
  bool get hasTraditionalAuth => pinEnabled || passwordEnabled;
  bool get isSecure => maxLoginAttempts > 0 && lockoutDuration > 0;

  List<String> get availableAuthMethods {
    List<String> methods = [];
    if (touchIdEnabled) methods.add('touchId');
    if (faceIdEnabled) methods.add('faceId');
    if (pinEnabled) methods.add('pin');
    if (passwordEnabled) methods.add('password');
    return methods;
  }
}
