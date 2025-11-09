import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/cu_config_service.dart';

enum AccountType {
  checking,
  savings,
  moneyMarket,
  loan,
  mortgage,
  creditCard,
  certificate,
}

enum AccountStatus {
  active,
  pending,
  frozen,
  closed,
}

/// CU Account Model with variable branding
class CUAccount {
  final String id;
  final String accountNumber;
  final String productName;
  final AccountType type;
  final double balance;
  final double available;
  final AccountStatus status;
  final double? apr;
  final double? apy;
  final int? rewardsPoints;
  final DateTime openedDate;
  final Map<String, dynamic> metadata;

  CUAccount({
    required this.id,
    required this.accountNumber,
    required this.productName,
    required this.type,
    required this.balance,
    required this.available,
    required this.status,
    this.apr,
    this.apy,
    this.rewardsPoints,
    required this.openedDate,
    this.metadata = const {},
  });

  factory CUAccount.fromJson(Map<String, dynamic> json) {
    return CUAccount(
      id: json['id'],
      accountNumber: json['account_number'],
      productName: json['product_name'],
      type: AccountType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AccountType.checking,
      ),
      balance: (json['balance'] ?? 0).toDouble(),
      available: (json['available'] ?? 0).toDouble(),
      status: AccountStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AccountStatus.active,
      ),
      apr: json['apr']?.toDouble(),
      apy: json['apy']?.toDouble(),
      rewardsPoints: json['rewards_points'],
      openedDate: DateTime.parse(json['opened_date']),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_number': accountNumber,
      'product_name': productName,
      'type': type.name,
      'balance': balance,
      'available': available,
      'status': status.name,
      'apr': apr,
      'apy': apy,
      'rewards_points': rewardsPoints,
      'opened_date': openedDate.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// CU Product Model with variable branding
class CUProduct {
  final String id;
  final String name;
  final String description;
  final AccountType type;
  final double? minBalance;
  final double? apr;
  final double? apy;
  final List<String> features;
  final Map<String, dynamic> requirements;

  CUProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.minBalance,
    this.apr,
    this.apy,
    this.features = const [],
    this.requirements = const {},
  });
}

/// Enterprise-grade CU Core Banking Service
class CUCoreService {
  static final CUCoreService _instance = CUCoreService._internal();
  factory CUCoreService() => _instance;
  CUCoreService._internal();

  final _supabase = Supabase.instance.client;
  final _config = CUConfigService();
  final _accountsController = StreamController<List<CUAccount>>.broadcast();

  Stream<List<CUAccount>> get accountsStream => _accountsController.stream;

  /// Get CU products with variable branding
  List<CUProduct> getProducts() {
    final shortName = _config.cuShortName;

    return [
      CUProduct(
        id: 'premier-checking',
        name: '$shortName Premier Checking',
        description: 'Full-featured checking with rewards',
        type: AccountType.checking,
        minBalance: 1500,
        features: [
          'No monthly fees with \$1,500 balance',
          'Earn rewards on debit purchases',
          'Free checks and money orders',
          'ATM fee rebates nationwide',
        ],
        requirements: {
          'minimum_age': 18,
          'direct_deposit': false,
        },
      ),
      CUProduct(
        id: 'rewards-savings',
        name: '$shortName Rewards Savings',
        description: 'High-yield savings with tiered rates',
        type: AccountType.savings,
        apy: 4.50,
        minBalance: 25,
        features: [
          '4.50% APY on balances up to \$10,000',
          'No monthly fees',
          'Automatic transfers',
          'Mobile check deposit',
        ],
        requirements: {
          'minimum_age': 0,
          'checking_required': false,
        },
      ),
      CUProduct(
        id: 'money-market',
        name: '$shortName Money Market',
        description: 'Premium money market account',
        type: AccountType.moneyMarket,
        apy: 4.75,
        minBalance: 2500,
        features: [
          '4.75% APY on all balances',
          'Check writing privileges',
          'Debit card access',
          'Tiered interest rates',
        ],
        requirements: {
          'minimum_age': 18,
          'minimum_deposit': 2500,
        },
      ),
      CUProduct(
        id: 'visa-signature',
        name: '$shortName Visa Signature Card',
        description: 'Premium rewards credit card',
        type: AccountType.creditCard,
        apr: 12.99,
        features: [
          '2% cash back on all purchases',
          '5% on rotating categories',
          'No annual fee',
          'Travel insurance included',
          '0% intro APR for 12 months',
        ],
        requirements: {
          'credit_score': 700,
          'income': 50000,
        },
      ),
      CUProduct(
        id: 'auto-loan',
        name: '$shortName Auto Loan',
        description: 'Competitive auto financing',
        type: AccountType.loan,
        apr: 4.99,
        features: [
          'Rates as low as 4.99% APR',
          'Up to 84-month terms',
          'No prepayment penalties',
          'GAP insurance available',
        ],
        requirements: {
          'minimum_age': 18,
          'credit_score': 650,
        },
      ),
      CUProduct(
        id: 'mortgage',
        name: '$shortName Home Mortgage',
        description: 'Home financing solutions',
        type: AccountType.mortgage,
        apr: 6.75,
        features: [
          'Competitive fixed and adjustable rates',
          'Low down payment options',
          'First-time buyer programs',
          'No PMI with 20% down',
        ],
        requirements: {
          'minimum_age': 18,
          'credit_score': 620,
          'debt_to_income': 0.43,
        },
      ),
      CUProduct(
        id: 'certificate',
        name: '$shortName Term Certificate',
        description: 'Guaranteed returns with fixed terms',
        type: AccountType.certificate,
        apy: 5.00,
        minBalance: 1000,
        features: [
          'Terms from 3 months to 5 years',
          'Competitive fixed rates',
          'Automatic renewal options',
          'Add-on certificates available',
        ],
        requirements: {
          'minimum_deposit': 1000,
        },
      ),
    ];
  }

