class CUTermsAcceptance {
  final String financialInstitutionId;
  final String memberId;
  final String termsId;
  final String termsTitle;
  final String termsDescription;
  final String termsContent;
  final String termsVersion;
  final DateTime effectiveDate;
  final DateTime? expirationDate;
  final String? legalJurisdiction;
  final String? governingLaw;
  final Map<String, dynamic> termsData;
  final Map<String, dynamic> complianceData;
  final Map<String, dynamic> auditTrail;
  final String? status;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUTermsAcceptance({
    required this.financialInstitutionId,
    required this.memberId,
    required this.termsId,
    required this.termsTitle,
    required this.termsDescription,
    required this.termsContent,
    required this.termsVersion,
    required this.effectiveDate,
    this.expirationDate,
    this.legalJurisdiction,
    this.governingLaw,
    this.termsData = const {},
    this.complianceData = const {},
    this.auditTrail = const {},
    this.status,
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUTermsAcceptance.fromJson(Map<String, dynamic> json) {
    return CUTermsAcceptance(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      termsId: json['termsId'] as String,
      termsTitle: json['termsTitle'] as String,
      termsDescription: json['termsDescription'] as String,
      termsContent: json['termsContent'] as String,
      termsVersion: json['termsVersion'] as String,
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'] as String)
          : null,
      legalJurisdiction: json['legalJurisdiction'] as String?,
      governingLaw: json['governingLaw'] as String?,
      termsData: Map<String, dynamic>.from(json['termsData'] ?? {}),
      complianceData: Map<String, dynamic>.from(json['complianceData'] ?? {}),
      auditTrail: Map<String, dynamic>.from(json['auditTrail'] ?? {}),
      status: json['status'] as String?,
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
      'termsId': termsId,
      'termsTitle': termsTitle,
      'termsDescription': termsDescription,
      'termsContent': termsContent,
      'termsVersion': termsVersion,
      'effectiveDate': effectiveDate.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'legalJurisdiction': legalJurisdiction,
      'governingLaw': governingLaw,
      'termsData': termsData,
      'complianceData': complianceData,
      'auditTrail': auditTrail,
      'status': status,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
