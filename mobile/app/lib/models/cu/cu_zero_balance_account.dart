class CUZeroBalanceAccount {
  final String financialInstitutionId;
  final String memberId;
  final String accountId;
  final String accountType;
  final String accountNumber;
  final String nickname;
  final double currentBalance;
  final double minimumBalance;
  final String status;
  final bool overdraftProtection;
  final bool mobileBanking;
  final bool onlineBanking;
  final Map<String, dynamic> accountFeatures;
  final Map<String, dynamic> fees;
  final Map<String, dynamic> limits;
  final Map<String, dynamic> complianceData;
  final Map<String, dynamic> auditTrail;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUZeroBalanceAccount({
    required this.financialInstitutionId,
    required this.memberId,
    required this.accountId,
    required this.accountType,
    required this.accountNumber,
    required this.nickname,
    required this.currentBalance,
    required this.minimumBalance,
    required this.status,
    required this.overdraftProtection,
    required this.mobileBanking,
    required this.onlineBanking,
    this.accountFeatures = const {},
    this.fees = const {},
    this.limits = const {},
    this.complianceData = const {},
    this.auditTrail = const {},
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUZeroBalanceAccount.fromJson(Map<String, dynamic> json) {
    return CUZeroBalanceAccount(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      accountId: json['accountId'] as String,
      accountType: json['accountType'] as String,
      accountNumber: json['accountNumber'] as String,
      nickname: json['nickname'] as String,
      currentBalance: (json['currentBalance'] as num).toDouble(),
      minimumBalance: (json['minimumBalance'] as num).toDouble(),
      status: json['status'] as String,
      overdraftProtection: json['overdraftProtection'] as bool,
      mobileBanking: json['mobileBanking'] as bool,
      onlineBanking: json['onlineBanking'] as bool,
      accountFeatures: Map<String, dynamic>.from(json['accountFeatures'] ?? {}),
      fees: Map<String, dynamic>.from(json['fees'] ?? {}),
      limits: Map<String, dynamic>.from(json['limits'] ?? {}),
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
      'accountType': accountType,
      'accountNumber': accountNumber,
      'nickname': nickname,
      'currentBalance': currentBalance,
      'minimumBalance': minimumBalance,
      'status': status,
      'overdraftProtection': overdraftProtection,
      'mobileBanking': mobileBanking,
      'onlineBanking': onlineBanking,
      'accountFeatures': accountFeatures,
      'fees': fees,
      'limits': limits,
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
