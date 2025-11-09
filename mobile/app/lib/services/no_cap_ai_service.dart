import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'transaction_service.dart';
import 'chat_service.dart';

/// The "No Cap Can't Take It Back" AI Service
/// Monitors spending, enforces commitments, and provides financial coaching
class NoCapAIService {
  static final NoCapAIService _instance = NoCapAIService._internal();
  factory NoCapAIService() => _instance;
  NoCapAIService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final TransactionService _transactionService = TransactionService();
  final ChatService _chatService = ChatService();

  // AI personality and responses
  static const String _aiName = "CUGPT No Cap";

  // Real-time monitoring
  final StreamController<BudgetViolation> _violationStreamController =
      StreamController<BudgetViolation>.broadcast();
  Stream<BudgetViolation> get violationStream =>
      _violationStreamController.stream;

  final StreamController<AchievementUnlock> _achievementStreamController =
      StreamController<AchievementUnlock>.broadcast();
  Stream<AchievementUnlock> get achievementStream =>
      _achievementStreamController.stream;

  /// Initialize the AI service and start monitoring
  Future<void> initialize() async {
    debugPrint('🤖 NoCapAI Service initialized - No cap, no backing down! ');
    _startTransactionMonitoring();
    await _checkDailyStreaks();
  }

  /// Analyze spending patterns and suggest commitment opportunities
  Future<List<CommitmentSuggestion>> analyzeSpendingForSuggestions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // Get recent transactions to analyze patterns
      final transactions = await _transactionService.getTransactions(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      final suggestions = <CommitmentSuggestion>[];
      final spendingByMerchant = <String, SpendingPattern>{};

      // Analyze transactions for patterns
      for (final transaction in transactions.transactions) {
        final merchant = transaction['merchant_name'] as String? ?? 'Unknown';
        final amount = (transaction['amount'] as num?)?.abs().toDouble() ?? 0.0;
        final category = transaction['category'] as List<String>? ?? ['other'];

        if (!spendingByMerchant.containsKey(merchant)) {
          spendingByMerchant[merchant] = SpendingPattern(
            merchant: merchant,
            category: category.first,
            totalSpent: 0.0,
            transactionCount: 0,
            averageAmount: 0.0,
            lastTransaction: DateTime.now(),
          );
        }

        final pattern = spendingByMerchant[merchant]!;
        pattern.totalSpent += amount;
        pattern.transactionCount++;
        pattern.averageAmount = pattern.totalSpent / pattern.transactionCount;

        final transactionDate =
            DateTime.tryParse(transaction['date'] ?? '') ?? DateTime.now();
        if (transactionDate.isAfter(pattern.lastTransaction)) {
          pattern.lastTransaction = transactionDate;
        }
      }

      // Generate suggestions based on spending patterns
      final sortedPatterns = spendingByMerchant.values.toList()
        ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

      for (final pattern in sortedPatterns.take(5)) {
        if (pattern.totalSpent > 50 && pattern.transactionCount >= 3) {
          // Suggest a commitment for high-spend merchants
          final suggestion = CommitmentSuggestion(
            type: CommitmentType.merchant,
            target: pattern.merchant,
            category: pattern.category,
            suggestedLimit: _calculateSuggestedLimit(pattern),
            reasoning: _generateAIReasoning(pattern),
            aiConfidence: _calculateConfidence(pattern),
            potentialSavings: _calculatePotentialSavings(pattern),
            difficulty: _calculateDifficulty(pattern),
          );
          suggestions.add(suggestion);
        }
      }

      return suggestions;
    } catch (e) {
      debugPrint('Error analyzing spending patterns: $e');
      return [];
    }
  }

  /// Generate commitment suggestions for a user
  Future<List<String>> generateCommitmentSuggestions(String userId) async {
    try {
      final suggestions = await analyzeSpendingForSuggestions();
      return suggestions.map((s) => generateCommitmentMessage(s)).toList();
    } catch (e) {
      debugPrint('Error generating commitment suggestions: $e');
      return [
        "Consider setting a monthly coffee budget limit",
        "Track your entertainment spending more closely",
        "Set up a savings goal for emergency funds",
        "Create a merchant-specific spending limit",
        "Monitor your subscription services"
      ];
    }
  }

  /// Create a personalized AI message for commitment creation
  String generateCommitmentMessage(CommitmentSuggestion suggestion) {
    final messages = [
      "Real talk  - I've been watching your ${suggestion.target} spending, and it's time for some no cap accountability!",
      "Listen up! 🗣 Your ${suggestion.target} habits need a reality check. Let's lock in a commitment that'll keep you honest.",
      "No cap time!  I see you've spent \$${suggestion.potentialSavings.toStringAsFixed(0)} at ${suggestion.target} lately. Ready to take control?",
      "Yo! 🤖 Time for some financial discipline. ${suggestion.target} has been getting too much of your money - let's fix that!",
    ];

    return messages[Random().nextInt(messages.length)] +
        "\n\n${suggestion.reasoning}" +
        "\n\nSuggested limit: \$${suggestion.suggestedLimit.toStringAsFixed(0)}/month";
  }

  /// Process a transaction and check for violations
  Future<ViolationResult?> processTransaction(
      Map<String, dynamic> transaction) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // Get active commitments for this user
      final commitments = await getActiveCommitments();

      final merchant = transaction['merchant_name'] as String? ?? '';
      final amount = (transaction['amount'] as num?)?.abs().toDouble() ?? 0.0;
      final category =
          (transaction['category'] as List?)?.first as String? ?? 'other';

      for (final commitment in commitments) {
        if (await _isViolation(commitment, merchant, category, amount)) {
          final violation =
              await _recordViolation(commitment, transaction, amount);
          _violationStreamController.add(violation);

          return ViolationResult(
            violation: violation,
            aiMessage: _generateViolationMessage(commitment, amount),
            pointsPenalty: commitment.pointsPenalty,
            streakBroken: violation.streakBroken,
          );
        }
      }

      // Check for positive reinforcement opportunities
      await _checkForAchievements(transaction);

      return null;
    } catch (e) {
      debugPrint('Error processing transaction: $e');
      return null;
    }
  }

  /// Get all active commitments for the current user
  Future<List<BudgetCommitment>> getActiveCommitments() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('budget_commitments')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response
          .map<BudgetCommitment>((data) => BudgetCommitment.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching commitments: $e');
      return [];
    }
  }

  /// Generate AI coaching message based on user's financial behavior
  Future<String> generateCoachingMessage(CoachingContext context) async {
    switch (context.type) {
      case CoachingType.preTransaction:
        return _generatePreTransactionWarning(context);
      case CoachingType.violation:
        return _generateViolationMessage(context.commitment!, context.amount!);
      case CoachingType.achievement:
        return _generateAchievementMessage(context.achievement!);
      case CoachingType.dailyCheckin:
        return await _generateDailyCheckinMessage();
      case CoachingType.streakCelebration:
        return _generateStreakMessage(context.streakDays!);
    }
  }

  // Private helper methods

  void _startTransactionMonitoring() {
    // Listen to real-time transaction updates
    _transactionService.transactionStream.listen((transactions) {
      for (final transaction in transactions) {
        processTransaction(transaction);
      }
    });
  }

  Future<void> _checkDailyStreaks() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Update streak counters for active commitments
      final commitments = await getActiveCommitments();
      for (final commitment in commitments) {
        await _updateCommitmentStreak(commitment);
      }
    } catch (e) {
      debugPrint('Error checking daily streaks: $e');
    }
  }

  double _calculateSuggestedLimit(SpendingPattern pattern) {
    // Suggest a limit that's 20-30% less than current spending
    final reduction = 0.25; // 25% reduction
    return (pattern.totalSpent * (1 - reduction)).roundToDouble();
  }

  String _generateAIReasoning(SpendingPattern pattern) {
    if (pattern.category == 'food_and_drink') {
      return "I noticed you've been hitting ${pattern.merchant} ${pattern.transactionCount} times this month. That's \$${pattern.totalSpent.toStringAsFixed(0)} on coffee/food - we could definitely optimize this! ☕💰";
    } else if (pattern.category == 'entertainment') {
      return "Entertainment spending at ${pattern.merchant} is looking heavy - \$${pattern.totalSpent.toStringAsFixed(0)} this month. Time to budget some fun money! ";
    } else if (pattern.category == 'shopping') {
      return "${pattern.merchant} shopping is hitting different - \$${pattern.totalSpent.toStringAsFixed(0)} in ${pattern.transactionCount} trips. Let's get intentional with purchases! 🛍";
    } else {
      return "Your ${pattern.merchant} spending pattern caught my attention. \$${pattern.totalSpent.toStringAsFixed(0)} over ${pattern.transactionCount} transactions - let's create some boundaries! ";
    }
  }

  double _calculateConfidence(SpendingPattern pattern) {
    // Higher confidence for consistent, frequent spending
    final frequencyScore = (pattern.transactionCount / 10).clamp(0.0, 1.0);
    final amountScore = (pattern.totalSpent / 200).clamp(0.0, 1.0);
    return ((frequencyScore + amountScore) / 2 * 100).roundToDouble();
  }

  double _calculatePotentialSavings(SpendingPattern pattern) {
    return pattern.totalSpent * 0.25; // 25% potential savings
  }

  CommitmentDifficulty _calculateDifficulty(SpendingPattern pattern) {
    if (pattern.totalSpent > 200 && pattern.transactionCount > 10) {
      return CommitmentDifficulty.hardcore;
    } else if (pattern.totalSpent > 100 && pattern.transactionCount > 5) {
      return CommitmentDifficulty.moderate;
    } else {
      return CommitmentDifficulty.casual;
    }
  }

  Future<bool> _isViolation(BudgetCommitment commitment, String merchant,
      String category, double amount) async {
    // Check if this transaction violates the commitment
    if (commitment.type == CommitmentType.merchant) {
      return merchant.toLowerCase().contains(commitment.target.toLowerCase());
    } else if (commitment.type == CommitmentType.category) {
      return category == commitment.target;
    }
    return false;
  }

  Future<BudgetViolation> _recordViolation(BudgetCommitment commitment,
      Map<String, dynamic> transaction, double amount) async {
    final user = _supabase.auth.currentUser!;

    // Check if this breaks a streak
    final wasOnStreak = commitment.streakCount > 0;

    final violationMessage = _generateViolationMessage(commitment, amount);
    final violation = {
      'commitment_id': commitment.id,
      'transaction_id': transaction['transaction_id'] ?? '',
      'violation_amount': amount,
      'points_deducted': commitment.pointsPenalty,
      'violation_date': DateTime.now().toIso8601String(),
      'ai_analysis': _generateViolationAnalysis(commitment, amount),
      'streak_broken': wasOnStreak,
      'message': violationMessage,
      'penalty_points': commitment.pointsPenalty,
    };

    final response = await _supabase
        .from('commitment_violations')
        .insert(violation)
        .select()
        .single();

    // Update commitment streak
    if (wasOnStreak) {
      await _supabase
          .from('budget_commitments')
          .update({'streak_count': 0}).eq('id', commitment.id);
    }

    // Deduct points from user
    await _deductPoints(user.id, commitment.pointsPenalty);

    return BudgetViolation.fromJson(response);
  }

  String _generateViolationMessage(BudgetCommitment commitment, double amount) {
    final messages = [
      "Yo! 🚨 That \$${amount.toStringAsFixed(2)} at ${commitment.target} just broke your commitment! No cap - we gotta stay accountable! 💸",
      "Hold up! ✋ You just violated your ${commitment.target} budget limit. That's -${commitment.pointsPenalty} points! Time to get back on track! ",
      "Real talk  - that purchase at ${commitment.target} wasn't in the plan. You're stronger than this! Let's refocus! ",
      "Ooof! 😬 ${commitment.target} just took \$${amount.toStringAsFixed(2)} from you AND ${commitment.pointsPenalty} points from me. We can bounce back! 🔄",
    ];

    return messages[Random().nextInt(messages.length)];
  }

  String _generateViolationAnalysis(
      BudgetCommitment commitment, double amount) {
    return "Transaction of \$${amount.toStringAsFixed(2)} at ${commitment.target} exceeded commitment parameters. "
        "User was ${commitment.streakCount} days into their streak. "
        "Recommend immediate re-engagement strategy.";
  }

  String _generatePreTransactionWarning(CoachingContext context) {
    return " Hold up! You're about to spend at ${context.merchant} but you've got an active commitment! "
        "Remember your goals - you've got this!  Consider finding an alternative or using your override if absolutely necessary.";
  }

  String _generateAchievementMessage(Achievement achievement) {
    return " NO CAP! You just unlocked '${achievement.name}'! "
        "${achievement.description} Keep this energy going! ";
  }

  Future<String> _generateDailyCheckinMessage() async {
    final commitments = await getActiveCommitments();
    final activeCount = commitments.length;
    final totalStreak = commitments.fold(0, (sum, c) => sum + c.streakCount);

    return "Good morning! 🌅 You've got $activeCount active commitments and $totalStreak total streak days. "
        "Today's another chance to prove you're about that financial discipline life! ";
  }

  String _generateStreakMessage(int streakDays) {
    if (streakDays >= 30) {
      return " THIRTY DAYS NO CAP! You're officially a financial discipline legend! This streak is UNBREAKABLE! ";
    } else if (streakDays >= 14) {
      return " TWO WEEKS STRONG! Your commitment game is getting serious! Keep this momentum! ";
    } else if (streakDays >= 7) {
      return " ONE WEEK IN! You're building real habits now. This is where champions are made! ";
    } else {
      return " Day $streakDays complete! Every day counts when you're building financial discipline! ";
    }
  }

  Future<void> _checkForAchievements(Map<String, dynamic> transaction) async {
    // Check for achievement unlocks based on good behavior
    // This would include logic for various achievement types
  }

  Future<void> _updateCommitmentStreak(BudgetCommitment commitment) async {
    // Update streak if user successfully avoided spending at target merchant/category today
    // This would involve checking if there were any transactions today that violated the commitment
  }

  Future<void> _deductPoints(String userId, int points) async {
    try {
      await _supabase.rpc('deduct_user_points', params: {
        'user_id': userId,
        'points_to_deduct': points,
      });
    } catch (e) {
      debugPrint('Error deducting points: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _violationStreamController.close();
    _achievementStreamController.close();
  }
}

// Data Models

enum CommitmentType { merchant, category, amountLimit, savingsGoal }

enum CommitmentDifficulty {
  casual,
  moderate,
  hardcore,
  easy,
  medium,
  hard,
  extreme
}

enum CoachingType {
  preTransaction,
  violation,
  achievement,
  dailyCheckin,
  streakCelebration
}

class SpendingPattern {
  String merchant;
  String category;
  double totalSpent;
  int transactionCount;
  double averageAmount;
  DateTime lastTransaction;

  SpendingPattern({
    required this.merchant,
    required this.category,
    required this.totalSpent,
    required this.transactionCount,
    required this.averageAmount,
    required this.lastTransaction,
  });
}

class CommitmentSuggestion {
  final CommitmentType type;
  final String target;
  final String category;
  final double suggestedLimit;
  final String reasoning;
  final double aiConfidence;
  final double potentialSavings;
  final CommitmentDifficulty difficulty;

  CommitmentSuggestion({
    required this.type,
    required this.target,
    required this.category,
    required this.suggestedLimit,
    required this.reasoning,
    required this.aiConfidence,
    required this.potentialSavings,
    required this.difficulty,
  });
}

class BudgetCommitment {
  final String id;
  final String userId;
  final CommitmentType type;
  final String target;
  final String category;
  final double spendingLimit;
  final String timePeriod;
  final int pointsReward;
  final int pointsPenalty;
  final DateTime lockedUntil;
  final DateTime createdAt;
  final bool isActive;
  final int streakCount;
  final double currentSpent;
  final bool isLocked;
  final CommitmentDifficulty difficulty;

  BudgetCommitment({
    required this.id,
    required this.userId,
    required this.type,
    required this.target,
    required this.category,
    required this.spendingLimit,
    required this.timePeriod,
    required this.pointsReward,
    required this.pointsPenalty,
    required this.lockedUntil,
    required this.createdAt,
    required this.isActive,
    required this.streakCount,
    required this.currentSpent,
    required this.isLocked,
    required this.difficulty,
  });

  factory BudgetCommitment.fromJson(Map<String, dynamic> json) {
    return BudgetCommitment(
      id: json['id'],
      userId: json['user_id'],
      type: CommitmentType.values
          .firstWhere((e) => e.name == json['commitment_type']),
      target: json['target_merchant'] ?? json['target_category'] ?? '',
      category: json['target_category'] ?? '',
      spendingLimit: (json['spending_limit'] as num).toDouble(),
      timePeriod: json['time_period'],
      pointsReward: json['points_reward'],
      pointsPenalty: json['points_penalty'],
      lockedUntil: DateTime.parse(json['locked_until']),
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'],
      streakCount: json['streak_count'] ?? 0,
      currentSpent: (json['current_spent'] as num?)?.toDouble() ?? 0.0,
      isLocked: json['is_locked'] ?? false,
      difficulty: CommitmentDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => CommitmentDifficulty.casual,
      ),
    );
  }
}

