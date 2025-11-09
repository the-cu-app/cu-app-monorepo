import 'package:flutter/material.dart';

/// Account categories for business rule classification
enum AccountCategory {
  depository,  // Checking, Savings, Money Market, CD
  credit,      // Credit Cards, Lines of Credit
  loan,        // Mortgages, Personal Loans, Student Loans
  investment,  // Brokerage, 401k, IRA
}

/// Specific account subtypes with detailed classifications
enum AccountSubtype {
  // Depository accounts
  checking,
  savings,
  moneyMarket,
  certificateOfDeposit,
  cashManagement,
  hsa,
  
  // Credit accounts
  creditCard,
  lineOfCredit,
  
  // Loan accounts
  mortgage,
  personalLoan,
  studentLoan,
  autoLoan,
  
  // Investment accounts
  brokerage,
  retirement401k,
  traditionalIra,
  rothIra,
}

/// Centralized configuration for account types
class AccountTypeConfig {
  final AccountCategory category;
  final AccountSubtype subtype;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final bool supportsNegativeBalance;
  final bool showInterestRate;
  final bool showRewardsPoints;
  final List<String> availableActions;
  final String displayName;
  final String shortName;

  const AccountTypeConfig({
    required this.category,
    required this.subtype,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.supportsNegativeBalance,
    required this.showInterestRate,
    required this.showRewardsPoints,
    required this.availableActions,
    required this.displayName,
    required this.shortName,
  });

  /// Get gradient colors for this account type
  List<Color> get gradientColors => [primaryColor, secondaryColor];

  /// Check if account can be source for transfers
  bool get canTransferFrom => category != AccountCategory.loan;

  /// Check if account can be destination for transfers
  bool get canTransferTo => 
    category == AccountCategory.depository || 
    category == AccountCategory.credit;

  /// Check if account shows available balance vs current balance
  bool get showAvailableBalance => 
    category == AccountCategory.depository || 
    category == AccountCategory.credit;
}

