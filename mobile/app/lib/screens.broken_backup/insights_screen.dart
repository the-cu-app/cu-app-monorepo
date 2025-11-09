import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../services/banking_service.dart';
import '../services/merchant_logo_service.dart';
import '../widgets/skeleton_loaders.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  final TransactionService _transactionService = TransactionService();
  final BankingService _bankingService = BankingService();
  final MerchantLogoService _merchantLogoService = MerchantLogoService();
  
  late TabController _tabController;
  TransactionInsights? _insights;
  Map<String, double> _monthlySpending = {};
  List<Map<String, dynamic>> _recurringTransactions = [];
  List<Map<String, dynamic>> _topTransactions = [];
  bool _isLoading = true;
  
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInsights();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    
    try {
      // Load insights
      final insights = await _transactionService.getTransactionInsights(
        startDate: _selectedRange.start,
        endDate: _selectedRange.end,
      );
      
      // Load monthly spending trend
      final monthlySpending = await _calculateMonthlySpending();
      
      // Load recurring transactions
      final recurringTxns = await _loadRecurringTransactions();
      
      // Load top transactions
      final topTxns = await _loadTopTransactions();
      
      setState(() {
        _insights = insights;
        _monthlySpending = monthlySpending;
        _recurringTransactions = recurringTxns;
        _topTransactions = topTxns;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading insights: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, double>> _calculateMonthlySpending() async {
    final spending = <String, double>{};
    
    // Get last 6 months of data
    for (int i = 0; i < 6; i++) {
      final monthStart = DateTime(
        DateTime.now().year,
        DateTime.now().month - i,
        1,
      );
      final monthEnd = DateTime(
        monthStart.year,
        monthStart.month + 1,
        0,
      );
      
      final result = await _transactionService.getTransactions(
        startDate: monthStart,
        endDate: monthEnd,
        pageSize: 100,
      );
      
      double total = 0;
      for (final txn in result.transactions) {
        final amount = (txn['amount'] ?? 0.0).toDouble();
        if (amount > 0) total += amount;
      }
      
      spending[DateFormat('MMM').format(monthStart)] = total;
    }
    
    return spending;
  }

  Future<List<Map<String, dynamic>>> _loadRecurringTransactions() async {
    final result = await _transactionService.getTransactions(
      startDate: _selectedRange.start,
      endDate: _selectedRange.end,
      pageSize: 100,
    );
    
    return result.transactions
        .where((txn) => txn['is_recurring'] == true || txn['is_subscription'] == true)
        .toList();
  }

  Future<List<Map<String, dynamic>>> _loadTopTransactions() async {
    final result = await _transactionService.getTransactions(
      startDate: _selectedRange.start,
      endDate: _selectedRange.end,
      pageSize: 100,
    );
    
    final transactions = result.transactions
        .where((txn) => (txn['amount'] ?? 0.0) > 0)
        .toList()
        ..sort((a, b) => (b['amount'] ?? 0.0).compareTo(a['amount'] ?? 0.0));
    
    return transactions.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Insights'),
        ),
        body: const AnalyticsSkeleton(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Trends'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildCategoriesTab(),
          _buildTrendsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM d').format(_selectedRange.start)} - ${DateFormat('MMM d').format(_selectedRange.end)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Spending',
                  value: '\$${_insights?.totalSpending.toStringAsFixed(2) ?? '0.00'}',
                  icon: Icons.trending_down,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Income',
                  value: '\$${_insights?.totalIncome.toStringAsFixed(2) ?? '0.00'}',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Avg Transaction',
                  value: '\$${_insights?.averageTransaction.toStringAsFixed(2) ?? '0.00'}',
                  icon: Icons.calculate,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Recurring',
                  value: '${_insights?.recurringTransactions ?? 0}',
                  icon: Icons.repeat,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          
          // Top merchants
          const SizedBox(height: 32),
          Text(
            'Top Merchants',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_insights != null)
            ...(_insights!.topMerchants).map((entry) => _buildMerchantRow(
              entry.key,
              entry.value,
            )),
          
          // Recent large transactions
          const SizedBox(height: 32),
          Text(
            'Largest Transactions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._topTransactions.map((txn) => _buildTransactionRow(txn)),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    if (_insights == null || _insights!.topCategories.isEmpty) {
      return const Center(
        child: Text('No transaction data available'),
      );
    }

    final totalSpending = _insights!.totalSpending;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Pie chart
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: _insights!.topCategories.map((entry) {
                  final percentage = (entry.value / totalSpending) * 100;
                  final color = _getCategoryColor(entry.key);
                  
                  return PieChartSectionData(
                    value: entry.value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    color: color,
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 0,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Handle touch events
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Category list
          ..._insights!.topCategories.map((entry) {
            final percentage = (entry.value / totalSpending) * 100;
            return _buildCategoryItem(
              entry.key,
              entry.value,
              percentage,
              _getCategoryColor(entry.key),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    if (_monthlySpending.isEmpty) {
      return const Center(
        child: Text('No spending data available'),
      );
    }

    final sortedMonths = _monthlySpending.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly spending chart
          Text(
            'Monthly Spending Trend',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedMonths.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sortedMonths[index].key,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1000,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${(value / 1000).toStringAsFixed(1)}k',
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                minX: 0,
                maxX: sortedMonths.length - 1.0,
                minY: 0,
                maxY: sortedMonths.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: sortedMonths.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.value);
                    }).toList(),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Recurring transactions
          const SizedBox(height: 32),
          Text(
            'Recurring & Subscriptions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_recurringTransactions.isEmpty)
            const Text('No recurring transactions found')
          else
            ..._recurringTransactions.map((txn) => _buildRecurringItem(txn)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantRow(String merchant, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          MerchantLogo(merchantName: merchant, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$count transactions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> txn) {
    final merchantName = txn['merchant_name'] ?? txn['name'] ?? 'Unknown';
    final amount = (txn['amount'] ?? 0.0).toDouble();
    final date = DateTime.tryParse(txn['date'] ?? '') ?? DateTime.now();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          MerchantLogo(merchantName: merchantName, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchantName,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM d').format(date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(1)}% of total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringItem(Map<String, dynamic> txn) {
    final merchantName = txn['merchant_name'] ?? txn['name'] ?? 'Unknown';
    final amount = (txn['amount'] ?? 0.0).toDouble();
    final isSubscription = txn['is_subscription'] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: MerchantLogo(merchantName: merchantName, size: 40),
        title: Text(merchantName),
        subtitle: Text(
          isSubscription ? 'Subscription' : 'Recurring payment',
          style: TextStyle(
            color: isSubscription ? Colors.blue : Colors.purple,
          ),
        ),
        trailing: Text(
          '\$${amount.toStringAsFixed(2)}/mo',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food & Dining': Colors.orange,
      'Shopping': Colors.blue,
      'Transportation': Colors.green,
      'Entertainment': Colors.purple,
      'Bills & Utilities': Colors.red,
      'Healthcare': Colors.pink,
      'Transfer': Colors.grey,
      'Other': Colors.teal,
    };
    return colors[category] ?? Colors.grey;
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
    );
    
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
      _loadInsights();
    }
  }
}