class BudgetViolation {
  final String id;
  final String commitmentId;
  final String transactionId;
  final double violationAmount;
  final int pointsDeducted;
  final DateTime violationDate;
  final String aiAnalysis;
  final bool streakBroken;
  final String message;
  final int penaltyPoints;

  BudgetViolation({
    required this.id,
    required this.commitmentId,
    required this.transactionId,
    required this.violationAmount,
    required this.pointsDeducted,
    required this.violationDate,
    required this.aiAnalysis,
    required this.streakBroken,
    required this.message,
    required this.penaltyPoints,
  });

  factory BudgetViolation.fromJson(Map<String, dynamic> json) {
    return BudgetViolation(
      id: json['id'],
      commitmentId: json['commitment_id'],
      transactionId: json['transaction_id'],
      violationAmount: (json['violation_amount'] as num).toDouble(),
      pointsDeducted: json['points_deducted'],
      violationDate: DateTime.parse(json['violation_date']),
      aiAnalysis: json['ai_analysis'],
      streakBroken: json['streak_broken'] ?? false,
      message: json['message'] ?? 'Budget violation detected',
      penaltyPoints: json['penalty_points'] ?? json['points_deducted'] ?? 0,
    );
  }
}

class ViolationResult {
  final BudgetViolation violation;
  final String aiMessage;
  final int pointsPenalty;
  final bool streakBroken;

  ViolationResult({
    required this.violation,
    required this.aiMessage,
    required this.pointsPenalty,
    required this.streakBroken,
  });
}

class CoachingContext {
  final CoachingType type;
  final String? merchant;
  final double? amount;
  final BudgetCommitment? commitment;
  final Achievement? achievement;
  final int? streakDays;

  CoachingContext({
    required this.type,
    this.merchant,
    this.amount,
    this.commitment,
    this.achievement,
    this.streakDays,
  });
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final int pointsAwarded;
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsAwarded,
    required this.unlockedAt,
  });
}

class AchievementUnlock {
  final Achievement achievement;
  final String celebrationMessage;

  AchievementUnlock({
    required this.achievement,
    required this.celebrationMessage,
  });
}
