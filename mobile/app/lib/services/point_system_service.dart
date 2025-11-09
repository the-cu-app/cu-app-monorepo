import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class PointSystemService {
  static final PointSystemService _instance = PointSystemService._internal();
  factory PointSystemService() => _instance;
  PointSystemService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Real-time point updates
  final StreamController<PointUpdate> _pointUpdateController = 
      StreamController<PointUpdate>.broadcast();
  Stream<PointUpdate> get pointUpdateStream => _pointUpdateController.stream;

  // Achievement unlocks
  final StreamController<Achievement> _achievementController = 
      StreamController<Achievement>.broadcast();
  Stream<Achievement> get achievementStream => _achievementController.stream;

  // Streak updates
  final StreamController<StreakUpdate> _streakController = 
      StreamController<StreakUpdate>.broadcast();
  Stream<StreakUpdate> get streakStream => _streakController.stream;

  /// Award points for various actions
  Future<PointAwardResult> awardPoints({
    required String userId,
    required PointAction action,
    required int points,
    Map<String, dynamic>? metadata,
    String? commitmentId,
  }) async {
    try {
      // Get current user stats
      final userStats = await getUserStats(userId);
      final newTotal = userStats.totalPoints + points;
      
      // Calculate multipliers
      final multiplier = _calculateMultiplier(userStats, action);
      final finalPoints = (points * multiplier).round();
      
      // Create point transaction
      final pointTransaction = {
        'user_id': userId,
        'action': action.name,
        'base_points': points,
        'multiplier': multiplier,
        'final_points': finalPoints,
        'metadata': metadata ?? {},
        'commitment_id': commitmentId,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insert point transaction
      await _supabase
          .from('point_transactions')
          .insert(pointTransaction);

      // Update user total points
      await _supabase
          .from('user_point_stats')
          .upsert({
            'user_id': userId,
            'total_points': newTotal + finalPoints,
            'lifetime_earned': userStats.lifetimeEarned + finalPoints,
            'current_streak': action == PointAction.commitmentSuccess 
                ? userStats.currentStreak + 1 
                : userStats.currentStreak,
            'longest_streak': max(
              userStats.longestStreak, 
              action == PointAction.commitmentSuccess 
                  ? userStats.currentStreak + 1 
                  : userStats.currentStreak
            ),
            'updated_at': DateTime.now().toIso8601String(),
          });

      // Check for achievements
      final achievements = await _checkAchievements(userId, newTotal + finalPoints, action);
      
      // Check for streak milestones
      await _checkStreakMilestones(userId, userStats.currentStreak + 1);

      // Emit point update
      _pointUpdateController.add(PointUpdate(
        userId: userId,
        action: action,
        pointsAwarded: finalPoints,
        newTotal: newTotal + finalPoints,
        multiplier: multiplier,
        achievements: achievements,
      ));

      return PointAwardResult(
        success: true,
        pointsAwarded: finalPoints,
        multiplier: multiplier,
        newTotal: newTotal + finalPoints,
        achievements: achievements,
        message: _getSuccessMessage(action, finalPoints),
      );

    } catch (e) {
      debugPrint('Error awarding points: $e');
      return PointAwardResult(
        success: false,
        pointsAwarded: 0,
        multiplier: 1.0,
        newTotal: 0,
        achievements: [],
        message: 'Failed to award points',
      );
    }
  }

  /// Deduct points for violations
  Future<PointDeductionResult> deductPoints({
    required String userId,
    required PointPenalty penalty,
    required int points,
    Map<String, dynamic>? metadata,
    String? commitmentId,
  }) async {
    try {
      final userStats = await getUserStats(userId);
      
      // Calculate penalty multiplier based on violation severity
      final penaltyMultiplier = _calculatePenaltyMultiplier(userStats, penalty);
      final finalDeduction = (points * penaltyMultiplier).round();
      
      // Ensure user can't go below 0 points
      final newTotal = max(0, userStats.totalPoints - finalDeduction);
      
      // Reset streak if major violation
      final newStreak = penalty.resetStreak ? 0 : userStats.currentStreak;
      
      // Create penalty transaction
      final penaltyTransaction = {
        'user_id': userId,
        'penalty_type': penalty.name,
        'base_points': -points,
        'multiplier': penaltyMultiplier,
        'final_points': -finalDeduction,
        'metadata': metadata ?? {},
        'commitment_id': commitmentId,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insert penalty transaction
      await _supabase
          .from('point_transactions')
          .insert(penaltyTransaction);

      // Update user stats
      await _supabase
          .from('user_point_stats')
          .upsert({
            'user_id': userId,
            'total_points': newTotal,
            'current_streak': newStreak,
            'violations_count': userStats.violationsCount + 1,
            'updated_at': DateTime.now().toIso8601String(),
          });

      // Emit point update
      _pointUpdateController.add(PointUpdate(
        userId: userId,
        action: PointAction.violation,
        pointsAwarded: -finalDeduction,
        newTotal: newTotal,
        multiplier: penaltyMultiplier,
        achievements: [],
      ));

      return PointDeductionResult(
        success: true,
        pointsDeducted: finalDeduction,
        penaltyMultiplier: penaltyMultiplier,
        newTotal: newTotal,
        streakReset: penalty.resetStreak,
        message: _getPenaltyMessage(penalty, finalDeduction),
      );

    } catch (e) {
      debugPrint('Error deducting points: $e');
      return PointDeductionResult(
        success: false,
        pointsDeducted: 0,
        penaltyMultiplier: 1.0,
        newTotal: 0,
        streakReset: false,
        message: 'Failed to process penalty',
      );
    }
  }

  /// Get user point statistics
  Future<UserPointStats> getUserStats(String userId) async {
    try {
      final response = await _supabase
          .from('user_point_stats')
          .select()
          .eq('user_id', userId)
          .single();

      return UserPointStats.fromMap(response);
    } catch (e) {
      // Return default stats if user doesn't exist
      return UserPointStats(
        userId: userId,
        totalPoints: 0,
        lifetimeEarned: 0,
        currentStreak: 0,
        longestStreak: 0,
        level: 1,
        violationsCount: 0,
        achievementsUnlocked: 0,
      );
    }
  }

  /// Get user's achievement progress
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final response = await _supabase
          .from('user_achievements')
          .select('*, achievements(*)')
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);

      return response
          .map((item) => Achievement.fromMap(item['achievements']))
          .toList();
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      return [];
    }
  }

  /// Get leaderboard data
  Future<List<LeaderboardEntry>> getLeaderboard({
    LeaderboardType type = LeaderboardType.totalPoints,
    int limit = 10,
  }) async {
    try {
      String orderBy;
      switch (type) {
        case LeaderboardType.totalPoints:
          orderBy = 'total_points';
          break;
        case LeaderboardType.currentStreak:
          orderBy = 'current_streak';
          break;
        case LeaderboardType.longestStreak:
          orderBy = 'longest_streak';
          break;
        case LeaderboardType.achievements:
          orderBy = 'achievements_unlocked';
          break;
      }

      final response = await _supabase
          .from('user_point_stats')
          .select('*, users(display_name, avatar_url)')
          .order(orderBy, ascending: false)
          .limit(limit);

      return response
          .asMap()
          .entries
          .map((entry) => LeaderboardEntry.fromMap(entry.value, entry.key + 1))
          .toList();
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Redeem points for rewards
  Future<RedemptionResult> redeemReward({
    required String userId,
    required String rewardId,
  }) async {
    try {
      // Get reward details
      final rewardResponse = await _supabase
          .from('rewards')
          .select()
          .eq('id', rewardId)
          .single();

      final reward = Reward.fromMap(rewardResponse);
      final userStats = await getUserStats(userId);

      // Check if user has enough points
      if (userStats.totalPoints < reward.cost) {
        return RedemptionResult(
          success: false,
          message: 'Insufficient points! You need ${reward.cost - userStats.totalPoints} more points.',
        );
      }

      // Check if reward is available
      if (!reward.isAvailable) {
        return RedemptionResult(
          success: false,
          message: 'This reward is currently unavailable.',
        );
      }

      // Process redemption
      final newTotal = userStats.totalPoints - reward.cost;
      
      // Update user points
      await _supabase
          .from('user_point_stats')
          .update({'total_points': newTotal})
          .eq('user_id', userId);

      // Create redemption record
      await _supabase
          .from('reward_redemptions')
          .insert({
            'user_id': userId,
            'reward_id': rewardId,
            'points_spent': reward.cost,
            'redeemed_at': DateTime.now().toIso8601String(),
          });

      // Create point transaction
      await _supabase
          .from('point_transactions')
          .insert({
            'user_id': userId,
            'action': 'reward_redemption',
            'base_points': -reward.cost,
            'multiplier': 1.0,
            'final_points': -reward.cost,
            'metadata': {'reward_id': rewardId, 'reward_name': reward.name},
            'created_at': DateTime.now().toIso8601String(),
          });

      // Emit point update
      _pointUpdateController.add(PointUpdate(
        userId: userId,
        action: PointAction.rewardRedemption,
        pointsAwarded: -reward.cost,
        newTotal: newTotal,
        multiplier: 1.0,
        achievements: [],
      ));

      return RedemptionResult(
        success: true,
        message: ' Successfully redeemed ${reward.name}!',
        reward: reward,
        newPointBalance: newTotal,
      );

    } catch (e) {
      debugPrint('Error redeeming reward: $e');
      return RedemptionResult(
        success: false,
        message: 'Failed to redeem reward. Please try again.',
      );
    }
  }

  /// Calculate point multipliers based on user performance
  double _calculateMultiplier(UserPointStats stats, PointAction action) {
    double multiplier = 1.0;
    
    // Streak bonus
    if (stats.currentStreak >= 30) {
      multiplier += 0.5; // 50% bonus for 30+ day streak
    } else if (stats.currentStreak >= 14) {
      multiplier += 0.3; // 30% bonus for 14+ day streak  
    } else if (stats.currentStreak >= 7) {
      multiplier += 0.2; // 20% bonus for 7+ day streak
    }
    
    // Level bonus
    multiplier += (stats.level - 1) * 0.1; // 10% per level above 1
    
    // Action-specific multipliers
    switch (action) {
      case PointAction.commitmentSuccess:
        multiplier += 0.2; // Extra bonus for keeping commitments
        break;
      case PointAction.emergencyAverted:
        multiplier += 0.5; // Big bonus for avoiding emergency spending
        break;
      case PointAction.savingsGoalMet:
        multiplier += 0.3; // Good bonus for savings
        break;
      default:
        break;
    }
    
    return multiplier;
  }

  /// Calculate penalty multipliers for violations
  double _calculatePenaltyMultiplier(UserPointStats stats, PointPenalty penalty) {
    double multiplier = 1.0;
    
    // Repeat offender penalty
    if (stats.violationsCount >= 10) {
      multiplier += 0.5; // 50% more penalty for serial violators
    } else if (stats.violationsCount >= 5) {
      multiplier += 0.3; // 30% more penalty
    } else if (stats.violationsCount >= 3) {
      multiplier += 0.2; // 20% more penalty
    }
    
    // High streak penalty (more to lose)
    if (stats.currentStreak >= 30) {
      multiplier += 0.3; // Bigger penalty when on long streaks
    } else if (stats.currentStreak >= 14) {
      multiplier += 0.2;
    }
    
    return multiplier;
  }

  /// Check for achievement unlocks
  Future<List<Achievement>> _checkAchievements(String userId, int totalPoints, PointAction action) async {
    List<Achievement> newAchievements = [];
    
    try {
      // Get all achievements user hasn't unlocked
      final unlockedIds = await _supabase
          .from('user_achievements')
          .select('achievement_id')
          .eq('user_id', userId);
      
      final unlockedSet = unlockedIds.map((item) => item['achievement_id']).toSet();
      
      final availableAchievements = await _supabase
          .from('achievements')
          .select()
          .not('id', 'in', unlockedSet);

      final userStats = await getUserStats(userId);
      
      for (final achievementMap in availableAchievements) {
        final achievement = Achievement.fromMap(achievementMap);
        
        bool shouldUnlock = false;
        
        // Check achievement conditions
        switch (achievement.type) {
          case AchievementType.pointMilestone:
            shouldUnlock = totalPoints >= achievement.target;
            break;
          case AchievementType.streakMilestone:
            shouldUnlock = userStats.currentStreak >= achievement.target;
            break;
          case AchievementType.commitmentCount:
            // Would need to query commitment count
            break;
          case AchievementType.savingsAmount:
            // Would need to query savings data
            break;
        }
        
        if (shouldUnlock) {
          // Unlock achievement
          await _supabase
              .from('user_achievements')
              .insert({
                'user_id': userId,
                'achievement_id': achievement.id,
                'unlocked_at': DateTime.now().toIso8601String(),
              });
          
          // Award achievement points
          await _supabase
              .from('point_transactions')
              .insert({
                'user_id': userId,
                'action': 'achievement_unlock',
                'base_points': achievement.points,
                'multiplier': 1.0,
                'final_points': achievement.points,
                'metadata': {'achievement_id': achievement.id, 'achievement_name': achievement.name},
                'created_at': DateTime.now().toIso8601String(),
              });
          
          newAchievements.add(achievement);
          
          // Emit achievement unlock
          _achievementController.add(achievement);
        }
      }
      
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
    
    return newAchievements;
  }

  /// Check for streak milestones
  Future<void> _checkStreakMilestones(String userId, int streak) async {
    final milestones = [7, 14, 30, 60, 90, 180, 365];
    
    if (milestones.contains(streak)) {
      _streakController.add(StreakUpdate(
        userId: userId,
        newStreak: streak,
        milestone: streak,
        bonusPoints: streak * 10, // 10 points per day in streak
      ));
      
      // Award milestone bonus
      await awardPoints(
        userId: userId,
        action: PointAction.streakMilestone,
        points: streak * 10,
        metadata: {'streak_days': streak},
      );
    }
  }

  String _getSuccessMessage(PointAction action, int points) {
    switch (action) {
      case PointAction.commitmentSuccess:
        return ' No cap kept! +$points points for staying strong!';
      case PointAction.savingsGoalMet:
        return '💰 Savings goal crushed! +$points points!';
      case PointAction.emergencyAverted:
        return ' Emergency spending avoided! +$points points!';
      case PointAction.streakMilestone:
        return ' Streak milestone! +$points bonus points!';
      case PointAction.budgetUnderLimit:
        return ' Under budget! +$points points!';
      default:
        return ' Great job! +$points points!';
    }
  }

  String _getPenaltyMessage(PointPenalty penalty, int points) {
    switch (penalty) {
      case PointPenalty.minorViolation:
        return ' Budget slip-up. -$points points. Get back on track!';
      case PointPenalty.majorViolation:
        return '🚨 Major violation! -$points points and streak reset!';
      case PointPenalty.commitmentBreak:
        return '💔 Commitment broken. -$points points. No cap means no cap!';
      case PointPenalty.emergencySpending:
        return ' Emergency spending detected. -$points points.';
      default:
        return ' -$points points. Stay focused!';
    }
  }

  void dispose() {
    _pointUpdateController.close();
    _achievementController.close();
    _streakController.close();
  }
}

// Enums and Data Models
enum PointAction {
  commitmentSuccess,
  savingsGoalMet,
  budgetUnderLimit,
  emergencyAverted,
  streakMilestone,
  dailyCheckIn,
  rewardRedemption,
  violation,
}

enum PointPenalty {
  minorViolation(resetStreak: false),
  majorViolation(resetStreak: true),
  commitmentBreak(resetStreak: true),
  emergencySpending(resetStreak: false);

  const PointPenalty({required this.resetStreak});
  final bool resetStreak;
}

enum LeaderboardType {
  totalPoints,
  currentStreak,
  longestStreak,
  achievements,
}

enum AchievementType {
  pointMilestone,
  streakMilestone,
  commitmentCount,
  savingsAmount,
}

// Data Classes
class PointUpdate {
  final String userId;
  final PointAction action;
  final int pointsAwarded;
  final int newTotal;
  final double multiplier;
  final List<Achievement> achievements;

  PointUpdate({
    required this.userId,
    required this.action,
    required this.pointsAwarded,
    required this.newTotal,
    required this.multiplier,
    required this.achievements,
  });
}

class PointAwardResult {
  final bool success;
  final int pointsAwarded;
  final double multiplier;
  final int newTotal;
  final List<Achievement> achievements;
  final String message;

  PointAwardResult({
    required this.success,
    required this.pointsAwarded,
    required this.multiplier,
    required this.newTotal,
    required this.achievements,
    required this.message,
  });
}

class PointDeductionResult {
  final bool success;
  final int pointsDeducted;
  final double penaltyMultiplier;
  final int newTotal;
  final bool streakReset;
  final String message;

  PointDeductionResult({
    required this.success,
    required this.pointsDeducted,
    required this.penaltyMultiplier,
    required this.newTotal,
    required this.streakReset,
    required this.message,
  });
}

class UserPointStats {
  final String userId;
  final int totalPoints;
  final int lifetimeEarned;
  final int currentStreak;
  final int longestStreak;
  final int level;
  final int violationsCount;
  final int achievementsUnlocked;
  final DateTime? lastActivity;

  UserPointStats({
    required this.userId,
    required this.totalPoints,
    required this.lifetimeEarned,
    required this.currentStreak,
    required this.longestStreak,
    required this.level,
    required this.violationsCount,
    required this.achievementsUnlocked,
    this.lastActivity,
  });

  factory UserPointStats.fromMap(Map<String, dynamic> map) {
    return UserPointStats(
      userId: map['user_id'] ?? '',
      totalPoints: map['total_points'] ?? 0,
      lifetimeEarned: map['lifetime_earned'] ?? 0,
      currentStreak: map['current_streak'] ?? 0,
      longestStreak: map['longest_streak'] ?? 0,
      level: map['level'] ?? 1,
      violationsCount: map['violations_count'] ?? 0,
      achievementsUnlocked: map['achievements_unlocked'] ?? 0,
      lastActivity: map['last_activity'] != null 
          ? DateTime.parse(map['last_activity']) 
          : null,
    );
  }
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int points;
  final AchievementType type;
  final int target;
  final bool isRare;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.points,
    required this.type,
    required this.target,
    required this.isRare,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      points: map['points'] ?? 0,
      type: AchievementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AchievementType.pointMilestone,
      ),
      target: map['target'] ?? 0,
      isRare: map['is_rare'] ?? false,
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;
  final int achievementsUnlocked;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.totalPoints,
    required this.currentStreak,
    required this.longestStreak,
    required this.achievementsUnlocked,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, int rank) {
    return LeaderboardEntry(
      rank: rank,
      userId: map['user_id'] ?? '',
      displayName: map['users']['display_name'] ?? 'Anonymous',
      avatarUrl: map['users']['avatar_url'],
      totalPoints: map['total_points'] ?? 0,
      currentStreak: map['current_streak'] ?? 0,
      longestStreak: map['longest_streak'] ?? 0,
      achievementsUnlocked: map['achievements_unlocked'] ?? 0,
    );
  }
}

class Reward {
  final String id;
  final String name;
  final String description;
  final int cost;
  final String icon;
  final bool isAvailable;
  final DateTime? expiresAt;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.icon,
    required this.isAvailable,
    this.expiresAt,
  });

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      cost: map['cost'] ?? 0,
      icon: map['icon'] ?? '',
      isAvailable: map['is_available'] ?? true,
      expiresAt: map['expires_at'] != null 
          ? DateTime.parse(map['expires_at']) 
          : null,
    );
  }
}

class RedemptionResult {
  final bool success;
  final String message;
  final Reward? reward;
  final int? newPointBalance;

  RedemptionResult({
    required this.success,
    required this.message,
    this.reward,
    this.newPointBalance,
  });
}

class StreakUpdate {
  final String userId;
  final int newStreak;
  final int milestone;
  final int bonusPoints;

  StreakUpdate({
    required this.userId,
    required this.newStreak,
    required this.milestone,
    required this.bonusPoints,
  });
}