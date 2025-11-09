import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseRealtimeService {
  static final SupabaseRealtimeService _instance = SupabaseRealtimeService._internal();
  factory SupabaseRealtimeService() => _instance;
  SupabaseRealtimeService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream controllers for real-time data
  final _accountsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _transactionsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _balanceController = StreamController<double>.broadcast();

  // Subscription tracking
  RealtimeChannel? _accountsChannel;
  RealtimeChannel? _transactionsChannel;

  bool _isInitialized = false;

  // Getters for streams
  Stream<List<Map<String, dynamic>>> get accountsStream => _accountsController.stream;
  Stream<List<Map<String, dynamic>>> get transactionsStream => _transactionsController.stream;
  Stream<double> get balanceStream => _balanceController.stream;

  // Initialize real-time subscriptions
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing Supabase real-time subscriptions...');

      // Subscribe to accounts table changes
      _subscribeToAccounts();

      // Subscribe to transactions table changes
      _subscribeToTransactions();

      _isInitialized = true;
      debugPrint('Supabase real-time service initialized');
    } catch (e) {
      debugPrint('Error initializing Supabase real-time: $e');
    }
  }

  // Subscribe to accounts table
  void _subscribeToAccounts() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('No user authenticated, skipping accounts subscription');
      return;
    }

    _accountsChannel = _supabase
        .channel('accounts-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.accountsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('Accounts change detected: ${payload.eventType}');
            _handleAccountsChange(payload);
          },
        )
        .subscribe();

    debugPrint('Subscribed to accounts table for user: $userId');
  }

  // Subscribe to transactions table
  void _subscribeToTransactions() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('No user authenticated, skipping transactions subscription');
      return;
    }

    _transactionsChannel = _supabase
        .channel('transactions-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.transactionsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('Transactions change detected: ${payload.eventType}');
            _handleTransactionsChange(payload);
          },
        )
        .subscribe();

    debugPrint('Subscribed to transactions table for user: $userId');
  }

  // Handle accounts table changes
  void _handleAccountsChange(PostgresChangePayload payload) async {
    try {
      // Fetch updated accounts data
      final accounts = await fetchAccounts();
      _accountsController.add(accounts);

      // Calculate and broadcast new total balance
      final totalBalance = accounts.fold<double>(
        0.0,
        (sum, account) => sum + ((account['balance'] ?? 0.0) as num).toDouble(),
      );
      _balanceController.add(totalBalance);

      debugPrint('Broadcasted ${accounts.length} accounts, total balance: \$${totalBalance.toStringAsFixed(2)}');
    } catch (e) {
      debugPrint('Error handling accounts change: $e');
    }
  }

  // Handle transactions table changes
  void _handleTransactionsChange(PostgresChangePayload payload) async {
    try {
      // Fetch updated transactions data
      final transactions = await fetchTransactions();
      _transactionsController.add(transactions);

      debugPrint('Broadcasted ${transactions.length} transactions');
    } catch (e) {
      debugPrint('Error handling transactions change: $e');
    }
  }

  // Fetch accounts from Supabase
  Future<List<Map<String, dynamic>>> fetchAccounts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from(SupabaseConfig.accountsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching accounts: $e');
      return [];
    }
  }

  // Fetch transactions from Supabase
  Future<List<Map<String, dynamic>>> fetchTransactions({int limit = 50}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from(SupabaseConfig.transactionsTable)
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      return [];
    }
  }

  // Manually trigger data refresh
  Future<void> refresh() async {
    try {
      debugPrint('Manually refreshing real-time data...');

      // Fetch and broadcast accounts
      final accounts = await fetchAccounts();
      _accountsController.add(accounts);

      // Calculate and broadcast balance
      final totalBalance = accounts.fold<double>(
        0.0,
        (sum, account) => sum + ((account['balance'] ?? 0.0) as num).toDouble(),
      );
      _balanceController.add(totalBalance);

      // Fetch and broadcast transactions
      final transactions = await fetchTransactions();
      _transactionsController.add(transactions);

      debugPrint('Manual refresh completed');
    } catch (e) {
      debugPrint('Error during manual refresh: $e');
    }
  }

  // Unsubscribe from all channels
  Future<void> dispose() async {
    try {
      if (_accountsChannel != null) {
        await _supabase.removeChannel(_accountsChannel!);
        _accountsChannel = null;
      }

      if (_transactionsChannel != null) {
        await _supabase.removeChannel(_transactionsChannel!);
        _transactionsChannel = null;
      }

      await _accountsController.close();
      await _transactionsController.close();
      await _balanceController.close();

      _isInitialized = false;
      debugPrint('Supabase real-time service disposed');
    } catch (e) {
      debugPrint('Error disposing real-time service: $e');
    }
  }

  // Sync Plaid data to Supabase
  Future<void> syncPlaidToSupabase({
    required List<Map<String, dynamic>> accounts,
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('No user authenticated, cannot sync to Supabase');
        return;
      }

      debugPrint('Syncing ${accounts.length} accounts and ${transactions.length} transactions to Supabase...');

      // Sync accounts
      for (final account in accounts) {
        final accountData = {
          'user_id': userId,
          'account_id': account['account_id'] ?? account['id'],
          'name': account['name'],
          'type': account['type'],
          'subtype': account['subtype'],
          'balance': account['balance'],
          'available': account['available'],
          'currency': account['currency'] ?? 'USD',
          'mask': account['mask'],
          'institution': account['institution'],
          'is_primary': account['is_primary'] ?? false,
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Upsert account (insert or update)
        await _supabase
            .from(SupabaseConfig.accountsTable)
            .upsert(accountData, onConflict: 'account_id');
      }

      // Sync transactions
      for (final transaction in transactions) {
        final transactionData = {
          'user_id': userId,
          'transaction_id': transaction['transaction_id'] ?? transaction['id'],
          'account_id': transaction['account_id'],
          'amount': transaction['amount'],
          'name': transaction['name'],
          'merchant_name': transaction['merchant_name'],
          'category': transaction['category'],
          'date': transaction['date'],
          'pending': transaction['pending'] ?? false,
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Upsert transaction (insert or update)
        await _supabase
            .from(SupabaseConfig.transactionsTable)
            .upsert(transactionData, onConflict: 'transaction_id');
      }

      debugPrint('Successfully synced Plaid data to Supabase');

      // Trigger refresh to broadcast updated data
      await refresh();
    } catch (e) {
      debugPrint('Error syncing Plaid data to Supabase: $e');
    }
  }
}