/// Static configuration mapping for all account types
class AccountTypeRegistry {
  static const Map<AccountSubtype, AccountTypeConfig> _configs = {
    // Depository Accounts
    AccountSubtype.checking: AccountTypeConfig(
      category: AccountCategory.depository,
      subtype: AccountSubtype.checking,
      icon: Icons.account_balance,
      primaryColor: Color(0xFF1976D2),
      secondaryColor: Color(0xFF0D47A1),
      supportsNegativeBalance: true, // Overdraft protection
      showInterestRate: false,
      showRewardsPoints: false,
      availableActions: ['transfer', 'deposit', 'pay_bill', 'view_transactions', 'deposit_check'],
      displayName: 'Checking Account',
      shortName: 'Checking',
    ),

    AccountSubtype.savings: AccountTypeConfig(
      category: AccountCategory.depository,
      subtype: AccountSubtype.savings,
      icon: Icons.savings,
      primaryColor: Color(0xFF388E3C),
      secondaryColor: Color(0xFF1B5E20),
      supportsNegativeBalance: false,
      showInterestRate: true,
      showRewardsPoints: false,
      availableActions: ['transfer', 'deposit', 'view_transactions'],
      displayName: 'Savings Account',
      shortName: 'Savings',
    ),

    AccountSubtype.moneyMarket: AccountTypeConfig(
      category: AccountCategory.depository,
      subtype: AccountSubtype.moneyMarket,
      icon: Icons.trending_up,
      primaryColor: Color(0xFF00796B),
      secondaryColor: Color(0xFF004D40),
      supportsNegativeBalance: false,
      showInterestRate: true,
      showRewardsPoints: false,
      availableActions: ['transfer', 'deposit', 'view_transactions'],
      displayName: 'Money Market Account',
      shortName: 'Money Market',
    ),

    AccountSubtype.certificateOfDeposit: AccountTypeConfig(
      category: AccountCategory.depository,
      subtype: AccountSubtype.certificateOfDeposit,
      icon: Icons.account_balance_wallet,
      primaryColor: Color(0xFF5D4037),
      secondaryColor: Color(0xFF3E2723),
      supportsNegativeBalance: false,
      showInterestRate: true,
      showRewardsPoints: false,
      availableActions: ['view_transactions', 'view_terms'],
      displayName: 'Certificate of Deposit',
      shortName: 'CD',
    ),

    // Credit Accounts
    AccountSubtype.creditCard: AccountTypeConfig(
      category: AccountCategory.credit,
      subtype: AccountSubtype.creditCard,
      icon: Icons.credit_card,
      primaryColor: Color(0xFF7B1FA2),
      secondaryColor: Color(0xFF4A148C),
      supportsNegativeBalance: true, // Credit limit
      showInterestRate: true,
      showRewardsPoints: true,
      availableActions: ['make_payment', 'view_transactions', 'view_rewards', 'view_statements'],
      displayName: 'Credit Card',
      shortName: 'Credit Card',
    ),

    AccountSubtype.lineOfCredit: AccountTypeConfig(
      category: AccountCategory.credit,
      subtype: AccountSubtype.lineOfCredit,
      icon: Icons.credit_score,
      primaryColor: Color(0xFF8E24AA),
      secondaryColor: Color(0xFF6A1B9A),
      supportsNegativeBalance: true,
      showInterestRate: true,
      showRewardsPoints: false,
      availableActions: ['draw_funds', 'make_payment', 'view_transactions'],
      displayName: 'Line of Credit',
      shortName: 'LOC',
    ),

    // Loan Accounts
    AccountSubtype.mortgage: AccountTypeConfig(
      category: AccountCategory.loan,
      subtype: AccountSubtype.mortgage,
      icon: Icons.home,
      primaryColor: Color(0xFFE65100),
      secondaryColor: Color(0xFFBF360C),
      supportsNegativeBalance: false,
      showInterestRate: true,
      showRewardsPoints: false,
      availableActions: ['make_payment', 'view_schedule', 'view_statements', 'view_escrow'],
      displayName: 'Mortgage',
      shortName: 'Mortgage',
    ),

    AccountSubtype.personalLoan: AccountTypeConfig(
      category: AccountCategory.loan,
      subtype: AccountSubtype.personalLoan,
      icon: Icons.account_balance_wallet,
      primaryColor: Color(0xFFF57C00),
      secondaryColor: Color(0xFFE65100),
      supportsNegativeBalance: false,
      showInterestRate: true,
      showRewardsPoints: false,
      availableActions: ['make_payment', 'view_schedule', 'view_statements'],
      displayName: 'Personal Loan',
      shortName: 'Personal Loan',
    ),

    AccountSubtype.autoLoan: AccountTypeConfig(
      category: AccountCategory.loan,
      subtype: AccountSubtype.autoLoan,
      icon: Icons.directions_car,
      primaryColor: Color(0xFFFF5722),
      secondaryColor: Color(0xFFD84315),
      supportsNegativeBalance: false,
      showInterestRate: true,
      showRewardsPoints: false,
      availableActions: ['make_payment', 'view_schedule', 'view_statements'],
      displayName: 'Auto Loan',
      shortName: 'Auto Loan',
    ),

    AccountSubtype.studentLoan: AccountTypeConfig(
      category: AccountCategory.loan,
      subtype: AccountSubtype.studentLoan,
      icon: Icons.school,
      primaryColor: Color(0xFF795548),
      secondaryColor: Color(0xFF5D4037),
      supportsNegativeBalance: false,
      showInterestRate: true,
      showRewardsPoints: false,
      availableActions: ['make_payment', 'view_schedule', 'view_statements', 'view_deferment'],
      displayName: 'Student Loan',
      shortName: 'Student Loan',
    ),

    // Investment Accounts
    AccountSubtype.brokerage: AccountTypeConfig(
      category: AccountCategory.investment,
      subtype: AccountSubtype.brokerage,
      icon: Icons.trending_up,
      primaryColor: Color(0xFF2E7D32),
      secondaryColor: Color(0xFF1B5E20),
      supportsNegativeBalance: false,
      showInterestRate: false,
      showRewardsPoints: false,
      availableActions: ['trade', 'transfer', 'view_portfolio', 'view_performance'],
      displayName: 'Brokerage Account',
      shortName: 'Brokerage',
    ),

    AccountSubtype.retirement401k: AccountTypeConfig(
      category: AccountCategory.investment,
      subtype: AccountSubtype.retirement401k,
      icon: Icons.savings,
      primaryColor: Color(0xFF558B2F),
      secondaryColor: Color(0xFF33691E),
      supportsNegativeBalance: false,
      showInterestRate: false,
      showRewardsPoints: false,
      availableActions: ['contribute', 'view_portfolio', 'view_performance', 'rebalance'],
      displayName: '401(k) Retirement',
      shortName: '401(k)',
    ),

    AccountSubtype.traditionalIra: AccountTypeConfig(
      category: AccountCategory.investment,
      subtype: AccountSubtype.traditionalIra,
      icon: Icons.account_balance,
      primaryColor: Color(0xFF689F38),
      secondaryColor: Color(0xFF558B2F),
      supportsNegativeBalance: false,
      showInterestRate: false,
      showRewardsPoints: false,
      availableActions: ['contribute', 'withdraw', 'view_portfolio', 'view_performance'],
      displayName: 'Traditional IRA',
      shortName: 'Traditional IRA',
    ),

    AccountSubtype.rothIra: AccountTypeConfig(
      category: AccountCategory.investment,
      subtype: AccountSubtype.rothIra,
      icon: Icons.security,
      primaryColor: Color(0xFF7CB342),
      secondaryColor: Color(0xFF689F38),
      supportsNegativeBalance: false,
      showInterestRate: false,
      showRewardsPoints: false,
      availableActions: ['contribute', 'withdraw_contributions', 'view_portfolio', 'view_performance'],
      displayName: 'Roth IRA',
      shortName: 'Roth IRA',
    ),
  };

