enum ProfileType {
  personal('Personal', 'Individual member account'),
  business('Business', 'Business member account'),
  youth('Youth', 'Youth savings account (Under 18)'),
  fiduciary('Fiduciary', 'Trust or estate account');

  final String displayName;
  final String description;
  
  const ProfileType(this.displayName, this.description);
}

class UserProfile {
  final String id;
  final String userId;
  final ProfileType type;
  final String displayName;
  final String? businessName;
  final String? ein; // For business accounts
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final bool isActive;
  final bool isPrimary;
  final Map<String, dynamic>? metadata;
  
  // Permissions and limits based on profile type
  final ProfilePermissions permissions;
  final ProfileLimits limits;

  UserProfile({
    required this.id,
    required this.userId,
    required this.type,
    required this.displayName,
    this.businessName,
    this.ein,
    required this.createdAt,
    this.lastUsedAt,
    this.isActive = true,
    this.isPrimary = false,
    this.metadata,
    required this.permissions,
    required this.limits,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userId: json['user_id'],
      type: ProfileType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ProfileType.personal,
      ),
      displayName: json['display_name'],
      businessName: json['business_name'],
      ein: json['ein'],
      createdAt: DateTime.parse(json['created_at']),
      lastUsedAt: json['last_used_at'] != null 
          ? DateTime.parse(json['last_used_at']) 
          : null,
      isActive: json['is_active'] ?? true,
      isPrimary: json['is_primary'] ?? false,
      metadata: json['metadata'],
      permissions: ProfilePermissions.fromJson(json['permissions'] ?? {}),
      limits: ProfileLimits.fromJson(json['limits'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'display_name': displayName,
      'business_name': businessName,
      'ein': ein,
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'is_active': isActive,
      'is_primary': isPrimary,
      'metadata': metadata,
      'permissions': permissions.toJson(),
      'limits': limits.toJson(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? userId,
    ProfileType? type,
    String? displayName,
    String? businessName,
    String? ein,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? isActive,
    bool? isPrimary,
    Map<String, dynamic>? metadata,
    ProfilePermissions? permissions,
    ProfileLimits? limits,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      businessName: businessName ?? this.businessName,
      ein: ein ?? this.ein,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isActive: isActive ?? this.isActive,
      isPrimary: isPrimary ?? this.isPrimary,
      metadata: metadata ?? this.metadata,
      permissions: permissions ?? this.permissions,
      limits: limits ?? this.limits,
    );
  }
}

class ProfilePermissions {
  final bool canTransfer;
  final bool canDeposit;
  final bool canWithdraw;
  final bool canPayBills;
  final bool canManageCards;
  final bool canViewStatements;
  final bool canManageUsers; // For business accounts
  final bool requiresParentalApproval; // For youth accounts
  final bool canTrade; // For investment features
  final bool canApplyForLoans;
  final bool canSetupAutoPay;
  
  ProfilePermissions({
    required this.canTransfer,
    required this.canDeposit,
    required this.canWithdraw,
    required this.canPayBills,
    required this.canManageCards,
    required this.canViewStatements,
    this.canManageUsers = false,
    this.requiresParentalApproval = false,
    this.canTrade = false,
    required this.canApplyForLoans,
    required this.canSetupAutoPay,
  });

  factory ProfilePermissions.forProfileType(ProfileType type) {
    switch (type) {
      case ProfileType.personal:
        return ProfilePermissions(
          canTransfer: true,
          canDeposit: true,
          canWithdraw: true,
          canPayBills: true,
          canManageCards: true,
          canViewStatements: true,
          canApplyForLoans: true,
          canSetupAutoPay: true,
          canTrade: true,
        );
      case ProfileType.business:
        return ProfilePermissions(
          canTransfer: true,
          canDeposit: true,
          canWithdraw: true,
          canPayBills: true,
          canManageCards: true,
          canViewStatements: true,
          canManageUsers: true,
          canApplyForLoans: true,
          canSetupAutoPay: true,
          canTrade: true,
        );
      case ProfileType.youth:
        return ProfilePermissions(
          canTransfer: false,
          canDeposit: true,
          canWithdraw: false,
          canPayBills: false,
          canManageCards: false,
          canViewStatements: true,
          requiresParentalApproval: true,
          canApplyForLoans: false,
          canSetupAutoPay: false,
        );
      case ProfileType.fiduciary:
        return ProfilePermissions(
          canTransfer: true,
          canDeposit: true,
          canWithdraw: true,
          canPayBills: true,
          canManageCards: false,
          canViewStatements: true,
          canApplyForLoans: false,
          canSetupAutoPay: true,
          canTrade: true,
        );
    }
  }

  factory ProfilePermissions.fromJson(Map<String, dynamic> json) {
    return ProfilePermissions(
      canTransfer: json['can_transfer'] ?? true,
      canDeposit: json['can_deposit'] ?? true,
      canWithdraw: json['can_withdraw'] ?? true,
      canPayBills: json['can_pay_bills'] ?? true,
      canManageCards: json['can_manage_cards'] ?? true,
      canViewStatements: json['can_view_statements'] ?? true,
      canManageUsers: json['can_manage_users'] ?? false,
      requiresParentalApproval: json['requires_parental_approval'] ?? false,
      canTrade: json['can_trade'] ?? false,
      canApplyForLoans: json['can_apply_for_loans'] ?? true,
      canSetupAutoPay: json['can_setup_autopay'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'can_transfer': canTransfer,
      'can_deposit': canDeposit,
      'can_withdraw': canWithdraw,
      'can_pay_bills': canPayBills,
      'can_manage_cards': canManageCards,
      'can_view_statements': canViewStatements,
      'can_manage_users': canManageUsers,
      'requires_parental_approval': requiresParentalApproval,
      'can_trade': canTrade,
      'can_apply_for_loans': canApplyForLoans,
      'can_setup_autopay': canSetupAutoPay,
    };
  }
}

class ProfileLimits {
  final double dailyTransferLimit;
  final double monthlyTransferLimit;
  final double dailyWithdrawalLimit;
  final double mobileDepositLimit;
  final int maxAccountsAllowed;
  final int maxCardsAllowed;
  
  ProfileLimits({
    required this.dailyTransferLimit,
    required this.monthlyTransferLimit,
    required this.dailyWithdrawalLimit,
    required this.mobileDepositLimit,
    required this.maxAccountsAllowed,
    required this.maxCardsAllowed,
  });

  factory ProfileLimits.forProfileType(ProfileType type) {
    switch (type) {
      case ProfileType.personal:
        return ProfileLimits(
          dailyTransferLimit: 10000,
          monthlyTransferLimit: 50000,
          dailyWithdrawalLimit: 1000,
          mobileDepositLimit: 5000,
          maxAccountsAllowed: 10,
          maxCardsAllowed: 5,
        );
      case ProfileType.business:
        return ProfileLimits(
          dailyTransferLimit: 50000,
          monthlyTransferLimit: 500000,
          dailyWithdrawalLimit: 5000,
          mobileDepositLimit: 25000,
          maxAccountsAllowed: 20,
          maxCardsAllowed: 20,
        );
      case ProfileType.youth:
        return ProfileLimits(
          dailyTransferLimit: 0,
          monthlyTransferLimit: 0,
          dailyWithdrawalLimit: 0,
          mobileDepositLimit: 100,
          maxAccountsAllowed: 2,
          maxCardsAllowed: 0,
        );
      case ProfileType.fiduciary:
        return ProfileLimits(
          dailyTransferLimit: 100000,
          monthlyTransferLimit: 1000000,
          dailyWithdrawalLimit: 10000,
          mobileDepositLimit: 50000,
          maxAccountsAllowed: 5,
          maxCardsAllowed: 2,
        );
    }
  }

  factory ProfileLimits.fromJson(Map<String, dynamic> json) {
    return ProfileLimits(
      dailyTransferLimit: (json['daily_transfer_limit'] ?? 10000).toDouble(),
      monthlyTransferLimit: (json['monthly_transfer_limit'] ?? 50000).toDouble(),
      dailyWithdrawalLimit: (json['daily_withdrawal_limit'] ?? 1000).toDouble(),
      mobileDepositLimit: (json['mobile_deposit_limit'] ?? 5000).toDouble(),
      maxAccountsAllowed: json['max_accounts_allowed'] ?? 10,
      maxCardsAllowed: json['max_cards_allowed'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_transfer_limit': dailyTransferLimit,
      'monthly_transfer_limit': monthlyTransferLimit,
      'daily_withdrawal_limit': dailyWithdrawalLimit,
      'mobile_deposit_limit': mobileDepositLimit,
      'max_accounts_allowed': maxAccountsAllowed,
      'max_cards_allowed': maxCardsAllowed,
    };
  }
}