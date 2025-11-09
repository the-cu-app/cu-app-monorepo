class CUDigitalEnrollment {
  final String financialInstitutionId;
  final String enrollmentUrl;
  final String enrollmentStatus;
  final DateTime startDate;
  final DateTime? completionDate;
  final Map<String, dynamic> enrollmentData;
  final List<String> requiredDocuments;
  final List<String> completedSteps;
  final String? enrollmentId;
  final String? memberId;
  final Map<String, dynamic> personalInfo;
  final Map<String, dynamic> identityVerification;
  final Map<String, dynamic> addressVerification;
  final List<String> selectedProducts;
  final Map<String, dynamic> accountSetup;
  final List<String> uploadedDocuments;
  final String? approvalStatus;
  final String? rejectionReason;
  final Map<String, dynamic> metadata;

  const CUDigitalEnrollment({
    required this.financialInstitutionId,
    required this.enrollmentUrl,
    required this.enrollmentStatus,
    required this.startDate,
    this.completionDate,
    required this.enrollmentData,
    required this.requiredDocuments,
    required this.completedSteps,
    this.enrollmentId,
    this.memberId,
    required this.personalInfo,
    required this.identityVerification,
    required this.addressVerification,
    required this.selectedProducts,
    required this.accountSetup,
    required this.uploadedDocuments,
    this.approvalStatus,
    this.rejectionReason,
    required this.metadata,
  });

  factory CUDigitalEnrollment.fromJson(Map<String, dynamic> json) {
    return CUDigitalEnrollment(
      financialInstitutionId: json['financialInstitutionId'] as String,
      enrollmentUrl: json['enrollmentUrl'] as String,
      enrollmentStatus: json['enrollmentStatus'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      completionDate: json['completionDate'] != null
          ? DateTime.parse(json['completionDate'] as String)
          : null,
      enrollmentData: Map<String, dynamic>.from(json['enrollmentData'] as Map),
      requiredDocuments: List<String>.from(json['requiredDocuments'] as List),
      completedSteps: List<String>.from(json['completedSteps'] as List),
      enrollmentId: json['enrollmentId'] as String?,
      memberId: json['memberId'] as String?,
      personalInfo: Map<String, dynamic>.from(json['personalInfo'] as Map),
      identityVerification: Map<String, dynamic>.from(
        json['identityVerification'] as Map,
      ),
      addressVerification: Map<String, dynamic>.from(
        json['addressVerification'] as Map,
      ),
      selectedProducts: List<String>.from(json['selectedProducts'] as List),
      accountSetup: Map<String, dynamic>.from(json['accountSetup'] as Map),
      uploadedDocuments: List<String>.from(json['uploadedDocuments'] as List),
      approvalStatus: json['approvalStatus'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financialInstitutionId': financialInstitutionId,
      'enrollmentUrl': enrollmentUrl,
      'enrollmentStatus': enrollmentStatus,
      'startDate': startDate.toIso8601String(),
      'completionDate': completionDate?.toIso8601String(),
      'enrollmentData': enrollmentData,
      'requiredDocuments': requiredDocuments,
      'completedSteps': completedSteps,
      'enrollmentId': enrollmentId,
      'memberId': memberId,
      'personalInfo': personalInfo,
      'identityVerification': identityVerification,
      'addressVerification': addressVerification,
      'selectedProducts': selectedProducts,
      'accountSetup': accountSetup,
      'uploadedDocuments': uploadedDocuments,
      'approvalStatus': approvalStatus,
      'rejectionReason': rejectionReason,
      'metadata': metadata,
    };
  }

  CUDigitalEnrollment copyWith({
    String? financialInstitutionId,
    String? enrollmentUrl,
    String? enrollmentStatus,
    DateTime? startDate,
    DateTime? completionDate,
    Map<String, dynamic>? enrollmentData,
    List<String>? requiredDocuments,
    List<String>? completedSteps,
    String? enrollmentId,
    String? memberId,
    Map<String, dynamic>? personalInfo,
    Map<String, dynamic>? identityVerification,
    Map<String, dynamic>? addressVerification,
    List<String>? selectedProducts,
    Map<String, dynamic>? accountSetup,
    List<String>? uploadedDocuments,
    String? approvalStatus,
    String? rejectionReason,
    Map<String, dynamic>? metadata,
  }) {
    return CUDigitalEnrollment(
      financialInstitutionId:
          financialInstitutionId ?? this.financialInstitutionId,
      enrollmentUrl: enrollmentUrl ?? this.enrollmentUrl,
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
      startDate: startDate ?? this.startDate,
      completionDate: completionDate ?? this.completionDate,
      enrollmentData: enrollmentData ?? this.enrollmentData,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      completedSteps: completedSteps ?? this.completedSteps,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      memberId: memberId ?? this.memberId,
      personalInfo: personalInfo ?? this.personalInfo,
      identityVerification: identityVerification ?? this.identityVerification,
      addressVerification: addressVerification ?? this.addressVerification,
      selectedProducts: selectedProducts ?? this.selectedProducts,
      accountSetup: accountSetup ?? this.accountSetup,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isCompleted => enrollmentStatus == 'completed';
  bool get isInProgress => enrollmentStatus == 'in_progress';
  bool get isPending => enrollmentStatus == 'pending';
  bool get isApproved => approvalStatus == 'approved';
  bool get isRejected => approvalStatus == 'rejected';
  bool get isPendingApproval => approvalStatus == 'pending';

  double get completionPercentage {
    if (requiredDocuments.isEmpty) return 0.0;
    return (completedSteps.length / requiredDocuments.length) * 100;
  }

  Duration get enrollmentDuration {
    final endDate = completionDate ?? DateTime.now();
    return endDate.difference(startDate);
  }

  String get enrollmentDurationDisplay {
    final duration = enrollmentDuration;
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    }
  }

  List<String> get remainingSteps {
    final allSteps = [
      'Personal Information',
      'Identity Verification',
      'Address Verification',
      'Product Selection',
      'Account Setup',
      'Document Upload',
      'Review & Submit',
      'Approval',
    ];
    return allSteps.where((step) => !completedSteps.contains(step)).toList();
  }

  bool get hasRequiredDocuments => requiredDocuments.isNotEmpty;
  bool get hasUploadedDocuments => uploadedDocuments.isNotEmpty;
  bool get isDocumentComplete =>
      uploadedDocuments.length >= requiredDocuments.length;

  String get statusDisplayName {
    switch (enrollmentStatus) {
      case 'started':
        return 'Started';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'failed':
        return 'Failed';
      default:
        return enrollmentStatus;
    }
  }

  String get approvalStatusDisplayName {
    switch (approvalStatus) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending Approval';
      case 'under_review':
        return 'Under Review';
      default:
        return approvalStatus ?? 'Not Submitted';
    }
  }
}
