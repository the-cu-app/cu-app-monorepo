class CUVerificationStatus {
  final String financialInstitutionId;
  final String memberId;
  final String statusId;
  final String overallStatus;
  final double completionPercentage;
  final bool isComplete;
  final List<String> completedSteps;
  final List<String> pendingSteps;
  final List<String> failedSteps;
  final Map<String, dynamic> stepDetails;
  final Map<String, dynamic> verificationData;
  final Map<String, dynamic> complianceData;
  final Map<String, dynamic> auditTrail;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUVerificationStatus({
    required this.financialInstitutionId,
    required this.memberId,
    required this.statusId,
    required this.overallStatus,
    required this.completionPercentage,
    required this.isComplete,
    this.completedSteps = const [],
    this.pendingSteps = const [],
    this.failedSteps = const [],
    this.stepDetails = const {},
    this.verificationData = const {},
    this.complianceData = const {},
    this.auditTrail = const {},
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUVerificationStatus.fromJson(Map<String, dynamic> json) {
    return CUVerificationStatus(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      statusId: json['statusId'] as String,
      overallStatus: json['overallStatus'] as String,
      completionPercentage: (json['completionPercentage'] as num).toDouble(),
      isComplete: json['isComplete'] as bool,
      completedSteps: List<String>.from(json['completedSteps'] ?? []),
      pendingSteps: List<String>.from(json['pendingSteps'] ?? []),
      failedSteps: List<String>.from(json['failedSteps'] ?? []),
      stepDetails: Map<String, dynamic>.from(json['stepDetails'] ?? {}),
      verificationData: Map<String, dynamic>.from(
        json['verificationData'] ?? {},
      ),
      complianceData: Map<String, dynamic>.from(json['complianceData'] ?? {}),
      auditTrail: Map<String, dynamic>.from(json['auditTrail'] ?? {}),
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
      'statusId': statusId,
      'overallStatus': overallStatus,
      'completionPercentage': completionPercentage,
      'isComplete': isComplete,
      'completedSteps': completedSteps,
      'pendingSteps': pendingSteps,
      'failedSteps': failedSteps,
      'stepDetails': stepDetails,
      'verificationData': verificationData,
      'complianceData': complianceData,
      'auditTrail': auditTrail,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
