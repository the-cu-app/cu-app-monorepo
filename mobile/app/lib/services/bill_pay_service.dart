import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class BillPayService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get user payees
  Future<List<Map<String, dynamic>>> getUserPayees() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from(SupabaseConfig.payeesTable)
        .select()
        .eq('user_id', user.id)
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Add new payee
  Future<Map<String, dynamic>> addPayee({
    required String name,
    required String accountNumber,
    required String routingNumber,
    String? address,
    String? phone,
    String? email,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final payee = {
      'user_id': user.id,
      'name': name,
      'account_number': accountNumber,
      'routing_number': routingNumber,
      'address': address,
      'phone': phone,
      'email': email,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from(SupabaseConfig.payeesTable)
        .insert(payee)
        .select()
        .single();

    return response;
  }

  // Update payee
  Future<void> updatePayee(
    String payeeId, {
    String? name,
    String? accountNumber,
    String? routingNumber,
    String? address,
    String? phone,
    String? email,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (accountNumber != null) updates['account_number'] = accountNumber;
    if (routingNumber != null) updates['routing_number'] = routingNumber;
    if (address != null) updates['address'] = address;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;

    await _supabase
        .from(SupabaseConfig.payeesTable)
        .update(updates)
        .eq('id', payeeId);
  }

  // Delete payee
  Future<void> deletePayee(String payeeId) async {
    await _supabase.from(SupabaseConfig.payeesTable).delete().eq('id', payeeId);
  }

  // Get scheduled payments
  Future<List<Map<String, dynamic>>> getScheduledPayments() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from(SupabaseConfig.scheduledPaymentsTable)
        .select()
        .eq('user_id', user.id)
        .order('next_payment_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Schedule payment
  Future<Map<String, dynamic>> schedulePayment({
    required String payeeId,
    required String accountId,
    required double amount,
    required DateTime nextPaymentDate,
    required String frequency, // 'one-time', 'weekly', 'bi-weekly', 'monthly'
    String? memo,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final payment = {
      'user_id': user.id,
      'payee_id': payeeId,
      'account_id': accountId,
      'amount': amount,
      'next_payment_date': nextPaymentDate.toIso8601String(),
      'frequency': frequency,
      'memo': memo,
      'status': 'scheduled',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from(SupabaseConfig.scheduledPaymentsTable)
        .insert(payment)
        .select()
        .single();

    return response;
  }

  // Process scheduled payment
  Future<void> processScheduledPayment(String paymentId) async {
    final payment = await _supabase
        .from(SupabaseConfig.scheduledPaymentsTable)
        .select()
        .eq('id', paymentId)
        .single();

    if (payment == null) return;

    // Process the payment
    await _processPayment(
      payeeId: payment['payee_id'],
      accountId: payment['account_id'],
      amount: payment['amount'],
      memo: payment['memo'],
    );

    // Update next payment date based on frequency
    final nextDate = _calculateNextPaymentDate(
      DateTime.parse(payment['next_payment_date']),
      payment['frequency'],
    );

    if (nextDate != null) {
      // Update for recurring payments
      await _supabase.from(SupabaseConfig.scheduledPaymentsTable).update({
        'next_payment_date': nextDate.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentId);
    } else {
      // Delete one-time payments
      await _supabase
          .from(SupabaseConfig.scheduledPaymentsTable)
          .delete()
          .eq('id', paymentId);
    }
  }

  // Process immediate payment
  Future<void> processImmediatePayment({
    required String payeeId,
    required String accountId,
    required double amount,
    String? memo,
  }) async {
    await _processPayment(
      payeeId: payeeId,
      accountId: accountId,
      amount: amount,
      memo: memo,
    );
  }

  // Internal payment processing
  Future<void> _processPayment({
    required String payeeId,
    required String accountId,
    required double amount,
    String? memo,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Create transaction record
    await _supabase.from(SupabaseConfig.transactionsTable).insert({
      'user_id': user.id,
      'account_id': accountId,
      'description': 'Bill Payment',
      'amount': amount,
      'type': 'debit',
      'category': 'Bill Payment',
      'merchant': 'Bill Pay',
      'reference': memo,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Update account balance
    final account = await _supabase
        .from(SupabaseConfig.accountsTable)
        .select('balance')
        .eq('id', accountId)
        .single();

    if (account != null) {
      final currentBalance = account['balance'] ?? 0.0;
      final newBalance = currentBalance - amount;

      await _supabase.from(SupabaseConfig.accountsTable).update({
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', accountId);
    }
  }

  // Calculate next payment date
  DateTime? _calculateNextPaymentDate(DateTime currentDate, String frequency) {
    switch (frequency) {
      case 'weekly':
        return currentDate.add(const Duration(days: 7));
      case 'bi-weekly':
        return currentDate.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(
          currentDate.year,
          currentDate.month + 1,
          currentDate.day,
        );
      case 'one-time':
      default:
        return null;
    }
  }

  // Cancel scheduled payment
  Future<void> cancelScheduledPayment(String paymentId) async {
    await _supabase
        .from(SupabaseConfig.scheduledPaymentsTable)
        .delete()
        .eq('id', paymentId);
  }

  // Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    String? payeeId,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    var queryBuilder = _supabase
        .from(SupabaseConfig.transactionsTable)
        .select()
        .eq('user_id', user.id)
        .eq('category', 'Bill Payment');

    if (payeeId != null) {
      // This would require joining with payees table
      // For now, we'll filter by description containing payee info
    }

    if (accountId != null) {
      queryBuilder = queryBuilder.eq('account_id', accountId);
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
}
