class CUProduct {
  final String financialInstitutionId;
  final String productId;
  final String productName;
  final String productType;
  final String productDescription;
  final double interestRate;
  final double minimumBalance;
  final double minimumDeposit;
  final double maximumBalance;
  final double maximumDeposit;
  final List<String> features;
  final List<String> requirements;
  final List<String> benefits;
  final List<String> restrictions;
  final bool isActive;
  final bool isFeatured;
  final bool requiresApproval;
  final String productCategory;
  final String productSubcategory;
  final DateTime lastUpdated;
  final DateTime? effectiveDate;
  final DateTime? expirationDate;
  final Map<String, dynamic> productTerms;
  final Map<String, dynamic> fees;
  final Map<String, dynamic> rates;
  final List<String> eligibilityCriteria;
  final List<String> requiredDocuments;
  final String productStatus;
  final int sortOrder;
  final Map<String, dynamic> metadata;

  const CUProduct({
    required this.financialInstitutionId,
    required this.productId,
    required this.productName,
    required this.productType,
    required this.productDescription,
    required this.interestRate,
    required this.minimumBalance,
    required this.minimumDeposit,
    required this.maximumBalance,
    required this.maximumDeposit,
    required this.features,
    required this.requirements,
    required this.benefits,
    required this.restrictions,
    required this.isActive,
    required this.isFeatured,
    required this.requiresApproval,
    required this.productCategory,
    required this.productSubcategory,
    required this.lastUpdated,
    this.effectiveDate,
    this.expirationDate,
    required this.productTerms,
    required this.fees,
    required this.rates,
    required this.eligibilityCriteria,
    required this.requiredDocuments,
    required this.productStatus,
    required this.sortOrder,
    required this.metadata,
  });

