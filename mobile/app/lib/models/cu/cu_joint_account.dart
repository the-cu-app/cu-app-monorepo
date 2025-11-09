class CUJointAccount {
  final String financialInstitutionId;
  final String primaryMemberId;
  final String secondaryMemberId;
  final String accountType;
  final String ownershipType;
  final String accessLevel;
  final String signatureRequired;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUJointAccount({
    required this.financialInstitutionId,
    required this.primaryMemberId,
    required this.secondaryMemberId,
    required this.accountType,
    required this.ownershipType,
    required this.accessLevel,
    required this.signatureRequired,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUJointAccount.fromJson(Map<String, dynamic> json) {
    return CUJointAccount(
      financialInstitutionId: json['financialInstitutionId'] as String,
      primaryMemberId: json['primaryMemberId'] as String,
      secondaryMemberId: json['secondaryMemberId'] as String,
      accountType: json['accountType'] as String,
      ownershipType: json['ownershipType'] as String,
      accessLevel: json['accessLevel'] as String,
      signatureRequired: json['signatureRequired'] as String,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financialInstitutionId': financialInstitutionId,
      'primaryMemberId': primaryMemberId,
      'secondaryMemberId': secondaryMemberId,
      'accountType': accountType,
      'ownershipType': ownershipType,
      'accessLevel': accessLevel,
      'signatureRequired': signatureRequired,
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
