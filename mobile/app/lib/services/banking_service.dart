import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/supabase_config.dart';
import 'plaid_service.dart';
import 'cu_core_service.dart';

class BankingService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  final PlaidService _plaidService = PlaidService();
  final CUCoreService _cuCoreService = CUCoreService();

  // Our working Plaid API endpoint (Supabase Edge Function)
  static const String _plaidApiUrl =
      'https://vsduehkavltenthprjwe.supabase.co/functions/v1/plaid-balance';

  // Get all accounts (CU primary + Plaid external)
  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    List<Map<String, dynamic>> allAccounts = [];
    
    try {
      // First, get primary CU.APP accounts
      final primaryAccounts = await _cuCoreService.getAccounts();
      for (var account in primaryAccounts) {
        allAccounts.add({
          'id': account.id,
          'name': account.productName,
          'type': account.type.name,
          'subtype': account.type.name,
          'balance': account.balance,
          'available': account.available,
          'currency': 'USD',
          'mask': account.accountNumber,
          'institution': 'CU.APP Credit Union',
          'account_number': account.accountNumber,
          'status': account.status.name,
          'is_primary': true,  // Flag to identify primary CU.APP accounts
          'apr': account.apr,
          'apy': account.apy,
          'rewards_points': account.rewardsPoints,
          'created_at': account.openedDate.toIso8601String(),
        });
      }
      
      // Then, get external accounts via Plaid
      final plaidAccounts = await getUserAccounts();
      for (var account in plaidAccounts) {
        account['is_primary'] = false;  // Flag for external accounts
        allAccounts.add(account);
      }
      
      return allAccounts;
    } catch (e) {
      print('Error fetching all accounts: $e');
      // Return at least CU.APP demo accounts
      return allAccounts.isEmpty ? _getDemoAccounts() : allAccounts;
    }
  }
  
  // Get user accounts (with real Plaid API integration)
  Future<List<Map<String, dynamic>>> getUserAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('No user authenticated, using demo accounts');
      return _getDemoAccounts();
    }

    try {
      print('Attempting to fetch real Plaid data from: $_plaidApiUrl');

      // Try to get real accounts from our Plaid API
      final response = await http.get(Uri.parse(_plaidApiUrl));

      print('Plaid API response status: ${response.statusCode}');
      print('Plaid API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
            'Successfully fetched ${data['accounts']?.length ?? 0} accounts from Plaid API');
        print('Sample account data: ${data['accounts']?.isNotEmpty == true ? data['accounts'][0] : 'No accounts'}');

        if (data['accounts'] != null && data['accounts'].isNotEmpty) {
          final plaidAccounts = (data['accounts'] as List)
              .asMap()
              .entries
              .map((entry) {
                final index = entry.key;
                final account = entry.value;
                return {
                  'id': account['id'],
                  'name': account['name'],
                  'type': account['subtype'] ?? account['type'], // Use subtype for more specific type
                  'subtype': account['subtype'],
                  'balance': (account['balance'] ?? 0.0).toDouble(),
                  'available': (account['available'] ?? 0.0).toDouble(),
                  'currency': 'USD',
                  'mask': account['mask'] ?? '****',
                  'lastFour': account['mask'] ?? '****', // Add lastFour field
                  'institution': account['institution'] ?? 'Chase Bank',
                  'account_number': account['mask'] ?? '****',
                  'account_id': account['id'], // Add account_id field
                  'status': 'active',
                  'is_primary': index == 0, // Make first account primary
                  'is_pinned': index < 3, // Pin first 3 accounts
                  'created_at': DateTime.now().toIso8601String(),
                  'user_id': user?.id ?? 'demo_user',
                };
              })
              .toList();

          print('Returning ${plaidAccounts.length} real Plaid accounts');
          print('First mapped account: ${plaidAccounts.isNotEmpty ? plaidAccounts[0] : 'None'}');
          return plaidAccounts;
        } else {
          print('No accounts found in Plaid response, using demo accounts');
          return _getDemoAccounts();
        }
      } else {
        print(
            'Plaid API returned status ${response.statusCode}, using demo accounts');
        return _getDemoAccounts();
      }
    } catch (e) {
      print('Error fetching from Plaid API: $e');
      if (user == null) {
        print('No user authenticated, using demo accounts');
        return _getDemoAccounts();
      } else {
        print('User authenticated but API failed - showing empty state');
        return [];
      }
    }
  }

  // Get total balance from Plaid API
  Future<double> getTotalBalance() async {
    try {
      print('Fetching total balance from Plaid API...');
      final response = await http.get(Uri.parse(_plaidApiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final totalBalance = (data['totalBalance'] ?? 0.0).toDouble();
        print(
            'Successfully fetched total balance: \$${totalBalance.toStringAsFixed(2)}');
        return totalBalance;
      } else {
        print(
            'Plaid API returned status ${response.statusCode} for total balance');
      }
    } catch (e) {
      print('Error fetching total balance: $e');
    }

    // Fallback to demo total
    final demoTotal = 4250.75 + 12500.00 - 1845.32;
    print('Using demo total balance: \$${demoTotal.toStringAsFixed(2)}');
    return demoTotal;
  }

  // Get account details (with Plaid integration)
  Future<Map<String, dynamic>?> getAccountDetails(String accountId) async {
    try {
      // Try to get Plaid account details first
      final response = await http.get(Uri.parse(_plaidApiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['accounts'] != null) {
          final account = (data['accounts'] as List).firstWhere(
            (acc) => acc['id'] == accountId,
            orElse: () => null,
          );

          if (account != null) {
            return {
              'id': account['id'],
              'name': account['name'],
              'type': account['type'],
              'subtype': account['subtype'],
              'balance': (account['balance'] ?? 0.0).toDouble(),
              'available': (account['available'] ?? 0.0).toDouble(),
              'currency': 'USD',
              'mask': account['mask'] ?? '****',
              'institution': account['institution'] ?? 'Chase Bank',
              'account_number': account['mask'] ?? '****',
              'status': 'active',
              'created_at': DateTime.now().toIso8601String(),
            };
          }
        }
      }
    } catch (e) {
      print('Error fetching Plaid account details: $e');
    }

    // Fallback to demo account details
    return _getDemoAccountDetails(accountId);
  }

  // Get account transactions
  Future<List<Map<String, dynamic>>> getAccountTransactions(String accountId,
      {int limit = 10}) async {
    // For now, return demo transactions
    return [
      {
        'id': 'txn_001',
        'account_id': accountId,
        'amount': -45.67,
        'description': 'Coffee Shop',
        'category': 'Food & Drink',
        'date':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'txn_002',
        'account_id': accountId,
        'amount': 1200.00,
        'description': 'Salary Deposit',
        'category': 'Transfer',
        'date':
            DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
    ];
  }

  // Get spending analytics
  Future<Map<String, dynamic>> getSpendingAnalytics() async {
    return {
      'total_spent': 1245.67,
      'total_income': 3200.00,
      'net_worth': 15420.75,
      'spending_by_category': {
        'Food & Drink': 245.67,
        'Transportation': 89.50,
        'Entertainment': 156.00,
      },
    };
  }

  // Create demo accounts (deprecated - now handled by Plaid API)
  Future<void> createDemoAccounts(String userId) async {
    try {
      print(
          'createDemoAccounts is deprecated. Plaid linking is handled by the new API.');
    } catch (e) {
      print('Plaid account linking failed: $e');
      // Don't rethrow - this is not critical for app functionality
    }
  }

  // Get transaction categories
  Future<List<String>> getTransactionCategories() async {
    return [
      'Food & Drink',
      'Transportation',
      'Entertainment',
      'Shopping',
      'Bills & Utilities',
      'Healthcare',
      'Travel',
      'Education',
      'Transfer',
      'Other',
    ];
  }

  // Search transactions with enhanced filtering
  Future<List<Map<String, dynamic>>> searchTransactions({
    String? query,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
    double? minAmount,
    double? maxAmount,
    List<String>? categories,
    List<String>? accountIds,
    List<String>? transactionTypes,
    List<String>? statuses,
    String? sortBy,
    bool sortAscending = false,
  }) async {
    try {
      // Try to get Plaid transactions first if available
      if (_plaidService.hasLinkedAccounts) {
        final plaidTransactions = await _plaidService.getTransactions(
          startDate: startDate?.toIso8601String().split('T')[0],
          endDate: endDate?.toIso8601String().split('T')[0],
          accountId: accountId,
        );
        
        // Enrich and filter Plaid transactions
        List<Map<String, dynamic>> enrichedTransactions = _enrichTransactionData(plaidTransactions);
        
        // Apply filters
        if (query != null && query.isNotEmpty) {
          final lowerQuery = query.toLowerCase();
          enrichedTransactions = enrichedTransactions.where((txn) {
            final merchantName = (txn['merchant_name'] ?? txn['name'] ?? '').toString().toLowerCase();
            final categoryName = (txn['category'] ?? '').toString().toLowerCase();
            final amount = txn['amount']?.toString() ?? '';
            
            return merchantName.contains(lowerQuery) ||
                   categoryName.contains(lowerQuery) ||
                   amount.contains(lowerQuery);
          }).toList();
        }
        
        if (category != null) {
          enrichedTransactions = enrichedTransactions.where((txn) => 
            txn['category'] == category || txn['primary_category'] == category
          ).toList();
        }
        
        if (categories != null && categories.isNotEmpty) {
          enrichedTransactions = enrichedTransactions.where((txn) => 
            categories.contains(txn['category']) || categories.contains(txn['primary_category'])
          ).toList();
        }
        
        if (accountIds != null && accountIds.isNotEmpty) {
          enrichedTransactions = enrichedTransactions.where((txn) => 
            accountIds.contains(txn['account_id'])
          ).toList();
        }
        
        if (minAmount != null) {
          enrichedTransactions = enrichedTransactions.where((txn) => 
            (txn['amount'] ?? 0).abs() >= minAmount
          ).toList();
        }
        
        if (maxAmount != null) {
          enrichedTransactions = enrichedTransactions.where((txn) => 
            (txn['amount'] ?? 0).abs() <= maxAmount
          ).toList();
        }
        
        if (statuses != null && statuses.isNotEmpty) {
          enrichedTransactions = enrichedTransactions.where((txn) {
            final isPending = txn['pending'] ?? false;
            final status = isPending ? 'pending' : 'posted';
            return statuses.contains(status);
          }).toList();
        }
        
        // Sort transactions
        if (sortBy != null) {
          enrichedTransactions.sort((a, b) {
            int comparison = 0;
            
            switch (sortBy) {
              case 'date':
                final dateA = DateTime.parse(a['date'] ?? a['created_at'] ?? '');
                final dateB = DateTime.parse(b['date'] ?? b['created_at'] ?? '');
                comparison = dateB.compareTo(dateA);
                break;
              case 'amount':
                final amountA = (a['amount'] ?? 0).abs().toDouble();
                final amountB = (b['amount'] ?? 0).abs().toDouble();
                comparison = amountB.compareTo(amountA);
                break;
              case 'merchant':
                final merchantA = (a['merchant_name'] ?? a['name'] ?? '').toString();
                final merchantB = (b['merchant_name'] ?? b['name'] ?? '').toString();
                comparison = merchantA.compareTo(merchantB);
                break;
              case 'category':
                final categoryA = (a['category'] ?? 'Other').toString();
                final categoryB = (b['category'] ?? 'Other').toString();
                comparison = categoryA.compareTo(categoryB);
                break;
            }
            
            return sortAscending ? -comparison : comparison;
          });
        }
        
        return enrichedTransactions;
      }
    } catch (e) {
      print('Error searching Plaid transactions: $e');
    }
    
    // Fallback to demo transactions with rich data
    return _getDemoTransactions();
  }
  
  // Enhanced transaction enrichment
  List<Map<String, dynamic>> _enrichTransactionData(List<Map<String, dynamic>> transactions) {
    return transactions.map((transaction) {
      // Enrich transaction data
      final enriched = Map<String, dynamic>.from(transaction);
      
      // Clean merchant name
      enriched['merchant_name'] = transaction['merchant_name'] ?? transaction['name'];
      enriched['clean_name'] = _cleanMerchantName(enriched['merchant_name']);
      
      // Add logo URL (in real app, this would come from a merchant API)
      enriched['logo_url'] = _getMerchantLogoUrl(enriched['clean_name']);
      
      // Parse categories
      if (transaction['category'] is List && (transaction['category'] as List).isNotEmpty) {
        enriched['primary_category'] = (transaction['category'] as List)[0];
        enriched['subcategory'] = (transaction['category'] as List).length > 1 
            ? (transaction['category'] as List)[1] 
            : null;
      }
      
      // Add spending insights
      enriched['is_recurring'] = _detectRecurringTransaction(transaction);
      enriched['is_subscription'] = _detectSubscription(transaction);
      
      // Determine transaction type
      enriched['transaction_type'] = _determineTransactionType(transaction);
      
      return enriched;
    }).toList();
  }
  
  String _cleanMerchantName(String? name) {
    if (name == null) return 'Unknown Merchant';
    
    // Remove common suffixes and clean up
    return name
        .replaceAll(RegExp(r'\s+\d{4,}'), '') // Remove trailing numbers
        .replaceAll(RegExp(r'\s+#\d+'), '') // Remove store numbers
        .replaceAll(RegExp(r'\*'), '') // Remove asterisks
        .trim();
  }
  
  String? _getMerchantLogoUrl(String merchantName) {
    // In a real app, this would query a merchant logo API
    // For demo, return placeholder based on known merchants
    final lowerName = merchantName.toLowerCase();
    
    if (lowerName.contains('starbucks')) return 'https://logo.clearbit.com/starbucks.com';
    if (lowerName.contains('amazon')) return 'https://logo.clearbit.com/amazon.com';
    if (lowerName.contains('uber')) return 'https://logo.clearbit.com/uber.com';
    if (lowerName.contains('netflix')) return 'https://logo.clearbit.com/netflix.com';
    if (lowerName.contains('spotify')) return 'https://logo.clearbit.com/spotify.com';
    if (lowerName.contains('whole foods')) return 'https://logo.clearbit.com/wholefoodsmarket.com';
    
    return null;
  }
  
  bool _detectRecurringTransaction(Map<String, dynamic> transaction) {
    // Simple recurring detection based on merchant and amount
    // In production, use more sophisticated ML models
    final merchantName = transaction['merchant_name']?.toString().toLowerCase() ?? '';
    final subscriptionKeywords = ['netflix', 'spotify', 'gym', 'insurance', 'subscription'];
    
    return subscriptionKeywords.any((keyword) => merchantName.contains(keyword));
  }
  
  bool _detectSubscription(Map<String, dynamic> transaction) {
    final merchantName = transaction['merchant_name']?.toString().toLowerCase() ?? '';
    final subscriptionMerchants = [
      'netflix', 'spotify', 'apple music', 'amazon prime', 
      'disney+', 'hulu', 'youtube premium', 'adobe', 'microsoft'
    ];
    
    return subscriptionMerchants.any((merchant) => merchantName.contains(merchant));
  }
  
  String _determineTransactionType(Map<String, dynamic> transaction) {
    final amount = (transaction['amount'] ?? 0).toDouble();
    final category = (transaction['category'] ?? '').toString().toLowerCase();
    final description = (transaction['description'] ?? transaction['name'] ?? '').toString().toLowerCase();
    
    if (category.contains('transfer') || description.contains('transfer')) {
      return 'transfer';
    } else if (category.contains('deposit') || amount < 0) {
      return 'deposit';
    } else if (category.contains('payment') || description.contains('payment')) {
      return 'payment';
    } else if (category.contains('refund') || description.contains('refund')) {
      return 'refund';
    } else if (category.contains('fee') || description.contains('fee')) {
      return 'fee';
    } else {
      return 'withdrawal';
    }
  }
  
  // Get demo transactions with rich data
  List<Map<String, dynamic>> _getDemoTransactions() {
    final now = DateTime.now();
    
    return [
      {
        'id': 'txn_001',
        'account_id': 'demo_checking_001',
        'account_name': 'Chase Total Checking',
        'amount': -5.75,
        'merchant_name': 'Starbucks Coffee',
        'clean_name': 'Starbucks',
        'name': 'Starbucks Coffee #12345',
        'category': 'Food & Dining',
        'primary_category': 'Food & Dining',
        'subcategory': 'Coffee Shops',
        'date': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'pending': true,
        'is_recurring': false,
        'is_subscription': false,
        'transaction_type': 'withdrawal',
        'logo_url': 'https://logo.clearbit.com/starbucks.com',
      },
      {
        'id': 'txn_002',
        'account_id': 'demo_checking_001',
        'account_name': 'Chase Total Checking',
        'amount': -89.99,
        'merchant_name': 'Whole Foods Market',
        'clean_name': 'Whole Foods',
        'name': 'Whole Foods Market #10234',
        'category': 'Food & Dining',
        'primary_category': 'Food & Dining',
        'subcategory': 'Groceries',
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'pending': false,
        'is_recurring': false,
        'is_subscription': false,
        'transaction_type': 'withdrawal',
        'logo_url': 'https://logo.clearbit.com/wholefoodsmarket.com',
      },
      {
        'id': 'txn_003',
        'account_id': 'demo_checking_001',
        'account_name': 'Chase Total Checking',
        'amount': 3500.00,
        'merchant_name': 'Direct Deposit - Tech Corp',
        'clean_name': 'Tech Corp Payroll',
        'name': 'Direct Deposit - Tech Corp',
        'category': 'Transfer',
        'primary_category': 'Transfer',
        'subcategory': 'Deposit',
        'date': now.subtract(const Duration(days: 3)).toIso8601String(),
        'pending': false,
        'is_recurring': true,
        'is_subscription': false,
        'transaction_type': 'deposit',
      },
      {
        'id': 'txn_004',
        'account_id': 'demo_checking_001',
        'account_name': 'Chase Total Checking',
        'amount': -15.99,
        'merchant_name': 'Netflix',
        'clean_name': 'Netflix',
        'name': 'Netflix.com',
        'category': 'Entertainment',
        'primary_category': 'Entertainment',
        'subcategory': 'Subscription',
        'date': now.subtract(const Duration(days: 5)).toIso8601String(),
        'pending': false,
        'is_recurring': true,
        'is_subscription': true,
        'transaction_type': 'withdrawal',
        'logo_url': 'https://logo.clearbit.com/netflix.com',
      },
      {
        'id': 'txn_005',
        'account_id': 'demo_checking_001',
        'account_name': 'Chase Total Checking',
        'amount': -45.00,
        'merchant_name': 'Shell Gas Station',
        'clean_name': 'Shell',
        'name': 'Shell Gas Station #2341',
        'category': 'Transportation',
        'primary_category': 'Transportation',
        'subcategory': 'Gas & Fuel',
        'date': now.subtract(const Duration(days: 7)).toIso8601String(),
        'pending': false,
        'is_recurring': false,
        'is_subscription': false,
        'transaction_type': 'withdrawal',
      },
      {
        'id': 'txn_006',
        'account_id': 'demo_credit_001',
        'account_name': 'Chase Sapphire Reserve',
        'amount': -234.56,
        'merchant_name': 'Amazon.com',
        'clean_name': 'Amazon',
        'name': 'Amazon.com*MX3RT5GH2',
        'category': 'Shopping',
        'primary_category': 'Shopping',
        'subcategory': 'Online',
        'date': now.subtract(const Duration(days: 10)).toIso8601String(),
        'pending': false,
        'is_recurring': false,
        'is_subscription': false,
        'transaction_type': 'withdrawal',
        'logo_url': 'https://logo.clearbit.com/amazon.com',
      },
      {
        'id': 'txn_007',
        'account_id': 'demo_checking_001',
        'account_name': 'Chase Total Checking',
        'amount': -9.99,
        'merchant_name': 'Spotify',
        'clean_name': 'Spotify',
        'name': 'Spotify Premium',
        'category': 'Entertainment',
        'primary_category': 'Entertainment',
        'subcategory': 'Music',
        'date': now.subtract(const Duration(days: 15)).toIso8601String(),
        'pending': false,
        'is_recurring': true,
        'is_subscription': true,
        'transaction_type': 'withdrawal',
        'logo_url': 'https://logo.clearbit.com/spotify.com',
      },
      {
        'id': 'txn_008',
        'account_id': 'demo_checking_001',
        'account_name': 'Chase Total Checking',
        'amount': -500.00,
        'merchant_name': 'Transfer to Savings',
        'clean_name': 'Internal Transfer',
        'name': 'Transfer to Savings Account',
        'category': 'Transfer',
        'primary_category': 'Transfer',
        'subcategory': 'Account Transfer',
        'date': now.subtract(const Duration(days: 20)).toIso8601String(),
        'pending': false,
        'is_recurring': false,
        'is_subscription': false,
        'transaction_type': 'transfer',
      },
      {
        'id': 'txn_009',
        'account_id': 'demo_savings_001',
        'account_name': 'Chase Premier Savings',
        'amount': 500.00,
        'merchant_name': 'Transfer from Checking',
        'clean_name': 'Internal Transfer',
        'name': 'Transfer from Checking Account',
        'category': 'Transfer',
        'primary_category': 'Transfer',
        'subcategory': 'Account Transfer',
        'date': now.subtract(const Duration(days: 20)).toIso8601String(),
        'pending': false,
        'is_recurring': false,
        'is_subscription': false,
        'transaction_type': 'transfer',
      },
      {
        'id': 'txn_010',
        'account_id': 'demo_credit_001',
        'account_name': 'Chase Sapphire Reserve',
        'amount': -156.32,
        'merchant_name': 'Uber Rides',
        'clean_name': 'Uber',
        'name': 'Uber *TRIP',
        'category': 'Transportation',
        'primary_category': 'Transportation',
        'subcategory': 'Ride Sharing',
        'date': now.subtract(const Duration(days: 25)).toIso8601String(),
        'pending': false,
        'is_recurring': false,
        'is_subscription': false,
        'transaction_type': 'withdrawal',
        'logo_url': 'https://logo.clearbit.com/uber.com',
      },
      {
        'id': 'txn_011',
        'account_id': 'demo_checking_001',
        'account_name': 'Chase Total Checking',
        'amount': -125.00,
        'merchant_name': 'State Farm Insurance',
        'clean_name': 'State Farm',
        'name': 'State Farm Auto Insurance',
        'category': 'Bills & Utilities',
        'primary_category': 'Bills & Utilities',
        'subcategory': 'Insurance',
        'date': now.subtract(const Duration(days: 28)).toIso8601String(),
        'pending': false,
        'is_recurring': true,
        'is_subscription': false,
        'transaction_type': 'payment',
      },
      {
        'id': 'txn_012',
        'account_id': 'demo_credit_001',
        'account_name': 'Chase Sapphire Reserve',
        'amount': -432.10,
        'merchant_name': 'Best Buy',
        'clean_name': 'Best Buy',
        'name': 'Best Buy Electronics',
        'category': 'Shopping',
        'primary_category': 'Shopping',
        'subcategory': 'Electronics',
        'date': now.subtract(const Duration(days: 30)).toIso8601String(),
        'pending': false,
        'is_recurring': false,
        'is_subscription': false,
        'transaction_type': 'withdrawal',
      },
      {
        'id': 'txn_013',
        'account_id': 'demo_checking_001',
        'account_name': 'Chase Total Checking',
        'amount': -65.43,
        'merchant_name': 'Target',
        'clean_name': 'Target',
        'name': 'Target Store #2341',
        'category': 'Shopping',
        'primary_category': 'Shopping',
        'subcategory': 'Department Store',
        'date': now.subtract(const Duration(days: 35)).toIso8601String(),
        'pending': false,
        'is_recurring': false,
        'is_subscription': false,
        'transaction_type': 'withdrawal',
      },
      {
        'id': 'txn_014',
        'account_id': 'demo_checking_001',
        'account_name': 'Chase Total Checking',
        'amount': 89.99,
        'merchant_name': 'Refund - Amazon',
        'clean_name': 'Amazon Refund',
        'name': 'Amazon.com Refund',
        'category': 'Shopping',
        'primary_category': 'Shopping',
        'subcategory': 'Refund',
        'date': now.subtract(const Duration(days: 40)).toIso8601String(),
        'pending': false,
        'is_recurring': false,
        'is_subscription': false,
        'transaction_type': 'refund',
        'logo_url': 'https://logo.clearbit.com/amazon.com',
      },
      {
        'id': 'txn_015',
        'account_id': 'demo_checking_001',
        'account_name': 'Chase Total Checking',
        'amount': -35.00,
        'merchant_name': 'LA Fitness',
        'clean_name': 'LA Fitness',
        'name': 'LA Fitness Monthly',
        'category': 'Healthcare',
        'primary_category': 'Healthcare',
        'subcategory': 'Gym',
        'date': now.subtract(const Duration(days: 45)).toIso8601String(),
        'pending': false,
        'is_recurring': true,
        'is_subscription': true,
        'transaction_type': 'withdrawal',
      },
      {
        'id': 'txn_016',
        'account_id': 'demo_credit_001',
        'account_name': 'Chase Sapphire Reserve',
        'amount': -25.00,
        'merchant_name': 'Annual Fee',
        'clean_name': 'Chase Annual Fee',
        'name': 'Chase Sapphire Reserve Annual Fee',
        'category': 'Bank Fees',
        'primary_category': 'Bank Fees',
        'subcategory': 'Credit Card Fee',
        'date': now.subtract(const Duration(days: 60)).toIso8601String(),
        'pending': false,
        'is_recurring': false,
        'is_subscription': false,
        'transaction_type': 'fee',
      },
    ];
  }

  // Plaid sandbox methods for demo screen
  Future<String> createSimpleSandboxToken() async {
    // Simulate creating a simple sandbox token
    await Future.delayed(const Duration(seconds: 1));
    return 'public-sandbox-simple-token-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> createSandboxPublicToken(
      {Map<String, dynamic>? config}) async {
    // Simulate creating a sandbox public token
    await Future.delayed(const Duration(seconds: 1));
    return 'public-sandbox-config-token-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> exchangePublicToken(String publicToken) async {
    // Simulate exchanging public token for access token
    await Future.delayed(const Duration(seconds: 1));
    print('Exchanged public token: $publicToken for access token');
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    // Return demo accounts for sandbox demo
    return _getDemoAccounts();
  }

  Future<void> createTestTransactions() async {
    // Simulate creating test transactions
    await Future.delayed(const Duration(seconds: 1));
    print('Test transactions created successfully');
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    // Return enhanced demo transactions with real merchant data for logo matching
    return await _getEnhancedTransactions();
  }
  
  Future<List<Map<String, dynamic>>> _getEnhancedTransactions() async {
    final now = DateTime.now();
    
    return [
      {
        'id': '1',
        'merchant_name': 'Starbucks',
        'name': 'Starbucks Coffee',
        'category': 'Food & Coffee',
        'subcategory': 'Coffee Shop',
        'amount': 5.75,
        'date': now.toIso8601String(),
        'pending': true,
        'account_name': 'Chase Total Checking',
        'account_id': 'acc_1',
        'logo_url': 'https://logo.clearbit.com/starbucks.com',
        'merchant_data': {
          'location': '123 Main St, Seattle, WA',
          'phone': '(206) 555-0123'
        }
      },
      {
        'id': '2',
        'merchant_name': 'Amazon',
        'name': 'Amazon Purchase',
        'category': 'Shopping',
        'subcategory': 'Online Shopping',
        'amount': 127.43,
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'pending': false,
        'account_name': 'Chase Total Checking',
        'account_id': 'acc_1',
        'logo_url': 'https://logo.clearbit.com/amazon.com',
        'merchant_data': {
          'order_id': 'AMZ-123456789'
        }
      },
      {
        'id': '3',
        'merchant_name': 'Apple',
        'name': 'Apple Store',
        'category': 'Shopping',
        'subcategory': 'Electronics',
        'amount': 1299.00,
        'date': now.subtract(const Duration(days: 2)).toIso8601String(),
        'pending': false,
        'account_name': 'Chase Total Checking',
        'account_id': 'acc_1',
        'logo_url': 'https://logo.clearbit.com/apple.com',
        'merchant_data': {
          'product': 'MacBook Pro',
          'store': 'Apple Store Seattle'
        }
      },
      {
        'id': '4',
        'merchant_name': 'Netflix',
        'name': 'Netflix Subscription',
        'category': 'Entertainment',
        'subcategory': 'Streaming',
        'amount': 15.99,
        'date': now.subtract(const Duration(days: 3)).toIso8601String(),
        'pending': false,
        'account_name': 'Chase Total Checking',
        'account_id': 'acc_1',
        'logo_url': 'https://logo.clearbit.com/netflix.com',
        'is_recurring': true,
        'merchant_data': {
          'plan': 'Premium Plan',
          'billing_cycle': 'Monthly'
        }
      },
      {
        'id': '5',
        'merchant_name': 'Tesla',
        'name': 'Tesla Supercharger',
        'category': 'Transportation',
        'subcategory': 'Electric Vehicle Charging',
        'amount': 24.56,
        'date': now.subtract(const Duration(days: 4)).toIso8601String(),
        'pending': false,
        'account_name': 'Chase Total Checking',
        'account_id': 'acc_1',
        'logo_url': 'https://logo.clearbit.com/tesla.com',
        'merchant_data': {
          'location': 'Tesla Supercharger - Bellevue',
          'kwh_charged': '45.2 kWh'
        }
      },
      {
        'id': '6',
        'merchant_name': 'Microsoft',
        'name': 'Microsoft Office 365',
        'category': 'Software',
        'subcategory': 'Productivity Software',
        'amount': 12.99,
        'date': now.subtract(const Duration(days: 5)).toIso8601String(),
        'pending': false,
        'account_name': 'Chase Total Checking',
        'account_id': 'acc_1',
        'logo_url': 'https://logo.clearbit.com/microsoft.com',
        'is_recurring': true,
        'merchant_data': {
          'subscription': 'Personal Plan',
          'renewal_date': now.add(const Duration(days: 25)).toIso8601String()
        }
      },
      {
        'id': '7',
        'merchant_name': 'Uber',
        'name': 'Uber Trip',
        'category': 'Transportation',
        'subcategory': 'Ride Sharing',
        'amount': 18.75,
        'date': now.subtract(const Duration(days: 6)).toIso8601String(),
        'pending': false,
        'account_name': 'Chase Total Checking',
        'account_id': 'acc_1',
        'logo_url': 'https://logo.clearbit.com/uber.com',
        'merchant_data': {
          'trip_id': 'UBER-789012',
          'from': 'Downtown Seattle',
          'to': 'Capitol Hill'
        }
      },
      {
        'id': 'insight_1',
        'type': 'insight',
        'title': 'Spending Insight',
        'message': 'You\'ve spent 23% less on dining this month compared to last month',
        'icon': Icons.trending_down,
        'color': Colors.green,
        'category': 'insights',
      },
      {
        'id': '8',
        'merchant_name': 'Spotify',
        'name': 'Spotify Premium',
        'category': 'Entertainment',
        'subcategory': 'Music Streaming',
        'amount': 9.99,
        'date': now.subtract(const Duration(days: 7)).toIso8601String(),
        'pending': false,
        'account_name': 'Chase Total Checking',
        'account_id': 'acc_1',
        'logo_url': 'https://logo.clearbit.com/spotify.com',
        'is_recurring': true,
        'merchant_data': {
          'plan': 'Individual Premium',
          'family_account': false
        }
      },
      {
        'id': '9',
        'merchant_name': 'Whole Foods',
        'name': 'Whole Foods Market',
        'category': 'Food & Groceries',
        'subcategory': 'Grocery Store',
        'amount': 89.32,
        'date': now.subtract(const Duration(days: 8)).toIso8601String(),
        'pending': false,
        'account_name': 'Chase Total Checking',
        'account_id': 'acc_1',
        'logo_url': 'https://logo.clearbit.com/wholefoodsmarket.com',
        'merchant_data': {
          'store': 'Whole Foods Market - Bellevue',
          'receipt_items': 27
        }
      },
      {
        'id': 'income_1',
        'merchant_name': 'Direct Deposit',
        'name': 'Salary Deposit',
        'category': 'Income',
        'subcategory': 'Salary',
        'amount': -5247.83,
        'date': now.subtract(const Duration(days: 14)).toIso8601String(),
        'pending': false,
        'account_name': 'Chase Total Checking',
        'account_id': 'acc_1',
        'is_income': true,
        'merchant_data': {
          'employer': 'Tech Solutions Inc',
          'pay_period': 'Bi-weekly'
        }
      }
    ];
  }

  // Plaid Transfer Methods
  Future<Map<String, dynamic>> initiateTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String description,
  }) async {
    try {
      print(
          'Initiating transfer: \$${amount.toStringAsFixed(2)} from $fromAccountId to $toAccountId');

      // Call Plaid Transfer API through our Edge Function
      final response = await http.post(
        Uri.parse(
            'https://vsduehkavltenthprjwe.supabase.co/functions/v1/plaid-transfer'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from_account_id': fromAccountId,
          'to_account_id': toAccountId,
          'amount': amount,
          'description': description,
          'currency': 'USD',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Transfer initiated successfully: ${data['transfer_id']}');
        return data;
      } else {
        throw Exception('Failed to initiate transfer: ${response.body}');
      }
    } catch (e) {
      print('Transfer initiation error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTransferStatus(String transferId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://vsduehkavltenthprjwe.supabase.co/functions/v1/plaid-transfer-status?transfer_id=$transferId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get transfer status: ${response.body}');
      }
    } catch (e) {
      print('Transfer status error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTransferHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://vsduehkavltenthprjwe.supabase.co/functions/v1/plaid-transfer-history'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['transfers'] ?? []);
      } else {
        throw Exception('Failed to get transfer history: ${response.body}');
      }
    } catch (e) {
      print('Transfer history error: $e');
      rethrow;
    }
  }

  // Validate transfer before initiating
  Map<String, dynamic>? validateTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required List<Map<String, dynamic>> accounts,
  }) {
    // Find source account
    final fromAccount = accounts.firstWhere(
      (account) => account['id'] == fromAccountId,
      orElse: () => {},
    );

    if (fromAccount.isEmpty) {
      return {'valid': false, 'error': 'Source account not found'};
    }

    // Check if source account has sufficient balance
    final currentBalance = fromAccount['balance'] ?? 0.0;
    if (currentBalance < amount) {
      return {
        'valid': false,
        'error':
            'Insufficient balance. Available: \$${currentBalance.toStringAsFixed(2)}'
      };
    }

    // Check if accounts are different
    if (fromAccountId == toAccountId) {
      return {'valid': false, 'error': 'Cannot transfer to the same account'};
    }

    // Check if amount is positive
    if (amount <= 0) {
      return {
        'valid': false,
        'error': 'Transfer amount must be greater than 0'
      };
    }

    return {'valid': true, 'error': null};
  }

  // Helper for demo account details
  Map<String, dynamic>? _getDemoAccountDetails(String accountId) {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    if (accountId == 'demo_checking_001') {
      return {
        'id': 'demo_checking_001',
        'name': 'CU.APP Checking',
        'type': 'depository',
        'subtype': 'checking',
        'balance': 4250.75,
        'currency': 'USD',
        'mask': '1234',
        'institution': 'CU.APP',
        'account_number': '****1234',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };
    } else if (accountId == 'demo_savings_001') {
      return {
        'id': 'demo_savings_001',
        'name': 'Chase Premier Savings',
        'type': 'depository',
        'subtype': 'savings',
        'balance': 12500.00,
        'currency': 'USD',
        'mask': '5678',
        'institution': 'CU.APP',
        'account_number': '****5678',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };
    } else if (accountId == 'demo_credit_001') {
      return {
        'id': 'demo_credit_001',
        'name': 'Chase Sapphire Reserve',
        'type': 'credit',
        'subtype': 'credit card',
        'balance': -1845.32,
        'currency': 'USD',
        'mask': '9012',
        'institution': 'CU.APP',
        'account_number': '****9012',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };
    }
    return null;
  }

  // Helper to get demo accounts
  List<Map<String, dynamic>> _getDemoAccounts() {
    final user = _supabase.auth.currentUser;

    return [
      {
        'id': 'demo_checking_001',
        'name': 'CU.APP Checking',
        'type': 'depository',
        'subtype': 'checking',
        'balance': 4250.75,
        'currency': 'USD',
        'mask': '1234',
        'institution': 'CU.APP',
        'account_number': '****1234',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'user_id': user?.id ?? 'demo_user',
      },
      {
        'id': 'demo_savings_001',
        'name': 'CU.APP High Yield Savings',
        'type': 'depository',
        'subtype': 'savings',
        'balance': 12500.00,
        'currency': 'USD',
        'mask': '5678',
        'institution': 'CU.APP',
        'account_number': '****5678',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'user_id': user?.id ?? 'demo_user',
      },
      {
        'id': 'demo_credit_001',
        'name': 'CU.APP Rewards Credit Card',
        'type': 'credit',
        'subtype': 'credit card',
        'balance': -1845.32,
        'currency': 'USD',
        'mask': '9012',
        'institution': 'CU.APP',
        'account_number': '****9012',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'user_id': user?.id ?? 'demo_user',
      },
    ];
  }
}
