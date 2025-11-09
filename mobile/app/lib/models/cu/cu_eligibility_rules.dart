class CUEligibilityRules {
  final String financialInstitutionId;
  final int minimumAge;
  final String residencyRequirement;
  final List<String> eligibleStates;
  final List<String> eligibleCounties;
  final List<String> eligibleEmployers;
  final List<String> eligibleOrganizations;
  final bool requiresEmployment;
  final bool requiresResidency;
  final Map<String, dynamic> additionalRequirements;
  final List<String> excludedStates;
  final List<String> excludedCounties;
  final List<String> excludedEmployers;
  final List<String> excludedOrganizations;
  final Map<String, dynamic> ageRequirements;
  final Map<String, dynamic> incomeRequirements;
  final Map<String, dynamic> creditRequirements;
  final List<String> requiredDocuments;
  final List<String> verificationMethods;
  final Map<String, dynamic> customRules;
  final DateTime effectiveDate;
  final DateTime? expirationDate;
  final bool isActive;
  final String ruleVersion;
  final Map<String, dynamic> metadata;

  const CUEligibilityRules({
    required this.financialInstitutionId,
    required this.minimumAge,
    required this.residencyRequirement,
    required this.eligibleStates,
    required this.eligibleCounties,
    required this.eligibleEmployers,
    required this.eligibleOrganizations,
    required this.requiresEmployment,
    required this.requiresResidency,
    required this.additionalRequirements,
    required this.excludedStates,
    required this.excludedCounties,
    required this.excludedEmployers,
    required this.excludedOrganizations,
    required this.ageRequirements,
    required this.incomeRequirements,
    required this.creditRequirements,
    required this.requiredDocuments,
    required this.verificationMethods,
    required this.customRules,
    required this.effectiveDate,
    this.expirationDate,
    required this.isActive,
    required this.ruleVersion,
    required this.metadata,
  });

  factory CUEligibilityRules.fromJson(Map<String, dynamic> json) {
    return CUEligibilityRules(
      financialInstitutionId: json['financialInstitutionId'] as String,
      minimumAge: json['minimumAge'] as int,
      residencyRequirement: json['residencyRequirement'] as String,
      eligibleStates: List<String>.from(json['eligibleStates'] as List),
      eligibleCounties: List<String>.from(json['eligibleCounties'] as List),
      eligibleEmployers: List<String>.from(json['eligibleEmployers'] as List),
      eligibleOrganizations: List<String>.from(
        json['eligibleOrganizations'] as List,
      ),
      requiresEmployment: json['requiresEmployment'] as bool,
      requiresResidency: json['requiresResidency'] as bool,
      additionalRequirements: Map<String, dynamic>.from(
        json['additionalRequirements'] as Map,
      ),
      excludedStates: List<String>.from(json['excludedStates'] as List),
      excludedCounties: List<String>.from(json['excludedCounties'] as List),
      excludedEmployers: List<String>.from(json['excludedEmployers'] as List),
      excludedOrganizations: List<String>.from(
        json['excludedOrganizations'] as List,
      ),
      ageRequirements: Map<String, dynamic>.from(
        json['ageRequirements'] as Map,
      ),
      incomeRequirements: Map<String, dynamic>.from(
        json['incomeRequirements'] as Map,
      ),
      creditRequirements: Map<String, dynamic>.from(
        json['creditRequirements'] as Map,
      ),
      requiredDocuments: List<String>.from(json['requiredDocuments'] as List),
      verificationMethods: List<String>.from(
        json['verificationMethods'] as List,
      ),
      customRules: Map<String, dynamic>.from(json['customRules'] as Map),
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'] as String)
          : null,
      isActive: json['isActive'] as bool,
      ruleVersion: json['ruleVersion'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financialInstitutionId': financialInstitutionId,
      'minimumAge': minimumAge,
      'residencyRequirement': residencyRequirement,
      'eligibleStates': eligibleStates,
      'eligibleCounties': eligibleCounties,
      'eligibleEmployers': eligibleEmployers,
      'eligibleOrganizations': eligibleOrganizations,
      'requiresEmployment': requiresEmployment,
      'requiresResidency': requiresResidency,
      'additionalRequirements': additionalRequirements,
      'excludedStates': excludedStates,
      'excludedCounties': excludedCounties,
      'excludedEmployers': excludedEmployers,
      'excludedOrganizations': excludedOrganizations,
      'ageRequirements': ageRequirements,
      'incomeRequirements': incomeRequirements,
      'creditRequirements': creditRequirements,
      'requiredDocuments': requiredDocuments,
      'verificationMethods': verificationMethods,
      'customRules': customRules,
      'effectiveDate': effectiveDate.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'isActive': isActive,
      'ruleVersion': ruleVersion,
      'metadata': metadata,
    };
  }

  CUEligibilityRules copyWith({
    String? financialInstitutionId,
    int? minimumAge,
    String? residencyRequirement,
    List<String>? eligibleStates,
    List<String>? eligibleCounties,
    List<String>? eligibleEmployers,
    List<String>? eligibleOrganizations,
    bool? requiresEmployment,
    bool? requiresResidency,
    Map<String, dynamic>? additionalRequirements,
    List<String>? excludedStates,
    List<String>? excludedCounties,
    List<String>? excludedEmployers,
    List<String>? excludedOrganizations,
    Map<String, dynamic>? ageRequirements,
    Map<String, dynamic>? incomeRequirements,
    Map<String, dynamic>? creditRequirements,
    List<String>? requiredDocuments,
    List<String>? verificationMethods,
    Map<String, dynamic>? customRules,
    DateTime? effectiveDate,
    DateTime? expirationDate,
    bool? isActive,
    String? ruleVersion,
    Map<String, dynamic>? metadata,
  }) {
    return CUEligibilityRules(
      financialInstitutionId:
          financialInstitutionId ?? this.financialInstitutionId,
      minimumAge: minimumAge ?? this.minimumAge,
      residencyRequirement: residencyRequirement ?? this.residencyRequirement,
      eligibleStates: eligibleStates ?? this.eligibleStates,
      eligibleCounties: eligibleCounties ?? this.eligibleCounties,
      eligibleEmployers: eligibleEmployers ?? this.eligibleEmployers,
      eligibleOrganizations:
          eligibleOrganizations ?? this.eligibleOrganizations,
      requiresEmployment: requiresEmployment ?? this.requiresEmployment,
      requiresResidency: requiresResidency ?? this.requiresResidency,
      additionalRequirements:
          additionalRequirements ?? this.additionalRequirements,
      excludedStates: excludedStates ?? this.excludedStates,
      excludedCounties: excludedCounties ?? this.excludedCounties,
      excludedEmployers: excludedEmployers ?? this.excludedEmployers,
      excludedOrganizations:
          excludedOrganizations ?? this.excludedOrganizations,
      ageRequirements: ageRequirements ?? this.ageRequirements,
      incomeRequirements: incomeRequirements ?? this.incomeRequirements,
      creditRequirements: creditRequirements ?? this.creditRequirements,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      verificationMethods: verificationMethods ?? this.verificationMethods,
      customRules: customRules ?? this.customRules,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      expirationDate: expirationDate ?? this.expirationDate,
      isActive: isActive ?? this.isActive,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired =>
      expirationDate != null && DateTime.now().isAfter(expirationDate!);
  bool get isEffective => DateTime.now().isAfter(effectiveDate);
  bool get isActiveAndEffective => isActive && !isExpired && isEffective;

  bool get hasStateRestrictions => eligibleStates.isNotEmpty;
  bool get hasCountyRestrictions => eligibleCounties.isNotEmpty;
  bool get hasEmployerRestrictions => eligibleEmployers.isNotEmpty;
  bool get hasOrganizationRestrictions => eligibleOrganizations.isNotEmpty;

  bool get hasExclusions =>
      excludedStates.isNotEmpty ||
      excludedCounties.isNotEmpty ||
      excludedEmployers.isNotEmpty ||
      excludedOrganizations.isNotEmpty;

  List<String> get allEligibleStates =>
      eligibleStates.where((state) => !excludedStates.contains(state)).toList();
  List<String> get allEligibleCounties => eligibleCounties
      .where((county) => !excludedCounties.contains(county))
      .toList();
  List<String> get allEligibleEmployers => eligibleEmployers
      .where((employer) => !excludedEmployers.contains(employer))
      .toList();
  List<String> get allEligibleOrganizations => eligibleOrganizations
      .where((org) => !excludedOrganizations.contains(org))
      .toList();

  String get residencyRequirementDisplayName {
    switch (residencyRequirement.toLowerCase()) {
      case 'state':
        return 'State Residency';
      case 'county':
        return 'County Residency';
      case 'city':
        return 'City Residency';
      case 'zip':
        return 'ZIP Code Residency';
      case 'none':
        return 'No Residency Requirement';
      default:
        return residencyRequirement;
    }
  }

  bool get isStrictEligibility =>
      requiresEmployment && requiresResidency && hasStateRestrictions;
  bool get isOpenEligibility =>
      !requiresEmployment && !requiresResidency && !hasStateRestrictions;

  Map<String, dynamic> get eligibilitySummary => {
        'minimumAge': minimumAge,
        'residencyRequirement': residencyRequirement,
        'requiresEmployment': requiresEmployment,
        'requiresResidency': requiresResidency,
        'eligibleStatesCount': eligibleStates.length,
        'eligibleCountiesCount': eligibleCounties.length,
        'eligibleEmployersCount': eligibleEmployers.length,
        'eligibleOrganizationsCount': eligibleOrganizations.length,
        'excludedStatesCount': excludedStates.length,
        'excludedCountiesCount': excludedCounties.length,
        'excludedEmployersCount': excludedEmployers.length,
        'excludedOrganizationsCount': excludedOrganizations.length,
        'requiredDocumentsCount': requiredDocuments.length,
        'verificationMethodsCount': verificationMethods.length,
        'isActive': isActive,
        'isEffective': isEffective,
        'isExpired': isExpired,
      };
}
