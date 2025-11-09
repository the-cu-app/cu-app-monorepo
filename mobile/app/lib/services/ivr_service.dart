// Interactive Voice Response (IVR) Service for CU.APP
// Provides voice-based navigation and interaction for credit union members

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:text_to_speech/text_to_speech.dart' as tts;
import 'package:supabase_flutter/supabase_flutter.dart';

/// IVR Service for handling voice interactions
class IVRService {
  static final IVRService _instance = IVRService._internal();
  factory IVRService() => _instance;
  IVRService._internal();

  // Speech services
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final tts.TextToSpeech _textToSpeech = tts.TextToSpeech();

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  // State management
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  String _currentLanguage = 'en-US';

  // Stream controllers
  final StreamController<IVRCommand> _commandStream =
      StreamController<IVRCommand>.broadcast();
  final StreamController<IVRResponse> _responseStream =
      StreamController<IVRResponse>.broadcast();
  final StreamController<IVRState> _stateStream =
      StreamController<IVRState>.broadcast();

  // Current session
  IVRSession? _currentSession;
  List<IVRCommand> _commandHistory = [];

  // Getters
  Stream<IVRCommand> get commandStream => _commandStream.stream;
  Stream<IVRResponse> get responseStream => _responseStream.stream;
  Stream<IVRState> get stateStream => _stateStream.stream;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  IVRSession? get currentSession => _currentSession;

