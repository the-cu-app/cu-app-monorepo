class CUYouthAccount {
  final String financialInstitutionId;
  final String memberId;
  final String accountId;
  final String youthName;
  final String dateOfBirth;
  final String accountType;
  final String guardianName;
  final String guardianRelationship;
  final String guardianId;
  final double initialDeposit;
  final String status;
  final Map<String, dynamic> accountFeatures;
  final Map<String, dynamic> restrictions;
  final Map<String, dynamic> guardianControls;
  final Map<String, dynamic> complianceData;
  final Map<String, dynamic> auditTrail;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUYouthAccount({
    required this.financialInstitutionId,
    required this.memberId,
    required this.accountId,
    required this.youthName,
    required this.dateOfBirth,
    required this.accountType,
    required this.guardianName,
    required this.guardianRelationship,
    required this.guardianId,
    required this.initialDeposit,
    required this.status,
    this.accountFeatures = const {},
    this.restrictions = const {},
    this.guardianControls = const {},
    this.complianceData = const {},
    this.auditTrail = const {},
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUYouthAccount.fromJson(Map<String, dynamic> json) {
    return CUYouthAccount(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      accountId: json['accountId'] as String,
      youthName: json['youthName'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      accountType: json['accountType'] as String,
      guardianName: json['guardianName'] as String,
      guardianRelationship: json['guardianRelationship'] as String,
      guardianId: json['guardianId'] as String,
      initialDeposit: (json['initialDeposit'] as num).toDouble(),
      status: json['status'] as String,
      accountFeatures: Map<String, dynamic>.from(json['accountFeatures'] ?? {}),
      restrictions: Map<String, dynamic>.from(json['restrictions'] ?? {}),
      guardianControls: Map<String, dynamic>.from(
        json['guardianControls'] ?? {},
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
      'accountId': accountId,
      'youthName': youthName,
      'dateOfBirth': dateOfBirth,
      'accountType': accountType,
      'guardianName': guardianName,
      'guardianRelationship': guardianRelationship,
      'guardianId': guardianId,
      'initialDeposit': initialDeposit,
      'status': status,
      'accountFeatures': accountFeatures,
      'restrictions': restrictions,
      'guardianControls': guardianControls,
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
