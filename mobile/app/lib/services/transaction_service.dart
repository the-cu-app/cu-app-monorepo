import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'plaid_service.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  final PlaidService _plaidService = PlaidService();
  
  // Cache management
  final Map<String, CachedTransactionData> _cache = {};
  static const Duration _cacheTimeout = Duration(minutes: 3);
  
  // Pagination settings
  static const int _pageSize = 50;
  
  // Transaction stream for real-time updates
  final _transactionStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get transactionStream => _transactionStreamController.stream;

  // Get paginated transactions with caching
  Future<TransactionPageResult> getTransactions({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? merchantName,
    double? minAmount,
    double? maxAmount,
    int page = 1,
    int pageSize = _pageSize,
    bool forceRefresh = false,
  }) async {
    // Create cache key
    final cacheKey = _createCacheKey(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
      category: category,
      merchantName: merchantName,
      minAmount: minAmount,
      maxAmount: maxAmount,
      page: page,
      pageSize: pageSize,
    );

    // Check cache if not forcing refresh
    if (!forceRefresh) {
      final cached = _getFromCache(cacheKey);
      if (cached != null) {
        debugPrint('Transaction cache hit for page $page');
        return cached;
      }
    }

    try {
      // Use Plaid paginated endpoint
      final response = await http.post(
        Uri.parse('https://vsduehkavltenthprjwe.supabase.co/functions/v1/plaid-transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accountId': accountId,
          'startDate': startDate?.toIso8601String().split('T')[0],
          'endDate': endDate?.toIso8601String().split('T')[0],
          'category': category,
          'merchantName': merchantName,
          'minAmount': minAmount,
          'maxAmount': maxAmount,
          'count': pageSize,
          'offset': (page - 1) * pageSize,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Create result
        final result = TransactionPageResult(
          transactions: List<Map<String, dynamic>>.from(data['transactions'] ?? []),
          totalCount: data['total_transactions'] ?? 0,
          currentPage: data['page_info']?['current_page'] ?? page,
          totalPages: data['page_info']?['pages'] ?? 1,
          hasMore: data['has_more'] ?? false,
          pageSize: pageSize,
          isCached: response.headers['x-cache-hit'] == 'true',
        );

        // Cache the result
        _addToCache(cacheKey, result);

        // Emit to stream for real-time updates
        if (page == 1) {
          _transactionStreamController.add(result.transactions);
        }

        return result;
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      // Return empty result on error
      return TransactionPageResult(
        transactions: [],
        totalCount: 0,
        currentPage: page,
        totalPages: 0,
        hasMore: false,
        pageSize: pageSize,
        isCached: false,
      );
    }
  }

  // Search transactions across all pages
  Future<List<Map<String, dynamic>>> searchAllTransactions({
    required String query,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<Map<String, dynamic>> allTransactions = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore && page <= 10) { // Limit to 10 pages max
      final result = await getTransactions(
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
        page: page,
        pageSize: 100, // Larger page size for search
      );

      // Filter locally for better performance
      final filtered = result.transactions.where((txn) {
        final lowerQuery = query.toLowerCase();
        final merchant = (txn['merchant_name'] ?? txn['name'] ?? '').toString().toLowerCase();
        final category = (txn['category'] ?? '').toString().toLowerCase();
        final amount = txn['amount']?.toString() ?? '';
        
        return merchant.contains(lowerQuery) ||
               category.contains(lowerQuery) ||
               amount.contains(lowerQuery);
      }).toList();

      allTransactions.addAll(filtered);
      hasMore = result.hasMore;
      page++;
    }

    return allTransactions;
  }

  // Get transaction insights
  Future<TransactionInsights> getTransactionInsights({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Get first page to analyze
    final result = await getTransactions(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
      pageSize: 100,
    );

    if (result.transactions.isEmpty) {
      return TransactionInsights.empty();
    }

    // Calculate insights
    final categoryTotals = <String, double>{};
    final merchantFrequency = <String, int>{};
    double totalSpending = 0;
    double totalIncome = 0;
    int recurringCount = 0;

    for (final transaction in result.transactions) {
      final amount = (transaction['amount'] ?? 0).toDouble();
      final category = transaction['primary_category'] ?? 'Other';
      final merchant = transaction['clean_name'] ?? 'Unknown';
      final isRecurring = transaction['is_recurring'] ?? false;

      // Track spending vs income
      if (amount > 0) {
        totalSpending += amount;
      } else {
        totalIncome += amount.abs();
      }

      // Track categories
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount.abs();

      // Track merchants
      merchantFrequency[merchant] = (merchantFrequency[merchant] ?? 0) + 1;

      // Count recurring
      if (isRecurring) recurringCount++;
    }

    // Sort and get top categories/merchants
    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topMerchants = merchantFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return TransactionInsights(
      totalSpending: totalSpending,
      totalIncome: totalIncome,
      topCategories: topCategories.take(5).toList(),
      topMerchants: topMerchants.take(5).toList(),
      recurringTransactions: recurringCount,
      averageTransaction: totalSpending / result.transactions.length,
    );
  }

  // Prefetch next page for smooth scrolling
  Future<void> prefetchNextPage({
    required int currentPage,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? merchantName,
    double? minAmount,
    double? maxAmount,
  }) async {
    // Prefetch in background
    getTransactions(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
      category: category,
      merchantName: merchantName,
      minAmount: minAmount,
      maxAmount: maxAmount,
      page: currentPage + 1,
    ).then((_) {
      debugPrint('Prefetched page ${currentPage + 1}');
    }).catchError((e) {
      debugPrint('Prefetch error: $e');
    });
  }

  // Clear cache
  void clearCache() {
    _cache.clear();
    debugPrint('Transaction cache cleared');
  }

  // Cache management helpers
  String _createCacheKey({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? merchantName,
    double? minAmount,
    double? maxAmount,
    required int page,
    required int pageSize,
  }) {
    return [
      accountId ?? 'all',
      startDate?.millisecondsSinceEpoch ?? 'null',
      endDate?.millisecondsSinceEpoch ?? 'null',
      category ?? 'null',
      merchantName ?? 'null',
      minAmount ?? 'null',
      maxAmount ?? 'null',
      page,
      pageSize,
    ].join(':');
  }

  TransactionPageResult? _getFromCache(String key) {
    final cached = _cache[key];
    if (cached == null) return null;

    if (DateTime.now().difference(cached.timestamp) > _cacheTimeout) {
      _cache.remove(key);
      return null;
    }

    return cached.data;
  }

  void _addToCache(String key, TransactionPageResult data) {
    _cache[key] = CachedTransactionData(
      data: data,
      timestamp: DateTime.now(),
    );

    // Clean old cache entries
    _cleanCache();
  }

  void _cleanCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) {
      return now.difference(value.timestamp) > _cacheTimeout;
    });
  }

  void dispose() {
    _transactionStreamController.close();
  }
}

// Data models
class TransactionPageResult {
  final List<Map<String, dynamic>> transactions;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final int pageSize;
  final bool isCached;

  TransactionPageResult({
    required this.transactions,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    required this.pageSize,
    required this.isCached,
  });
}

class CachedTransactionData {
  final TransactionPageResult data;
  final DateTime timestamp;

  CachedTransactionData({
    required this.data,
    required this.timestamp,
  });
}

class TransactionInsights {
  final double totalSpending;
  final double totalIncome;
  final List<MapEntry<String, double>> topCategories;
  final List<MapEntry<String, int>> topMerchants;
  final int recurringTransactions;
  final double averageTransaction;

  TransactionInsights({
    required this.totalSpending,
    required this.totalIncome,
    required this.topCategories,
    required this.topMerchants,
    required this.recurringTransactions,
    required this.averageTransaction,
  });

  factory TransactionInsights.empty() => TransactionInsights(
    totalSpending: 0,
    totalIncome: 0,
    topCategories: [],
    topMerchants: [],
    recurringTransactions: 0,
    averageTransaction: 0,
  );
}