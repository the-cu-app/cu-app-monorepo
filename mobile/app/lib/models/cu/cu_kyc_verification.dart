class CUKYCVerification {
  final String financialInstitutionId;
  final String memberId;
  final String verificationType;
  final String verificationStatus;
  final Map<String, dynamic> verificationData;
  final DateTime verificationDate;
  final bool isVerified;
  final String verificationScore;
  final List<String> verificationIssues;
  final Map<String, dynamic> identityChecks;
  final Map<String, dynamic> addressChecks;
  final Map<String, dynamic> documentChecks;
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

  const CUKYCVerification({
    required this.financialInstitutionId,
    required this.memberId,
    required this.verificationType,
    required this.verificationStatus,
    required this.verificationData,
    required this.verificationDate,
    required this.isVerified,
    required this.verificationScore,
    this.verificationIssues = const [],
    this.identityChecks = const {},
    this.addressChecks = const {},
    this.documentChecks = const {},
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

  factory CUKYCVerification.fromJson(Map<String, dynamic> json) {
    return CUKYCVerification(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      verificationType: json['verificationType'] as String,
      verificationStatus: json['verificationStatus'] as String,
      verificationData: Map<String, dynamic>.from(
        json['verificationData'] ?? {},
      ),
      verificationDate: DateTime.parse(json['verificationDate'] as String),
      isVerified: json['isVerified'] as bool,
      verificationScore: json['verificationScore'] as String,
      verificationIssues: List<String>.from(json['verificationIssues'] ?? []),
      identityChecks: Map<String, dynamic>.from(json['identityChecks'] ?? {}),
      addressChecks: Map<String, dynamic>.from(json['addressChecks'] ?? {}),
      documentChecks: Map<String, dynamic>.from(json['documentChecks'] ?? {}),
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
      'verificationType': verificationType,
      'verificationStatus': verificationStatus,
      'verificationData': verificationData,
      'verificationDate': verificationDate.toIso8601String(),
      'isVerified': isVerified,
      'verificationScore': verificationScore,
      'verificationIssues': verificationIssues,
      'identityChecks': identityChecks,
      'addressChecks': addressChecks,
      'documentChecks': documentChecks,
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
}
