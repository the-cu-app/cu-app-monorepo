import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class TransfersService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Process internal transfer
  Future<Map<String, dynamic>> processInternalTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? memo,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Validate accounts belong to user
    final fromAccount = await _validateAccountOwnership(fromAccountId, user.id);
    final toAccount = await _validateAccountOwnership(toAccountId, user.id);

    if (fromAccount == null || toAccount == null) {
      throw Exception('Invalid account');
    }

    // Check sufficient funds
    if ((fromAccount['balance'] ?? 0.0) < amount) {
      throw Exception('Insufficient funds');
    }

    // Create transfer record
    final transfer = {
      'user_id': user.id,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'amount': amount,
      'type': 'internal_transfer',
      'memo': memo,
      'status': 'completed',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response =
        await _supabase.from('transfers').insert(transfer).select().single();

    // Update account balances
    await _updateAccountBalance(fromAccountId, -amount);
    await _updateAccountBalance(toAccountId, amount);

    // Create transaction records
    await _createTransferTransactions(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      memo: memo,
    );

    return response;
  }

  // Process external transfer
  Future<Map<String, dynamic>> processExternalTransfer({
    required String fromAccountId,
    required String externalAccountNumber,
    required String externalRoutingNumber,
    required String externalBankName,
    required double amount,
    String? memo,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Validate account ownership
    final fromAccount = await _validateAccountOwnership(fromAccountId, user.id);
    if (fromAccount == null) {
      throw Exception('Invalid account');
    }

    // Check sufficient funds
    if ((fromAccount['balance'] ?? 0.0) < amount) {
      throw Exception('Insufficient funds');
    }

    // Create external transfer record
    final transfer = {
      'user_id': user.id,
      'from_account_id': fromAccountId,
      'external_account_number': externalAccountNumber,
      'external_routing_number': externalRoutingNumber,
      'external_bank_name': externalBankName,
      'amount': amount,
      'type': 'external_transfer',
      'memo': memo,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response =
        await _supabase.from('transfers').insert(transfer).select().single();

    // Update account balance
    await _updateAccountBalance(fromAccountId, -amount);

    // Create transaction record
    await _supabase.from(SupabaseConfig.transactionsTable).insert({
      'user_id': user.id,
      'account_id': fromAccountId,
      'description': 'External Transfer to $externalBankName',
      'amount': amount,
      'type': 'debit',
      'category': 'Transfer',
      'merchant': externalBankName,
      'reference': memo,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    return response;
  }

  // Get transfer history
  Future<List<Map<String, dynamic>>> getTransferHistory({
    String? accountId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    var queryBuilder =
        _supabase.from('transfers').select().eq('user_id', user.id);

    if (accountId != null) {
      queryBuilder = queryBuilder
          .or('from_account_id.eq.$accountId,to_account_id.eq.$accountId');
    }

    if (type != null) {
      queryBuilder = queryBuilder.eq('type', type);
    }

    if (startDate != null) {
      queryBuilder =
          queryBuilder.gte('created_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      queryBuilder = queryBuilder.lte('created_at', endDate.toIso8601String());
    }

    final response = await queryBuilder.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Validate account ownership
  Future<Map<String, dynamic>?> _validateAccountOwnership(
    String accountId,
    String userId,
  ) async {
    final response = await _supabase
        .from(SupabaseConfig.accountsTable)
        .select()
        .eq('id', accountId)
        .eq('user_id', userId)
        .single();

    return response;
  }

  // Update account balance
  Future<void> _updateAccountBalance(String accountId, double amount) async {
    final account = await _supabase
        .from(SupabaseConfig.accountsTable)
        .select('balance')
        .eq('id', accountId)
        .single();

    if (account != null) {
      final currentBalance = account['balance'] ?? 0.0;
      final newBalance = currentBalance + amount;

      await _supabase.from(SupabaseConfig.accountsTable).update({
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', accountId);
    }
  }

  // Create transfer transaction records
  Future<void> _createTransferTransactions({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? memo,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Debit from source account
    await _supabase.from(SupabaseConfig.transactionsTable).insert({
      'user_id': user.id,
      'account_id': fromAccountId,
      'description': 'Transfer to Account',
      'amount': amount,
      'type': 'debit',
      'category': 'Transfer',
      'merchant': 'Internal Transfer',
      'reference': memo,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Credit to destination account
    await _supabase.from(SupabaseConfig.transactionsTable).insert({
      'user_id': user.id,
      'account_id': toAccountId,
      'description': 'Transfer from Account',
      'amount': amount,
      'type': 'credit',
      'category': 'Transfer',
      'merchant': 'Internal Transfer',
      'reference': memo,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Process Zelle transfer
  Future<Map<String, dynamic>> processZelleTransfer({
    required String fromAccountId,
    required String recipientEmail,
    required String recipientName,
    required double amount,
    String? memo,
    String? recipientId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Validate account ownership
    final fromAccount = await _validateAccountOwnership(fromAccountId, user.id);
    if (fromAccount == null) {
      throw Exception('Invalid account');
    }

    // Check sufficient funds
    if ((fromAccount['balance'] ?? 0.0) < amount) {
      throw Exception('Insufficient funds');
    }

    // Check daily limit
    final todayTotal = await _getDailyZelleTotal(user.id);
    final limits = getTransferLimits()['zelle_transfer'];
    if (todayTotal + amount > limits['daily_limit']) {
      throw Exception(
          'Daily limit exceeded. You can send up to \$${limits['daily_limit']} per day.');
    }

    // Create Zelle transfer record
    final transfer = {
      'user_id': user.id,
      'from_account_id': fromAccountId,
      'recipient_email': recipientEmail,
      'recipient_name': recipientName,
      'recipient_id': recipientId,
      'amount': amount,
      'type': 'zelle_transfer',
      'memo': memo,
      'status': 'completed',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response =
        await _supabase.from('transfers').insert(transfer).select().single();

    // Update account balance
    await _updateAccountBalance(fromAccountId, -amount);

    // Create transaction record
    await _supabase.from(SupabaseConfig.transactionsTable).insert({
      'user_id': user.id,
      'account_id': fromAccountId,
      'description': 'Zelle to $recipientName',
      'amount': amount,
      'type': 'debit',
      'category': 'Transfer',
      'merchant': 'Zelle',
      'reference': memo,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Send push notification (in production)
    // await _sendTransferNotification(recipientEmail, amount, user.email);

    return response;
  }

  // Get daily Zelle total
  Future<double> _getDailyZelleTotal(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final response = await _supabase
        .from('transfers')
        .select('amount')
        .eq('user_id', userId)
        .eq('type', 'zelle_transfer')
        .gte('created_at', startOfDay.toIso8601String());

    double total = 0;
    for (final transfer in response) {
      total += transfer['amount'] ?? 0.0;
    }

    return total;
  }

  // Get transfer limits
  Map<String, dynamic> getTransferLimits() {
    return {
      'internal_transfer': {
        'daily_limit': 10000.0,
        'monthly_limit': 50000.0,
        'min_amount': 0.01,
        'max_amount': 10000.0,
      },
      'external_transfer': {
        'daily_limit': 5000.0,
        'monthly_limit': 25000.0,
        'min_amount': 0.01,
        'max_amount': 5000.0,
      },
      'zelle_transfer': {
        'daily_limit': 2000.0,
        'monthly_limit': 10000.0,
        'min_amount': 0.01,
        'max_amount': 2000.0,
      },
    };
  }
}