  /// Generate mock accounts with CU branding
  List<CUAccount> _generateMockAccounts() {
    final shortName = _config.cuShortName;
    final now = DateTime.now();

    return [
      CUAccount(
        id: '${_config.cuId}-001',
        accountNumber: '****4567',
        productName: '$shortName Premier Checking',
        type: AccountType.checking,
        balance: 12543.67,
        available: 12043.67,
        status: AccountStatus.active,
        openedDate: DateTime(2020, 3, 15),
        metadata: {
          'branch': 'Main Branch',
          'officer': 'Member Services',
        },
      ),
      CUAccount(
        id: '${_config.cuId}-002',
        accountNumber: '****8901',
        productName: '$shortName Rewards Savings',
        type: AccountType.savings,
        balance: 45678.90,
        available: 45678.90,
        status: AccountStatus.active,
        apy: 4.50,
        openedDate: DateTime(2020, 3, 15),
        metadata: {
          'goal': 'Emergency Fund',
          'auto_transfer': true,
        },
      ),
      CUAccount(
        id: '${_config.cuId}-003',
        accountNumber: '****2345',
        productName: '$shortName Visa Signature',
        type: AccountType.creditCard,
        balance: -2345.67,
        available: 17654.33,
        status: AccountStatus.active,
        apr: 12.99,
        rewardsPoints: 45678,
        openedDate: DateTime(2021, 6, 1),
        metadata: {
          'credit_limit': 20000,
          'payment_due': DateTime(now.year, now.month, 15).toIso8601String(),
        },
      ),
      CUAccount(
        id: '${_config.cuId}-004',
        accountNumber: '****6789',
        productName: '$shortName Auto Loan',
        type: AccountType.loan,
        balance: -18543.21,
        available: 0,
        status: AccountStatus.active,
        apr: 4.99,
        openedDate: DateTime(2023, 9, 10),
        metadata: {
          'original_amount': 35000,
          'term_months': 60,
          'vehicle': '2023 Honda CR-V',
        },
      ),
      CUAccount(
        id: '${_config.cuId}-005',
        accountNumber: '****3456',
        productName: '$shortName Term Certificate',
        type: AccountType.certificate,
        balance: 25000.00,
        available: 0,
        status: AccountStatus.active,
        apy: 5.00,
        openedDate: DateTime(2024, 1, 15),
        metadata: {
          'term_months': 12,
          'maturity_date': DateTime(2025, 1, 15).toIso8601String(),
          'auto_renew': true,
        },
      ),
    ];
  }

  /// Get CU accounts
  Future<List<CUAccount>> getAccounts() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final accounts = _generateMockAccounts();
      _accountsController.add(accounts);

      return accounts;
    } catch (e) {
      throw Exception('Failed to load accounts: $e');
    }
  }

  /// Get account details
  Future<Map<String, dynamic>> getAccountDetails(String accountId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final accounts = _generateMockAccounts();
      final account = accounts.firstWhere(
        (a) => a.id == accountId,
        orElse: () => throw Exception('Account not found'),
      );

      return {
        'account': account.toJson(),
        'recent_transactions': _getMockTransactions(accountId),
        'pending_transactions': _getMockPendingTransactions(accountId),
        'scheduled_transfers': [],
        'alerts': _getAccountAlerts(account),
      };
    } catch (e) {
      throw Exception('Failed to load account details: $e');
    }
  }

  List<Map<String, dynamic>> _getMockTransactions(String accountId) {
    return [
      {
        'id': 't1',
        'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'description': 'Grocery Store',
        'amount': -87.43,
        'category': 'Groceries',
      },
      {
        'id': 't2',
        'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'description': 'Direct Deposit - Employer',
        'amount': 2845.67,
        'category': 'Income',
      },
      {
        'id': 't3',
        'date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'description': 'Insurance Payment',
        'amount': -145.00,
        'category': 'Insurance',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockPendingTransactions(String accountId) {
    return [
      {
        'id': 'p1',
        'date': DateTime.now().toIso8601String(),
        'description': 'Pending - Amazon.com',
        'amount': -52.99,
        'category': 'Shopping',
      },
    ];
  }

  List<Map<String, dynamic>> _getAccountAlerts(CUAccount account) {
    List<Map<String, dynamic>> alerts = [];

    if (account.type == AccountType.creditCard && account.metadata['payment_due'] != null) {
      final dueDate = DateTime.parse(account.metadata['payment_due']);
      final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

      if (daysUntilDue <= 7) {
        alerts.add({
          'type': 'warning',
          'message': 'Payment due in $daysUntilDue days',
        });
      }
    }

    return alerts;
  }

  void dispose() {
    _accountsController.close();
  }
}
