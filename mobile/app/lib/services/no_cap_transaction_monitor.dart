import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'transaction_service.dart';
import 'no_cap_ai_service.dart';
import 'budget_commitment_service.dart';
import 'point_system_service.dart';

class NoCapTransactionMonitor {
  static final NoCapTransactionMonitor _instance = NoCapTransactionMonitor._internal();
  factory NoCapTransactionMonitor() => _instance;
  NoCapTransactionMonitor._internal();

  // Service dependencies
  final TransactionService _transactionService = TransactionService();
  final NoCapAIService _aiService = NoCapAIService();
  final BudgetCommitmentService _commitmentService = BudgetCommitmentService();
  final PointSystemService _pointService = PointSystemService();

  // Monitoring state
  bool _isMonitoring = false;
  StreamSubscription<List<Map<String, dynamic>>>? _transactionSubscription;
  Timer? _periodicCheckTimer;
  final Map<String, DateTime> _lastCheckedTransactions = {};

  // Real-time violation alerts
  final StreamController<TransactionViolationAlert> _violationAlertController = 
      StreamController<TransactionViolationAlert>.broadcast();
  Stream<TransactionViolationAlert> get violationAlertStream => _violationAlertController.stream;

  // Budget performance updates
  final StreamController<BudgetPerformanceUpdate> _performanceController = 
      StreamController<BudgetPerformanceUpdate>.broadcast();
  Stream<BudgetPerformanceUpdate> get performanceStream => _performanceController.stream;

  /// Start monitoring transactions for No Cap commitments
  Future<void> startMonitoring(String userId) async {
    if (_isMonitoring) {
      debugPrint('Transaction monitoring already active');
      return;
    }

    debugPrint('🔍 Starting No Cap transaction monitoring for user: $userId');
    
    try {
      _isMonitoring = true;

      // Subscribe to real-time transaction stream
      _transactionSubscription = _transactionService.transactionStream.listen(
        (transactions) => _processNewTransactions(userId, transactions),
        onError: (error) {
          debugPrint('Transaction stream error: $error');
          _handleMonitoringError(userId, error);
        },
      );

      // Start periodic checks for missed transactions
      _startPeriodicChecks(userId);

      // Load and check recent transactions on startup
      await _performInitialTransactionCheck(userId);

      debugPrint('✅ No Cap transaction monitoring started successfully');

    } catch (e) {
      debugPrint('❌ Failed to start transaction monitoring: $e');
      _isMonitoring = false;
      rethrow;
    }
  }

  /// Stop monitoring transactions
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    debugPrint('⏹️ Stopping No Cap transaction monitoring');
    
    _isMonitoring = false;
    await _transactionSubscription?.cancel();
    _periodicCheckTimer?.cancel();
    
