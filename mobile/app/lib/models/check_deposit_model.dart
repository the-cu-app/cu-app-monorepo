import 'dart:io';

enum CheckDepositStatus {
  draft,
  captureInProgress,
  reviewPending,
  processing,
  completed,
  failed,
  cancelled,
}

enum CheckSide {
  front,
  back,
}

class CheckDeposit {
  final String id;
  final String userId;
  final String profileId;
  final String accountId;
  final double amount;
  final String? checkNumber;
  final File? frontImage;
  final File? backImage;
  final String? frontImagePath;
  final String? backImagePath;
  final CheckDepositStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? referenceNumber;
  final String? failureReason;
  final Map<String, dynamic>? metadata;
  final bool endorsementVerified;

  CheckDeposit({
    required this.id,
    required this.userId,
    required this.profileId,
    required this.accountId,
    required this.amount,
    this.checkNumber,
    this.frontImage,
    this.backImage,
    this.frontImagePath,
    this.backImagePath,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.referenceNumber,
    this.failureReason,
    this.metadata,
    this.endorsementVerified = false,
  });

  factory CheckDeposit.fromJson(Map<String, dynamic> json) {
    return CheckDeposit(
      id: json['id'],
      userId: json['user_id'],
      profileId: json['profile_id'],
      accountId: json['account_id'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      checkNumber: json['check_number'],
      frontImagePath: json['front_image_path'],
      backImagePath: json['back_image_path'],
      status: CheckDepositStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CheckDepositStatus.draft,
      ),
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      referenceNumber: json['reference_number'],
      failureReason: json['failure_reason'],
      metadata: json['metadata'],
      endorsementVerified: json['endorsement_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'profile_id': profileId,
      'account_id': accountId,
      'amount': amount,
      'check_number': checkNumber,
      'front_image_path': frontImagePath,
      'back_image_path': backImagePath,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'reference_number': referenceNumber,
      'failure_reason': failureReason,
      'metadata': metadata,
      'endorsement_verified': endorsementVerified,
    };
  }

  CheckDeposit copyWith({
    String? id,
    String? userId,
    String? profileId,
    String? accountId,
    double? amount,
    String? checkNumber,
    File? frontImage,
    File? backImage,
    String? frontImagePath,
    String? backImagePath,
    CheckDepositStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? referenceNumber,
    String? failureReason,
    Map<String, dynamic>? metadata,
    bool? endorsementVerified,
  }) {
    return CheckDeposit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      profileId: profileId ?? this.profileId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      checkNumber: checkNumber ?? this.checkNumber,
      frontImage: frontImage ?? this.frontImage,
      backImage: backImage ?? this.backImage,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
      endorsementVerified: endorsementVerified ?? this.endorsementVerified,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case CheckDepositStatus.draft:
        return 'Draft';
      case CheckDepositStatus.captureInProgress:
        return 'Capturing Images';
      case CheckDepositStatus.reviewPending:
        return 'Review Pending';
      case CheckDepositStatus.processing:
        return 'Processing';
      case CheckDepositStatus.completed:
        return 'Completed';
      case CheckDepositStatus.failed:
        return 'Failed';
      case CheckDepositStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isEditable => 
      status == CheckDepositStatus.draft || 
      status == CheckDepositStatus.captureInProgress ||
      status == CheckDepositStatus.reviewPending;
}

class CheckDepositLimits {
  final double dailyLimit;
  final double transactionLimit;
  final double monthlyLimit;
  final int dailyCount;
  final int monthlyCount;
  final double usedDailyAmount;
  final double usedMonthlyAmount;
  final int usedDailyCount;
  final int usedMonthlyCount;

  CheckDepositLimits({
    required this.dailyLimit,
    required this.transactionLimit,
    required this.monthlyLimit,
    required this.dailyCount,
    required this.monthlyCount,
    required this.usedDailyAmount,
    required this.usedMonthlyAmount,
    required this.usedDailyCount,
    required this.usedMonthlyCount,
  });

  double get remainingDailyAmount => dailyLimit - usedDailyAmount;
  double get remainingMonthlyAmount => monthlyLimit - usedMonthlyAmount;
  int get remainingDailyCount => dailyCount - usedDailyCount;
  int get remainingMonthlyCount => monthlyCount - usedMonthlyCount;

  bool canDeposit(double amount) {
    return amount <= transactionLimit &&
        amount <= remainingDailyAmount &&
        amount <= remainingMonthlyAmount &&
        usedDailyCount < dailyCount &&
        usedMonthlyCount < monthlyCount;
  }

  String? getDepositError(double amount) {
    if (amount > transactionLimit) {
      return 'Amount exceeds transaction limit of \$${transactionLimit.toStringAsFixed(2)}';
    }
    if (amount > remainingDailyAmount) {
      return 'Amount exceeds daily limit. Remaining: \$${remainingDailyAmount.toStringAsFixed(2)}';
    }
    if (amount > remainingMonthlyAmount) {
      return 'Amount exceeds monthly limit. Remaining: \$${remainingMonthlyAmount.toStringAsFixed(2)}';
    }
    if (usedDailyCount >= dailyCount) {
      return 'Daily deposit count limit reached ($dailyCount deposits)';
    }
    if (usedMonthlyCount >= monthlyCount) {
      return 'Monthly deposit count limit reached ($monthlyCount deposits)';
    }
    return null;
  }
}