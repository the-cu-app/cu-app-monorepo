import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import '../config/supabase_config.dart';
import 'no_cap_ai_service.dart';
import 'point_system_service.dart';

/// Budget Commitment Engine - Creates and enforces "locked" spending commitments
/// Once a commitment is created, it cannot be easily broken without consequences
class BudgetCommitmentService {
  static final BudgetCommitmentService _instance =
      BudgetCommitmentService._internal();
  factory BudgetCommitmentService() => _instance;
  BudgetCommitmentService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final PointSystemService _pointService = PointSystemService();

  // Commitment locking periods (cannot be deleted during these periods)
  static const Map<CommitmentDifficulty, Duration> _lockPeriods = {
    CommitmentDifficulty.casual: Duration(hours: 24),
    CommitmentDifficulty.moderate: Duration(days: 3),
    CommitmentDifficulty.hardcore: Duration(days: 7),
  };

  /// Create a new budget commitment with AI guidance
  Future<CommitmentCreationResult> createCommitment({
    required CommitmentType type,
    required String target, // merchant name or category
    required double spendingLimit,
    required String timePeriod, // 'daily', 'weekly', 'monthly'
    required CommitmentDifficulty difficulty,
    String? userNote,
    bool requireBiometric = true,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Step 1: Biometric authentication for commitment creation
      if (requireBiometric && await _localAuth.canCheckBiometrics) {
        final authenticated = await _localAuth.authenticate(
          localizedReason:
              ' Authenticate to lock in your budget commitment - No cap, no backing down!',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (!authenticated) {
          return CommitmentCreationResult(
            success: false,
            error: 'Biometric authentication required to create commitment',
          );
        }
      }

      // Step 2: Calculate points reward/penalty based on difficulty
      final points = _calculateCommitmentPoints(difficulty, spendingLimit);

      // Step 3: Determine lock period
      final lockPeriod = _lockPeriods[difficulty] ?? const Duration(days: 1);
      final lockedUntil = DateTime.now().add(lockPeriod);

      // Step 4: Create commitment record
      final commitmentData = {
        'user_id': user.id,
        'commitment_type': type.name,
        'target_merchant': type == CommitmentType.merchant ? target : null,
        'target_category': type == CommitmentType.category ? target : null,
        'spending_limit': spendingLimit,
        'time_period': timePeriod,
        'points_reward': points.reward,
        'points_penalty': points.penalty,
        'locked_until': lockedUntil.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
        'streak_count': 0,
        'difficulty': difficulty.name,
        'user_note': userNote,
      };

      final response = await _supabase
          .from('budget_commitments')
          .insert(commitmentData)
          .select()
          .single();

      final commitment = BudgetCommitment.fromJson(response);

      // Step 5: Log the commitment creation in audit trail
      await _logCommitmentAudit(
        commitmentId: commitment.id,
        action: 'created',
        details: 'Commitment locked until ${lockedUntil.toIso8601String()}',
      );

      // Step 6: Award points for creating commitment
      await _pointService.awardPoints(
        userId: user.id,
        action: PointAction.commitmentSuccess,
        points: 25, // Base points for commitment creation
        metadata: {'target': target, 'type': 'commitment_creation'},
      );

      return CommitmentCreationResult(
        success: true,
        commitment: commitment,
        message:
            ' Commitment locked! No backing down for ${_formatDuration(lockPeriod)}. You got this! ',
      );
    } catch (e) {
      debugPrint('Error creating commitment: $e');
      return CommitmentCreationResult(
        success: false,
        error: 'Failed to create commitment: $e',
      );
    }
  }

  /// Attempt to delete a commitment (requires security checks)
  Future<CommitmentDeletionResult> deleteCommitment(
      String commitmentId, String reason) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Step 1: Get the commitment
      final response = await _supabase
          .from('budget_commitments')
          .select()
          .eq('id', commitmentId)
          .eq('user_id', user.id)
          .single();

      final commitment = BudgetCommitment.fromJson(response);

      // Step 2: Check if commitment is still locked
      if (DateTime.now().isBefore(commitment.lockedUntil)) {
        final remainingTime = commitment.lockedUntil.difference(DateTime.now());
        return CommitmentDeletionResult(
          success: false,
          error:
              ' Commitment is locked for ${_formatDuration(remainingTime)} more! No cap means NO CAP! ',
          canOverride: true,
          overridePenalty: 200, // Heavy penalty for early deletion
        );
      }

      // Step 3: Require biometric authentication for deletion
      if (await _localAuth.canCheckBiometrics) {
        final authenticated = await _localAuth.authenticate(
          localizedReason:
              ' Confirm deletion of budget commitment - This action cannot be undone!',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (!authenticated) {
          return CommitmentDeletionResult(
            success: false,
            error: 'Biometric authentication required to delete commitment',
          );
        }
      }

      // Step 4: Soft delete the commitment (keep for audit trail)
      await _supabase.from('budget_commitments').update({
        'is_active': false,
        'deleted_at': DateTime.now().toIso8601String(),
        'deletion_reason': reason,
      }).eq('id', commitmentId);

      // Step 5: Log deletion in audit trail
      await _logCommitmentAudit(
        commitmentId: commitmentId,
        action: 'deleted',
        details: 'Reason: $reason',
      );

      // Step 6: Deduct points for breaking commitment early
      if (commitment.streakCount > 0) {
        await _pointService.deductPoints(
          userId: user.id,
          penalty: PointPenalty.commitmentBreak,
          points: commitment.streakCount * 10, // Lose streak bonus
          metadata: {'reason': 'Deleted commitment with active streak'},
        );
      }

      return CommitmentDeletionResult(
        success: true,
        message:
            '💔 Commitment deleted. Hope you learned something from this experience!',
      );
    } catch (e) {
      debugPrint('Error deleting commitment: $e');
      return CommitmentDeletionResult(
        success: false,
        error: 'Failed to delete commitment: $e',
      );
    }
  }

