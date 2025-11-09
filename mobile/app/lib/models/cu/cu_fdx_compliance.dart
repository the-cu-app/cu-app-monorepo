class CUFDXCompliance {
  final String financialInstitutionId;
  final String fdxVersion;
  final List<String> complianceChecks;
  final Map<String, bool> complianceStatus;
  final List<String> complianceIssues;
  final DateTime lastComplianceCheck;
  final String complianceScore;
  final Map<String, dynamic> complianceData;
  final List<String> failedChecks;
  final List<String> passedChecks;
  final Map<String, dynamic> complianceMetrics;
  final String complianceLevel;
  final List<String> recommendations;
  final Map<String, dynamic> auditTrail;
  final bool isCompliant;
  final DateTime? nextComplianceCheck;
  final Map<String, dynamic> metadata;

  const CUFDXCompliance({
    required this.financialInstitutionId,
    required this.fdxVersion,
    required this.complianceChecks,
    required this.complianceStatus,
    required this.complianceIssues,
    required this.lastComplianceCheck,
    required this.complianceScore,
    required this.complianceData,
    required this.failedChecks,
    required this.passedChecks,
    required this.complianceMetrics,
    required this.complianceLevel,
    required this.recommendations,
    required this.auditTrail,
    required this.isCompliant,
    this.nextComplianceCheck,
    required this.metadata,
  });

  factory CUFDXCompliance.fromJson(Map<String, dynamic> json) {
    return CUFDXCompliance(
      financialInstitutionId: json['financialInstitutionId'] as String,
      fdxVersion: json['fdxVersion'] as String,
      complianceChecks: List<String>.from(json['complianceChecks'] as List),
      complianceStatus: Map<String, bool>.from(json['complianceStatus'] as Map),
      complianceIssues: List<String>.from(json['complianceIssues'] as List),
      lastComplianceCheck: DateTime.parse(
        json['lastComplianceCheck'] as String,
      ),
      complianceScore: json['complianceScore'] as String,
      complianceData: Map<String, dynamic>.from(json['complianceData'] as Map),
      failedChecks: List<String>.from(json['failedChecks'] as List),
      passedChecks: List<String>.from(json['passedChecks'] as List),
      complianceMetrics: Map<String, dynamic>.from(
        json['complianceMetrics'] as Map,
      ),
      complianceLevel: json['complianceLevel'] as String,
      recommendations: List<String>.from(json['recommendations'] as List),
      auditTrail: Map<String, dynamic>.from(json['auditTrail'] as Map),
      isCompliant: json['isCompliant'] as bool,
      nextComplianceCheck: json['nextComplianceCheck'] != null
          ? DateTime.parse(json['nextComplianceCheck'] as String)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financialInstitutionId': financialInstitutionId,
      'fdxVersion': fdxVersion,
      'complianceChecks': complianceChecks,
      'complianceStatus': complianceStatus,
      'complianceIssues': complianceIssues,
      'lastComplianceCheck': lastComplianceCheck.toIso8601String(),
      'complianceScore': complianceScore,
      'complianceData': complianceData,
      'failedChecks': failedChecks,
      'passedChecks': passedChecks,
      'complianceMetrics': complianceMetrics,
      'complianceLevel': complianceLevel,
      'recommendations': recommendations,
      'auditTrail': auditTrail,
      'isCompliant': isCompliant,
      'nextComplianceCheck': nextComplianceCheck?.toIso8601String(),
      'metadata': metadata,
    };
  }

  CUFDXCompliance copyWith({
    String? financialInstitutionId,
    String? fdxVersion,
    List<String>? complianceChecks,
    Map<String, bool>? complianceStatus,
    List<String>? complianceIssues,
    DateTime? lastComplianceCheck,
    String? complianceScore,
    Map<String, dynamic>? complianceData,
    List<String>? failedChecks,
    List<String>? passedChecks,
    Map<String, dynamic>? complianceMetrics,
    String? complianceLevel,
    List<String>? recommendations,
    Map<String, dynamic>? auditTrail,
    bool? isCompliant,
    DateTime? nextComplianceCheck,
    Map<String, dynamic>? metadata,
  }) {
    return CUFDXCompliance(
      financialInstitutionId:
          financialInstitutionId ?? this.financialInstitutionId,
      fdxVersion: fdxVersion ?? this.fdxVersion,
      complianceChecks: complianceChecks ?? this.complianceChecks,
      complianceStatus: complianceStatus ?? this.complianceStatus,
      complianceIssues: complianceIssues ?? this.complianceIssues,
      lastComplianceCheck: lastComplianceCheck ?? this.lastComplianceCheck,
      complianceScore: complianceScore ?? this.complianceScore,
      complianceData: complianceData ?? this.complianceData,
      failedChecks: failedChecks ?? this.failedChecks,
      passedChecks: passedChecks ?? this.passedChecks,
      complianceMetrics: complianceMetrics ?? this.complianceMetrics,
      complianceLevel: complianceLevel ?? this.complianceLevel,
      recommendations: recommendations ?? this.recommendations,
      auditTrail: auditTrail ?? this.auditTrail,
      isCompliant: isCompliant ?? this.isCompliant,
      nextComplianceCheck: nextComplianceCheck ?? this.nextComplianceCheck,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isFullyCompliant => isCompliant && complianceIssues.isEmpty;
  bool get hasComplianceIssues => complianceIssues.isNotEmpty;
  bool get isPartiallyCompliant => !isCompliant && passedChecks.isNotEmpty;
  bool get isNonCompliant => !isCompliant && passedChecks.isEmpty;

  double get complianceScoreValue {
    final score = complianceScore.replaceAll('%', '');
    return double.tryParse(score) ?? 0.0;
  }

  String get complianceLevelDisplayName {
    switch (complianceLevel.toLowerCase()) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      case 'critical':
        return 'Critical';
      default:
        return complianceLevel;
    }
  }

  String get fdxVersionDisplayName {
    switch (fdxVersion.toLowerCase()) {
      case 'v5':
        return 'FDX v5.0';
      case 'v4':
        return 'FDX v4.0';
      case 'v3':
        return 'FDX v3.0';
      default:
        return 'FDX $fdxVersion';
    }
  }

  Duration get timeSinceLastCheck =>
      DateTime.now().difference(lastComplianceCheck);

  bool get isCheckOverdue {
    if (nextComplianceCheck == null) return false;
    return DateTime.now().isAfter(nextComplianceCheck!);
  }

  String get timeSinceLastCheckDisplay {
    final duration = timeSinceLastCheck;
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'} ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'} ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  List<String> get criticalIssues => complianceIssues
      .where(
        (issue) =>
            issue.toLowerCase().contains('critical') ||
            issue.toLowerCase().contains('security') ||
            issue.toLowerCase().contains('authentication'),
      )
      .toList();

  List<String> get warningIssues => complianceIssues
      .where((issue) => !criticalIssues.contains(issue))
      .toList();

  Map<String, dynamic> get complianceSummary => {
        'isCompliant': isCompliant,
        'complianceScore': complianceScore,
        'complianceLevel': complianceLevel,
        'totalChecks': complianceChecks.length,
        'passedChecks': passedChecks.length,
        'failedChecks': failedChecks.length,
        'complianceIssues': complianceIssues.length,
        'criticalIssues': criticalIssues.length,
        'warningIssues': warningIssues.length,
        'lastCheck': lastComplianceCheck.toIso8601String(),
        'timeSinceLastCheck': timeSinceLastCheckDisplay,
        'isCheckOverdue': isCheckOverdue,
        'fdxVersion': fdxVersion,
      };
}
