import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../../services/banking_service.dart';
import '../../services/plaid_service.dart';
import '../../widgets/consistent_list_tile.dart';
import 'dart:math' as math;

class SpendingAnalyticsScreen extends StatefulWidget {
  const SpendingAnalyticsScreen({super.key});

  @override
  State<SpendingAnalyticsScreen> createState() => _SpendingAnalyticsScreenState();
}

class _SpendingAnalyticsScreenState extends State<SpendingAnalyticsScreen> 
    with SingleTickerProviderStateMixin {
  final BankingService _bankingService = BankingService();
  final PlaidService _plaidService = PlaidService();
  
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  bool _isLoading = true;
  
  // Analytics data from Plaid
  Map<String, double> _categorySpending = {};
  List<SpendingTrend> _spendingTrends = [];
  double _totalSpending = 0;
  double _totalIncome = 0;
  double _netCashFlow = 0;
  List<Transaction> _topTransactions = [];
  Map<String, BudgetData> _budgets = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      // Get transactions from Plaid via our banking service
      final transactions = await _bankingService.searchTransactions(
        startDate: _getStartDate(),
        endDate: DateTime.now(),
      );
      
      // Process transactions for analytics
      _processTransactions(transactions);
      
      // Load budget data (mock for now, can be stored in Supabase)
      _loadBudgets();
      
    } catch (e) {
      print('Error loading analytics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  DateTime _getStartDate() {
    switch (_selectedPeriod) {
      case 'This Week':
        return DateTime.now().subtract(const Duration(days: 7));
      case 'This Month':
        return DateTime(DateTime.now().year, DateTime.now().month, 1);
      case 'Last Month':
        final lastMonth = DateTime.now().subtract(const Duration(days: 30));
        return DateTime(lastMonth.year, lastMonth.month, 1);
      case 'This Year':
        return DateTime(DateTime.now().year, 1, 1);
      default:
        return DateTime.now().subtract(const Duration(days: 30));
    }
  }

  void _processTransactions(List<Map<String, dynamic>> transactions) {
    _categorySpending.clear();
    _totalSpending = 0;
    _totalIncome = 0;
    _topTransactions.clear();
    
    for (var txn in transactions) {
      final amount = (txn['amount'] ?? 0.0).toDouble();
      final category = txn['category'] ?? 'Other';
      final isIncome = amount < 0; // Plaid uses negative for income
      
      if (isIncome) {
        _totalIncome += amount.abs();
      } else {
        _totalSpending += amount;
        
        // Group by category
        _categorySpending[category] = 
            (_categorySpending[category] ?? 0) + amount;
      }
      
      // Track top transactions
      if (amount > 0 && _topTransactions.length < 5) {
        _topTransactions.add(Transaction(
          name: txn['name'] ?? 'Unknown',
          amount: amount,
          category: category,
          date: DateTime.tryParse(txn['date'] ?? '') ?? DateTime.now(),
          merchantName: txn['merchant_name'],
        ));
      }
    }
    
    _netCashFlow = _totalIncome - _totalSpending;
    
    // Sort categories by spending
    _categorySpending = Map.fromEntries(
      _categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
    );
    
    // Generate spending trends (mock data for demonstration)
    _generateSpendingTrends();
  }

  void _generateSpendingTrends() {
    _spendingTrends = [
      SpendingTrend(month: 'Jan', amount: 2850),
      SpendingTrend(month: 'Feb', amount: 3200),
      SpendingTrend(month: 'Mar', amount: 2900),
      SpendingTrend(month: 'Apr', amount: 3500),
      SpendingTrend(month: 'May', amount: 3100),
      SpendingTrend(month: 'Jun', amount: _totalSpending),
    ];
  }

  void _loadBudgets() {
    _budgets = {
      'Food & Dining': BudgetData(budget: 500, spent: _categorySpending['Food & Dining'] ?? 0),
      'Shopping': BudgetData(budget: 300, spent: _categorySpending['Shopping'] ?? 0),
      'Transportation': BudgetData(budget: 200, spent: _categorySpending['Transportation'] ?? 0),
      'Entertainment': BudgetData(budget: 150, spent: _categorySpending['Entertainment'] ?? 0),
      'Bills & Utilities': BudgetData(budget: 800, spent: _categorySpending['Bills & Utilities'] ?? 0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Trends'),
            Tab(text: 'Budgets'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _loadAnalytics();
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            itemBuilder: (context) => [
              'This Week',
              'This Month',
              'Last Month',
              'This Year',
            ].map((period) => PopupMenuItem(
              value: period,
              child: Text(period),
            )).toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCategoriesTab(),
                _buildTrendsTab(),
                _buildBudgetsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cash Flow Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Income',
                  amount: _totalIncome,
                  color: Colors.green,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Spending',
                  amount: _totalSpending,
                  color: Colors.red,
                  icon: Icons.trending_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            title: 'Net Cash Flow',
            amount: _netCashFlow,
            color: _netCashFlow >= 0 ? Colors.green : Colors.red,
            icon: _netCashFlow >= 0 ? Icons.add_circle : Icons.remove_circle,
            fullWidth: true,
          ),
          
          const SizedBox(height: 24),
          
          // Spending by Category Donut Chart
          Text(
            'Spending Breakdown',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildDonutChart(),
          ),
          
          const SizedBox(height: 24),
          
          // Top Transactions
          Text(
            'Top Transactions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._topTransactions.map((txn) => _buildTransactionTile(txn)),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final theme = Theme.of(context);
    final sortedCategories = _categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCategories.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Spending by Category',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        
        final entry = sortedCategories[index - 1];
        final percentage = (_totalSpending > 0) 
            ? (entry.value / _totalSpending * 100) 
            : 0.0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(entry.key).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(entry.key),
                color: _getCategoryColor(entry.key),
                size: 20,
              ),
            ),
            title: Text(entry.key),
            subtitle: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(_getCategoryColor(entry.key)),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${entry.value.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendsTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Trends',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildLineChart(),
          ),
          const SizedBox(height: 24),
          
          // Insights
          Text(
            'Insights',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            icon: Icons.trending_up,
            title: 'Spending Trend',
            description: 'Your spending has increased by 12% compared to last month',
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildInsightCard(
            icon: Icons.restaurant,
            title: 'Top Category',
            description: 'Food & Dining is your highest spending category this month',
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildInsightCard(
            icon: Icons.savings,
            title: 'Savings Opportunity',
            description: 'You could save \$200 by reducing discretionary spending',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetsTab() {
    final theme = Theme.of(context);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _budgets.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budget Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your spending against your budget',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }
        
        final entry = _budgets.entries.toList()[index - 1];
        final percentage = (entry.value.budget > 0) 
            ? (entry.value.spent / entry.value.budget).clamp(0.0, 1.0)
            : 0.0;
        final remaining = math.max(0, entry.value.budget - entry.value.spent);
        final isOverBudget = entry.value.spent > entry.value.budget;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOverBudget 
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOverBudget 
                            ? 'Over by \$${(entry.value.spent - entry.value.budget).toStringAsFixed(2)}'
                            : '\$${remaining.toStringAsFixed(2)} left',
                        style: TextStyle(
                          color: isOverBudget ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Spent: \$${entry.value.spent.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                'Budget: \$${entry.value.budget.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              minHeight: 8,
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation(
                                isOverBudget ? Colors.red : _getCategoryColor(entry.key),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}% of budget used',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    bool fullWidth = false,
  }) {
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${amount.abs().toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart() {
    final theme = Theme.of(context);
    final data = _categorySpending.entries.take(5).toList();
    
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.map((entry) {
                final percentage = (_totalSpending > 0)
                    ? (entry.value / _totalSpending * 100)
                    : 0.0;
                
                return PieChartSectionData(
                  color: _getCategoryColor(entry.key),
                  value: entry.value,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    final theme = Theme.of(context);
    final maxY = _spendingTrends.map((e) => e.amount).reduce(math.max);
    
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
                  '\$${(value / 1000).toStringAsFixed(1)}k',
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
                if (value.toInt() < _spendingTrends.length) {
                  return Text(
                    _spendingTrends[value.toInt()].month,
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: _spendingTrends.length - 1.0,
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: _spendingTrends.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.amount);
            }).toList(),
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Transaction txn) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(txn.category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(txn.category),
            color: _getCategoryColor(txn.category),
            size: 20,
          ),
        ),
        title: Text(txn.merchantName ?? txn.name),
        subtitle: Text(txn.category),
        trailing: Text(
          '\$${txn.amount.toStringAsFixed(2)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(description),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food and drink':
        return Colors.orange;
      case 'shopping':
      case 'shops':
        return Colors.pink;
      case 'transportation':
      case 'travel':
        return Colors.blue;
      case 'entertainment':
      case 'recreation':
        return Colors.purple;
      case 'bills & utilities':
      case 'service':
        return Colors.red;
      case 'healthcare':
      case 'medical':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food and drink':
        return Icons.restaurant;
      case 'shopping':
      case 'shops':
        return Icons.shopping_bag;
      case 'transportation':
      case 'travel':
        return Icons.directions_car;
      case 'entertainment':
      case 'recreation':
        return Icons.movie;
      case 'bills & utilities':
      case 'service':
        return Icons.receipt;
      case 'healthcare':
      case 'medical':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }
}

// Data Models
class SpendingTrend {
  final String month;
  final double amount;

  SpendingTrend({required this.month, required this.amount});
}

class Transaction {
  final String name;
  final double amount;
  final String category;
  final DateTime date;
  final String? merchantName;

  Transaction({
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
    this.merchantName,
  });
}

class BudgetData {
  final double budget;
  final double spent;

  BudgetData({required this.budget, required this.spent});
}