import 'dart:math';

enum CardType { debit, credit }
enum CardStatus { active, locked, suspended, expired }
enum CardNetwork { visa, mastercard, amex, discover }

class BankCard {
  final String id;
  final String profileId;
  final String accountId;
  final CardType type;
  final CardStatus status;
  final CardNetwork network;
  final String cardNumber; // Stored as masked (e.g., "**** **** **** 1234")
  final String cardholderName;
  final String expirationDate; // MM/YY format
  final String cvv; // For virtual cards only
  final bool isVirtual;
  final bool isPrimary;
  
  // Card Controls
  final CardControls controls;
  
  // Limits
  final CardLimits limits;
  
  // Metadata
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final Map<String, dynamic>? metadata;

  BankCard({
    required this.id,
    required this.profileId,
    required this.accountId,
    required this.type,
    required this.status,
    required this.network,
    required this.cardNumber,
    required this.cardholderName,
    required this.expirationDate,
    this.cvv = '',
    required this.isVirtual,
    this.isPrimary = false,
    required this.controls,
    required this.limits,
    required this.createdAt,
    this.lastUsedAt,
    this.metadata,
  });

  // Get last 4 digits
  String get last4 => cardNumber.substring(cardNumber.length - 4);
  
  // Get formatted card number for display
  String get displayCardNumber => cardNumber;
  
  // Check if card is expired
  bool get isExpired {
    final parts = expirationDate.split('/');
    if (parts.length != 2) return false;
    
    final month = int.tryParse(parts[0]) ?? 0;
    final year = int.tryParse('20${parts[1]}') ?? 0;
    
    final now = DateTime.now();
    final expiry = DateTime(year, month + 1, 0); // Last day of expiry month
    
    return now.isAfter(expiry);
  }
  
  // Generate a masked card number from full number
  static String maskCardNumber(String fullNumber) {
    if (fullNumber.length < 12) return fullNumber;
    final last4 = fullNumber.substring(fullNumber.length - 4);
    return '**** **** **** $last4';
  }
  
  // Generate virtual card details
  static BankCard generateVirtualCard({
    required String profileId,
    required String accountId,
    required CardType type,
    required String cardholderName,
  }) {
    final random = Random();
    final virtualNumber = List.generate(16, (_) => random.nextInt(10)).join();
    final cvv = List.generate(3, (_) => random.nextInt(10)).join();
    final expMonth = random.nextInt(12) + 1;
    final expYear = DateTime.now().year + random.nextInt(5) + 1;
    
    return BankCard(
      id: 'vcard_${DateTime.now().millisecondsSinceEpoch}',
      profileId: profileId,
      accountId: accountId,
      type: type,
      status: CardStatus.active,
      network: CardNetwork.visa,
      cardNumber: maskCardNumber(virtualNumber),
      cardholderName: cardholderName,
      expirationDate: '${expMonth.toString().padLeft(2, '0')}/${expYear.toString().substring(2)}',
      cvv: cvv,
      isVirtual: true,
      controls: CardControls.defaultControls(),
      limits: CardLimits.defaultLimits(type),
      createdAt: DateTime.now(),
    );
  }

