class CUIncomeVerification {
  final String financialInstitutionId;
  final String memberId;
  final String providerName;
  final String verificationType;
  final String verificationStatus;
  final Map<String, dynamic> verificationData;
  final DateTime verificationDate;
  final bool isVerified;
  final String verificationScore;
  final List<String> verificationIssues;
  final Map<String, dynamic> providerMetadata;
  final double reportedIncome;
  final double verifiedIncome;
  final String incomeType;
  final String? employerName;
  final String? jobTitle;
  final String? employmentStatus;
  final String? employerAddress;
  final String? employerPhone;
  final String? employerEmail;
  final String? supervisorName;
  final String? supervisorPhone;
  final String? supervisorEmail;
  final DateTime? employmentStartDate;
  final DateTime? employmentEndDate;
  final String? payFrequency;
  final String? payMethod;
  final String? bankAccountNumber;
  final String? bankRoutingNumber;
  final String? bankName;
  final String? bankAddress;
  final String? bankPhone;
  final String? bankEmail;
  final List<String> incomeSources;
  final List<String> verifiedSources;
  final Map<String, dynamic> bankStatementData;
  final Map<String, dynamic> paystubData;
  final Map<String, dynamic> taxReturnData;
  final Map<String, dynamic> w2Data;
  final Map<String, dynamic> w4Data;
  final Map<String, dynamic> directDepositData;
  final Map<String, dynamic> payrollData;
  final Map<String, dynamic> benefitsData;
  final Map<String, dynamic> deductionsData;
  final Map<String, dynamic> overtimeData;
  final Map<String, dynamic> bonusData;
  final Map<String, dynamic> commissionData;
  final Map<String, dynamic> tipsData;
  final Map<String, dynamic> selfEmploymentData;
  final Map<String, dynamic> businessData;
  final Map<String, dynamic> investmentData;
  final Map<String, dynamic> rentalData;
  final Map<String, dynamic> retirementData;
  final Map<String, dynamic> disabilityData;
  final Map<String, dynamic> socialSecurityData;
  final Map<String, dynamic> unemploymentData;
  final Map<String, dynamic> otherIncomeData;
  final Map<String, dynamic> riskAssessment;
  final Map<String, dynamic> complianceChecks;
  final String? verificationId;
  final String? sessionId;
  final String? referenceId;
  final Map<String, dynamic> auditTrail;
  final DateTime? expiresAt;
  final bool isActive;
  final String? rejectionReason;
  final List<String> requiredDocuments;
  final List<String> completedDocuments;
  final Map<String, dynamic> customFields;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUIncomeVerification({
    required this.financialInstitutionId,
    required this.memberId,
    required this.providerName,
    required this.verificationType,
    required this.verificationStatus,
    required this.verificationData,
    required this.verificationDate,
    required this.isVerified,
    required this.verificationScore,
    this.verificationIssues = const [],
    this.providerMetadata = const {},
    required this.reportedIncome,
    required this.verifiedIncome,
    required this.incomeType,
    this.employerName,
    this.jobTitle,
    this.employmentStatus,
    this.employerAddress,
    this.employerPhone,
    this.employerEmail,
    this.supervisorName,
    this.supervisorPhone,
    this.supervisorEmail,
    this.employmentStartDate,
    this.employmentEndDate,
    this.payFrequency,
    this.payMethod,
    this.bankAccountNumber,
    this.bankRoutingNumber,
    this.bankName,
    this.bankAddress,
    this.bankPhone,
    this.bankEmail,
    this.incomeSources = const [],
    this.verifiedSources = const [],
    this.bankStatementData = const {},
    this.paystubData = const {},
    this.taxReturnData = const {},
    this.w2Data = const {},
    this.w4Data = const {},
    this.directDepositData = const {},
    this.payrollData = const {},
    this.benefitsData = const {},
    this.deductionsData = const {},
    this.overtimeData = const {},
    this.bonusData = const {},
    this.commissionData = const {},
    this.tipsData = const {},
    this.selfEmploymentData = const {},
    this.businessData = const {},
    this.investmentData = const {},
    this.rentalData = const {},
    this.retirementData = const {},
    this.disabilityData = const {},
    this.socialSecurityData = const {},
    this.unemploymentData = const {},
    this.otherIncomeData = const {},
    this.riskAssessment = const {},
    this.complianceChecks = const {},
    this.verificationId,
    this.sessionId,
    this.referenceId,
    this.auditTrail = const {},
    this.expiresAt,
    this.isActive = true,
    this.rejectionReason,
    this.requiredDocuments = const [],
    this.completedDocuments = const [],
    this.customFields = const {},
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUIncomeVerification.fromJson(Map<String, dynamic> json) {
    return CUIncomeVerification(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      providerName: json['providerName'] as String,
      verificationType: json['verificationType'] as String,
      verificationStatus: json['verificationStatus'] as String,
      verificationData: Map<String, dynamic>.from(
        json['verificationData'] ?? {},
      ),
      verificationDate: DateTime.parse(json['verificationDate'] as String),
      isVerified: json['isVerified'] as bool,
      verificationScore: json['verificationScore'] as String,
      verificationIssues: List<String>.from(json['verificationIssues'] ?? []),
      providerMetadata: Map<String, dynamic>.from(
        json['providerMetadata'] ?? {},
      ),
      reportedIncome: (json['reportedIncome'] as num).toDouble(),
      verifiedIncome: (json['verifiedIncome'] as num).toDouble(),
      incomeType: json['incomeType'] as String,
      employerName: json['employerName'] as String?,
      jobTitle: json['jobTitle'] as String?,
      employmentStatus: json['employmentStatus'] as String?,
      employerAddress: json['employerAddress'] as String?,
      employerPhone: json['employerPhone'] as String?,
      employerEmail: json['employerEmail'] as String?,
      supervisorName: json['supervisorName'] as String?,
      supervisorPhone: json['supervisorPhone'] as String?,
      supervisorEmail: json['supervisorEmail'] as String?,
      employmentStartDate: json['employmentStartDate'] != null
          ? DateTime.parse(json['employmentStartDate'] as String)
          : null,
      employmentEndDate: json['employmentEndDate'] != null
          ? DateTime.parse(json['employmentEndDate'] as String)
          : null,
      payFrequency: json['payFrequency'] as String?,
      payMethod: json['payMethod'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankRoutingNumber: json['bankRoutingNumber'] as String?,
      bankName: json['bankName'] as String?,
      bankAddress: json['bankAddress'] as String?,
      bankPhone: json['bankPhone'] as String?,
      bankEmail: json['bankEmail'] as String?,
      incomeSources: List<String>.from(json['incomeSources'] ?? []),
      verifiedSources: List<String>.from(json['verifiedSources'] ?? []),
      bankStatementData: Map<String, dynamic>.from(
        json['bankStatementData'] ?? {},
      ),
      paystubData: Map<String, dynamic>.from(json['paystubData'] ?? {}),
      taxReturnData: Map<String, dynamic>.from(json['taxReturnData'] ?? {}),
      w2Data: Map<String, dynamic>.from(json['w2Data'] ?? {}),
      w4Data: Map<String, dynamic>.from(json['w4Data'] ?? {}),
      directDepositData: Map<String, dynamic>.from(
        json['directDepositData'] ?? {},
      ),
      payrollData: Map<String, dynamic>.from(json['payrollData'] ?? {}),
      benefitsData: Map<String, dynamic>.from(json['benefitsData'] ?? {}),
      deductionsData: Map<String, dynamic>.from(json['deductionsData'] ?? {}),
      overtimeData: Map<String, dynamic>.from(json['overtimeData'] ?? {}),
      bonusData: Map<String, dynamic>.from(json['bonusData'] ?? {}),
      commissionData: Map<String, dynamic>.from(json['commissionData'] ?? {}),
      tipsData: Map<String, dynamic>.from(json['tipsData'] ?? {}),
      selfEmploymentData: Map<String, dynamic>.from(
        json['selfEmploymentData'] ?? {},
      ),
      businessData: Map<String, dynamic>.from(json['businessData'] ?? {}),
      investmentData: Map<String, dynamic>.from(json['investmentData'] ?? {}),
      rentalData: Map<String, dynamic>.from(json['rentalData'] ?? {}),
      retirementData: Map<String, dynamic>.from(json['retirementData'] ?? {}),
      disabilityData: Map<String, dynamic>.from(json['disabilityData'] ?? {}),
      socialSecurityData: Map<String, dynamic>.from(
        json['socialSecurityData'] ?? {},
      ),
      unemploymentData: Map<String, dynamic>.from(
        json['unemploymentData'] ?? {},
      ),
      otherIncomeData: Map<String, dynamic>.from(json['otherIncomeData'] ?? {}),
      riskAssessment: Map<String, dynamic>.from(json['riskAssessment'] ?? {}),
      complianceChecks: Map<String, dynamic>.from(
        json['complianceChecks'] ?? {},
      ),
      verificationId: json['verificationId'] as String?,
      sessionId: json['sessionId'] as String?,
      referenceId: json['referenceId'] as String?,
      auditTrail: Map<String, dynamic>.from(json['auditTrail'] ?? {}),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      rejectionReason: json['rejectionReason'] as String?,
      requiredDocuments: List<String>.from(json['requiredDocuments'] ?? []),
      completedDocuments: List<String>.from(json['completedDocuments'] ?? []),
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
      'memberId': memberId,
      'providerName': providerName,
      'verificationType': verificationType,
      'verificationStatus': verificationStatus,
      'verificationData': verificationData,
      'verificationDate': verificationDate.toIso8601String(),
      'isVerified': isVerified,
      'verificationScore': verificationScore,
      'verificationIssues': verificationIssues,
      'providerMetadata': providerMetadata,
      'reportedIncome': reportedIncome,
      'verifiedIncome': verifiedIncome,
      'incomeType': incomeType,
      'employerName': employerName,
      'jobTitle': jobTitle,
      'employmentStatus': employmentStatus,
      'employerAddress': employerAddress,
      'employerPhone': employerPhone,
      'employerEmail': employerEmail,
      'supervisorName': supervisorName,
      'supervisorPhone': supervisorPhone,
      'supervisorEmail': supervisorEmail,
      'employmentStartDate': employmentStartDate?.toIso8601String(),
      'employmentEndDate': employmentEndDate?.toIso8601String(),
      'payFrequency': payFrequency,
      'payMethod': payMethod,
      'bankAccountNumber': bankAccountNumber,
      'bankRoutingNumber': bankRoutingNumber,
      'bankName': bankName,
      'bankAddress': bankAddress,
      'bankPhone': bankPhone,
      'bankEmail': bankEmail,
      'incomeSources': incomeSources,
      'verifiedSources': verifiedSources,
      'bankStatementData': bankStatementData,
      'paystubData': paystubData,
      'taxReturnData': taxReturnData,
      'w2Data': w2Data,
      'w4Data': w4Data,
      'directDepositData': directDepositData,
      'payrollData': payrollData,
      'benefitsData': benefitsData,
      'deductionsData': deductionsData,
      'overtimeData': overtimeData,
      'bonusData': bonusData,
      'commissionData': commissionData,
      'tipsData': tipsData,
      'selfEmploymentData': selfEmploymentData,
      'businessData': businessData,
      'investmentData': investmentData,
      'rentalData': rentalData,
      'retirementData': retirementData,
      'disabilityData': disabilityData,
      'socialSecurityData': socialSecurityData,
      'unemploymentData': unemploymentData,
      'otherIncomeData': otherIncomeData,
      'riskAssessment': riskAssessment,
      'complianceChecks': complianceChecks,
      'verificationId': verificationId,
      'sessionId': sessionId,
      'referenceId': referenceId,
      'auditTrail': auditTrail,
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'rejectionReason': rejectionReason,
      'requiredDocuments': requiredDocuments,
      'completedDocuments': completedDocuments,
      'customFields': customFields,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CUIncomeVerification copyWith({
    String? financialInstitutionId,
    String? memberId,
    String? providerName,
    String? verificationType,
    String? verificationStatus,
    Map<String, dynamic>? verificationData,
    DateTime? verificationDate,
    bool? isVerified,
    String? verificationScore,
    List<String>? verificationIssues,
    Map<String, dynamic>? providerMetadata,
    double? reportedIncome,
    double? verifiedIncome,
    String? incomeType,
    String? employerName,
    String? jobTitle,
    String? employmentStatus,
    String? employerAddress,
    String? employerPhone,
    String? employerEmail,
    String? supervisorName,
    String? supervisorPhone,
    String? supervisorEmail,
    DateTime? employmentStartDate,
    DateTime? employmentEndDate,
    String? payFrequency,
    String? payMethod,
    String? bankAccountNumber,
    String? bankRoutingNumber,
    String? bankName,
    String? bankAddress,
    String? bankPhone,
    String? bankEmail,
    List<String>? incomeSources,
    List<String>? verifiedSources,
    Map<String, dynamic>? bankStatementData,
    Map<String, dynamic>? paystubData,
    Map<String, dynamic>? taxReturnData,
    Map<String, dynamic>? w2Data,
    Map<String, dynamic>? w4Data,
    Map<String, dynamic>? directDepositData,
    Map<String, dynamic>? payrollData,
    Map<String, dynamic>? benefitsData,
    Map<String, dynamic>? deductionsData,
    Map<String, dynamic>? overtimeData,
    Map<String, dynamic>? bonusData,
    Map<String, dynamic>? commissionData,
    Map<String, dynamic>? tipsData,
    Map<String, dynamic>? selfEmploymentData,
    Map<String, dynamic>? businessData,
    Map<String, dynamic>? investmentData,
    Map<String, dynamic>? rentalData,
    Map<String, dynamic>? retirementData,
    Map<String, dynamic>? disabilityData,
    Map<String, dynamic>? socialSecurityData,
    Map<String, dynamic>? unemploymentData,
    Map<String, dynamic>? otherIncomeData,
    Map<String, dynamic>? riskAssessment,
    Map<String, dynamic>? complianceChecks,
    String? verificationId,
    String? sessionId,
    String? referenceId,
    Map<String, dynamic>? auditTrail,
    DateTime? expiresAt,
    bool? isActive,
    String? rejectionReason,
    List<String>? requiredDocuments,
    List<String>? completedDocuments,
    Map<String, dynamic>? customFields,
    String? notes,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CUIncomeVerification(
      financialInstitutionId:
          financialInstitutionId ?? this.financialInstitutionId,
      memberId: memberId ?? this.memberId,
      providerName: providerName ?? this.providerName,
      verificationType: verificationType ?? this.verificationType,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationData: verificationData ?? this.verificationData,
      verificationDate: verificationDate ?? this.verificationDate,
      isVerified: isVerified ?? this.isVerified,
      verificationScore: verificationScore ?? this.verificationScore,
      verificationIssues: verificationIssues ?? this.verificationIssues,
      providerMetadata: providerMetadata ?? this.providerMetadata,
      reportedIncome: reportedIncome ?? this.reportedIncome,
      verifiedIncome: verifiedIncome ?? this.verifiedIncome,
      incomeType: incomeType ?? this.incomeType,
      employerName: employerName ?? this.employerName,
      jobTitle: jobTitle ?? this.jobTitle,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      employerAddress: employerAddress ?? this.employerAddress,
      employerPhone: employerPhone ?? this.employerPhone,
      employerEmail: employerEmail ?? this.employerEmail,
      supervisorName: supervisorName ?? this.supervisorName,
      supervisorPhone: supervisorPhone ?? this.supervisorPhone,
      supervisorEmail: supervisorEmail ?? this.supervisorEmail,
      employmentStartDate: employmentStartDate ?? this.employmentStartDate,
      employmentEndDate: employmentEndDate ?? this.employmentEndDate,
      payFrequency: payFrequency ?? this.payFrequency,
      payMethod: payMethod ?? this.payMethod,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankRoutingNumber: bankRoutingNumber ?? this.bankRoutingNumber,
      bankName: bankName ?? this.bankName,
      bankAddress: bankAddress ?? this.bankAddress,
      bankPhone: bankPhone ?? this.bankPhone,
      bankEmail: bankEmail ?? this.bankEmail,
      incomeSources: incomeSources ?? this.incomeSources,
      verifiedSources: verifiedSources ?? this.verifiedSources,
      bankStatementData: bankStatementData ?? this.bankStatementData,
      paystubData: paystubData ?? this.paystubData,
      taxReturnData: taxReturnData ?? this.taxReturnData,
      w2Data: w2Data ?? this.w2Data,
      w4Data: w4Data ?? this.w4Data,
      directDepositData: directDepositData ?? this.directDepositData,
      payrollData: payrollData ?? this.payrollData,
      benefitsData: benefitsData ?? this.benefitsData,
      deductionsData: deductionsData ?? this.deductionsData,
      overtimeData: overtimeData ?? this.overtimeData,
      bonusData: bonusData ?? this.bonusData,
      commissionData: commissionData ?? this.commissionData,
      tipsData: tipsData ?? this.tipsData,
      selfEmploymentData: selfEmploymentData ?? this.selfEmploymentData,
      businessData: businessData ?? this.businessData,
      investmentData: investmentData ?? this.investmentData,
      rentalData: rentalData ?? this.rentalData,
      retirementData: retirementData ?? this.retirementData,
      disabilityData: disabilityData ?? this.disabilityData,
      socialSecurityData: socialSecurityData ?? this.socialSecurityData,
      unemploymentData: unemploymentData ?? this.unemploymentData,
      otherIncomeData: otherIncomeData ?? this.otherIncomeData,
      riskAssessment: riskAssessment ?? this.riskAssessment,
      complianceChecks: complianceChecks ?? this.complianceChecks,
      verificationId: verificationId ?? this.verificationId,
      sessionId: sessionId ?? this.sessionId,
      referenceId: referenceId ?? this.referenceId,
      auditTrail: auditTrail ?? this.auditTrail,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      completedDocuments: completedDocuments ?? this.completedDocuments,
      customFields: customFields ?? this.customFields,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CUIncomeVerification(financialInstitutionId: $financialInstitutionId, memberId: $memberId, providerName: $providerName, verificationType: $verificationType, verificationStatus: $verificationStatus, isVerified: $isVerified, verificationScore: $verificationScore, reportedIncome: $reportedIncome, verifiedIncome: $verifiedIncome, incomeType: $incomeType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CUIncomeVerification &&
        other.financialInstitutionId == financialInstitutionId &&
        other.memberId == memberId &&
        other.providerName == providerName &&
        other.verificationType == verificationType &&
        other.verificationStatus == verificationStatus &&
        other.isVerified == isVerified &&
        other.verificationScore == verificationScore &&
        other.reportedIncome == reportedIncome &&
        other.verifiedIncome == verifiedIncome &&
        other.incomeType == incomeType;
  }

  @override
  int get hashCode {
    return Object.hash(
      financialInstitutionId,
      memberId,
      providerName,
      verificationType,
      verificationStatus,
      isVerified,
      verificationScore,
      reportedIncome,
      verifiedIncome,
      incomeType,
    );
  }
}