  /// Override a locked commitment (emergency deletion with heavy penalty)
  Future<CommitmentOverrideResult> overrideLockedCommitment({
    required String commitmentId,
    required String emergencyReason,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Step 1: Double biometric authentication for override
      for (int i = 0; i < 2; i++) {
        final authenticated = await _localAuth.authenticate(
          localizedReason: i == 0
              ? '🚨 EMERGENCY OVERRIDE - First authentication required'
              : '🚨 EMERGENCY OVERRIDE - Second authentication to confirm',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (!authenticated) {
          return CommitmentOverrideResult(
            success: false,
            error: 'Double authentication required for emergency override',
          );
        }
      }

      // Step 2: Get commitment details
      final response = await _supabase
          .from('budget_commitments')
          .select()
          .eq('id', commitmentId)
          .eq('user_id', user.id)
          .single();

      final commitment = BudgetCommitment.fromJson(response);

      // Step 3: Calculate massive penalty
      final overridePenalty =
          200 + (commitment.streakCount * 25); // Base + streak penalty

      // Step 4: Create cooling off period for future commitments
      final coolingOffPeriod = DateTime.now().add(const Duration(hours: 48));

      // Step 5: Override the commitment
      await _supabase.from('budget_commitments').update({
        'is_active': false,
        'overridden_at': DateTime.now().toIso8601String(),
        'override_reason': emergencyReason,
        'override_penalty': overridePenalty,
      }).eq('id', commitmentId);

      // Step 6: Set user cooling off period
      await _supabase.from('user_points').update({
        'commitment_cooloff_until': coolingOffPeriod.toIso8601String(),
      }).eq('user_id', user.id);

      // Step 7: Deduct massive points penalty
      await _pointService.deductPoints(
        userId: user.id,
        penalty: PointPenalty.emergencySpending,
        points: overridePenalty,
        metadata: {'reason': 'Emergency override of locked commitment'},
      );

      // Step 8: Log critical audit event
      await _logCommitmentAudit(
        commitmentId: commitmentId,
        action: 'emergency_override',
        details:
            'EMERGENCY OVERRIDE: $emergencyReason | Penalty: $overridePenalty points',
      );

      return CommitmentOverrideResult(
        success: true,
        pointsPenalty: overridePenalty,
        coolingOffUntil: coolingOffPeriod,
        message:
            '💥 COMMITMENT OVERRIDDEN! You lost $overridePenalty points and are in timeout until ${_formatDateTime(coolingOffPeriod)}. This better have been worth it! 😤',
      );
    } catch (e) {
      debugPrint('Error overriding commitment: $e');
      return CommitmentOverrideResult(
        success: false,
        error: 'Failed to override commitment: $e',
      );
    }
  }

  /// Get commitment statistics for user dashboard
  Future<CommitmentStats> getCommitmentStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return CommitmentStats.empty();
    }