  // Copy with
  BankCard copyWith({
    CardStatus? status,
    CardControls? controls,
    CardLimits? limits,
    DateTime? lastUsedAt,
    Map<String, dynamic>? metadata,
  }) {
    return BankCard(
      id: id,
      profileId: profileId,
      accountId: accountId,
      type: type,
      status: status ?? this.status,
      network: network,
      cardNumber: cardNumber,
      cardholderName: cardholderName,
      expirationDate: expirationDate,
      cvv: cvv,
      isVirtual: isVirtual,
      isPrimary: isPrimary,
      controls: controls ?? this.controls,
      limits: limits ?? this.limits,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

class CardControls {
  final bool isLocked;
  final bool onlineTransactions;
  final bool internationalTransactions;
  final bool atmWithdrawals;
  final bool contactlessPayments;
  final bool recurringPayments;
  final List<String> blockedCategories;
  final List<String> blockedMerchants;
  final List<String> allowedCountries;
  final bool notificationsEnabled;

  CardControls({
    required this.isLocked,
    required this.onlineTransactions,
    required this.internationalTransactions,
    required this.atmWithdrawals,
    required this.contactlessPayments,
    required this.recurringPayments,
    required this.blockedCategories,
    required this.blockedMerchants,
    required this.allowedCountries,
    required this.notificationsEnabled,
  });

  factory CardControls.defaultControls() {
    return CardControls(
      isLocked: false,
      onlineTransactions: true,
      internationalTransactions: true,
      atmWithdrawals: true,
      contactlessPayments: true,
      recurringPayments: true,
      blockedCategories: [],
      blockedMerchants: [],
      allowedCountries: ['US'],
      notificationsEnabled: true,
    );
  }

  CardControls copyWith({
    bool? isLocked,
    bool? onlineTransactions,
    bool? internationalTransactions,
    bool? atmWithdrawals,
    bool? contactlessPayments,
    bool? recurringPayments,
    List<String>? blockedCategories,
    List<String>? blockedMerchants,
    List<String>? allowedCountries,
    bool? notificationsEnabled,
  }) {
    return CardControls(
      isLocked: isLocked ?? this.isLocked,
      onlineTransactions: onlineTransactions ?? this.onlineTransactions,
      internationalTransactions: internationalTransactions ?? this.internationalTransactions,
      atmWithdrawals: atmWithdrawals ?? this.atmWithdrawals,
      contactlessPayments: contactlessPayments ?? this.contactlessPayments,
      recurringPayments: recurringPayments ?? this.recurringPayments,
      blockedCategories: blockedCategories ?? this.blockedCategories,
      blockedMerchants: blockedMerchants ?? this.blockedMerchants,
      allowedCountries: allowedCountries ?? this.allowedCountries,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class CardLimits {
  final double dailySpendLimit;
  final double dailyATMLimit;
  final double singleTransactionLimit;
  final Map<String, double> categoryLimits;
  final int dailyTransactionCount;

  CardLimits({
    required this.dailySpendLimit,
    required this.dailyATMLimit,
    required this.singleTransactionLimit,
    required this.categoryLimits,
    required this.dailyTransactionCount,
  });

  factory CardLimits.defaultLimits(CardType type) {
    return CardLimits(
      dailySpendLimit: type == CardType.credit ? 5000.0 : 2000.0,
      dailyATMLimit: 500.0,
      singleTransactionLimit: type == CardType.credit ? 2000.0 : 1000.0,
      categoryLimits: {},
      dailyTransactionCount: 50,
    );
  }

  CardLimits copyWith({
    double? dailySpendLimit,
    double? dailyATMLimit,
    double? singleTransactionLimit,
    Map<String, double>? categoryLimits,
    int? dailyTransactionCount,
  }) {
    return CardLimits(
      dailySpendLimit: dailySpendLimit ?? this.dailySpendLimit,
      dailyATMLimit: dailyATMLimit ?? this.dailyATMLimit,
      singleTransactionLimit: singleTransactionLimit ?? this.singleTransactionLimit,
      categoryLimits: categoryLimits ?? this.categoryLimits,
      dailyTransactionCount: dailyTransactionCount ?? this.dailyTransactionCount,
    );
  }
}

// Transaction categories for spending limits
class SpendingCategory {
  static const String groceries = 'Groceries';
  static const String dining = 'Dining';
  static const String entertainment = 'Entertainment';
  static const String travel = 'Travel';
  static const String shopping = 'Shopping';
  static const String gas = 'Gas';
  static const String utilities = 'Utilities';
  static const String healthcare = 'Healthcare';
  static const String other = 'Other';
  
  static List<String> get all => [
    groceries,
    dining,
    entertainment,
    travel,
    shopping,
    gas,
    utilities,
    healthcare,
    other,
  ];
}