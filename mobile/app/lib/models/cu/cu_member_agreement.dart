class CUMemberAgreement {
  final String financialInstitutionId;
  final String agreementId;
  final String agreementTitle;
  final String agreementDescription;
  final String agreementContent;
  final String agreementVersion;
  final String agreementType;
  final bool isRequired;
  final bool isActive;
  final DateTime effectiveDate;
  final DateTime? expirationDate;
  final String? legalJurisdiction;
  final String? governingLaw;
  final List<String> requiredSignatures;
  final List<String> optionalSignatures;
  final Map<String, dynamic> termsAndConditions;
  final Map<String, dynamic> privacyPolicy;
  final Map<String, dynamic> dataProcessing;
  final Map<String, dynamic> consentManagement;
  final Map<String, dynamic> disputeResolution;
  final Map<String, dynamic> liabilityLimitations;
  final Map<String, dynamic> intellectualProperty;
  final Map<String, dynamic> terminationClauses;
  final Map<String, dynamic> amendmentProcedures;
  final Map<String, dynamic> complianceRequirements;
  final Map<String, dynamic> auditRequirements;
  final Map<String, dynamic> reportingObligations;
  final Map<String, dynamic> customFields;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUMemberAgreement({
    required this.financialInstitutionId,
    required this.agreementId,
    required this.agreementTitle,
    required this.agreementDescription,
    required this.agreementContent,
    required this.agreementVersion,
    required this.agreementType,
    required this.isRequired,
    required this.isActive,
    required this.effectiveDate,
    this.expirationDate,
    this.legalJurisdiction,
    this.governingLaw,
    this.requiredSignatures = const [],
    this.optionalSignatures = const [],
    this.termsAndConditions = const {},
    this.privacyPolicy = const {},
    this.dataProcessing = const {},
    this.consentManagement = const {},
    this.disputeResolution = const {},
    this.liabilityLimitations = const {},
    this.intellectualProperty = const {},
    this.terminationClauses = const {},
    this.amendmentProcedures = const {},
    this.complianceRequirements = const {},
    this.auditRequirements = const {},
    this.reportingObligations = const {},
    this.customFields = const {},
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUMemberAgreement.fromJson(Map<String, dynamic> json) {
    return CUMemberAgreement(
      financialInstitutionId: json['financialInstitutionId'] as String,
      agreementId: json['agreementId'] as String,
      agreementTitle: json['agreementTitle'] as String,
      agreementDescription: json['agreementDescription'] as String,
      agreementContent: json['agreementContent'] as String,
      agreementVersion: json['agreementVersion'] as String,
      agreementType: json['agreementType'] as String,
      isRequired: json['isRequired'] as bool,
      isActive: json['isActive'] as bool,
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'] as String)
          : null,
      legalJurisdiction: json['legalJurisdiction'] as String?,
      governingLaw: json['governingLaw'] as String?,
      requiredSignatures: List<String>.from(json['requiredSignatures'] ?? []),
      optionalSignatures: List<String>.from(json['optionalSignatures'] ?? []),
      termsAndConditions: Map<String, dynamic>.from(
        json['termsAndConditions'] ?? {},
      ),
      privacyPolicy: Map<String, dynamic>.from(json['privacyPolicy'] ?? {}),
      dataProcessing: Map<String, dynamic>.from(json['dataProcessing'] ?? {}),
      consentManagement: Map<String, dynamic>.from(
        json['consentManagement'] ?? {},
      ),
      disputeResolution: Map<String, dynamic>.from(
        json['disputeResolution'] ?? {},
      ),
      liabilityLimitations: Map<String, dynamic>.from(
        json['liabilityLimitations'] ?? {},
      ),
      intellectualProperty: Map<String, dynamic>.from(
        json['intellectualProperty'] ?? {},
      ),
      terminationClauses: Map<String, dynamic>.from(
        json['terminationClauses'] ?? {},
      ),
      amendmentProcedures: Map<String, dynamic>.from(
        json['amendmentProcedures'] ?? {},
      ),
      complianceRequirements: Map<String, dynamic>.from(
        json['complianceRequirements'] ?? {},
      ),
      auditRequirements: Map<String, dynamic>.from(
        json['auditRequirements'] ?? {},
      ),
      reportingObligations: Map<String, dynamic>.from(
        json['reportingObligations'] ?? {},
      ),
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
      'agreementId': agreementId,
      'agreementTitle': agreementTitle,
      'agreementDescription': agreementDescription,
      'agreementContent': agreementContent,
      'agreementVersion': agreementVersion,
      'agreementType': agreementType,
      'isRequired': isRequired,
      'isActive': isActive,
      'effectiveDate': effectiveDate.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'legalJurisdiction': legalJurisdiction,
      'governingLaw': governingLaw,
      'requiredSignatures': requiredSignatures,
      'optionalSignatures': optionalSignatures,
      'termsAndConditions': termsAndConditions,
      'privacyPolicy': privacyPolicy,
      'dataProcessing': dataProcessing,
      'consentManagement': consentManagement,
      'disputeResolution': disputeResolution,
      'liabilityLimitations': liabilityLimitations,
      'intellectualProperty': intellectualProperty,
      'terminationClauses': terminationClauses,
      'amendmentProcedures': amendmentProcedures,
      'complianceRequirements': complianceRequirements,
      'auditRequirements': auditRequirements,
      'reportingObligations': reportingObligations,
      'customFields': customFields,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
