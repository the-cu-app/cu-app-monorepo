class CUSignatureCapture {
  final String financialInstitutionId;
  final String memberId;
  final String signatureId;
  final String documentType;
  final List<int> signatureData;
  final String signatureFormat;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> verificationData;
  final Map<String, dynamic> complianceData;
  final Map<String, dynamic> auditTrail;
  final String? status;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime capturedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUSignatureCapture({
    required this.financialInstitutionId,
    required this.memberId,
    required this.signatureId,
    required this.documentType,
    required this.signatureData,
    required this.signatureFormat,
    this.metadata = const {},
    this.verificationData = const {},
    this.complianceData = const {},
    this.auditTrail = const {},
    this.status,
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.capturedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUSignatureCapture.fromJson(Map<String, dynamic> json) {
    return CUSignatureCapture(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      signatureId: json['signatureId'] as String,
      documentType: json['documentType'] as String,
      signatureData: List<int>.from(json['signatureData'] ?? []),
      signatureFormat: json['signatureFormat'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      verificationData: Map<String, dynamic>.from(
        json['verificationData'] ?? {},
      ),
      complianceData: Map<String, dynamic>.from(json['complianceData'] ?? {}),
      auditTrail: Map<String, dynamic>.from(json['auditTrail'] ?? {}),
      status: json['status'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financialInstitutionId': financialInstitutionId,
      'memberId': memberId,
      'signatureId': signatureId,
      'documentType': documentType,
      'signatureData': signatureData,
      'signatureFormat': signatureFormat,
      'metadata': metadata,
      'verificationData': verificationData,
      'complianceData': complianceData,
      'auditTrail': auditTrail,
      'status': status,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'capturedAt': capturedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