  /// Initialize the IVR service
  Future<bool> initialize() async {
    try {
      // Initialize speech-to-text
      final sttAvailable = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );

      // Initialize text-to-speech
      final ttsAvailable = await _textToSpeech.initialize();

      if (sttAvailable && ttsAvailable) {
        _isInitialized = true;
        _updateState(IVRState.ready);
        debugPrint('IVR Service initialized successfully');
        return true;
      } else {
        debugPrint('IVR Service initialization failed');
        return false;
      }
    } catch (e) {
      debugPrint('IVR Service initialization error: $e');
      return false;
    }
  }

  /// Start a new IVR session
  Future<IVRSession> startSession({
    required String userId,
    String? sessionId,
    IVRContext context = IVRContext.mainMenu,
  }) async {
    if (!_isInitialized) {
      throw IVRException('IVR Service not initialized');
    }

    final session = IVRSession(
      id: sessionId ?? _generateSessionId(),
      userId: userId,
      context: context,
      startTime: DateTime.now(),
    );

    _currentSession = session;
    _commandHistory.clear();

    // Log session start
    await _logSessionEvent(session, 'session_started');

    // Welcome message
    await speak('Welcome to your credit union. How can I help you today?');

    _updateState(IVRState.active);
    return session;
  }

  /// End the current IVR session
  Future<void> endSession() async {
    if (_currentSession == null) return;

    final session = _currentSession!;
    session.endTime = DateTime.now();

    // Log session end
    await _logSessionEvent(session, 'session_ended');

    // Stop any ongoing speech
    await stopSpeaking();
    await stopListening();

    _currentSession = null;
    _updateState(IVRState.ready);
  }

  /// Start listening for voice commands
  Future<void> startListening() async {
    if (!_isInitialized || _isListening) return;

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: _currentLanguage,
        onSoundLevelChange: _onSoundLevelChange,
      );

      _isListening = true;
      _updateState(IVRState.listening);
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      _updateState(IVRState.error);
    }
  }

  /// Stop listening for voice commands
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speechToText.stop();
    _isListening = false;
    _updateState(IVRState.active);
  }

  /// Speak text using text-to-speech
  Future<void> speak(String text,
      {IVRPriority priority = IVRPriority.normal}) async {
    if (!_isInitialized || text.isEmpty) return;

    try {
      // Stop current speech if higher priority
      if (_isSpeaking && priority == IVRPriority.high) {
        await _textToSpeech.stop();
      }

      await _textToSpeech.speak(text);
      _isSpeaking = true;

      // Log the speech
      if (_currentSession != null) {
        await _logSessionEvent(_currentSession!, 'speech_output',
            data: {'text': text});
      }

      _updateState(IVRState.speaking);
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;

    await _textToSpeech.stop();
    _isSpeaking = false;
    _updateState(IVRState.active);
  }

  /// Process a voice command
  Future<IVRResponse> processCommand(String command) async {
    if (_currentSession == null) {
      throw IVRException('No active IVR session');
    }

    final ivrCommand = IVRCommand(
      id: _generateCommandId(),
      sessionId: _currentSession!.id,
      text: command,
      timestamp: DateTime.now(),
      confidence: 1.0, // Would be provided by speech recognition
    );

    _commandHistory.add(ivrCommand);
    _commandStream.add(ivrCommand);

    // Log the command
    await _logSessionEvent(_currentSession!, 'command_received', data: {
      'command': command,
      'commandId': ivrCommand.id,
    });

    // Process the command based on current context
    final response = await _processCommandByContext(ivrCommand);

    // Log the response
    await _logSessionEvent(_currentSession!, 'response_generated', data: {
      'response': response.text,
      'responseId': response.id,
    });

    _responseStream.add(response);
    return response;
  }

  /// Navigate to a specific IVR context
  Future<void> navigateToContext(IVRContext context) async {
    if (_currentSession == null) return;

    _currentSession!.context = context;

    // Provide context-specific greeting
    final greeting = _getContextGreeting(context);
    if (greeting.isNotEmpty) {
      await speak(greeting);
    }

    await _logSessionEvent(_currentSession!, 'context_changed', data: {
      'newContext': context.name,
    });
  }

  /// Get account balance via voice
  Future<IVRResponse> getAccountBalance() async {
    if (_currentSession == null) {
      throw IVRException('No active IVR session');
    }

    try {
      // Fetch account data from Supabase
      final response = await _supabase
          .from('accounts')
          .select('account_name, balance, account_type')
          .eq('user_id', _currentSession!.userId)
          .eq('is_active', true);

      if (response.isEmpty) {
        return IVRResponse(
          id: _generateResponseId(),
          sessionId: _currentSession!.id,
          text: 'I couldn\'t find any active accounts for you.',
          type: IVRResponseType.error,
          timestamp: DateTime.now(),
        );
      }

      final accounts = response as List<Map<String, dynamic>>;
      final totalBalance = accounts.fold<double>(
          0, (sum, account) => sum + (account['balance'] as num).toDouble());

      final balanceText = _formatBalanceResponse(accounts, totalBalance);

      return IVRResponse(
        id: _generateResponseId(),
        sessionId: _currentSession!.id,
        text: balanceText,
        type: IVRResponseType.success,
        timestamp: DateTime.now(),
        data: {
          'accounts': accounts,
          'totalBalance': totalBalance,
        },
      );
    } catch (e) {
      debugPrint('Error fetching account balance: $e');
      return IVRResponse(
        id: _generateResponseId(),
        sessionId: _currentSession!.id,
        text:
            'I\'m sorry, I couldn\'t retrieve your account balance at this time.',
        type: IVRResponseType.error,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get recent transactions via voice
  Future<IVRResponse> getRecentTransactions({int limit = 5}) async {
    if (_currentSession == null) {
      throw IVRException('No active IVR session');
    }

    try {
      final response = await _supabase
          .from('transactions')
          .select('*')
          .eq('user_id', _currentSession!.userId)
          .order('date', ascending: false)
          .limit(limit);

      if (response.isEmpty) {
        return IVRResponse(
          id: _generateResponseId(),
          sessionId: _currentSession!.id,
          text: 'I couldn\'t find any recent transactions.',
          type: IVRResponseType.success,
          timestamp: DateTime.now(),
        );
      }

      final transactions = response as List<Map<String, dynamic>>;
      final transactionsText = _formatTransactionsResponse(transactions);

      return IVRResponse(
        id: _generateResponseId(),
        sessionId: _currentSession!.id,
        text: transactionsText,
        type: IVRResponseType.success,
        timestamp: DateTime.now(),
        data: {'transactions': transactions},
      );
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      return IVRResponse(
        id: _generateResponseId(),
        sessionId: _currentSession!.id,
        text:
            'I\'m sorry, I couldn\'t retrieve your transactions at this time.',
        type: IVRResponseType.error,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Transfer funds via voice
  Future<IVRResponse> transferFunds({
    required String fromAccount,
    required String toAccount,
    required double amount,
    String? memo,
  }) async {
    if (_currentSession == null) {
      throw IVRException('No active IVR session');
    }

    try {
      // Validate accounts and amount
      final validationResponse = await _validateTransfer(
          fromAccount, toAccount, amount, _currentSession!.userId);

      if (!validationResponse.isValid) {
        return IVRResponse(
          id: _generateResponseId(),
          sessionId: _currentSession!.id,
          text: validationResponse.errorMessage,
          type: IVRResponseType.error,
          timestamp: DateTime.now(),
        );
      }

      // Process the transfer
      final transferResponse = await _supabase.from('transfers').insert({
        'user_id': _currentSession!.userId,
        'from_account': fromAccount,
        'to_account': toAccount,
        'amount': amount,
        'memo': memo,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (transferResponse.isNotEmpty) {
        final transfer = transferResponse.first as Map<String, dynamic>;

        return IVRResponse(
          id: _generateResponseId(),
          sessionId: _currentSession!.id,
          text:
              'Transfer of \$${amount.toStringAsFixed(2)} from $fromAccount to $toAccount has been initiated.',
          type: IVRResponseType.success,
          timestamp: DateTime.now(),
          data: {'transfer': transfer},
        );
      } else {
        return IVRResponse(
          id: _generateResponseId(),
          sessionId: _currentSession!.id,
          text: 'I\'m sorry, the transfer could not be processed at this time.',
          type: IVRResponseType.error,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Error processing transfer: $e');
      return IVRResponse(
        id: _generateResponseId(),
        sessionId: _currentSession!.id,
        text: 'I\'m sorry, there was an error processing your transfer.',
        type: IVRResponseType.error,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get help information
  Future<IVRResponse> getHelp() async {
    final helpText =
        _getContextHelp(_currentSession?.context ?? IVRContext.mainMenu);

    return IVRResponse(
      id: _generateResponseId(),
      sessionId: _currentSession?.id ?? '',
      text: helpText,
      type: IVRResponseType.help,
      timestamp: DateTime.now(),
    );
  }

  /// Set language for speech recognition and synthesis
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;

    // Update TTS language
    await _textToSpeech.setLanguage(languageCode);

    debugPrint('IVR language set to: $languageCode');
  }

  /// Dispose of resources
  void dispose() {
    _commandStream.close();
    _responseStream.close();
    _stateStream.close();
    _speechToText.cancel();
    _textToSpeech.stop();
  }

  // Private methods

  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    if (result.finalResult) {
      final command = result.recognizedWords;
      if (command.isNotEmpty) {
        processCommand(command);
      }
    }
  }

  void _onSpeechError(stt.SpeechRecognitionError error) {
    debugPrint('Speech recognition error: ${error.errorMsg}');
    _updateState(IVRState.error);
  }

  void _onSpeechStatus(String status) {
    debugPrint('Speech recognition status: $status');

    switch (status) {
      case 'listening':
        _isListening = true;
        _updateState(IVRState.listening);
        break;
      case 'notListening':
        _isListening = false;
        _updateState(IVRState.active);
        break;
      case 'done':
        _isListening = false;
        _updateState(IVRState.active);
        break;
    }
  }

  void _onSoundLevelChange(double level) {
    // Could be used for visual feedback
  }

  void _updateState(IVRState state) {
    _stateStream.add(state);
  }

  Future<IVRResponse> _processCommandByContext(IVRCommand command) async {
    final context = _currentSession?.context ?? IVRContext.mainMenu;
    final commandText = command.text.toLowerCase();

    switch (context) {
      case IVRContext.mainMenu:
        return await _processMainMenuCommand(commandText);
      case IVRContext.accountInfo:
        return await _processAccountInfoCommand(commandText);
      case IVRContext.transfers:
        return await _processTransferCommand(commandText);
      case IVRContext.transactions:
        return await _processTransactionCommand(commandText);
      case IVRContext.support:
        return await _processSupportCommand(commandText);
    }
  }

  Future<IVRResponse> _processMainMenuCommand(String command) async {
    if (command.contains('balance') || command.contains('account')) {
      await navigateToContext(IVRContext.accountInfo);
      return await getAccountBalance();
    } else if (command.contains('transfer') || command.contains('send')) {
      await navigateToContext(IVRContext.transfers);
      return IVRResponse(
        id: _generateResponseId(),
        sessionId: _currentSession!.id,
        text:
            'I can help you transfer funds. Please tell me the amount and accounts.',
        type: IVRResponseType.prompt,
        timestamp: DateTime.now(),
      );
    } else if (command.contains('transaction') || command.contains('history')) {
      await navigateToContext(IVRContext.transactions);
      return await getRecentTransactions();
    } else if (command.contains('help') || command.contains('support')) {
      await navigateToContext(IVRContext.support);
      return await getHelp();
    } else {
      return IVRResponse(
        id: _generateResponseId(),
        sessionId: _currentSession!.id,
        text:
            'I didn\'t understand that. You can ask about your balance, transfers, transactions, or help.',
        type: IVRResponseType.prompt,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<IVRResponse> _processAccountInfoCommand(String command) async {
    if (command.contains('balance')) {
      return await getAccountBalance();
    } else if (command.contains('back') || command.contains('main')) {
      await navigateToContext(IVRContext.mainMenu);
      return IVRResponse(
        id: _generateResponseId(),
        sessionId: _currentSession!.id,
        text: 'Returning to main menu. How can I help you?',
        type: IVRResponseType.navigation,
        timestamp: DateTime.now(),
      );
    } else {
      return IVRResponse(
        id: _generateResponseId(),
        sessionId: _currentSession!.id,
        text:
            'You can ask about your balance or say "back" to return to the main menu.',
        type: IVRResponseType.prompt,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<IVRResponse> _processTransferCommand(String command) async {
    // This would be more complex in a real implementation
    // For now, return a simple response
    return IVRResponse(
      id: _generateResponseId(),
      sessionId: _currentSession!.id,
      text:
          'Transfer functionality is being processed. Please provide the amount and account details.',
      type: IVRResponseType.prompt,
      timestamp: DateTime.now(),
    );
  }

  Future<IVRResponse> _processTransactionCommand(String command) async {
    if (command.contains('recent') || command.contains('latest')) {
      return await getRecentTransactions();
    } else if (command.contains('back') || command.contains('main')) {
      await navigateToContext(IVRContext.mainMenu);
      return IVRResponse(
        id: _generateResponseId(),
        sessionId: _currentSession!.id,
        text: 'Returning to main menu. How can I help you?',
        type: IVRResponseType.navigation,
        timestamp: DateTime.now(),
      );
    } else {
      return IVRResponse(
        id: _generateResponseId(),
        sessionId: _currentSession!.id,
        text:
            'You can ask for recent transactions or say "back" to return to the main menu.',
        type: IVRResponseType.prompt,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<IVRResponse> _processSupportCommand(String command) async {
    return await getHelp();
  }

  String _getContextGreeting(IVRContext context) {
    switch (context) {
      case IVRContext.mainMenu:
        return 'You are in the main menu. How can I help you?';
      case IVRContext.accountInfo:
        return 'You are in account information. What would you like to know?';
      case IVRContext.transfers:
        return 'You are in transfers. I can help you move money between accounts.';
      case IVRContext.transactions:
        return 'You are in transactions. I can show you your recent activity.';
      case IVRContext.support:
        return 'You are in support. How can I assist you?';
    }
  }

  String _getContextHelp(IVRContext context) {
    switch (context) {
      case IVRContext.mainMenu:
        return 'You can say: "check balance", "transfer money", "show transactions", or "help".';
      case IVRContext.accountInfo:
        return 'You can say: "balance" to check your account balance, or "back" to return to the main menu.';
      case IVRContext.transfers:
        return 'You can say: "transfer [amount] from [account] to [account]", or "back" to return to the main menu.';
      case IVRContext.transactions:
        return 'You can say: "recent transactions" to see your latest activity, or "back" to return to the main menu.';
      case IVRContext.support:
        return 'You can say: "back" to return to the main menu, or ask me any questions about your account.';
    }
  }

  String _formatBalanceResponse(
      List<Map<String, dynamic>> accounts, double totalBalance) {
    if (accounts.length == 1) {
      final account = accounts.first;
      return 'Your ${account['account_name']} has a balance of \$${account['balance'].toStringAsFixed(2)}.';
    } else {
      final accountList = accounts
          .map((account) =>
              '${account['account_name']}: \$${account['balance'].toStringAsFixed(2)}')
          .join(', ');
      return 'Your accounts: $accountList. Total balance: \$${totalBalance.toStringAsFixed(2)}.';
    }
  }

  String _formatTransactionsResponse(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return 'You have no recent transactions.';
    }

    final transactionList = transactions.take(3).map((transaction) {
      final amount = (transaction['amount'] as num).toDouble();
      final merchant =
          transaction['merchant_name'] ?? transaction['name'] ?? 'Unknown';
      final date = DateTime.parse(transaction['date']).toLocal();
      final formattedDate = '${date.month}/${date.day}';

      return '$merchant: \$${amount.abs().toStringAsFixed(2)} on $formattedDate';
    }).join(', ');

    return 'Your recent transactions: $transactionList.';
  }

  Future<TransferValidation> _validateTransfer(String fromAccount,
      String toAccount, double amount, String userId) async {
    try {
      // Check if accounts exist and belong to user
      final accountsResponse = await _supabase
          .from('accounts')
          .select('account_name, balance')
          .eq('user_id', userId)
          .in_('account_name', [fromAccount, toAccount]);

      if (accountsResponse.length != 2) {
        return TransferValidation(
          isValid: false,
          errorMessage: 'One or both accounts could not be found.',
        );
      }

      // Check if from account has sufficient balance
      final fromAccountData = accountsResponse
          .firstWhere((account) => account['account_name'] == fromAccount);
      final currentBalance = (fromAccountData['balance'] as num).toDouble();

      if (currentBalance < amount) {
        return TransferValidation(
          isValid: false,
          errorMessage:
              'Insufficient funds. Your $fromAccount has \$${currentBalance.toStringAsFixed(2)}.',
        );
      }

      return TransferValidation(isValid: true);
    } catch (e) {
      debugPrint('Error validating transfer: $e');
      return TransferValidation(
        isValid: false,
        errorMessage: 'Unable to validate transfer at this time.',
      );
    }
  }

  Future<void> _logSessionEvent(IVRSession session, String event,
      {Map<String, dynamic>? data}) async {
    try {
      await _supabase.from('ivr_session_logs').insert({
        'session_id': session.id,
        'user_id': session.userId,
        'event': event,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging IVR session event: $e');
    }
  }

  String _generateSessionId() {
    return 'ivr_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  String _generateCommandId() {
    return 'cmd_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(4)}';
  }

  String _generateResponseId() {
    return 'resp_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(4)}';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(Iterable.generate(
        length,
        (_) => chars
            .codeUnitAt(DateTime.now().millisecondsSinceEpoch % chars.length)));
  }
}

// Data models

enum IVRState {
  initializing,
  ready,
  active,
  listening,
  speaking,
  error,
}

enum IVRContext {
  mainMenu,
  accountInfo,
  transfers,
  transactions,
  support,
}

enum IVRPriority {
  low,
  normal,
  high,
}

enum IVRResponseType {
  success,
  error,
  prompt,
  navigation,
  help,
}

class IVRSession {
  final String id;
  final String userId;
  IVRContext context;
  final DateTime startTime;
  DateTime? endTime;

  IVRSession({
    required this.id,
    required this.userId,
    required this.context,
    required this.startTime,
    this.endTime,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);
}

class IVRCommand {
  final String id;
  final String sessionId;
  final String text;
  final DateTime timestamp;
  final double confidence;

  IVRCommand({
    required this.id,
    required this.sessionId,
    required this.text,
    required this.timestamp,
    required this.confidence,
  });
}

class IVRResponse {
  final String id;
  final String sessionId;
  final String text;
  final IVRResponseType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  IVRResponse({
    required this.id,
    required this.sessionId,
    required this.text,
    required this.type,
    required this.timestamp,
    this.data,
  });
}

class TransferValidation {
  final bool isValid;
  final String? errorMessage;

  TransferValidation({
    required this.isValid,
    this.errorMessage,
  });
}

class IVRException implements Exception {
  final String message;
  IVRException(this.message);

  @override
  String toString() => 'IVRException: $message';
}

