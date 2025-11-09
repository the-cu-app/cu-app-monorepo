class CUOnlineBankingSetup {
  final String financialInstitutionId;
  final String memberId;
  final String username;
  final String? password;
  final List<String> securityQuestions;
  final bool twoFactorEnabled;
  final bool biometricEnabled;
  final int sessionTimeout;
  final bool autoLogout;
  final String? lastLoginDate;
  final String? lastLoginIP;
  final String? lastLoginDevice;
  final Map<String, dynamic> securitySettings;
  final Map<String, dynamic> accessControls;
  final Map<String, dynamic> sessionManagement;
  final Map<String, dynamic> deviceManagement;
  final Map<String, dynamic> auditLogs;
  final Map<String, dynamic> complianceSettings;
  final Map<String, dynamic> customFields;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUOnlineBankingSetup({
    required this.financialInstitutionId,
    required this.memberId,
    required this.username,
    this.password,
    this.securityQuestions = const [],
    required this.twoFactorEnabled,
    required this.biometricEnabled,
    required this.sessionTimeout,
    required this.autoLogout,
    this.lastLoginDate,
    this.lastLoginIP,
    this.lastLoginDevice,
    this.securitySettings = const {},
    this.accessControls = const {},
    this.sessionManagement = const {},
    this.deviceManagement = const {},
    this.auditLogs = const {},
    this.complianceSettings = const {},
    this.customFields = const {},
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUOnlineBankingSetup.fromJson(Map<String, dynamic> json) {
    return CUOnlineBankingSetup(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      username: json['username'] as String,
      password: json['password'] as String?,
      securityQuestions: List<String>.from(json['securityQuestions'] ?? []),
      twoFactorEnabled: json['twoFactorEnabled'] as bool,
      biometricEnabled: json['biometricEnabled'] as bool,
      sessionTimeout: json['sessionTimeout'] as int,
      autoLogout: json['autoLogout'] as bool,
      lastLoginDate: json['lastLoginDate'] as String?,
      lastLoginIP: json['lastLoginIP'] as String?,
      lastLoginDevice: json['lastLoginDevice'] as String?,
      securitySettings:
          Map<String, dynamic>.from(json['securitySettings'] ?? {}),
      accessControls: Map<String, dynamic>.from(json['accessControls'] ?? {}),
      sessionManagement:
          Map<String, dynamic>.from(json['sessionManagement'] ?? {}),
      deviceManagement:
          Map<String, dynamic>.from(json['deviceManagement'] ?? {}),
      auditLogs: Map<String, dynamic>.from(json['auditLogs'] ?? {}),
      complianceSettings:
          Map<String, dynamic>.from(json['complianceSettings'] ?? {}),
      customFields: Map<String, dynamic>.from(json['customFields'] ?? {}),
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financialInstitutionId': financialInstitutionId,
      'memberId': memberId,
      'username': username,
      'password': password,
      'securityQuestions': securityQuestions,
      'twoFactorEnabled': twoFactorEnabled,
      'biometricEnabled': biometricEnabled,
      'sessionTimeout': sessionTimeout,
      'autoLogout': autoLogout,
      'lastLoginDate': lastLoginDate,
      'lastLoginIP': lastLoginIP,
      'lastLoginDevice': lastLoginDevice,
      'securitySettings': securitySettings,
      'accessControls': accessControls,
      'sessionManagement': sessionManagement,
      'deviceManagement': deviceManagement,
      'auditLogs': auditLogs,
      'complianceSettings': complianceSettings,
      'customFields': customFields,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
