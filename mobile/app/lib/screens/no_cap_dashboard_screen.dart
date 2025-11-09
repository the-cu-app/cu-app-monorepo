import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/no_cap_ai_service.dart';
import '../services/budget_commitment_service.dart';
import '../services/point_system_service.dart' as point_service;
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class NoCapDashboardScreen extends StatefulWidget {
  const NoCapDashboardScreen({super.key});

  @override
  State<NoCapDashboardScreen> createState() => _NoCapDashboardScreenState();
}

class _NoCapDashboardScreenState extends State<NoCapDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final String _userId = 'current_user'; // Replace with actual user ID

  point_service.UserPointStats? _userStats;
  List<BudgetCommitment> _activeCommitments = [];
  List<point_service.Achievement> _recentAchievements = [];
  List<point_service.PointUpdate> _recentPointHistory = [];
  bool _isLoading = true;

  // Services
  final _pointService = point_service.PointSystemService();
  final _commitmentService = BudgetCommitmentService();
  final _aiService = NoCapAIService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
    _setupStreams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load all dashboard data in parallel
      final futures = await Future.wait([
        _pointService.getUserStats(_userId),
        _commitmentService.getActiveCommitments(_userId),
        _pointService.getUserAchievements(_userId),
      ]);

      setState(() {
        _userStats = futures[0] as point_service.UserPointStats;
        _activeCommitments = futures[1] as List<BudgetCommitment>;
        _recentAchievements =
            (futures[2] as List<point_service.Achievement>).take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard: $e')),
        );
      }
    }
  }

  void _setupStreams() {
    // Listen for point updates
    _pointService.pointUpdateStream.listen((update) {
      if (update.userId == _userId) {
        _loadDashboardData(); // Refresh data

        // Show point update notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(update.pointsAwarded > 0
                  ? ' +${update.pointsAwarded} points!'
                  : ' ${update.pointsAwarded} points'),
              backgroundColor:
                  update.pointsAwarded > 0 ? Colors.green : Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });

    // Listen for achievement unlocks
    _pointService.achievementStream.listen((point_service.Achievement achievement) {
      if (mounted) {
        _showAchievementDialog(achievement);
      }
    });

    // Listen for violations
    _aiService.violationStream.listen((violation) {
      if (mounted) {
        _showViolationAlert(violation);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'No Cap',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Can\'t Take It Back',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showNotifications,
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Commitments'),
            Tab(text: 'Achievements'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCommitmentsTab(),
                _buildAchievementsTab(),
                _buildLeaderboardTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewCommitment(),
        icon: const Icon(Icons.add_circle),
        label: const Text('New Commitment'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_userStats == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildStreakCard(),
            const SizedBox(height: 16),
            _buildQuickActionsCard(),
            const SizedBox(height: 16),
            _buildRecentActivityCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Stats',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Level ${_userStats!.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '',
                    'Points',
                    NumberFormat('#,###').format(_userStats!.totalPoints),
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '',
                    'Streak',
                    '${_userStats!.currentStreak} days',
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '🎖',
                    'Achievements',
                    '${_userStats!.achievementsUnlocked}',
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '',
                    'Best Streak',
                    '${_userStats!.longestStreak} days',
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    final streakColor = _getStreakColor(_userStats!.currentStreak);
    final streakMessage = _getStreakMessage(_userStats!.currentStreak);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              streakColor.withValues(alpha: 0.1),
              streakColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: streakColor, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Streak Status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              streakMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: streakColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_userStats!.currentStreak % 7) / 7,
              backgroundColor: streakColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(streakColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Next milestone in ${7 - (_userStats!.currentStreak % 7)} days',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildActionButton(
                  'New Commitment',
                  Icons.lock,
                  Colors.deepPurple,
                  () => _createNewCommitment(),
                ),
                _buildActionButton(
                  'View Rewards',
                  Icons.redeem,
                  Colors.orange,
                  () => _showRewards(),
                ),
                _buildActionButton(
                  'Emergency Stop',
                  Icons.emergency_outlined,
                  Colors.red,
                  () => _showEmergencyOptions(),
                ),
                _buildActionButton(
                  'AI Coach',
                  Icons.psychology,
                  Colors.blue,
                  () => _showAICoach(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => _showFullHistory(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Show recent achievements or activity
            if (_recentAchievements.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.timeline,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recent activity',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create your first commitment to get started!',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._recentAchievements.take(3).map(
                    (achievement) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: achievement.isRare
                            ? Colors.purple.withValues(alpha: 0.2)
                            : Colors.amber.withValues(alpha: 0.2),
                        child: Text(achievement.icon),
                      ),
                      title: Text(achievement.name),
                      subtitle: Text(achievement.description),
                      trailing: Text(
                        '+${achievement.points}pts',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommitmentsTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Commitments',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (_activeCommitments.isEmpty)
              _buildEmptyCommitments()
            else
              ..._activeCommitments
                  .map((commitment) => _buildCommitmentCard(commitment)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCommitments() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.lock_open,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Commitments Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ready to lock in your financial goals? Create your first "No Cap" commitment and start building unstoppable habits!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _createNewCommitment,
              icon: const Icon(Icons.add_circle),
              label: const Text('Create First Commitment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommitmentCard(BudgetCommitment commitment) {
    final progress = commitment.currentSpent / commitment.spendingLimit;
    final isViolated = progress > 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  commitment.isLocked ? Icons.lock : Icons.lock_open,
                  color: commitment.isLocked ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    commitment.target,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(commitment.difficulty)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    commitment.difficulty.name.toUpperCase(),
                    style: TextStyle(
                      color: _getDifficultyColor(commitment.difficulty),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(
                isViolated ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${commitment.currentSpent.toStringAsFixed(2)} / \$${commitment.spendingLimit.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isViolated ? Colors.red : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isViolated ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (isViolated) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'VIOLATED: Over budget by \$${(commitment.currentSpent - commitment.spendingLimit).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Achievements',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (_recentAchievements.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Achievements Yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start making commitments and keeping them to unlock achievements!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._recentAchievements.map(
                (achievement) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: achievement.isRare
                          ? Colors.purple.withValues(alpha: 0.2)
                          : Colors.amber.withValues(alpha: 0.2),
                      child: Text(
                        achievement.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          achievement.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (achievement.isRare) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'RARE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(achievement.description),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '+${achievement.points}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'points',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return FutureBuilder<List<point_service.LeaderboardEntry>>(
      future: _pointService.getLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Leaderboard coming soon!'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Global Leaderboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...snapshot.data!.asMap().entries.map((entry) {
                final index = entry.key;
                final leader = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRankColor(leader.rank),
                      child: Text(
                        '#${leader.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      leader.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${leader.totalPoints} points'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department,
                            size: 16, color: Colors.orange),
                        Text('${leader.currentStreak}'),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Helper methods
  Color _getStreakColor(int streak) {
    if (streak >= 30) return Colors.purple;
    if (streak >= 14) return Colors.orange;
    if (streak >= 7) return Colors.red;
    return Colors.grey;
  }

  String _getStreakMessage(int streak) {
    if (streak == 0) return 'Start your streak today! ';
    if (streak >= 30) return ' LEGENDARY streak! You\'re unstoppable!';
    if (streak >= 14) return ' Amazing consistency! Keep it up!';
    if (streak >= 7) return ' Great week! You\'re building momentum!';
    return ' Building your streak, day by day!';
  }

  Color _getDifficultyColor(CommitmentDifficulty difficulty) {
    switch (difficulty) {
      case CommitmentDifficulty.easy:
        return Colors.green;
      case CommitmentDifficulty.medium:
        return Colors.orange;
      case CommitmentDifficulty.hard:
        return Colors.red;
      case CommitmentDifficulty.extreme:
        return Colors.purple;
      case CommitmentDifficulty.casual:
        return Colors.blue;
      case CommitmentDifficulty.moderate:
        return Colors.amber;
      case CommitmentDifficulty.hardcore:
        return Colors.deepPurple;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  // Action methods
  void _createNewCommitment() {
    // Navigate to commitment creation screen
    Navigator.pushNamed(context, '/create-commitment');
  }

  void _showRewards() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Available Rewards',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.redeem, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'Rewards Coming Soon!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                        'Keep earning points to unlock amazing rewards!'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Emergency Options'),
        content: const Text(
          'Emergency spending detected or need to break a commitment? '
          'Remember: No Cap means no backing down, but we understand life happens.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to emergency options
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showAICoach() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'No Cap AI Coach',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🤖 "Ready to lock in those financial goals?"',
                      style:
                          TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to AI chat
                      },
                      child: const Text('Chat with AI Coach'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    // Show notifications screen
  }

  void _showFullHistory() {
    // Show full activity history
  }

  void _showAchievementDialog(point_service.Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('Achievement Unlocked!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              achievement.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(achievement.description),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${achievement.points} Points Earned!',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  void _showViolationAlert(BudgetViolation violation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Budget Violation!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(violation.message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Penalty: -${violation.penaltyPoints} points',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
