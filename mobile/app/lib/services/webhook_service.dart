import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'plaid_service.dart';
import 'transaction_service.dart';

class WebhookService {
  static final WebhookService _instance = WebhookService._internal();
  factory WebhookService() => _instance;
  WebhookService._internal();

  final PlaidService _plaidService = PlaidService();
  final TransactionService _transactionService = TransactionService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Stream controllers for real-time updates
  final _accountUpdateController = StreamController<AccountUpdate>.broadcast();
  final _transactionUpdateController = StreamController<TransactionUpdate>.broadcast();
  final _transferUpdateController = StreamController<TransferUpdate>.broadcast();
  final _errorController = StreamController<WebhookError>.broadcast();
  
  // Streams
  Stream<AccountUpdate> get accountUpdates => _accountUpdateController.stream;
  Stream<TransactionUpdate> get transactionUpdates => _transactionUpdateController.stream;
  Stream<TransferUpdate> get transferUpdates => _transferUpdateController.stream;
  Stream<WebhookError> get errors => _errorController.stream;
  
  // WebSocket connection
  RealtimeChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  
  // Webhook URL
  static const String _webhookBaseUrl = 'https://vsduehkavltenthprjwe.supabase.co/functions/v1/plaid-webhook';

  // Initialize webhook service
  Future<void> initialize() async {
    try {
      // Register webhook with Plaid if we have an access token
      if (_plaidService.hasLinkedAccounts) {
        await registerWebhook();
      }
      
      // Set up real-time listener
      _setupRealtimeListener();
      
      debugPrint('Webhook service initialized');
    } catch (e) {
      debugPrint('Failed to initialize webhook service: $e');
      _errorController.add(WebhookError(
        type: ErrorType.initialization,
        message: 'Failed to initialize webhook service',
        details: e.toString(),
      ));
    }
  }

