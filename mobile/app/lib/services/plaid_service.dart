import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/plaid_config.dart';
import 'optimized_http_client.dart';

class PlaidService {
  static final PlaidService _instance = PlaidService._internal();
  factory PlaidService() => _instance;
  PlaidService._internal();
  
  // Use optimized HTTP client for connection pooling
  final OptimizedHttpClient _httpClient = OptimizedHttpClient();

  // Plaid configuration - Now using Supabase Edge Functions for ALL REAL DATA
  static const String _baseUrl = PlaidConfig.baseUrl;
  static const String _edgeFunctionUrl = 'http://localhost:54321/functions/v1';
  
  // Headers for edge function requests
  static const Map<String, String> _edgeHeaders = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer YOUR_SUPABASE_ANON_KEY', // Replace with actual key
  };

  // Current access token (static to persist across instances)
  static String? _accessToken;

  // Current item ID (static to persist across instances)
  static String? _itemId;

  /// Create a sandbox public token for testing (bypasses Link flow)
  Future<String> createSandboxPublicToken({
    String institutionId = 'ins_109508', // Chase Bank sandbox
    List<String> initialProducts = const ['auth', 'transactions'],
    Map<String, dynamic>? config,
  }) async {
    try {
      // Build the request body
      final requestBody = {
        'client_id': PlaidConfig.clientId,
        'secret': PlaidConfig.secret,
        'institution_id': institutionId,
        'initial_products': initialProducts,
      };

      // Add options if config is provided
      if (config != null) {
        requestBody['options'] = {
          'override_username': 'user_custom',
          'override_password': jsonEncode(config),
        };
      }

      debugPrint('Creating sandbox token with: ${jsonEncode(requestBody)}');

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/sandbox/public_token/create'),
        headers: {
          'Content-Type': 'application/json',
          'Plaid-Version': PlaidConfig.apiVersion,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Sandbox public token created: ${data['public_token']}');
        return data['public_token'];
      } else {
        throw Exception(
            'Failed to create sandbox public token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Sandbox public token creation error: $e');
      rethrow;
    }
  }

  /// Create a link token for Plaid Link (for production use)
  Future<String> createLinkToken() async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/link/token/create'),
        headers: {
          'Content-Type': 'application/json',
          'Plaid-Version': PlaidConfig.apiVersion,
        },
        body: jsonEncode({
          'client_id': PlaidConfig.clientId,
          'secret': PlaidConfig.secret,
          'client_name': 'SUPAHYPER Demo',
          'country_codes': ['US'],
          'language': 'en',
          'user': {
            'client_user_id': 'user_${DateTime.now().millisecondsSinceEpoch}',
          },
          'products': ['auth', 'transactions', 'identity', 'assets'],
          'account_filters': {
            'depository': {
              'account_subtypes': ['checking', 'savings'],
            },
            'credit': {
              'account_subtypes': ['credit card'],
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['link_token'];
      } else {
        throw Exception('Failed to create link token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Link token creation error: $e');
      rethrow;
    }
  }

  /// Exchange public token for access token
  Future<void> exchangePublicToken(String publicToken) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/item/public_token/exchange'),
        headers: {
          'Content-Type': 'application/json',
          'Plaid-Version': PlaidConfig.apiVersion,
        },
        body: jsonEncode({
          'client_id': PlaidConfig.clientId,
          'secret': PlaidConfig.secret,
          'public_token': publicToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _itemId = data['item_id'];
        debugPrint('Access token obtained: $_accessToken');
        debugPrint('Item ID: $_itemId');
      } else {
        throw Exception('Failed to exchange token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Token exchange error: $e');
      rethrow;
    }
  }

  /// Create sandbox transactions for testing
  Future<void> createSandboxTransactions(
      List<Map<String, dynamic>> transactions) async {
    if (_accessToken == null) {
      throw Exception(
          'No access token available. Please link a bank account first.');
    }

    try {
      // Remove currency field as it's not supported by the API
      final cleanTransactions = transactions.map((transaction) {
        final cleanTransaction = Map<String, dynamic>.from(transaction);
        cleanTransaction.remove('currency');
        return cleanTransaction;
      }).toList();

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/sandbox/transactions/create'),
        headers: {
          'Content-Type': 'application/json',
          'Plaid-Version': PlaidConfig.apiVersion,
        },
        body: jsonEncode({
          'client_id': PlaidConfig.clientId,
          'secret': PlaidConfig.secret,
          'access_token': _accessToken,
          'transactions': cleanTransactions,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Sandbox transactions created: ${data['request_id']}');
      } else {
        throw Exception(
            'Failed to create sandbox transactions: ${response.body}');
      }
    } catch (e) {
      debugPrint('Create sandbox transactions error: $e');
      rethrow;
    }
  }

  /// Get account information
  Future<List<Map<String, dynamic>>> getAccounts() async {
    if (_accessToken == null) {
      throw Exception(
          'No access token available. Please link a bank account first.');
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/accounts/get'),
        headers: {
          'Content-Type': 'application/json',
          'Plaid-Version': PlaidConfig.apiVersion,
        },
        body: jsonEncode({
          'client_id': PlaidConfig.clientId,
          'secret': PlaidConfig.secret,
          'access_token': _accessToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['accounts']);
      } else {
        throw Exception('Failed to get accounts: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get accounts error: $e');
      rethrow;
    }
  }

  /// Get REAL account balances from Supabase Edge Function
  Future<Map<String, dynamic>> getRealAccountBalances({String? accessToken}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-balance'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'access_token': accessToken ?? _accessToken ?? 'access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Real balance data received: ${data['source']}');
        return data;
      } else {
        throw Exception('Failed to get real balances: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get real balances error: $e');
      rethrow;
    }
  }

  /// Legacy method for backwards compatibility
  Future<List<Map<String, dynamic>>> getAccountBalances() async {
    final realData = await getRealAccountBalances();
    return List<Map<String, dynamic>>.from(realData['accounts'] ?? []);
  }

  /// Get transactions
  Future<List<Map<String, dynamic>>> getTransactions({
    String? startDate,
    String? endDate,
    String? accountId,
  }) async {
    if (_accessToken == null) {
      throw Exception(
          'No access token available. Please link a bank account first.');
    }

    try {
      // First get all accounts to get account IDs
      final accounts = await getAccounts();
      if (accounts.isEmpty) {
        debugPrint('No accounts available for transactions');
        return [];
      }

      // Use specific account ID or all account IDs
      final accountIds = accountId != null
          ? [accountId]
          : accounts.map((account) => account['account_id'] as String).toList();

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/transactions/get'),
        headers: {
          'Content-Type': 'application/json',
          'Plaid-Version': PlaidConfig.apiVersion,
        },
        body: jsonEncode({
          'client_id': PlaidConfig.clientId,
          'secret': PlaidConfig.secret,
          'access_token': _accessToken,
          'start_date': startDate ??
              DateTime.now()
                  .subtract(Duration(days: 30))
                  .toIso8601String()
                  .split('T')[0],
          'end_date': endDate ?? DateTime.now().toIso8601String().split('T')[0],
          'options': {
            'account_ids': accountIds,
            'count': 100,
            'offset': 0,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['transactions']);
      } else {
        throw Exception('Failed to get transactions: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get transactions error: $e');
      rethrow;
    }
  }

  /// Get identity information
  Future<Map<String, dynamic>> getIdentity() async {
    if (_accessToken == null) {
      throw Exception(
          'No access token available. Please link a bank account first.');
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/identity/get'),
        headers: {
          'Content-Type': 'application/json',
          'Plaid-Version': PlaidConfig.apiVersion,
        },
        body: jsonEncode({
          'client_id': PlaidConfig.clientId,
          'secret': PlaidConfig.secret,
          'access_token': _accessToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to get identity: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get identity error: $e');
      rethrow;
    }
  }

  /// Check if user has linked accounts
  bool get hasLinkedAccounts => _accessToken != null;

  /// Get current access token
  String? get accessToken => _accessToken;

  /// Get current item ID
  String? get itemId => _itemId;

  /// Create test transactions for sandbox item
  Future<void> createTestTransactions() async {
    if (_accessToken == null) {
      throw Exception(
          'No access token available. Please link a bank account first.');
    }

    try {
      final testTransactions = [
        {
          'date_transacted': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String()
              .split('T')[0],
          'date_posted': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String()
              .split('T')[0],
          'amount': -89.99,
          'description': 'Netflix Subscription',
          'currency': 'USD',
        },
        {
          'date_transacted': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String()
              .split('T')[0],
          'date_posted': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String()
              .split('T')[0],
          'amount': -45.67,
          'description': 'Whole Foods Market',
          'currency': 'USD',
        },
        {
          'date_transacted': DateTime.now()
              .subtract(const Duration(days: 3))
              .toIso8601String()
              .split('T')[0],
          'date_posted': DateTime.now()
              .subtract(const Duration(days: 3))
              .toIso8601String()
              .split('T')[0],
          'amount': 3500.00,
          'description': 'Salary Deposit - Tech Corp',
          'currency': 'USD',
        },
      ];

      await createSandboxTransactions(testTransactions);
      debugPrint('Test transactions created successfully');
    } catch (e) {
      debugPrint('Failed to create test transactions: $e');
      // Don't rethrow - this is optional
    }
  }

  /// Create a simple sandbox public token using standard credentials
  Future<String> createSimpleSandboxToken() async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/sandbox/public_token/create'),
        headers: {
          'Content-Type': 'application/json',
          'Plaid-Version': PlaidConfig.apiVersion,
        },
        body: jsonEncode({
          'client_id': PlaidConfig.clientId,
          'secret': PlaidConfig.secret,
          'institution_id': 'ins_109508', // First Platypus Bank
          'initial_products': ['auth', 'transactions'],
          'options': {
            'override_username': 'user_good',
            'override_password': 'pass_good',
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Simple sandbox token created: ${data['public_token']}');
        return data['public_token'];
      } else {
        throw Exception(
            'Failed to create simple sandbox token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Simple sandbox token creation error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // COMPREHENSIVE REAL DATA METHODS USING SUPABASE EDGE FUNCTIONS
  // ============================================================================

  /// Get comprehensive account data with identity info
  Future<Map<String, dynamic>> getComprehensiveAccounts({String? accessToken}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-accounts'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'accessToken': accessToken ?? _accessToken ?? 'access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get comprehensive accounts: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get comprehensive accounts error: $e');
      rethrow;
    }
  }

  /// Get REAL transactions with filtering and pagination
  Future<Map<String, dynamic>> getRealTransactions({
    String? accessToken,
    String? accountId,
    String? startDate,
    String? endDate,
    int count = 50,
    int offset = 0,
    String? category,
    String? merchantName,
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-transactions'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'accessToken': accessToken ?? _accessToken ?? 'access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24',
          'accountId': accountId,
          'startDate': startDate,
          'endDate': endDate,
          'count': count,
          'offset': offset,
          'category': category,
          'merchantName': merchantName,
          'minAmount': minAmount,
          'maxAmount': maxAmount,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get real transactions: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get real transactions error: $e');
      rethrow;
    }
  }

  /// Get investment holdings and securities
  Future<Map<String, dynamic>> getInvestmentHoldings({String? accessToken}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-investments/holdings'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'accessToken': accessToken ?? _accessToken ?? 'access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get investment holdings: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get investment holdings error: $e');
      return {}; // Return empty map if investments not available
    }
  }

  /// Get investment transactions
  Future<Map<String, dynamic>> getInvestmentTransactions({
    String? accessToken,
    String? startDate,
    String? endDate,
    int count = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-investments/transactions'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'accessToken': accessToken ?? _accessToken ?? 'access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24',
          'start_date': startDate,
          'end_date': endDate,
          'count': count,
          'offset': offset,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get investment transactions: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get investment transactions error: $e');
      return {}; // Return empty map if not available
    }
  }

  /// Get identity data
  Future<Map<String, dynamic>> getRealIdentity({String? accessToken}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-identity/get'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'access_token': accessToken ?? _accessToken ?? 'access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get identity: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get identity error: $e');
      rethrow;
    }
  }

  /// Get liabilities (credit cards, loans, mortgages)
  Future<Map<String, dynamic>> getLiabilities({String? accessToken}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-liabilities'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'access_token': accessToken ?? _accessToken ?? 'access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get liabilities: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get liabilities error: $e');
      return {}; // Return empty map if not available
    }
  }

  /// Get income verification data
  Future<Map<String, dynamic>> getIncome({String? accessToken}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-income/get'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'access_token': accessToken ?? _accessToken ?? 'access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get income: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get income error: $e');
      return {}; // Return empty map if not available
    }
  }

  /// Get employment verification data
  Future<Map<String, dynamic>> getEmployment({String? accessToken}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-income/employment/get'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'access_token': accessToken ?? _accessToken ?? 'access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get employment: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get employment error: $e');
      return {}; // Return empty map if not available
    }
  }

  /// Get auth data (account and routing numbers)
  Future<Map<String, dynamic>> getAuthData({String? accessToken}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-auth/auth/get'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'access_token': accessToken ?? _accessToken ?? 'access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get auth data: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get auth data error: $e');
      rethrow;
    }
  }

  /// Create bank transfer (ACH)
  Future<Map<String, dynamic>> createBankTransfer({
    required String accountId,
    required String type, // 'debit' or 'credit'
    required String network, // 'ach' or 'same-day-ach'
    required double amount,
    required String description,
    String? accessToken,
    String? achClass,
    Map<String, dynamic>? user,
    String? customTag,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-bank-transfer/create'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'access_token': accessToken ?? _accessToken ?? 'access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24',
          'account_id': accountId,
          'type': type,
          'network': network,
          'amount': amount,
          'description': description,
          'ach_class': achClass ?? 'ppd',
          'user': user,
          'custom_tag': customTag,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create bank transfer: ${response.body}');
      }
    } catch (e) {
      debugPrint('Create bank transfer error: $e');
      rethrow;
    }
  }

  /// Get bank transfer status
  Future<Map<String, dynamic>> getBankTransfer({required String bankTransferId}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-bank-transfer/get'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'bank_transfer_id': bankTransferId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get bank transfer: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get bank transfer error: $e');
      rethrow;
    }
  }

  /// Search institutions
  Future<Map<String, dynamic>> searchInstitutions({
    required String query,
    List<String>? products,
    List<String>? countryCodes,
  }) async {
    try {
      final uri = Uri.parse('$_edgeFunctionUrl/plaid-institutions/search').replace(queryParameters: {
        'query': query,
        'products': products?.join(',') ?? 'transactions',
        'country_codes': countryCodes?.join(',') ?? 'US',
      });

      final response = await _httpClient.get(uri, headers: _edgeHeaders);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to search institutions: ${response.body}');
      }
    } catch (e) {
      debugPrint('Search institutions error: $e');
      rethrow;
    }
  }

  /// Create asset report
  Future<Map<String, dynamic>> createAssetReport({
    required List<String> accessTokens,
    int daysRequested = 730,
    String? webhook,
    Map<String, dynamic>? user,
    bool includeInsights = false,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-assets/report/create'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'access_tokens': accessTokens,
          'days_requested': daysRequested,
          'webhook': webhook,
          'user': user,
          'include_insights': includeInsights,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create asset report: ${response.body}');
      }
    } catch (e) {
      debugPrint('Create asset report error: $e');
      rethrow;
    }
  }

  /// Get comprehensive financial overview (ALL DATA AT ONCE)
  Future<Map<String, dynamic>> getFinancialOverview({String? accessToken}) async {
    try {
      final token = accessToken ?? _accessToken ?? 'access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24';
      
      debugPrint('Fetching comprehensive financial overview...');

      // Fetch all data in parallel for maximum performance
      final results = await Future.wait([
        getRealAccountBalances(accessToken: token),
        getComprehensiveAccounts(accessToken: token),
        getRealTransactions(accessToken: token, count: 100),
        getLiabilities(accessToken: token).catchError((e) => <String, dynamic>{}),
        getInvestmentHoldings(accessToken: token).catchError((e) => <String, dynamic>{}),
        getIncome(accessToken: token).catchError((e) => <String, dynamic>{}),
        getRealIdentity(accessToken: token).catchError((e) => <String, dynamic>{}),
      ]);

      final overview = {
        'balances': results[0],
        'accounts': results[1], 
        'transactions': results[2],
        'liabilities': results[3],
        'investments': results[4],
        'income': results[5],
        'identity': results[6],
        'overview_generated_at': DateTime.now().toIso8601String(),
        'source': 'comprehensive_real_plaid_data',
        'data_freshness': 'real_time_cached',
      };

      debugPrint('Financial overview generated successfully with ${overview.keys.length} data sections');
      return overview;
    } catch (e) {
      debugPrint('Failed to fetch financial overview: $e');
      rethrow;
    }
  }

  /// Update webhook URL for an item
  Future<Map<String, dynamic>> updateWebhook({
    String? accessToken,
    String? webhook,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_edgeFunctionUrl/plaid-webhook-management/item/webhook/update'),
        headers: _edgeHeaders,
        body: jsonEncode({
          'access_token': accessToken ?? _accessToken ?? 'access-sandbox-2f06761c-f9d8-4c53-96ce-17f03c272e24',
          'webhook': webhook,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update webhook: ${response.body}');
      }
    } catch (e) {
      debugPrint('Update webhook error: $e');
      rethrow;
    }
  }
}