  /// Get configuration for a specific account subtype
  static AccountTypeConfig? getConfig(AccountSubtype subtype) {
    return _configs[subtype];
  }

  /// Get configuration by parsing account data
  static AccountTypeConfig getConfigFromAccount(Map<String, dynamic> account) {
    final subtype = _parseAccountSubtype(account);
    return getConfig(subtype) ?? _getDefaultConfig();
  }

  /// Parse account subtype from account data
  static AccountSubtype _parseAccountSubtype(Map<String, dynamic> account) {
    final type = account['type']?.toString().toLowerCase() ?? '';
    final subtype = account['subtype']?.toString().toLowerCase() ?? '';
    final name = account['name']?.toString().toLowerCase() ?? '';

    // Handle Plaid API structure
    if (type == 'depository') {
      switch (subtype) {
        case 'checking': return AccountSubtype.checking;
        case 'savings': return AccountSubtype.savings;
        case 'money market': return AccountSubtype.moneyMarket;
        case 'cd': return AccountSubtype.certificateOfDeposit;
        case 'cash management': return AccountSubtype.cashManagement;
        case 'hsa': return AccountSubtype.hsa;
      }
    } else if (type == 'credit') {
      switch (subtype) {
        case 'credit card': return AccountSubtype.creditCard;
        case 'line of credit': return AccountSubtype.lineOfCredit;
      }
    } else if (type == 'loan') {
      if (name.contains('mortgage') || subtype.contains('mortgage')) {
        return AccountSubtype.mortgage;
      } else if (name.contains('auto') || subtype.contains('auto')) {
        return AccountSubtype.autoLoan;
      } else if (name.contains('student') || subtype.contains('student')) {
        return AccountSubtype.studentLoan;
      }
      return AccountSubtype.personalLoan;
    } else if (type == 'investment') {
      if (name.contains('401k') || name.contains('401(k)')) {
        return AccountSubtype.retirement401k;
      } else if (name.contains('ira') && name.contains('roth')) {
        return AccountSubtype.rothIra;
      } else if (name.contains('ira')) {
        return AccountSubtype.traditionalIra;
      }
      return AccountSubtype.brokerage;
    }

    // Handle legacy structure (type directly as subtype)
    switch (type) {
      case 'checking': return AccountSubtype.checking;
      case 'savings': return AccountSubtype.savings;
      case 'credit': return AccountSubtype.creditCard;
      case 'mortgage': return AccountSubtype.mortgage;
      case 'investment': return AccountSubtype.brokerage;
    }

    // Default fallback
    return AccountSubtype.checking;
  }

  /// Get default configuration for unknown account types
  static AccountTypeConfig _getDefaultConfig() {
    return const AccountTypeConfig(
      category: AccountCategory.depository,
      subtype: AccountSubtype.checking,
      icon: Icons.account_balance_wallet,
      primaryColor: Color(0xFF757575),
      secondaryColor: Color(0xFF424242),
      supportsNegativeBalance: false,
      showInterestRate: false,
      showRewardsPoints: false,
      availableActions: ['view_transactions'],
      displayName: 'Account',
      shortName: 'Account',
    );
  }

  /// Get all configurations for a specific category
  static List<AccountTypeConfig> getConfigsForCategory(AccountCategory category) {
    return _configs.values
        .where((config) => config.category == category)
        .toList();
  }

  /// Get all available account subtypes
  static List<AccountSubtype> getAllSubtypes() {
    return _configs.keys.toList();
  }
}