    debugPrint('✅ Transaction monitoring stopped');
  }

  /// Process new transactions from the stream
  Future<void> _processNewTransactions(String userId, List<Map<String, dynamic>> transactions) async {
    if (transactions.isEmpty) return;

    debugPrint('📥 Processing ${transactions.length} new transactions for No Cap analysis');

    // Get active commitments
    final activeCommitments = await _commitmentService.getActiveCommitments(userId);
    if (activeCommitments.isEmpty) {
      debugPrint('No active commitments found for user');
      return;
    }

    // Process each transaction
    for (final transaction in transactions) {
      await _analyzeTransaction(userId, transaction, activeCommitments);
    }

    // Update performance metrics
    await _updatePerformanceMetrics(userId, activeCommitments);
  }

  /// Analyze a single transaction against all active commitments
  Future<void> _analyzeTransaction(
    String userId,
    Map<String, dynamic> transaction,
    List<BudgetCommitment> commitments,
  ) async {
    final transactionId = transaction['transaction_id'] ?? transaction['id'];
    final amount = (transaction['amount'] ?? 0).toDouble().abs();
    final merchantName = transaction['merchant_name'] ?? transaction['name'] ?? 'Unknown';
    final category = transaction['primary_category'] ?? transaction['category'] ?? 'Other';
    final date = DateTime.tryParse(transaction['date'] ?? '') ?? DateTime.now();

    // Skip if already processed
    if (_lastCheckedTransactions.containsKey(transactionId) &&
        _lastCheckedTransactions[transactionId]!.isAfter(date.subtract(const Duration(minutes: 5)))) {
      return;
    }
    _lastCheckedTransactions[transactionId] = DateTime.now();

    debugPrint('🔍 Analyzing transaction: $merchantName (\$${amount.toStringAsFixed(2)})');

    // Check against each active commitment
    for (final commitment in commitments) {
      final violationResult = await _checkCommitmentViolation(
        userId,
        transaction,
        commitment,
        amount,
        merchantName,
        category,
      );

      if (violationResult != null) {
        await _handleViolation(userId, violationResult, transaction);
      } else {
        // No violation - potentially award points for good behavior
        await _checkPositiveBehavior(userId, commitment, amount);
      }
    }

    // Let AI service analyze the transaction
    await _aiService.processTransaction(transaction);
  }

  /// Check if a transaction violates a specific commitment
  Future<CommitmentViolationResult?> _checkCommitmentViolation(
    String userId,
    Map<String, dynamic> transaction,
    BudgetCommitment commitment,
    double amount,
    String merchantName,
    String category,
  ) async {
    // Skip if commitment is not locked or not active
    if (!commitment.isLocked || !commitment.isActive) {
      return null;
    }

    bool isViolation = false;
    ViolationType violationType = ViolationType.minor;
    String violationReason = '';

    // Check based on commitment type
    switch (commitment.type) {
      case CommitmentType.merchant:
        // Check if transaction is from the restricted merchant
        if (_isMerchantMatch(merchantName, commitment.target)) {
          isViolation = true;
          violationType = ViolationType.major;
          violationReason = 'Spending at restricted merchant: ${commitment.target}';
        }
        break;

      case CommitmentType.category:
        // Check if transaction is in the restricted category
        if (_isCategoryMatch(category, commitment.target)) {
          isViolation = true;
          violationType = ViolationType.major;
          violationReason = 'Spending in restricted category: ${commitment.target}';
        }
        break;

      case CommitmentType.amountLimit:
        // Check if this transaction would put spending over limit
        final newTotal = commitment.currentSpent + amount;
        if (newTotal > commitment.spendingLimit) {
          isViolation = true;
          violationType = newTotal > (commitment.spendingLimit * 1.5) 
              ? ViolationType.severe 
              : ViolationType.major;
          violationReason = 'Amount limit exceeded: \$${newTotal.toStringAsFixed(2)} > \$${commitment.spendingLimit.toStringAsFixed(2)}';
        }
        break;

      case CommitmentType.savingsGoal:
        // Check if spending impacts savings goal
        if (amount > commitment.spendingLimit) {
          isViolation = true;
          violationType = ViolationType.moderate;
          violationReason = 'Large expense may impact savings goal: \$${amount.toStringAsFixed(2)}';
        }
        break;
    }

    if (!isViolation) return null;

    return CommitmentViolationResult(
      commitmentId: commitment.id,
      transactionId: transaction['transaction_id'] ?? transaction['id'],
      violationType: violationType,
      violationReason: violationReason,
      amount: amount,
      merchantName: merchantName,
      category: category,
      overageAmount: (commitment.currentSpent + amount) - commitment.spendingLimit,
      severity: _calculateViolationSeverity(commitment, amount),
    );
  }

  /// Handle a commitment violation
  Future<void> _handleViolation(
    String userId,
    CommitmentViolationResult violation,
    Map<String, dynamic> transaction,
  ) async {
    debugPrint('🚨 VIOLATION DETECTED: ${violation.violationReason}');

    try {
      // Calculate penalty points based on violation severity
      final penaltyPoints = _calculatePenaltyPoints(violation);
      
      // Deduct points from user
      final penaltyResult = await _pointService.deductPoints(
        userId: userId,
        penalty: _mapViolationToPenalty(violation.violationType),
        points: penaltyPoints,
        metadata: {
          'violation_type': violation.violationType.name,
          'commitment_id': violation.commitmentId,
          'transaction_id': violation.transactionId,
          'merchant': violation.merchantName,
          'amount': violation.amount,
          'reason': violation.violationReason,
        },
        commitmentId: violation.commitmentId,
      );

      // Get AI response to violation
      final aiResponse = await _aiService.generateViolationResponse(
        violationType: violation.violationType,
        violationReason: violation.violationReason,
        penaltyPoints: penaltyPoints,
        userContext: await _getUserContext(userId),
      );

      // Update commitment with violation
      await _commitmentService.recordViolation(
        commitmentId: violation.commitmentId,
        violationAmount: violation.amount,
        penaltyPoints: penaltyPoints,
      );

      // Create violation alert
      final alert = TransactionViolationAlert(
        userId: userId,
        commitmentId: violation.commitmentId,
        transactionId: violation.transactionId,
        violationType: violation.violationType,
        violationReason: violation.violationReason,
        penaltyPoints: penaltyPoints,
        aiMessage: aiResponse,
        merchantName: violation.merchantName,
        amount: violation.amount,
        timestamp: DateTime.now(),
      );

      // Emit alert to stream
      _violationAlertController.add(alert);

      // Log violation for audit trail
      await _logViolationAudit(userId, violation, penaltyPoints, aiResponse);

      debugPrint('✅ Violation processed: -$penaltyPoints points');

    } catch (e) {
      debugPrint('❌ Error handling violation: $e');
    }
  }

  /// Check for positive behavior that should be rewarded
  Future<void> _checkPositiveBehavior(
    String userId,
    BudgetCommitment commitment,
    double amount,
  ) async {
    // Check if user is staying well under their budget
    final utilizationRate = commitment.currentSpent / commitment.spendingLimit;
    
    if (utilizationRate < 0.5 && commitment.daysRemaining > 7) {
      // User is doing very well - under 50% of budget with time remaining
      await _pointService.awardPoints(
        userId: userId,
        action: PointAction.budgetUnderLimit,
        points: 10,
        metadata: {
          'commitment_id': commitment.id,
          'utilization_rate': utilizationRate,
          'days_remaining': commitment.daysRemaining,
        },
        commitmentId: commitment.id,
      );
      
      debugPrint('🎉 Awarded points for staying under budget');
    }
  }

  /// Update performance metrics for all commitments
  Future<void> _updatePerformanceMetrics(
    String userId,
    List<BudgetCommitment> commitments,
  ) async {
    for (final commitment in commitments) {
      final performance = BudgetPerformanceUpdate(
        userId: userId,
        commitmentId: commitment.id,
        currentSpent: commitment.currentSpent,
        spendingLimit: commitment.spendingLimit,
        utilizationRate: commitment.currentSpent / commitment.spendingLimit,
        daysRemaining: commitment.daysRemaining,
        isOnTrack: commitment.currentSpent <= commitment.spendingLimit,
        trendDirection: await _calculateSpendingTrend(commitment.id),
      );

      _performanceController.add(performance);
    }
  }

  /// Perform initial check of recent transactions when monitoring starts
  Future<void> _performInitialTransactionCheck(String userId) async {
    debugPrint('🔍 Performing initial transaction check');
    
    try {
      // Get transactions from the last 7 days
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      
      final result = await _transactionService.getTransactions(
        startDate: startDate,
        endDate: endDate,
        pageSize: 100,
      );

      if (result.transactions.isNotEmpty) {
        await _processNewTransactions(userId, result.transactions);
        debugPrint('✅ Initial check processed ${result.transactions.length} transactions');
      }
    } catch (e) {
      debugPrint('❌ Initial transaction check failed: $e');
    }
  }

  /// Start periodic checks for missed transactions
  void _startPeriodicChecks(String userId) {
    _periodicCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      
      await _performPeriodicCheck(userId);
    });
  }

  /// Perform periodic check for any missed transactions
  Future<void> _performPeriodicCheck(String userId) async {
    try {
      // Get recent transactions to catch any missed ones
      final result = await _transactionService.getTransactions(
        startDate: DateTime.now().subtract(const Duration(hours: 2)),
        endDate: DateTime.now(),
        forceRefresh: true,
      );

      if (result.transactions.isNotEmpty) {
        await _processNewTransactions(userId, result.transactions);
      }
    } catch (e) {
      debugPrint('❌ Periodic check failed: $e');
    }
  }

  /// Handle monitoring errors
  void _handleMonitoringError(String userId, dynamic error) {
    debugPrint('❌ Transaction monitoring error: $error');
    
    // Try to restart monitoring after a delay
    Timer(const Duration(minutes: 1), () {
      if (!_isMonitoring) {
        startMonitoring(userId);
      }
    });
  }

  // Helper methods
  bool _isMerchantMatch(String transactionMerchant, String targetMerchant) {
    return transactionMerchant.toLowerCase().contains(targetMerchant.toLowerCase()) ||
           targetMerchant.toLowerCase().contains(transactionMerchant.toLowerCase());
  }

  bool _isCategoryMatch(String transactionCategory, String targetCategory) {
    return transactionCategory.toLowerCase().contains(targetCategory.toLowerCase());
  }

  ViolationSeverity _calculateViolationSeverity(BudgetCommitment commitment, double amount) {
    final overage = (commitment.currentSpent + amount) - commitment.spendingLimit;
    final overagePercent = overage / commitment.spendingLimit;
    
    if (overagePercent > 0.5) return ViolationSeverity.critical;
    if (overagePercent > 0.25) return ViolationSeverity.high;
    if (overagePercent > 0.1) return ViolationSeverity.medium;
    return ViolationSeverity.low;
  }

  int _calculatePenaltyPoints(CommitmentViolationResult violation) {
    int basePoints = 50; // Base penalty
    
    // Multiply based on violation type
    switch (violation.violationType) {
      case ViolationType.minor:
        basePoints = 25;
        break;
      case ViolationType.moderate:
        basePoints = 50;
        break;
      case ViolationType.major:
        basePoints = 100;
        break;
      case ViolationType.severe:
        basePoints = 200;
        break;
    }
    
    // Adjust for amount
    if (violation.amount > 100) basePoints = (basePoints * 1.5).round();
    if (violation.amount > 500) basePoints = (basePoints * 2.0).round();
    
    return basePoints;
  }

  PointPenalty _mapViolationToPenalty(ViolationType type) {
    switch (type) {
      case ViolationType.minor:
        return PointPenalty.minorViolation;
      case ViolationType.moderate:
      case ViolationType.major:
        return PointPenalty.majorViolation;
      case ViolationType.severe:
        return PointPenalty.commitmentBreak;
    }
  }

  Future<Map<String, dynamic>> _getUserContext(String userId) async {
    final stats = await _pointService.getUserStats(userId);
    return {
      'total_points': stats.totalPoints,
      'current_streak': stats.currentStreak,
      'violation_count': stats.violationsCount,
      'level': stats.level,
    };
  }

  Future<SpendingTrend> _calculateSpendingTrend(String commitmentId) async {
    // This would analyze spending patterns over time
    // For now, return neutral
    return SpendingTrend.neutral;
  }

  Future<void> _logViolationAudit(
    String userId,
    CommitmentViolationResult violation,
    int penaltyPoints,
    String aiResponse,
  ) async {
    // Log to audit system for compliance and debugging
    debugPrint('📝 Logging violation audit: ${violation.commitmentId}');
  }

  void dispose() {
    stopMonitoring();
    _violationAlertController.close();
    _performanceController.close();
  }
}

