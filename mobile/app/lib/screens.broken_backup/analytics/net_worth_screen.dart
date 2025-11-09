import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../../services/banking_service.dart';
import '../../services/plaid_service.dart';
import 'dart:math' as math;

class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  final BankingService _bankingService = BankingService();
  final PlaidService _plaidService = PlaidService();
  
  bool _isLoading = true;
  
  // Net Worth Data from Plaid
  double _totalAssets = 0;
  double _totalLiabilities = 0;
  double _netWorth = 0;
  double _monthlyChange = 0;
  double _yearlyChange = 0;
  
  List<AssetAccount> _assetAccounts = [];
  List<LiabilityAccount> _liabilityAccounts = [];
  List<NetWorthHistory> _netWorthHistory = [];
  
  @override
  void initState() {
    super.initState();
    _loadNetWorthData();
  }

  Future<void> _loadNetWorthData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get account data from Plaid
      final accounts = await _bankingService.getUserAccounts();
      
      // Process accounts into assets and liabilities
      _processAccounts(accounts);
      
      // Generate historical data (mock for now)
      _generateNetWorthHistory();
      
      // Calculate changes
      _calculateChanges();
      
    } catch (e) {
      print('Error loading net worth data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _processAccounts(List<Map<String, dynamic>> accounts) {
    _assetAccounts.clear();
    _liabilityAccounts.clear();
    _totalAssets = 0;
    _totalLiabilities = 0;
    
    for (var account in accounts) {
      final balance = (account['balance'] ?? 0.0).toDouble();
      final type = account['type'] ?? '';
      final subtype = account['subtype'] ?? '';
      
      if (type == 'depository' || type == 'investment' || type == 'brokerage') {
        // Asset accounts
        _assetAccounts.add(AssetAccount(
          name: account['name'] ?? 'Unknown Account',
          type: _getAccountTypeLabel(type, subtype),
          balance: balance,
          icon: _getAccountIcon(type, subtype),
          color: _getAccountColor(type, subtype),
        ));
        _totalAssets += balance;
      } else if (type == 'credit' || type == 'loan') {
        // Liability accounts
        _liabilityAccounts.add(LiabilityAccount(
          name: account['name'] ?? 'Unknown Account',
          type: _getAccountTypeLabel(type, subtype),
          balance: balance,
          icon: _getAccountIcon(type, subtype),
          color: _getAccountColor(type, subtype),
        ));
        _totalLiabilities += balance;
      }
    }
    
    _netWorth = _totalAssets - _totalLiabilities;
  }

  void _generateNetWorthHistory() {
    // Generate mock historical data
    final random = math.Random();
    final baseNetWorth = _netWorth;
    
    _netWorthHistory = List.generate(12, (index) {
      final monthsAgo = 11 - index;
      final variation = (random.nextDouble() - 0.5) * 5000;
      final historicalNetWorth = baseNetWorth - (monthsAgo * 500) + variation;
      
      return NetWorthHistory(
        date: DateTime.now().subtract(Duration(days: monthsAgo * 30)),
        netWorth: historicalNetWorth,
        assets: historicalNetWorth * 1.3,
        liabilities: historicalNetWorth * 0.3,
      );
    });
    
    // Add current month
    _netWorthHistory.add(NetWorthHistory(
      date: DateTime.now(),
      netWorth: _netWorth,
      assets: _totalAssets,
      liabilities: _totalLiabilities,
    ));
  }

  void _calculateChanges() {
    if (_netWorthHistory.length >= 2) {
      _monthlyChange = _netWorth - _netWorthHistory[_netWorthHistory.length - 2].netWorth;
    }
    
    if (_netWorthHistory.isNotEmpty) {
      _yearlyChange = _netWorth - _netWorthHistory.first.netWorth;
    }
  }

  String _getAccountTypeLabel(String type, String subtype) {
    if (subtype.isNotEmpty) {
      return subtype.replaceAll('_', ' ').split(' ').map((word) => 
        word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
      ).join(' ');
    }
    return type.replaceAll('_', ' ').split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
    ).join(' ');
  }

  IconData _getAccountIcon(String type, String subtype) {
    switch (type) {
      case 'depository':
        switch (subtype) {
          case 'checking':
            return Icons.account_balance_wallet;
          case 'savings':
            return Icons.savings;
          case 'cd':
            return Icons.lock_clock;
          case 'money market':
            return Icons.attach_money;
          default:
            return Icons.account_balance;
        }
      case 'investment':
      case 'brokerage':
        return Icons.trending_up;
      case 'credit':
        return Icons.credit_card;
      case 'loan':
        switch (subtype) {
          case 'mortgage':
            return Icons.home;
          case 'auto':
            return Icons.directions_car;
          case 'student':
            return Icons.school;
          default:
            return Icons.money_off;
        }
      default:
        return Icons.account_balance;
    }
  }

  Color _getAccountColor(String type, String subtype) {
    switch (type) {
      case 'depository':
        return Colors.blue;
      case 'investment':
      case 'brokerage':
        return Colors.green;
      case 'credit':
        return Colors.orange;
      case 'loan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Net Worth'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNetWorthData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNetWorthData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Net Worth Summary Card
                    _buildNetWorthSummaryCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Net Worth Chart
                    Text(
                      'Net Worth History',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: _buildNetWorthChart(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Assets & Liabilities Breakdown
                    Row(
                      children: [
                        Expanded(
                          child: _buildAssetsCard(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildLiabilitiesCard(),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Assets List
                    Text(
                      'Assets',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._assetAccounts.map((account) => 
                      _buildAccountTile(account, true)),
                    
                    const SizedBox(height: 24),
                    
                    // Liabilities List
                    if (_liabilityAccounts.isNotEmpty) ...[
                      Text(
                        'Liabilities',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._liabilityAccounts.map((account) => 
                        _buildAccountTile(account, false)),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Financial Health Score
                    _buildFinancialHealthCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNetWorthSummaryCard() {
    final theme = Theme.of(context);
    final isPositive = _netWorth >= 0;
    final monthlyChangeIsPositive = _monthlyChange >= 0;
    
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Net Worth',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${_netWorth.abs().toStringAsFixed(2)}',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: monthlyChangeIsPositive 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        monthlyChangeIsPositive 
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: monthlyChangeIsPositive 
                            ? Colors.green
                            : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${monthlyChangeIsPositive ? '+' : ''}\$${_monthlyChange.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          color: monthlyChangeIsPositive 
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'this month',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Assets',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\$${_totalAssets.toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_assetAccounts.length} accounts',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiabilitiesCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Liabilities',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\$${_totalLiabilities.toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_liabilityAccounts.length} accounts',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthChart() {
    final theme = Theme.of(context);
    
    final List<FlSpot> netWorthSpots = [];
    final List<FlSpot> assetsSpots = [];
    final List<FlSpot> liabilitiesSpots = [];
    
    for (int i = 0; i < _netWorthHistory.length; i++) {
      final history = _netWorthHistory[i];
      netWorthSpots.add(FlSpot(i.toDouble(), history.netWorth));
      assetsSpots.add(FlSpot(i.toDouble(), history.assets));
      liabilitiesSpots.add(FlSpot(i.toDouble(), history.liabilities));
    }
    
    final maxY = _netWorthHistory.map((h) => 
      math.max(h.assets, math.max(h.liabilities.abs(), h.netWorth.abs()))
    ).reduce(math.max);
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.surfaceVariant,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${(value / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < _netWorthHistory.length) {
                  final date = _netWorthHistory[value.toInt()].date;
                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  return Text(
                    months[date.month - 1],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
              interval: 2,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: _netWorthHistory.length - 1.0,
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          // Net Worth Line
          LineChartBarData(
            spots: netWorthSpots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
          // Assets Line
          LineChartBarData(
            spots: assetsSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 2,
            isStrokeCapRound: true,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
          // Liabilities Line
          LineChartBarData(
            spots: liabilitiesSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(dynamic account, bool isAsset) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: account.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            account.icon,
            color: account.color,
            size: 20,
          ),
        ),
        title: Text(account.name),
        subtitle: Text(account.type),
        trailing: Text(
          '\$${account.balance.toStringAsFixed(2)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isAsset ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialHealthCard() {
    final theme = Theme.of(context);
    
    // Calculate health score (simple formula)
    final debtToAssetRatio = _totalAssets > 0 ? _totalLiabilities / _totalAssets : 0;
    final healthScore = math.max(0, math.min(100, (1 - debtToAssetRatio) * 100));
    
    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;
    
    if (healthScore >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
      scoreIcon = Icons.sentiment_very_satisfied;
    } else if (healthScore >= 60) {
      scoreColor = Colors.blue;
      scoreLabel = 'Good';
      scoreIcon = Icons.sentiment_satisfied;
    } else if (healthScore >= 40) {
      scoreColor = Colors.orange;
      scoreLabel = 'Fair';
      scoreIcon = Icons.sentiment_neutral;
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Needs Attention';
      scoreIcon = Icons.sentiment_dissatisfied;
    }
    
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
                  'Financial Health Score',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(scoreIcon, color: scoreColor, size: 32),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: healthScore / 100,
              minHeight: 12,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(scoreColor),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${healthScore.toStringAsFixed(0)}/100',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    scoreLabel,
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Debt-to-Asset Ratio: ${(debtToAssetRatio * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data Models
class AssetAccount {
  final String name;
  final String type;
  final double balance;
  final IconData icon;
  final Color color;

  AssetAccount({
    required this.name,
    required this.type,
    required this.balance,
    required this.icon,
    required this.color,
  });
}

class LiabilityAccount {
  final String name;
  final String type;
  final double balance;
  final IconData icon;
  final Color color;

  LiabilityAccount({
    required this.name,
    required this.type,
    required this.balance,
    required this.icon,
    required this.color,
  });
}

class NetWorthHistory {
  final DateTime date;
  final double netWorth;
  final double assets;
  final double liabilities;

  NetWorthHistory({
    required this.date,
    required this.netWorth,
    required this.assets,
    required this.liabilities,
  });
}