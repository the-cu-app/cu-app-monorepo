class CUGeographicRules {
  final String financialInstitutionId;
  final List<String> eligibleStates;
  final List<String> eligibleCounties;
  final List<String> eligibleCities;
  final List<String> eligibleZipCodes;
  final double serviceRadius;
  final String serviceAreaType;
  final Map<String, dynamic> geographicBoundaries;
  final List<String> excludedStates;
  final List<String> excludedCounties;
  final List<String> excludedCities;
  final List<String> excludedZipCodes;
  final Map<String, dynamic> serviceAreaCenter;
  final List<Map<String, dynamic>> serviceAreaPolygons;
  final Map<String, dynamic> distanceRequirements;
  final List<String> specialServiceAreas;
  final Map<String, dynamic> branchLocations;
  final List<String> atmLocations;
  final Map<String, dynamic> mobileServiceAreas;
  final bool allowRemoteServices;
  final bool requirePhysicalPresence;
  final Map<String, dynamic> virtualServiceRules;
  final DateTime effectiveDate;
  final DateTime? expirationDate;
  final bool isActive;
  final String ruleVersion;
  final Map<String, dynamic> metadata;

  const CUGeographicRules({
    required this.financialInstitutionId,
    required this.eligibleStates,
    required this.eligibleCounties,
    required this.eligibleCities,
    required this.eligibleZipCodes,
    required this.serviceRadius,
    required this.serviceAreaType,
    required this.geographicBoundaries,
    required this.excludedStates,
    required this.excludedCounties,
    required this.excludedCities,
    required this.excludedZipCodes,
    required this.serviceAreaCenter,
    required this.serviceAreaPolygons,
    required this.distanceRequirements,
    required this.specialServiceAreas,
    required this.branchLocations,
    required this.atmLocations,
    required this.mobileServiceAreas,
    required this.allowRemoteServices,
    required this.requirePhysicalPresence,
    required this.virtualServiceRules,
    required this.effectiveDate,
    this.expirationDate,
    required this.isActive,
    required this.ruleVersion,
    required this.metadata,
  });

  factory CUGeographicRules.fromJson(Map<String, dynamic> json) {
    return CUGeographicRules(
      financialInstitutionId: json['financialInstitutionId'] as String,
      eligibleStates: List<String>.from(json['eligibleStates'] as List),
      eligibleCounties: List<String>.from(json['eligibleCounties'] as List),
      eligibleCities: List<String>.from(json['eligibleCities'] as List),
      eligibleZipCodes: List<String>.from(json['eligibleZipCodes'] as List),
      serviceRadius: (json['serviceRadius'] as num).toDouble(),
      serviceAreaType: json['serviceAreaType'] as String,
      geographicBoundaries: Map<String, dynamic>.from(
        json['geographicBoundaries'] as Map,
      ),
      excludedStates: List<String>.from(json['excludedStates'] as List),
      excludedCounties: List<String>.from(json['excludedCounties'] as List),
      excludedCities: List<String>.from(json['excludedCities'] as List),
      excludedZipCodes: List<String>.from(json['excludedZipCodes'] as List),
      serviceAreaCenter: Map<String, dynamic>.from(
        json['serviceAreaCenter'] as Map,
      ),
      serviceAreaPolygons: List<Map<String, dynamic>>.from(
        json['serviceAreaPolygons'] as List,
      ),
      distanceRequirements: Map<String, dynamic>.from(
        json['distanceRequirements'] as Map,
      ),
      specialServiceAreas: List<String>.from(
        json['specialServiceAreas'] as List,
      ),
      branchLocations: Map<String, dynamic>.from(
        json['branchLocations'] as Map,
      ),
      atmLocations: List<String>.from(json['atmLocations'] as List),
      mobileServiceAreas: Map<String, dynamic>.from(
        json['mobileServiceAreas'] as Map,
      ),
      allowRemoteServices: json['allowRemoteServices'] as bool,
      requirePhysicalPresence: json['requirePhysicalPresence'] as bool,
      virtualServiceRules: Map<String, dynamic>.from(
        json['virtualServiceRules'] as Map,
      ),
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
      'eligibleStates': eligibleStates,
      'eligibleCounties': eligibleCounties,
      'eligibleCities': eligibleCities,
      'eligibleZipCodes': eligibleZipCodes,
      'serviceRadius': serviceRadius,
      'serviceAreaType': serviceAreaType,
      'geographicBoundaries': geographicBoundaries,
      'excludedStates': excludedStates,
      'excludedCounties': excludedCounties,
      'excludedCities': excludedCities,
      'excludedZipCodes': excludedZipCodes,
      'serviceAreaCenter': serviceAreaCenter,
      'serviceAreaPolygons': serviceAreaPolygons,
      'distanceRequirements': distanceRequirements,
      'specialServiceAreas': specialServiceAreas,
      'branchLocations': branchLocations,
      'atmLocations': atmLocations,
      'mobileServiceAreas': mobileServiceAreas,
      'allowRemoteServices': allowRemoteServices,
      'requirePhysicalPresence': requirePhysicalPresence,
      'virtualServiceRules': virtualServiceRules,
      'effectiveDate': effectiveDate.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'isActive': isActive,
      'ruleVersion': ruleVersion,
      'metadata': metadata,
    };
  }

  CUGeographicRules copyWith({
    String? financialInstitutionId,
    List<String>? eligibleStates,
    List<String>? eligibleCounties,
    List<String>? eligibleCities,
    List<String>? eligibleZipCodes,
    double? serviceRadius,
    String? serviceAreaType,
    Map<String, dynamic>? geographicBoundaries,
    List<String>? excludedStates,
    List<String>? excludedCounties,
    List<String>? excludedCities,
    List<String>? excludedZipCodes,
    Map<String, dynamic>? serviceAreaCenter,
    List<Map<String, dynamic>>? serviceAreaPolygons,
    Map<String, dynamic>? distanceRequirements,
    List<String>? specialServiceAreas,
    Map<String, dynamic>? branchLocations,
    List<String>? atmLocations,
    Map<String, dynamic>? mobileServiceAreas,
    bool? allowRemoteServices,
    bool? requirePhysicalPresence,
    Map<String, dynamic>? virtualServiceRules,
    DateTime? effectiveDate,
    DateTime? expirationDate,
    bool? isActive,
    String? ruleVersion,
    Map<String, dynamic>? metadata,
  }) {
    return CUGeographicRules(
      financialInstitutionId:
          financialInstitutionId ?? this.financialInstitutionId,
      eligibleStates: eligibleStates ?? this.eligibleStates,
      eligibleCounties: eligibleCounties ?? this.eligibleCounties,
      eligibleCities: eligibleCities ?? this.eligibleCities,
      eligibleZipCodes: eligibleZipCodes ?? this.eligibleZipCodes,
      serviceRadius: serviceRadius ?? this.serviceRadius,
      serviceAreaType: serviceAreaType ?? this.serviceAreaType,
      geographicBoundaries: geographicBoundaries ?? this.geographicBoundaries,
      excludedStates: excludedStates ?? this.excludedStates,
      excludedCounties: excludedCounties ?? this.excludedCounties,
      excludedCities: excludedCities ?? this.excludedCities,
      excludedZipCodes: excludedZipCodes ?? this.excludedZipCodes,
      serviceAreaCenter: serviceAreaCenter ?? this.serviceAreaCenter,
      serviceAreaPolygons: serviceAreaPolygons ?? this.serviceAreaPolygons,
      distanceRequirements: distanceRequirements ?? this.distanceRequirements,
      specialServiceAreas: specialServiceAreas ?? this.specialServiceAreas,
      branchLocations: branchLocations ?? this.branchLocations,
      atmLocations: atmLocations ?? this.atmLocations,
      mobileServiceAreas: mobileServiceAreas ?? this.mobileServiceAreas,
      allowRemoteServices: allowRemoteServices ?? this.allowRemoteServices,
      requirePhysicalPresence:
          requirePhysicalPresence ?? this.requirePhysicalPresence,
      virtualServiceRules: virtualServiceRules ?? this.virtualServiceRules,
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
  bool get hasCityRestrictions => eligibleCities.isNotEmpty;
  bool get hasZipCodeRestrictions => eligibleZipCodes.isNotEmpty;
  bool get hasRadiusRestrictions => serviceRadius > 0;

  bool get hasExclusions =>
      excludedStates.isNotEmpty ||
      excludedCounties.isNotEmpty ||
      excludedCities.isNotEmpty ||
      excludedZipCodes.isNotEmpty;

  List<String> get allEligibleStates =>
      eligibleStates.where((state) => !excludedStates.contains(state)).toList();
  List<String> get allEligibleCounties => eligibleCounties
      .where((county) => !excludedCounties.contains(county))
      .toList();
  List<String> get allEligibleCities =>
      eligibleCities.where((city) => !excludedCities.contains(city)).toList();
  List<String> get allEligibleZipCodes =>
      eligibleZipCodes.where((zip) => !excludedZipCodes.contains(zip)).toList();

  String get serviceAreaTypeDisplayName {
    switch (serviceAreaType.toLowerCase()) {
      case 'state':
        return 'State-wide';
      case 'county':
        return 'County-wide';
      case 'city':
        return 'City-wide';
      case 'zip':
        return 'ZIP Code Area';
      case 'radius':
        return 'Radius-based';
      case 'polygon':
        return 'Custom Area';
      case 'national':
        return 'National';
      case 'international':
        return 'International';
      default:
        return serviceAreaType;
    }
  }

  bool get isStrictGeographic =>
      hasStateRestrictions && hasCountyRestrictions && hasCityRestrictions;
  bool get isOpenGeographic =>
      !hasStateRestrictions &&
      !hasCountyRestrictions &&
      !hasCityRestrictions &&
      !hasZipCodeRestrictions;

  Map<String, dynamic> get geographicSummary => {
        'serviceAreaType': serviceAreaType,
        'serviceRadius': serviceRadius,
        'eligibleStatesCount': eligibleStates.length,
        'eligibleCountiesCount': eligibleCounties.length,
        'eligibleCitiesCount': eligibleCities.length,
        'eligibleZipCodesCount': eligibleZipCodes.length,
        'excludedStatesCount': excludedStates.length,
        'excludedCountiesCount': excludedCounties.length,
        'excludedCitiesCount': excludedCities.length,
        'excludedZipCodesCount': excludedZipCodes.length,
        'specialServiceAreasCount': specialServiceAreas.length,
        'branchLocationsCount': branchLocations.length,
        'atmLocationsCount': atmLocations.length,
        'allowRemoteServices': allowRemoteServices,
        'requirePhysicalPresence': requirePhysicalPresence,
        'isActive': isActive,
        'isEffective': isEffective,
        'isExpired': isExpired,
      };
}
