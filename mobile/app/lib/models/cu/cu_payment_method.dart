class CUPaymentMethod {
  final String financialInstitutionId;
  final String memberId;
  final String paymentMethodId;
  final String methodType;
  final String methodName;
  final bool isActive;
  final bool isDefault;
  final Map<String, dynamic> methodData;
  final Map<String, dynamic> securitySettings;
  final Map<String, dynamic> limits;
  final Map<String, dynamic> fees;
  final Map<String, dynamic> processingInfo;
  final Map<String, dynamic> complianceData;
  final Map<String, dynamic> auditTrail;
  final String? lastUsedDate;
  final String? expirationDate;
  final String? status;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUPaymentMethod({
    required this.financialInstitutionId,
    required this.memberId,
    required this.paymentMethodId,
    required this.methodType,
    required this.methodName,
    required this.isActive,
    required this.isDefault,
    this.methodData = const {},
    this.securitySettings = const {},
    this.limits = const {},
    this.fees = const {},
    this.processingInfo = const {},
    this.complianceData = const {},
    this.auditTrail = const {},
    this.lastUsedDate,
    this.expirationDate,
    this.status,
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUPaymentMethod.fromJson(Map<String, dynamic> json) {
    return CUPaymentMethod(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      paymentMethodId: json['paymentMethodId'] as String,
      methodType: json['methodType'] as String,
      methodName: json['methodName'] as String,
      isActive: json['isActive'] as bool,
      isDefault: json['isDefault'] as bool,
      methodData: Map<String, dynamic>.from(json['methodData'] ?? {}),
      securitySettings: Map<String, dynamic>.from(
        json['securitySettings'] ?? {},
      ),
      limits: Map<String, dynamic>.from(json['limits'] ?? {}),
      fees: Map<String, dynamic>.from(json['fees'] ?? {}),
      processingInfo: Map<String, dynamic>.from(json['processingInfo'] ?? {}),
      complianceData: Map<String, dynamic>.from(json['complianceData'] ?? {}),
      auditTrail: Map<String, dynamic>.from(json['auditTrail'] ?? {}),
      lastUsedDate: json['lastUsedDate'] as String?,
      expirationDate: json['expirationDate'] as String?,
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
      'paymentMethodId': paymentMethodId,
      'methodType': methodType,
      'methodName': methodName,
      'isActive': isActive,
      'isDefault': isDefault,
      'methodData': methodData,
      'securitySettings': securitySettings,
      'limits': limits,
      'fees': fees,
      'processingInfo': processingInfo,
      'complianceData': complianceData,
      'auditTrail': auditTrail,
      'lastUsedDate': lastUsedDate,
      'expirationDate': expirationDate,
      'status': status,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