  factory CUProduct.fromJson(Map<String, dynamic> json) {
    return CUProduct(
      financialInstitutionId: json['financialInstitutionId'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productType: json['productType'] as String,
      productDescription: json['productDescription'] as String,
      interestRate: (json['interestRate'] as num).toDouble(),
      minimumBalance: (json['minimumBalance'] as num).toDouble(),
      minimumDeposit: (json['minimumDeposit'] as num).toDouble(),
      maximumBalance: (json['maximumBalance'] as num).toDouble(),
      maximumDeposit: (json['maximumDeposit'] as num).toDouble(),
      features: List<String>.from(json['features'] as List),
      requirements: List<String>.from(json['requirements'] as List),
      benefits: List<String>.from(json['benefits'] as List),
      restrictions: List<String>.from(json['restrictions'] as List),
      isActive: json['isActive'] as bool,
      isFeatured: json['isFeatured'] as bool,
      requiresApproval: json['requiresApproval'] as bool,
      productCategory: json['productCategory'] as String,
      productSubcategory: json['productSubcategory'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      effectiveDate: json['effectiveDate'] != null
          ? DateTime.parse(json['effectiveDate'] as String)
          : null,
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'] as String)
          : null,
      productTerms: Map<String, dynamic>.from(json['productTerms'] as Map),
      fees: Map<String, dynamic>.from(json['fees'] as Map),
      rates: Map<String, dynamic>.from(json['rates'] as Map),
      eligibilityCriteria: List<String>.from(
        json['eligibilityCriteria'] as List,
      ),
      requiredDocuments: List<String>.from(json['requiredDocuments'] as List),
      productStatus: json['productStatus'] as String,
      sortOrder: json['sortOrder'] as int,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financialInstitutionId': financialInstitutionId,
      'productId': productId,
      'productName': productName,
      'productType': productType,
      'productDescription': productDescription,
      'interestRate': interestRate,
      'minimumBalance': minimumBalance,
      'minimumDeposit': minimumDeposit,
      'maximumBalance': maximumBalance,
      'maximumDeposit': maximumDeposit,
      'features': features,
      'requirements': requirements,
      'benefits': benefits,
      'restrictions': restrictions,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'requiresApproval': requiresApproval,
      'productCategory': productCategory,
      'productSubcategory': productSubcategory,
      'lastUpdated': lastUpdated.toIso8601String(),
      'effectiveDate': effectiveDate?.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'productTerms': productTerms,
      'fees': fees,
      'rates': rates,
      'eligibilityCriteria': eligibilityCriteria,
      'requiredDocuments': requiredDocuments,
      'productStatus': productStatus,
      'sortOrder': sortOrder,
      'metadata': metadata,
    };
  }

  CUProduct copyWith({
    String? financialInstitutionId,
    String? productId,
    String? productName,
    String? productType,
    String? productDescription,
    double? interestRate,
    double? minimumBalance,
    double? minimumDeposit,
    double? maximumBalance,
    double? maximumDeposit,
    List<String>? features,
    List<String>? requirements,
    List<String>? benefits,
    List<String>? restrictions,
    bool? isActive,
    bool? isFeatured,
    bool? requiresApproval,
    String? productCategory,
    String? productSubcategory,
    DateTime? lastUpdated,
    DateTime? effectiveDate,
    DateTime? expirationDate,
    Map<String, dynamic>? productTerms,
    Map<String, dynamic>? fees,
    Map<String, dynamic>? rates,
    List<String>? eligibilityCriteria,
    List<String>? requiredDocuments,
    String? productStatus,
    int? sortOrder,
    Map<String, dynamic>? metadata,
  }) {
    return CUProduct(
      financialInstitutionId:
          financialInstitutionId ?? this.financialInstitutionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productType: productType ?? this.productType,
      productDescription: productDescription ?? this.productDescription,
      interestRate: interestRate ?? this.interestRate,
      minimumBalance: minimumBalance ?? this.minimumBalance,
      minimumDeposit: minimumDeposit ?? this.minimumDeposit,
      maximumBalance: maximumBalance ?? this.maximumBalance,
      maximumDeposit: maximumDeposit ?? this.maximumDeposit,
      features: features ?? this.features,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      restrictions: restrictions ?? this.restrictions,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      productCategory: productCategory ?? this.productCategory,
      productSubcategory: productSubcategory ?? this.productSubcategory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      expirationDate: expirationDate ?? this.expirationDate,
      productTerms: productTerms ?? this.productTerms,
      fees: fees ?? this.fees,
      rates: rates ?? this.rates,
      eligibilityCriteria: eligibilityCriteria ?? this.eligibilityCriteria,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      productStatus: productStatus ?? this.productStatus,
      sortOrder: sortOrder ?? this.sortOrder,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired =>
      expirationDate != null && DateTime.now().isAfter(expirationDate!);
  bool get isEffective =>
      effectiveDate == null || DateTime.now().isAfter(effectiveDate!);
  bool get isAvailable => isActive && !isExpired && isEffective;

  String get formattedInterestRate => '${interestRate.toStringAsFixed(2)}%';
  String get formattedMinimumBalance =>
      '\$${minimumBalance.toStringAsFixed(2)}';
  String get formattedMinimumDeposit =>
      '\$${minimumDeposit.toStringAsFixed(2)}';
  String get formattedMaximumBalance =>
      '\$${maximumBalance.toStringAsFixed(2)}';
  String get formattedMaximumDeposit =>
      '\$${maximumDeposit.toStringAsFixed(2)}';

  String get productTypeDisplayName {
    switch (productType.toLowerCase()) {
      case 'checking':
        return 'Checking Account';
      case 'savings':
        return 'Savings Account';
      case 'cd':
        return 'Certificate of Deposit';
      case 'loan':
        return 'Loan';
      case 'credit_card':
        return 'Credit Card';
      case 'mortgage':
        return 'Mortgage';
      case 'ira':
        return 'IRA';
      case 'money_market':
        return 'Money Market';
      default:
        return productType;
    }
  }

  String get productCategoryDisplayName {
    switch (productCategory.toLowerCase()) {
      case 'deposit':
        return 'Deposit Accounts';
      case 'loan':
        return 'Loans';
      case 'credit':
        return 'Credit Products';
      case 'investment':
        return 'Investment Products';
      case 'insurance':
        return 'Insurance Products';
      default:
        return productCategory;
    }
  }

  bool get hasHighInterestRate => interestRate > 2.0;
  bool get hasLowMinimumBalance => minimumBalance <= 100.0;
  bool get hasNoMinimumBalance => minimumBalance == 0.0;
  bool get hasNoFees => fees.isEmpty || fees.values.every((fee) => fee == 0);

  List<String> get keyFeatures => features.take(3).toList();
  List<String> get keyBenefits => benefits.take(3).toList();

  double get popularityScore {
    double score = 0;
    if (isFeatured) score += 2;
    if (hasHighInterestRate) score += 1;
    if (hasLowMinimumBalance) score += 1;
    if (hasNoFees) score += 1;
    if (features.length > 5) score += 1;
    return score;
  }
}
