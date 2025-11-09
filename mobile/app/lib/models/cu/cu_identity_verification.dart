class CUIdentityVerification {
  final String financialInstitutionId;
  final String memberId;
  final String providerName;
  final String verificationType;
  final String verificationStatus;
  final Map<String, dynamic> verificationData;
  final DateTime verificationDate;
  final bool isVerified;
  final String verificationScore;
  final List<String> verificationIssues;
  final Map<String, dynamic> providerMetadata;
  final String? documentType;
  final String? documentNumber;
  final String? verificationMethod;
  final Map<String, dynamic> biometricData;
  final Map<String, dynamic> addressVerification;
  final Map<String, dynamic> phoneVerification;
  final Map<String, dynamic> emailVerification;
  final Map<String, dynamic> ssnVerification;
  final Map<String, dynamic> ofacVerification;
  final Map<String, dynamic> pepVerification;
  final Map<String, dynamic> sanctionsVerification;
  final Map<String, dynamic> watchlistVerification;
  final Map<String, dynamic> riskAssessment;
  final Map<String, dynamic> complianceChecks;
  final String? verificationId;
  final String? sessionId;
  final String? referenceId;
  final Map<String, dynamic> auditTrail;
  final DateTime? expiresAt;
  final bool isActive;
  final String? rejectionReason;
  final List<String> requiredDocuments;
  final List<String> completedDocuments;
  final Map<String, dynamic> customFields;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUIdentityVerification({
    required this.financialInstitutionId,
    required this.memberId,
    required this.providerName,
    required this.verificationType,
    required this.verificationStatus,
    required this.verificationData,
    required this.verificationDate,
    required this.isVerified,
    required this.verificationScore,
    this.verificationIssues = const [],
    this.providerMetadata = const {},
    this.documentType,
    this.documentNumber,
    this.verificationMethod,
    this.biometricData = const {},
    this.addressVerification = const {},
    this.phoneVerification = const {},
    this.emailVerification = const {},
    this.ssnVerification = const {},
    this.ofacVerification = const {},
    this.pepVerification = const {},
    this.sanctionsVerification = const {},
    this.watchlistVerification = const {},
    this.riskAssessment = const {},
    this.complianceChecks = const {},
    this.verificationId,
    this.sessionId,
    this.referenceId,
    this.auditTrail = const {},
    this.expiresAt,
    this.isActive = true,
    this.rejectionReason,
    this.requiredDocuments = const [],
    this.completedDocuments = const [],
    this.customFields = const {},
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUIdentityVerification.fromJson(Map<String, dynamic> json) {
    return CUIdentityVerification(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      providerName: json['providerName'] as String,
      verificationType: json['verificationType'] as String,
      verificationStatus: json['verificationStatus'] as String,
      verificationData: Map<String, dynamic>.from(
        json['verificationData'] ?? {},
      ),
      verificationDate: DateTime.parse(json['verificationDate'] as String),
      isVerified: json['isVerified'] as bool,
      verificationScore: json['verificationScore'] as String,
      verificationIssues: List<String>.from(json['verificationIssues'] ?? []),
      providerMetadata: Map<String, dynamic>.from(
        json['providerMetadata'] ?? {},
      ),
      documentType: json['documentType'] as String?,
      documentNumber: json['documentNumber'] as String?,
      verificationMethod: json['verificationMethod'] as String?,
      biometricData: Map<String, dynamic>.from(json['biometricData'] ?? {}),
      addressVerification: Map<String, dynamic>.from(
        json['addressVerification'] ?? {},
      ),
      phoneVerification: Map<String, dynamic>.from(
        json['phoneVerification'] ?? {},
      ),
      emailVerification: Map<String, dynamic>.from(
        json['emailVerification'] ?? {},
      ),
      ssnVerification: Map<String, dynamic>.from(json['ssnVerification'] ?? {}),
      ofacVerification: Map<String, dynamic>.from(
        json['ofacVerification'] ?? {},
      ),
      pepVerification: Map<String, dynamic>.from(json['pepVerification'] ?? {}),
      sanctionsVerification: Map<String, dynamic>.from(
        json['sanctionsVerification'] ?? {},
      ),
      watchlistVerification: Map<String, dynamic>.from(
        json['watchlistVerification'] ?? {},
      ),
      riskAssessment: Map<String, dynamic>.from(json['riskAssessment'] ?? {}),
      complianceChecks: Map<String, dynamic>.from(
        json['complianceChecks'] ?? {},
      ),
      verificationId: json['verificationId'] as String?,
      sessionId: json['sessionId'] as String?,
      referenceId: json['referenceId'] as String?,
      auditTrail: Map<String, dynamic>.from(json['auditTrail'] ?? {}),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      rejectionReason: json['rejectionReason'] as String?,
      requiredDocuments: List<String>.from(json['requiredDocuments'] ?? []),
      completedDocuments: List<String>.from(json['completedDocuments'] ?? []),
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
      'providerName': providerName,
      'verificationType': verificationType,
      'verificationStatus': verificationStatus,
      'verificationData': verificationData,
      'verificationDate': verificationDate.toIso8601String(),
      'isVerified': isVerified,
      'verificationScore': verificationScore,
      'verificationIssues': verificationIssues,
      'providerMetadata': providerMetadata,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'verificationMethod': verificationMethod,
      'biometricData': biometricData,
      'addressVerification': addressVerification,
      'phoneVerification': phoneVerification,
      'emailVerification': emailVerification,
      'ssnVerification': ssnVerification,
      'ofacVerification': ofacVerification,
      'pepVerification': pepVerification,
      'sanctionsVerification': sanctionsVerification,
      'watchlistVerification': watchlistVerification,
      'riskAssessment': riskAssessment,
      'complianceChecks': complianceChecks,
      'verificationId': verificationId,
      'sessionId': sessionId,
      'referenceId': referenceId,
      'auditTrail': auditTrail,
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'rejectionReason': rejectionReason,
      'requiredDocuments': requiredDocuments,
      'completedDocuments': completedDocuments,
      'customFields': customFields,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CUIdentityVerification copyWith({
    String? financialInstitutionId,
    String? memberId,
    String? providerName,
    String? verificationType,
    String? verificationStatus,
    Map<String, dynamic>? verificationData,
    DateTime? verificationDate,
    bool? isVerified,
    String? verificationScore,
    List<String>? verificationIssues,
    Map<String, dynamic>? providerMetadata,
    String? documentType,
    String? documentNumber,
    String? verificationMethod,
    Map<String, dynamic>? biometricData,
    Map<String, dynamic>? addressVerification,
    Map<String, dynamic>? phoneVerification,
    Map<String, dynamic>? emailVerification,
    Map<String, dynamic>? ssnVerification,
    Map<String, dynamic>? ofacVerification,
    Map<String, dynamic>? pepVerification,
    Map<String, dynamic>? sanctionsVerification,
    Map<String, dynamic>? watchlistVerification,
    Map<String, dynamic>? riskAssessment,
    Map<String, dynamic>? complianceChecks,
    String? verificationId,
    String? sessionId,
    String? referenceId,
    Map<String, dynamic>? auditTrail,
    DateTime? expiresAt,
    bool? isActive,
    String? rejectionReason,
    List<String>? requiredDocuments,
    List<String>? completedDocuments,
    Map<String, dynamic>? customFields,
    String? notes,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CUIdentityVerification(
      financialInstitutionId:
          financialInstitutionId ?? this.financialInstitutionId,
      memberId: memberId ?? this.memberId,
      providerName: providerName ?? this.providerName,
      verificationType: verificationType ?? this.verificationType,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationData: verificationData ?? this.verificationData,
      verificationDate: verificationDate ?? this.verificationDate,
      isVerified: isVerified ?? this.isVerified,
      verificationScore: verificationScore ?? this.verificationScore,
      verificationIssues: verificationIssues ?? this.verificationIssues,
      providerMetadata: providerMetadata ?? this.providerMetadata,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      biometricData: biometricData ?? this.biometricData,
      addressVerification: addressVerification ?? this.addressVerification,
      phoneVerification: phoneVerification ?? this.phoneVerification,
      emailVerification: emailVerification ?? this.emailVerification,
      ssnVerification: ssnVerification ?? this.ssnVerification,
      ofacVerification: ofacVerification ?? this.ofacVerification,
      pepVerification: pepVerification ?? this.pepVerification,
      sanctionsVerification:
          sanctionsVerification ?? this.sanctionsVerification,
      watchlistVerification:
          watchlistVerification ?? this.watchlistVerification,
      riskAssessment: riskAssessment ?? this.riskAssessment,
      complianceChecks: complianceChecks ?? this.complianceChecks,
      verificationId: verificationId ?? this.verificationId,
      sessionId: sessionId ?? this.sessionId,
      referenceId: referenceId ?? this.referenceId,
      auditTrail: auditTrail ?? this.auditTrail,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      completedDocuments: completedDocuments ?? this.completedDocuments,
      customFields: customFields ?? this.customFields,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CUIdentityVerification(financialInstitutionId: $financialInstitutionId, memberId: $memberId, providerName: $providerName, verificationType: $verificationType, verificationStatus: $verificationStatus, isVerified: $isVerified, verificationScore: $verificationScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CUIdentityVerification &&
        other.financialInstitutionId == financialInstitutionId &&
        other.memberId == memberId &&
        other.providerName == providerName &&
        other.verificationType == verificationType &&
        other.verificationStatus == verificationStatus &&
        other.isVerified == isVerified &&
        other.verificationScore == verificationScore;
  }

  @override
  int get hashCode {
    return Object.hash(
      financialInstitutionId,
      memberId,
      providerName,
      verificationType,
      verificationStatus,
      isVerified,
      verificationScore,
    );
  }
}