  // Register webhook with Plaid
  Future<void> registerWebhook() async {
    try {
      final accessToken = _plaidService.accessToken;
      if (accessToken == null) return;
      
      final response = await http.post(
        Uri.parse('https://vsduehkavltenthprjwe.supabase.co/functions/v1/plaid-webhook-register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accessToken': accessToken,
          'webhookUrl': _webhookBaseUrl,
        }),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Webhook registered successfully');
      } else {
        throw Exception('Failed to register webhook: ${response.body}');
      }
    } catch (e) {
      debugPrint('Webhook registration error: $e');
      _errorController.add(WebhookError(
        type: ErrorType.registration,
        message: 'Failed to register webhook',
        details: e.toString(),
      ));
    }
  }

  // Set up real-time listener for webhook events
  void _setupRealtimeListener() {
    // Subscribe to webhook events
    _channel = _supabase
        .channel('webhook_events')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'webhook_logs',
          callback: (payload) {
            _handleWebhookEvent(payload.newRecord);
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            _isConnected = true;
            debugPrint('Connected to real-time webhook updates');
          } else if (status == RealtimeSubscribeStatus.closed) {
            _isConnected = false;
            _scheduleReconnect();
          }
        });
  }

  // Handle webhook event from database
  void _handleWebhookEvent(Map<String, dynamic> event) {
    try {
      final webhookType = event['webhook_type'] as String?;
      final payload = event['payload'] as Map<String, dynamic>?;
      
      if (webhookType == null || payload == null) return;
      
      switch (webhookType) {
        // Transaction updates
        case 'TRANSACTIONS_INITIAL_UPDATE':
        case 'TRANSACTIONS_HISTORICAL_UPDATE':
        case 'TRANSACTIONS_DEFAULT_UPDATE':
          _handleTransactionUpdate(payload);
          break;
          
        // Account updates
        case 'ACCOUNTS_UPDATE':
          _handleAccountUpdate(payload);
          break;
          
        // Transfer updates
        case 'TRANSFER_CREATED':
        case 'TRANSFER_SETTLED':
        case 'TRANSFER_FAILED':
          _handleTransferUpdate(payload, webhookType);
          break;
          
        // Error handling
        case 'ITEM_ERROR':
          _handleItemError(payload);
          break;
          
        default:
          debugPrint('Unhandled webhook type: $webhookType');
      }
    } catch (e) {
      debugPrint('Error handling webhook event: $e');
    }
  }

  // Handle transaction updates
  void _handleTransactionUpdate(Map<String, dynamic> payload) {
    final itemId = payload['item_id'] as String?;
    final newTransactions = payload['new_transactions'] as int? ?? 0;
    final removedTransactions = payload['removed_transactions'] as List<dynamic>? ?? [];
    
    // Clear transaction cache
    _transactionService.clearCache();
    
    // Emit update event
    _transactionUpdateController.add(TransactionUpdate(
      itemId: itemId ?? '',
      newCount: newTransactions,
      removedIds: removedTransactions.cast<String>(),
      timestamp: DateTime.now(),
    ));
  }

  // Handle account updates
  void _handleAccountUpdate(Map<String, dynamic> payload) {
    final itemId = payload['item_id'] as String?;
    
    // Emit update event
    _accountUpdateController.add(AccountUpdate(
      itemId: itemId ?? '',
      timestamp: DateTime.now(),
    ));
  }

  // Handle transfer updates
  void _handleTransferUpdate(Map<String, dynamic> payload, String webhookType) {
    final transferId = payload['transfer_id'] as String?;
    final status = webhookType.split('_').last.toLowerCase();
    
    _transferUpdateController.add(TransferUpdate(
      transferId: transferId ?? '',
      status: status,
      timestamp: DateTime.now(),
    ));
  }

  // Handle item errors
  void _handleItemError(Map<String, dynamic> payload) {
    final error = payload['error'] as Map<String, dynamic>?;
    if (error == null) return;
    
    _errorController.add(WebhookError(
      type: ErrorType.plaidError,
      message: error['error_message'] ?? 'Unknown error',
      code: error['error_code'],
      details: error['error_type'],
    ));
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        debugPrint('Attempting to reconnect to webhook service...');
        _setupRealtimeListener();
      }
    });
  }

  // Manual refresh trigger
  Future<void> refreshData() async {
    try {
      // Clear all caches
      _transactionService.clearCache();
      
      // Emit refresh events
      _accountUpdateController.add(AccountUpdate(
        itemId: 'manual_refresh',
        timestamp: DateTime.now(),
      ));
      
      _transactionUpdateController.add(TransactionUpdate(
        itemId: 'manual_refresh',
        newCount: 0,
        removedIds: [],
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Manual refresh error: $e');
    }
  }

  // Subscribe to specific updates
  StreamSubscription<T> subscribe<T>({
    required Stream<T> stream,
    required void Function(T) onData,
    Function? onError,
    void Function()? onDone,
  }) {
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: false,
    );
  }

  // Clean up
  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.unsubscribe();
    _accountUpdateController.close();
    _transactionUpdateController.close();
    _transferUpdateController.close();
    _errorController.close();
  }
}

// Update models
class AccountUpdate {
  final String itemId;
  final DateTime timestamp;

  AccountUpdate({
    required this.itemId,
    required this.timestamp,
  });
}

class TransactionUpdate {
  final String itemId;
  final int newCount;
  final List<String> removedIds;
  final DateTime timestamp;

  TransactionUpdate({
    required this.itemId,
    required this.newCount,
    required this.removedIds,
    required this.timestamp,
  });
}

class TransferUpdate {
  final String transferId;
  final String status;
  final DateTime timestamp;

  TransferUpdate({
    required this.transferId,
    required this.status,
    required this.timestamp,
  });
}

class WebhookError {
  final ErrorType type;
  final String message;
  final String? code;
  final String? details;

  WebhookError({
    required this.type,
    required this.message,
    this.code,
    this.details,
  });
}

enum ErrorType {
  initialization,
  registration,
  plaidError,
  networkError,
  unknown,
}