    try {
      // Get active commitments
      final activeCommitments = await _supabase
          .from('budget_commitments')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true);

      // Get violations this month
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final violations = await _supabase
          .from('commitment_violations')
          .select('*, budget_commitments(*)')
          .gte('violation_date', monthStart.toIso8601String())
          .eq('budget_commitments.user_id', user.id);

      // Calculate stats
      final totalActive = activeCommitments.length;
      final totalStreakDays = activeCommitments.fold<int>(
          0, (sum, c) => sum + (c['streak_count'] as int? ?? 0));
      final totalViolations = violations.length;
      final violationCost = violations.fold<double>(0,
          (sum, v) => sum + ((v['violation_amount'] as num?)?.toDouble() ?? 0));

      // Longest current streak
      final longestStreak = activeCommitments.isEmpty
          ? 0
          : activeCommitments
              .map((c) => c['streak_count'] as int? ?? 0)
              .reduce((a, b) => a > b ? a : b);

      return CommitmentStats(
        activeCommitments: totalActive,
        totalStreakDays: totalStreakDays,
        longestCurrentStreak: longestStreak,
        violationsThisMonth: totalViolations,
        violationCostThisMonth: violationCost,
        successRate: totalViolations == 0
            ? 100.0
            : (1 - (totalViolations / (totalActive + totalViolations))) * 100,
      );
    } catch (e) {
      debugPrint('Error getting commitment stats: $e');
      return CommitmentStats.empty();
    }
  }

  /// Get recent violations for user review
  Future<List<RecentViolation>> getRecentViolations({int limit = 10}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('commitment_violations')
          .select('*, budget_commitments(*)')
          .eq('budget_commitments.user_id', user.id)
          .order('violation_date', ascending: false)
          .limit(limit);

      return response
          .map<RecentViolation>((data) => RecentViolation.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error getting recent violations: $e');
      return [];
    }
  }

  /// Check if user can create new commitments (not in cooling off period)
  Future<bool> canCreateCommitments() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('user_points')
          .select('commitment_cooloff_until')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return true;

      final cooloffUntil = response['commitment_cooloff_until'] as String?;
      if (cooloffUntil == null) return true;

      final cooloffDate = DateTime.parse(cooloffUntil);
      return DateTime.now().isAfter(cooloffDate);
    } catch (e) {
      debugPrint('Error checking commitment cooloff: $e');
      return true; // Default to allow if error
    }
  }

  // Private helper methods

  CommitmentPoints _calculateCommitmentPoints(
      CommitmentDifficulty difficulty, double spendingLimit) {
    final basePoints =
        (spendingLimit * 0.1).round(); // 10% of limit as base points

    switch (difficulty) {
      case CommitmentDifficulty.casual:
        return CommitmentPoints(
          reward: basePoints,
          penalty: (basePoints * 1.5).round(),
        );
      case CommitmentDifficulty.moderate:
        return CommitmentPoints(
          reward: (basePoints * 2).round(),
          penalty: (basePoints * 3).round(),
        );
      case CommitmentDifficulty.hardcore:
        return CommitmentPoints(
          reward: (basePoints * 4).round(),
          penalty: (basePoints * 6).round(),
        );
      case CommitmentDifficulty.easy:
        return CommitmentPoints(
          reward: (basePoints * 0.5).round(),
          penalty: basePoints,
        );
      case CommitmentDifficulty.medium:
        return CommitmentPoints(
          reward: (basePoints * 1.5).round(),
          penalty: (basePoints * 2).round(),
        );
      case CommitmentDifficulty.hard:
        return CommitmentPoints(
          reward: (basePoints * 3).round(),
          penalty: (basePoints * 4).round(),
        );
      case CommitmentDifficulty.extreme:
        return CommitmentPoints(
          reward: (basePoints * 5).round(),
          penalty: (basePoints * 8).round(),
        );
    }
  }

  Future<void> _logCommitmentAudit({
    required String commitmentId,
    required String action,
    required String details,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('commitment_audit_log').insert({
        'commitment_id': commitmentId,
        'action_type': action,
        'user_id': user.id,
        'timestamp': DateTime.now().toIso8601String(),
        'details': details,
        'ip_address': 'mobile_app', // In real app, get actual IP
      });
    } catch (e) {
      debugPrint('Error logging audit event: $e');
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Result Classes

class CommitmentCreationResult {
  final bool success;
  final BudgetCommitment? commitment;
  final String? message;
  final String? error;

  CommitmentCreationResult({
    required this.success,
    this.commitment,
    this.message,
    this.error,
  });
}

class CommitmentDeletionResult {
  final bool success;
  final String? message;
  final String? error;
  final bool canOverride;
  final int overridePenalty;

  CommitmentDeletionResult({
    required this.success,
    this.message,
    this.error,
    this.canOverride = false,
    this.overridePenalty = 0,
  });
}

class CommitmentOverrideResult {
  final bool success;
  final int pointsPenalty;
  final DateTime? coolingOffUntil;
  final String? message;
  final String? error;

  CommitmentOverrideResult({
    required this.success,
    this.pointsPenalty = 0,
    this.coolingOffUntil,
    this.message,
    this.error,
  });
}

class CommitmentStats {
  final int activeCommitments;
  final int totalStreakDays;
  final int longestCurrentStreak;
  final int violationsThisMonth;
  final double violationCostThisMonth;
  final double successRate;

  CommitmentStats({
    required this.activeCommitments,
    required this.totalStreakDays,
    required this.longestCurrentStreak,
    required this.violationsThisMonth,
    required this.violationCostThisMonth,
    required this.successRate,
  });

  static CommitmentStats empty() {
    return CommitmentStats(
      activeCommitments: 0,
      totalStreakDays: 0,
      longestCurrentStreak: 0,
      violationsThisMonth: 0,
      violationCostThisMonth: 0.0,
      successRate: 100.0,
    );
  }
}

class CommitmentPoints {
  final int reward;
  final int penalty;

  CommitmentPoints({
    required this.reward,
    required this.penalty,
  });
}

class RecentViolation {
  final String id;
  final String commitmentTarget;
  final double amount;
  final int pointsDeducted;
  final DateTime date;
  final bool streakBroken;

  RecentViolation({
    required this.id,
    required this.commitmentTarget,
    required this.amount,
    required this.pointsDeducted,
    required this.date,
    required this.streakBroken,
  });

  factory RecentViolation.fromJson(Map<String, dynamic> json) {
    final commitment = json['budget_commitments'];
    return RecentViolation(
      id: json['id'],
      commitmentTarget: commitment['target_merchant'] ??
          commitment['target_category'] ??
          'Unknown',
      amount: (json['violation_amount'] as num).toDouble(),
      pointsDeducted: json['points_deducted'],
      date: DateTime.parse(json['violation_date']),
      streakBroken: json['streak_broken'] ?? false,
    );
  }
}

// Add the missing method to BudgetCommitmentService class
extension BudgetCommitmentServiceExtension on BudgetCommitmentService {
  /// Get all active commitments for the current user
  Future<List<BudgetCommitment>> getActiveCommitments(String userId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('budget_commitments')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response
          .map<BudgetCommitment>((data) => BudgetCommitment.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching active commitments: $e');
      return [];
    }
  }
}
