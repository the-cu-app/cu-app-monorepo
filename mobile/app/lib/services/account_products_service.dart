import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/plaid_service.dart';
import '../services/auth_service.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountProductsService {
  static final AccountProductsService _instance = AccountProductsService._internal();
  factory AccountProductsService() => _instance;
  AccountProductsService._internal();

  final PlaidService _plaidService = PlaidService();
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get available account products from Plaid and internal catalog
  Future<List<AccountProduct>> getAvailableProducts() async {
    try {
      // Get Plaid institution products
      final plaidProducts = await _getPlaidProducts();
      
      // Get internal banking products
      final internalProducts = await _getInternalProducts();
      
      // Get investment products
      final investmentProducts = await _getInvestmentProducts();
      
      // Combine all products
      final allProducts = [
        ...plaidProducts,
        ...internalProducts,
        ...investmentProducts,
      ];
      
      return allProducts;
    } catch (e) {
      debugPrint('Error getting available products: $e');
      return _getFallbackProducts();
    }
  }

  /// Get products from Plaid institutions
  Future<List<AccountProduct>> _getPlaidProducts() async {
    try {
      // Search for major institutions
      final majorBanks = [
        'Chase',
        'Bank of America',
        'Wells Fargo',
        'Citibank',
        'Capital One',
        'American Express',
        'Discover',
        'US Bank',
      ];

      final List<AccountProduct> products = [];

      for (String bank in majorBanks) {
        try {
          final institutionData = await _plaidService.searchInstitutions(
            query: bank,
            products: ['auth', 'transactions', 'identity'],
            countryCodes: ['US'],
          );

          final institutions = institutionData['institutions'] as List?;
          if (institutions != null && institutions.isNotEmpty) {
            final institution = institutions.first;
            
            // Add checking account product
            products.add(AccountProduct(
              id: 'plaid_${institution['institution_id']}_checking',
              name: '${institution['name']} Checking',
              institution: institution['name'],
              type: AccountType.checking,
              category: ProductCategory.banking,
              description: 'Full-featured checking account with mobile banking',
              features: [
                'Mobile check deposit',
                'ATM network access',
                'Online banking',
                'Bill pay',
                'Overdraft protection',
              ],
              minimumDeposit: _getMinimumDeposit(AccountType.checking),
              monthlyFee: _getMonthlyFee(institution['name'], AccountType.checking),
              interestRate: _getInterestRate(AccountType.checking),
              plaidInstitutionId: institution['institution_id'],
              isPlaidSupported: true,
              logoUrl: institution['logo']?.toString(),
            ));

            // Add savings account product
            products.add(AccountProduct(
              id: 'plaid_${institution['institution_id']}_savings',
              name: '${institution['name']} Savings',
              institution: institution['name'],
              type: AccountType.savings,
              category: ProductCategory.banking,
              description: 'High-yield savings account to grow your money',
              features: [
                'Competitive interest rates',
                'No minimum balance',
                'Mobile banking',
                'Automatic transfers',
              ],
              minimumDeposit: _getMinimumDeposit(AccountType.savings),
              monthlyFee: _getMonthlyFee(institution['name'], AccountType.savings),
              interestRate: _getInterestRate(AccountType.savings),
              plaidInstitutionId: institution['institution_id'],
              isPlaidSupported: true,
              logoUrl: institution['logo']?.toString(),
            ));

            // Add credit card if supported
            if (institution['name'].contains('American Express') || 
                institution['name'].contains('Capital One') ||
                institution['name'].contains('Chase') ||
                institution['name'].contains('Citibank')) {
              products.add(AccountProduct(
                id: 'plaid_${institution['institution_id']}_credit',
                name: '${institution['name']} Credit Card',
                institution: institution['name'],
                type: AccountType.credit,
                category: ProductCategory.credit,
                description: 'Rewards credit card with cashback and travel benefits',
                features: [
                  'Rewards program',
                  'Fraud protection',
                  'Mobile app',
                  'Credit monitoring',
                  '0% intro APR offers',
                ],
                minimumDeposit: 0.0,
                monthlyFee: 0.0,
                interestRate: _getCreditAPR(institution['name']),
                plaidInstitutionId: institution['institution_id'],
                isPlaidSupported: true,
                logoUrl: institution['logo']?.toString(),
              ));
            }
          }
        } catch (e) {
          debugPrint('Error fetching institution $bank: $e');
          continue;
        }
      }

      return products;
    } catch (e) {
      debugPrint('Error getting Plaid products: $e');
      return [];
    }
  }

  /// Get internal banking products (credit union specific)
  Future<List<AccountProduct>> _getInternalProducts() async {
    return [
      AccountProduct(
        id: 'cu_member_checking',
        name: 'Member Plus Checking',
        institution: 'SUPAHYPER Credit Union',
        type: AccountType.checking,
        category: ProductCategory.banking,
        description: 'Exclusive member checking account with premium benefits',
        features: [
          'No monthly fees for members',
          'Free ATM usage nationwide',
          'Mobile check deposit',
          'Early direct deposit',
          'Cashback rewards',
          'Member dividend sharing',
        ],
        minimumDeposit: 25.0,
        monthlyFee: 0.0,
        interestRate: 0.15,
        isInternal: true,
        isRecommended: true,
      ),
      
      AccountProduct(
        id: 'cu_high_yield_savings',
        name: 'High-Yield Member Savings',
        institution: 'SUPAHYPER Credit Union',
        type: AccountType.savings,
        category: ProductCategory.banking,
        description: 'Premium savings account with competitive rates',
        features: [
          '2.5% APY on all balances',
          'No minimum balance',
          'Automatic savings programs',
          'Goal-based savings buckets',
          'Member bonus rates',
        ],
        minimumDeposit: 5.0,
        monthlyFee: 0.0,
        interestRate: 2.5,
        isInternal: true,
        isRecommended: true,
      ),
      
      AccountProduct(
        id: 'cu_money_market',
        name: 'Premium Money Market',
        institution: 'SUPAHYPER Credit Union',
        type: AccountType.moneyMarket,
        category: ProductCategory.banking,
        description: 'High-yield money market with check writing privileges',
        features: [
          '3.2% APY on balances over \$2,500',
          'Check writing privileges',
          'Tiered interest rates',
          'FDIC insured up to \$250,000',
          'Online and mobile banking',
        ],
        minimumDeposit: 500.0,
        monthlyFee: 0.0,
        interestRate: 3.2,
        isInternal: true,
      ),
      
      AccountProduct(
        id: 'cu_rewards_credit',
        name: 'Member Rewards Visa',
        institution: 'SUPAHYPER Credit Union',
        type: AccountType.credit,
        category: ProductCategory.credit,
        description: 'Low-rate rewards credit card for members',
        features: [
          '1.5% cashback on all purchases',
          '5% cashback on rotating categories',
          'No annual fee',
          '9.9% APR for qualified members',
          'Balance transfer offers',
          'Credit score monitoring',
        ],
        minimumDeposit: 0.0,
        monthlyFee: 0.0,
        interestRate: 9.9,
        isInternal: true,
        isRecommended: true,
      ),
    ];
  }

  /// Get investment products
  Future<List<AccountProduct>> _getInvestmentProducts() async {
    return [
      AccountProduct(
        id: 'investment_brokerage',
        name: 'Investment Brokerage',
        institution: 'SUPAHYPER Investment Services',
        type: AccountType.investment,
        category: ProductCategory.investment,
        description: 'Full-service brokerage account for trading and investing',
        features: [
          'Commission-free stock trading',
          'ETF and mutual fund access',
          'Research tools and analysis',
          'Mobile trading app',
          'Dividend reinvestment',
          'Options and futures trading',
        ],
        minimumDeposit: 0.0,
        monthlyFee: 0.0,
        interestRate: 0.0,
        isInternal: true,
      ),
      
      AccountProduct(
        id: 'investment_ira',
        name: 'Individual Retirement Account (IRA)',
        institution: 'SUPAHYPER Investment Services',
        type: AccountType.retirement,
        category: ProductCategory.investment,
        description: 'Tax-advantaged retirement savings account',
        features: [
          'Traditional and Roth IRA options',
          'Wide range of investment choices',
          'No account maintenance fees',
          'Automatic contributions',
          'Rollover assistance',
          'Retirement planning tools',
        ],
        minimumDeposit: 100.0,
        monthlyFee: 0.0,
        interestRate: 0.0,
        isInternal: true,
        isRecommended: true,
      ),
      
      AccountProduct(
        id: 'investment_cd',
        name: 'Certificate of Deposit',
        institution: 'SUPAHYPER Credit Union',
        type: AccountType.cd,
        category: ProductCategory.banking,
        description: 'Guaranteed return certificate with fixed rates',
        features: [
          'Terms from 3 months to 5 years',
          'Guaranteed fixed interest rates',
          'FDIC insured up to \$250,000',
          'Automatic renewal options',
          'Special member rates',
          'Penalty-free withdrawals (conditions apply)',
        ],
        minimumDeposit: 500.0,
        monthlyFee: 0.0,
        interestRate: 4.5,
        isInternal: true,
      ),
    ];
  }

  /// Get fallback products if API calls fail
  List<AccountProduct> _getFallbackProducts() {
    return [
      AccountProduct(
        id: 'fallback_checking',
        name: 'Basic Checking',
        institution: 'SUPAHYPER Credit Union',
        type: AccountType.checking,
        category: ProductCategory.banking,
        description: 'Essential checking account for everyday banking',
        features: ['Mobile banking', 'ATM access', 'Online bill pay'],
        minimumDeposit: 25.0,
        monthlyFee: 0.0,
        interestRate: 0.05,
        isInternal: true,
      ),
      AccountProduct(
        id: 'fallback_savings',
        name: 'Basic Savings',
        institution: 'SUPAHYPER Credit Union',
        type: AccountType.savings,
        category: ProductCategory.banking,
        description: 'Simple savings account to start building wealth',
        features: ['Competitive rates', 'Mobile banking', 'Goal tracking'],
        minimumDeposit: 5.0,
        monthlyFee: 0.0,
        interestRate: 1.5,
        isInternal: true,
      ),
    ];
  }

  /// Create a new account product for user
  Future<Map<String, dynamic>> createAccountProduct({
    required String productId,
    required Map<String, dynamic> userInfo,
    required Map<String, dynamic> biometricSettings,
    double initialDeposit = 0.0,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the product details
      final products = await getAvailableProducts();
      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found'),
      );

      // Create account record in database
      final accountData = {
        'id': 'acc_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': user.id,
        'product_id': productId,
        'product_name': product.name,
        'institution': product.institution,
        'account_type': product.type.name,
        'category': product.category.name,
        'balance': initialDeposit,
        'minimum_deposit': product.minimumDeposit,
        'monthly_fee': product.monthlyFee,
        'interest_rate': product.interestRate,
        'is_internal': product.isInternal,
        'plaid_institution_id': product.plaidInstitutionId,
        'is_plaid_supported': product.isPlaidSupported,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'user_info': jsonEncode(userInfo),
        'biometric_settings': jsonEncode(biometricSettings),
      };

      final response = await _supabase
          .from('user_accounts')
          .insert(accountData)
          .select()
          .single();

      // If it's a Plaid-supported product, initiate Plaid Link
      if (product.isPlaidSupported && product.plaidInstitutionId != null) {
        try {
          final linkToken = await _plaidService.createLinkToken();
          response['plaid_link_token'] = linkToken;
          response['requires_plaid_link'] = true;
        } catch (e) {
          debugPrint('Failed to create Plaid link token: $e');
          response['requires_plaid_link'] = false;
        }
      }

      return response;
    } catch (e) {
      debugPrint('Error creating account product: $e');
      rethrow;
    }
  }

  /// Get user's created accounts
  Future<List<Map<String, dynamic>>> getUserAccounts() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('user_accounts')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting user accounts: $e');
      return [];
    }
  }

  /// Complete Plaid Link process for an account
  Future<void> completePlaidLink({
    required String accountId,
    required String publicToken,
  }) async {
    try {
      // Exchange public token for access token
      await _plaidService.exchangePublicToken(publicToken);

      // Update account with Plaid access token
      await _supabase
          .from('user_accounts')
          .update({
            'plaid_access_token': _plaidService.accessToken,
            'plaid_item_id': _plaidService.itemId,
            'plaid_linked_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', accountId);
    } catch (e) {
      debugPrint('Error completing Plaid link: $e');
      rethrow;
    }
  }

  /// Get product recommendations based on user profile
  Future<List<AccountProduct>> getRecommendedProducts({
    required Map<String, dynamic> userProfile,
  }) async {
    final allProducts = await getAvailableProducts();
    
    // Simple recommendation logic based on user profile
    final age = userProfile['age'] as int? ?? 25;
    final income = userProfile['annual_income'] as double? ?? 50000.0;
    final hasExistingAccounts = userProfile['has_existing_accounts'] as bool? ?? false;
    
    final recommendations = <AccountProduct>[];
    
    // Always recommend basic checking and savings for new users
    if (!hasExistingAccounts) {
      recommendations.addAll(
        allProducts.where((p) => 
          p.isInternal && 
          (p.type == AccountType.checking || p.type == AccountType.savings)
        )
      );
    }
    
    // Recommend investment accounts for higher income or older users
    if (income > 75000 || age > 30) {
      recommendations.addAll(
        allProducts.where((p) => p.category == ProductCategory.investment)
      );
    }
    
    // Recommend credit products for established users
    if (hasExistingAccounts && income > 40000) {
      recommendations.addAll(
        allProducts.where((p) => p.type == AccountType.credit && p.isInternal)
      );
    }
    
    return recommendations;
  }

  // Helper methods for calculating rates and fees
  double _getMinimumDeposit(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return 25.0;
      case AccountType.savings:
        return 5.0;
      case AccountType.moneyMarket:
        return 500.0;
      case AccountType.cd:
        return 500.0;
      default:
        return 0.0;
    }
  }

  double _getMonthlyFee(String institution, AccountType type) {
    // Credit unions typically have lower fees
    if (institution.toLowerCase().contains('credit union')) {
      return 0.0;
    }
    
    switch (type) {
      case AccountType.checking:
        return 12.0;
      case AccountType.savings:
        return 5.0;
      default:
        return 0.0;
    }
  }

  double _getInterestRate(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return 0.05;
      case AccountType.savings:
        return 1.8;
      case AccountType.moneyMarket:
        return 2.5;
      case AccountType.cd:
        return 4.0;
      default:
        return 0.0;
    }
  }

  double _getCreditAPR(String institution) {
    // Credit unions typically offer lower APR
    if (institution.toLowerCase().contains('credit union')) {
      return 9.9;
    }
    return 18.9;
  }
}