// Data models
enum ViolationType { minor, moderate, major, severe }
enum ViolationSeverity { low, medium, high, critical }
enum SpendingTrend { improving, neutral, worsening }

class CommitmentViolationResult {
  final String commitmentId;
  final String transactionId;
  final ViolationType violationType;
  final String violationReason;
  final double amount;
  final String merchantName;
  final String category;
  final double overageAmount;
  final ViolationSeverity severity;

  CommitmentViolationResult({
    required this.commitmentId,
    required this.transactionId,
    required this.violationType,
    required this.violationReason,
    required this.amount,
    required this.merchantName,
    required this.category,
    required this.overageAmount,
    required this.severity,
  });
}

class TransactionViolationAlert {
  final String userId;
  final String commitmentId;
  final String transactionId;
  final ViolationType violationType;
  final String violationReason;
  final int penaltyPoints;
  final String aiMessage;
  final String merchantName;
  final double amount;
  final DateTime timestamp;

  TransactionViolationAlert({
    required this.userId,
    required this.commitmentId,
    required this.transactionId,
    required this.violationType,
    required this.violationReason,
    required this.penaltyPoints,
    required this.aiMessage,
    required this.merchantName,
    required this.amount,
    required this.timestamp,
  });
}

class BudgetPerformanceUpdate {
  final String userId;
  final String commitmentId;
  final double currentSpent;
  final double spendingLimit;
  final double utilizationRate;
  final int daysRemaining;
  final bool isOnTrack;
  final SpendingTrend trendDirection;

  BudgetPerformanceUpdate({
    required this.userId,
    required this.commitmentId,
    required this.currentSpent,
    required this.spendingLimit,
    required this.utilizationRate,
    required this.daysRemaining,
    required this.isOnTrack,
    required this.trendDirection,
  });
}