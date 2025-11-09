import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zelle_model.dart';
import '../config/supabase_config.dart';
import 'package:uuid/uuid.dart';
import '../config/cu_config_service.dart';

class ZelleService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const _uuid = Uuid();

  // Get enrolled Zelle recipients
  Future<List<ZelleRecipient>> getEnrolledRecipients() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('zelle_recipients')
          .select()
          .eq('user_id', user.id)
          .eq('is_enrolled', true)
          .order('name');

      return (response as List)
          .map((json) => ZelleRecipient.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting enrolled recipients: $e');
      return [];
    }
  }

  // Get all recipients (including contacts)
  Future<List<ZelleRecipient>> getAllRecipients() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('zelle_recipients')
          .select()
          .eq('user_id', user.id)
          .order('is_favorite', ascending: false)
          .order('name');

      return (response as List)
          .map((json) => ZelleRecipient.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting recipients: $e');
      return [];
    }
  }

  // Get favorite recipients
  Future<List<ZelleRecipient>> getFavoriteRecipients() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('zelle_recipients')
          .select()
          .eq('user_id', user.id)
          .eq('is_favorite', true)
          .order('name');

      return (response as List)
          .map((json) => ZelleRecipient.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting favorite recipients: $e');
      return [];
    }
  }

  // Get recent recipients
  Future<List<ZelleRecipient>> getRecentRecipients({int limit = 10}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('zelle_recipients')
          .select()
          .eq('user_id', user.id)
          .not('last_payment_date', 'is', null)
          .order('last_payment_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ZelleRecipient.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting recent recipients: $e');
      return [];
    }
  }

  // Add new recipient
  Future<ZelleRecipient?> addRecipient({
    required String name,
    required String email,
    String? phone,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // Check if recipient already exists
      final existing = await _supabase
          .from('zelle_recipients')
          .select()
          .eq('user_id', user.id)
          .eq('email', email)
          .single();

      if (existing != null) {
        // Update existing recipient
        await _supabase
            .from('zelle_recipients')
            .update({
              'name': name,
              'phone': phone,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
        
        return ZelleRecipient.fromJson(existing);
      }

      // Create new recipient
      final recipientData = {
        'id': _uuid.v4(),
        'user_id': user.id,
        'name': name,
        'email': email,
        'phone': phone,
        'is_enrolled': await _checkZelleEnrollment(email),
        'is_favorite': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('zelle_recipients')
          .insert(recipientData)
          .select()
          .single();

      return ZelleRecipient.fromJson(response);
    } catch (e) {
      print('Error adding recipient: $e');
      return null;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String recipientId) async {
    try {
      final response = await _supabase
          .from('zelle_recipients')
          .select('is_favorite')
          .eq('id', recipientId)
          .single();

      final currentStatus = response['is_favorite'] ?? false;

      await _supabase
          .from('zelle_recipients')
          .update({
            'is_favorite': !currentStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recipientId);

      return true;
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  // Send money via Zelle
  Future<ZelleTransaction?> sendMoney({
    required String recipientId,
    required String fromAccountId,
    required double amount,
    String? memo,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // Get recipient details
      final recipient = await _supabase
          .from('zelle_recipients')
          .select()
          .eq('id', recipientId)
          .single();

      if (recipient == null) throw Exception('Recipient not found');

      // Create transaction
      final transactionData = {
        'id': _uuid.v4(),
        'sender_id': user.id,
        'sender_name': user.email ?? 'You',
        'recipient_id': recipientId,
        'recipient_name': recipient['name'],
        'amount': amount,
        'memo': memo,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'completed',
        'type': 'sent',
        'from_account_id': fromAccountId,
      };

      final response = await _supabase
          .from('zelle_transactions')
          .insert(transactionData)
          .select()
          .single();

      // Update recipient's last payment info
      await _supabase
          .from('zelle_recipients')
          .update({
            'last_payment_date': DateTime.now().toIso8601String(),
            'last_payment_amount': amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recipientId);

      // Update account balance (handled by transfers service)
      
      return ZelleTransaction.fromJson(response);
    } catch (e) {
      print('Error sending money: $e');
      return null;
    }
  }

  // Request money
  Future<ZellePaymentRequest?> requestMoney({
    required String recipientId,
    required double amount,
    String? memo,
    int expirationDays = 7,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final requestData = {
        'id': _uuid.v4(),
        'requester_id': user.id,
        'requester_name': user.email ?? 'User',
        'requester_email': user.email,
        'recipient_id': recipientId,
        'amount': amount,
        'memo': memo,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now()
            .add(Duration(days: expirationDays))
            .toIso8601String(),
        'status': 'pending',
      };

      final response = await _supabase
          .from('zelle_payment_requests')
          .insert(requestData)
          .select()
          .single();

      return ZellePaymentRequest.fromJson(response);
    } catch (e) {
      print('Error requesting money: $e');
      return null;
    }
  }

  // Get payment requests
  Future<List<ZellePaymentRequest>> getPaymentRequests({
    bool sent = true,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final query = sent
          ? _supabase
              .from('zelle_payment_requests')
              .select()
              .eq('requester_id', user.id)
          : _supabase
              .from('zelle_payment_requests')
              .select()
              .eq('recipient_id', user.id);

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => ZellePaymentRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting payment requests: $e');
      return [];
    }
  }

  // Accept payment request
  Future<bool> acceptPaymentRequest({
    required String requestId,
    required String fromAccountId,
  }) async {
    try {
      // Get request details
      final request = await _supabase
          .from('zelle_payment_requests')
          .select()
          .eq('id', requestId)
          .single();

      if (request == null) return false;

      // Update request status
      await _supabase
          .from('zelle_payment_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      // Process the payment
      await sendMoney(
        recipientId: request['requester_id'],
        fromAccountId: fromAccountId,
        amount: request['amount'].toDouble(),
        memo: request['memo'],
      );

      return true;
    } catch (e) {
      print('Error accepting payment request: $e');
      return false;
    }
  }

  // Decline payment request
  Future<bool> declinePaymentRequest(String requestId) async {
    try {
      await _supabase
          .from('zelle_payment_requests')
          .update({'status': 'declined'})
          .eq('id', requestId);

      return true;
    } catch (e) {
      print('Error declining payment request: $e');
      return false;
    }
  }

  // Get transaction history
  Future<List<ZelleTransaction>> getTransactionHistory({
    int limit = 50,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('zelle_transactions')
          .select()
          .or('sender_id.eq.${user.id},recipient_id.eq.${user.id}')
          .order('timestamp', ascending: false)
          .limit(limit);

      return (response as List).map((json) {
        // Determine if this is a sent or received transaction
        final transaction = ZelleTransaction.fromJson(json);
        if (json['recipient_id'] == user.id && json['type'] == 'sent') {
          // Update type for received transactions
          json['type'] = 'received';
          return ZelleTransaction.fromJson(json);
        }
        return transaction;
      }).toList();
    } catch (e) {
      print('Error getting transaction history: $e');
      return [];
    }
  }

  // Create recurring payment
  Future<ZelleRecurringPayment?> createRecurringPayment({
    required String recipientId,
    required double amount,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    String? memo,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // Get recipient details
      final recipient = await _supabase
          .from('zelle_recipients')
          .select()
          .eq('id', recipientId)
          .single();

      if (recipient == null) throw Exception('Recipient not found');

      final recurringData = {
        'id': _uuid.v4(),
        'user_id': user.id,
        'recipient_id': recipientId,
        'recipient_name': recipient['name'],
        'amount': amount,
        'frequency': frequency,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'memo': memo,
        'is_active': true,
        'next_execution_date': _calculateNextExecutionDate(startDate, frequency),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('zelle_recurring_payments')
          .insert(recurringData)
          .select()
          .single();

      return ZelleRecurringPayment.fromJson(response);
    } catch (e) {
      print('Error creating recurring payment: $e');
      return null;
    }
  }

  // Get recurring payments
  Future<List<ZelleRecurringPayment>> getRecurringPayments() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('zelle_recurring_payments')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ZelleRecurringPayment.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting recurring payments: $e');
      return [];
    }
  }

  // Cancel recurring payment
  Future<bool> cancelRecurringPayment(String paymentId) async {
    try {
      await _supabase
          .from('zelle_recurring_payments')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);

      return true;
    } catch (e) {
      print('Error canceling recurring payment: $e');
      return false;
    }
  }

  // Split bill
  Future<List<ZellePaymentRequest>> splitBill({
    required List<String> recipientIds,
    required double totalAmount,
    String? memo,
    bool equalSplit = true,
    Map<String, double>? customAmounts,
  }) async {
    final requests = <ZellePaymentRequest>[];
    
    try {
      if (equalSplit) {
        final amountPerPerson = totalAmount / recipientIds.length;
        
        for (final recipientId in recipientIds) {
          final request = await requestMoney(
            recipientId: recipientId,
            amount: amountPerPerson,
            memo: '${memo ?? 'Split bill'} - \$${amountPerPerson.toStringAsFixed(2)} each',
          );
          
          if (request != null) {
            requests.add(request);
          }
        }
      } else if (customAmounts != null) {
        for (final entry in customAmounts.entries) {
          final request = await requestMoney(
            recipientId: entry.key,
            amount: entry.value,
            memo: '${memo ?? 'Split bill'} - Your share: \$${entry.value.toStringAsFixed(2)}',
          );
          
          if (request != null) {
            requests.add(request);
          }
        }
      }
      
      return requests;
    } catch (e) {
      print('Error splitting bill: $e');
      return [];
    }
  }

  // Import contacts from phone
  Future<List<ZelleRecipient>> importContacts() async {
    try {
      // Request contacts permission
      final status = await Permission.contacts.request();
      
      if (!status.isGranted) {
        throw Exception('Contacts permission not granted');
      }

      // In a real app, you would use contacts_service package
      // For demo, return mock data
      return [
        ZelleRecipient(
          id: _uuid.v4(),
          name: 'John Smith',
          email: 'test.john.smith@${CUConfigService().cuDomain}',
          phone: '+1234567890',
          isEnrolled: true,
        ),
        ZelleRecipient(
          id: _uuid.v4(),
          name: 'Jane Doe',
          email: 'test.jane.doe@${CUConfigService().cuDomain}',
          phone: '+0987654321',
          isEnrolled: false,
        ),
      ];
    } catch (e) {
      print('Error importing contacts: $e');
      return [];
    }
  }

  // Check if email/phone is enrolled in Zelle
  Future<bool> _checkZelleEnrollment(String emailOrPhone) async {
    // In a real implementation, this would check with Zelle's API
    // For demo purposes, return random enrollment status
    return DateTime.now().millisecond % 2 == 0;
  }

  // Calculate next execution date for recurring payments
  String _calculateNextExecutionDate(DateTime startDate, String frequency) {
    DateTime nextDate;
    
    switch (frequency) {
      case 'weekly':
        nextDate = startDate.add(const Duration(days: 7));
        break;
      case 'biweekly':
        nextDate = startDate.add(const Duration(days: 14));
        break;
      case 'monthly':
        nextDate = DateTime(
          startDate.year,
          startDate.month + 1,
          startDate.day,
        );
        break;
      default:
        nextDate = startDate.add(const Duration(days: 30));
    }
    
    return nextDate.toIso8601String();
  }

  // Get Zelle limits
  Map<String, dynamic> getZelleLimits() {
    return {
      'daily_limit': 2000.0,
      'weekly_limit': 10000.0,
      'monthly_limit': 10000.0,
      'min_amount': 1.0,
      'max_amount': 2000.0,
      'request_expiration_days': 7,
    };
  }

  // Verify recipient before sending
  Future<Map<String, dynamic>> verifyRecipient(String recipientId) async {
    try {
      final recipient = await _supabase
          .from('zelle_recipients')
          .select()
          .eq('id', recipientId)
          .single();

      if (recipient == null) {
        return {
          'verified': false,
          'message': 'Recipient not found',
        };
      }

      // Check if enrolled in Zelle
      if (!recipient['is_enrolled']) {
        return {
          'verified': true,
          'warning': 'This recipient is not enrolled in Zelle. They will receive an invitation to enroll.',
          'recipient': ZelleRecipient.fromJson(recipient),
        };
      }

      return {
        'verified': true,
        'recipient': ZelleRecipient.fromJson(recipient),
      };
    } catch (e) {
      return {
        'verified': false,
        'message': 'Error verifying recipient',
      };
    }
  }
}