class CURiskAssessment {
  final String financialInstitutionId;
  final String memberId;
  final String assessmentId;
  final String assessmentType;
  final String riskLevel;
  final double riskScore;
  final Map<String, dynamic> responses;
  final Map<String, dynamic> riskFactors;
  final Map<String, dynamic> recommendations;
  final Map<String, dynamic> complianceChecks;
  final Map<String, dynamic> auditTrail;
  final String? status;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CURiskAssessment({
    required this.financialInstitutionId,
    required this.memberId,
    required this.assessmentId,
    required this.assessmentType,
    required this.riskLevel,
    required this.riskScore,
    this.responses = const {},
    this.riskFactors = const {},
    this.recommendations = const {},
    this.complianceChecks = const {},
    this.auditTrail = const {},
    this.status,
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CURiskAssessment.fromJson(Map<String, dynamic> json) {
    return CURiskAssessment(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      assessmentId: json['assessmentId'] as String,
      assessmentType: json['assessmentType'] as String,
      riskLevel: json['riskLevel'] as String,
      riskScore: (json['riskScore'] as num).toDouble(),
      responses: Map<String, dynamic>.from(json['responses'] ?? {}),
      riskFactors: Map<String, dynamic>.from(json['riskFactors'] ?? {}),
      recommendations: Map<String, dynamic>.from(json['recommendations'] ?? {}),
      complianceChecks: Map<String, dynamic>.from(
        json['complianceChecks'] ?? {},
      ),
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
      'assessmentId': assessmentId,
      'assessmentType': assessmentType,
      'riskLevel': riskLevel,
      'riskScore': riskScore,
      'responses': responses,
      'riskFactors': riskFactors,
      'recommendations': recommendations,
      'complianceChecks': complianceChecks,
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
