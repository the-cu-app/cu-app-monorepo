class CUBiometricData {
  final String financialInstitutionId;
  final String memberId;
  final String biometricType;
  final String biometricHash;
  final DateTime enrollmentDate;
  final bool isActive;
  final String deviceId;
  final String deviceModel;
  final String deviceOS;
  final String biometricTemplate;
  final double confidenceThreshold;
  final int usageCount;
  final DateTime lastUsed;
  final DateTime? expirationDate;
  final Map<String, dynamic> metadata;

  const CUBiometricData({
    required this.financialInstitutionId,
    required this.memberId,
    required this.biometricType,
    required this.biometricHash,
    required this.enrollmentDate,
    required this.isActive,
    required this.deviceId,
    required this.deviceModel,
    required this.deviceOS,
    required this.biometricTemplate,
    required this.confidenceThreshold,
    required this.usageCount,
    required this.lastUsed,
    this.expirationDate,
    required this.metadata,
  });

  factory CUBiometricData.fromJson(Map<String, dynamic> json) {
    return CUBiometricData(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      biometricType: json['biometricType'] as String,
      biometricHash: json['biometricHash'] as String,
      enrollmentDate: DateTime.parse(json['enrollmentDate'] as String),
      isActive: json['isActive'] as bool,
      deviceId: json['deviceId'] as String,
      deviceModel: json['deviceModel'] as String,
      deviceOS: json['deviceOS'] as String,
      biometricTemplate: json['biometricTemplate'] as String,
      confidenceThreshold: (json['confidenceThreshold'] as num).toDouble(),
      usageCount: json['usageCount'] as int,
      lastUsed: DateTime.parse(json['lastUsed'] as String),
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'] as String)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financialInstitutionId': financialInstitutionId,
      'memberId': memberId,
      'biometricType': biometricType,
      'biometricHash': biometricHash,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'isActive': isActive,
      'deviceId': deviceId,
      'deviceModel': deviceModel,
      'deviceOS': deviceOS,
      'biometricTemplate': biometricTemplate,
      'confidenceThreshold': confidenceThreshold,
      'usageCount': usageCount,
      'lastUsed': lastUsed.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'metadata': metadata,
    };
  }

  CUBiometricData copyWith({
    String? financialInstitutionId,
    String? memberId,
    String? biometricType,
    String? biometricHash,
    DateTime? enrollmentDate,
    bool? isActive,
    String? deviceId,
    String? deviceModel,
    String? deviceOS,
    String? biometricTemplate,
    double? confidenceThreshold,
    int? usageCount,
    DateTime? lastUsed,
    DateTime? expirationDate,
    Map<String, dynamic>? metadata,
  }) {
    return CUBiometricData(
      financialInstitutionId:
          financialInstitutionId ?? this.financialInstitutionId,
      memberId: memberId ?? this.memberId,
      biometricType: biometricType ?? this.biometricType,
      biometricHash: biometricHash ?? this.biometricHash,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      isActive: isActive ?? this.isActive,
      deviceId: deviceId ?? this.deviceId,
      deviceModel: deviceModel ?? this.deviceModel,
      deviceOS: deviceOS ?? this.deviceOS,
      biometricTemplate: biometricTemplate ?? this.biometricTemplate,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
      expirationDate: expirationDate ?? this.expirationDate,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired =>
      expirationDate != null && DateTime.now().isAfter(expirationDate!);
  bool get isRecentlyUsed => DateTime.now().difference(lastUsed).inDays < 7;
  bool get isFrequentlyUsed => usageCount > 10;

  String get biometricTypeDisplayName {
    switch (biometricType.toLowerCase()) {
      case 'fingerprint':
        return 'Fingerprint';
      case 'face':
        return 'Face Recognition';
      case 'voice':
        return 'Voice Recognition';
      case 'iris':
        return 'Iris Scan';
      case 'palm':
        return 'Palm Print';
      default:
        return 'Biometric';
    }
  }

  String get deviceInfo => '$deviceModel ($deviceOS)';

  double get usageFrequency {
    final daysSinceEnrollment =
        DateTime.now().difference(enrollmentDate).inDays;
    if (daysSinceEnrollment == 0) return 0;
    return usageCount / daysSinceEnrollment;
  }

  bool get isSecure => confidenceThreshold >= 0.8 && isActive && !isExpired;
}
