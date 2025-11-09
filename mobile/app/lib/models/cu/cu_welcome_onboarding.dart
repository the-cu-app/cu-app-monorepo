class CUWelcomeOnboarding {
  final String financialInstitutionId;
  final String memberId;
  final String onboardingId;
  final String onboardingType;
  final String status;
  final double completionPercentage;
  final bool isComplete;
  final List<String> completedSteps;
  final List<String> pendingSteps;
  final Map<String, dynamic> onboardingData;
  final Map<String, dynamic> memberPreferences;
  final Map<String, dynamic> customizationData;
  final Map<String, dynamic> auditTrail;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUWelcomeOnboarding({
    required this.financialInstitutionId,
    required this.memberId,
    required this.onboardingId,
    required this.onboardingType,
    required this.status,
    required this.completionPercentage,
    required this.isComplete,
    this.completedSteps = const [],
    this.pendingSteps = const [],
    this.onboardingData = const {},
    this.memberPreferences = const {},
    this.customizationData = const {},
    this.auditTrail = const {},
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUWelcomeOnboarding.fromJson(Map<String, dynamic> json) {
    return CUWelcomeOnboarding(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      onboardingId: json['onboardingId'] as String,
      onboardingType: json['onboardingType'] as String,
      status: json['status'] as String,
      completionPercentage: (json['completionPercentage'] as num).toDouble(),
      isComplete: json['isComplete'] as bool,
      completedSteps: List<String>.from(json['completedSteps'] ?? []),
      pendingSteps: List<String>.from(json['pendingSteps'] ?? []),
      onboardingData: Map<String, dynamic>.from(json['onboardingData'] ?? {}),
      memberPreferences: Map<String, dynamic>.from(
        json['memberPreferences'] ?? {},
      ),
      customizationData: Map<String, dynamic>.from(
        json['customizationData'] ?? {},
      ),
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
      'onboardingId': onboardingId,
      'onboardingType': onboardingType,
      'status': status,
      'completionPercentage': completionPercentage,
      'isComplete': isComplete,
      'completedSteps': completedSteps,
      'pendingSteps': pendingSteps,
      'onboardingData': onboardingData,
      'memberPreferences': memberPreferences,
      'customizationData': customizationData,
      'auditTrail': auditTrail,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