class AccountProduct {
  final String id;
  final String name;
  final String institution;
  final AccountType type;
  final ProductCategory category;
  final String description;
  final List<String> features;
  final double minimumDeposit;
  final double monthlyFee;
  final double interestRate;
  final String? plaidInstitutionId;
  final bool isPlaidSupported;
  final bool isInternal;
  final bool isRecommended;
  final String? logoUrl;

  AccountProduct({
    required this.id,
    required this.name,
    required this.institution,
    required this.type,
    required this.category,
    required this.description,
    required this.features,
    required this.minimumDeposit,
    required this.monthlyFee,
    required this.interestRate,
    this.plaidInstitutionId,
    this.isPlaidSupported = false,
    this.isInternal = false,
    this.isRecommended = false,
    this.logoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'institution': institution,
      'type': type.name,
      'category': category.name,
      'description': description,
      'features': features,
      'minimumDeposit': minimumDeposit,
      'monthlyFee': monthlyFee,
      'interestRate': interestRate,
      'plaidInstitutionId': plaidInstitutionId,
      'isPlaidSupported': isPlaidSupported,
      'isInternal': isInternal,
      'isRecommended': isRecommended,
      'logoUrl': logoUrl,
    };
  }
}

enum AccountType {
  checking,
  savings,
  moneyMarket,
  cd,
  credit,
  investment,
  retirement,
  loan,
}

enum ProductCategory {
  banking,
  credit,
  investment,
  loan,
}