import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../services/banking_service.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../widgets/merchant_logo_widget.dart';
import 'transaction_search_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final BankingService _bankingService = BankingService();
  
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  double _totalSpending = 1969.82;
  double _totalIncome = 3740.13;
  
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load demo transactions with real vendor names for logo matching
      final transactions = [
        {
          'id': '1',
          'merchant_name': 'Starbucks',
          'category': 'Food & Coffee',
          'amount': 5.75,
          'date': DateTime.now().toIso8601String(),
          'pending': true,
          'account_name': 'Chase Total Checking',
        },
        {
          'id': '2',
          'merchant_name': 'Whole Foods',
          'category': 'Food & Groceries',
          'amount': 89.99,
          'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'pending': false,
          'account_name': 'Chase Total Checking',
        },
        {
          'id': '3',
          'merchant_name': 'Tech Corp Payroll',
          'category': 'Transfer',
          'amount': -3500.00,
          'date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'pending': false,
          'account_name': 'Chase Total Checking',
          'is_income': true,
          'is_recurring': true,
        },
        {
          'id': '4',
          'merchant_name': 'Netflix',
          'category': 'Entertainment',
          'amount': 15.99,
          'date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          'pending': false,
          'account_name': 'Chase Total Checking',
          'is_recurring': true,
        },
        {
          'id': '5',
          'merchant_name': 'Shell',
          'category': 'Transportation',
          'amount': 45.00,
          'date': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          'pending': false,
          'account_name': 'Chase Total Checking',
        },
        {
          'id': 'insight_1',
          'type': 'insight',
          'title': 'Spending Insight',
          'message': 'You\'ve spent 23% less on dining this month',
          'icon': Icons.trending_down,
          'color': Colors.green,
        },
        {
          'id': '6',
          'merchant_name': 'Amazon',
          'category': 'Shopping',
          'amount': 127.43,
          'date': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
          'pending': false,
          'account_name': 'Chase Total Checking',
        },
        {
          'id': '7',
          'merchant_name': 'Target',
          'category': 'Shopping',
          'amount': 67.21,
          'date': DateTime.now().subtract(const Duration(days: 9)).toIso8601String(),
          'pending': false,
          'account_name': 'Chase Total Checking',
        },
        {
          'id': '8',
          'merchant_name': 'Uber',
          'category': 'Transportation',
          'amount': 18.50,
          'date': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
          'pending': false,
          'account_name': 'Chase Total Checking',
        },
        {
          'id': 'insight_2',
          'type': 'insight',
          'title': 'Recurring Payment',
          'message': 'Your Netflix subscription will renew in 2 days',
          'icon': Icons.notifications,
          'color': Colors.blue,
        },
        {
          'id': '9',
          'merchant_name': 'Spotify',
          'category': 'Entertainment',
          'amount': 9.99,
          'date': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
          'pending': false,
          'account_name': 'Chase Total Checking',
          'is_recurring': true,
        },
        {
          'id': '10',
          'merchant_name': 'CVS Pharmacy',
          'category': 'Health & Medical',
          'amount': 23.45,
          'date': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
          'pending': false,
          'account_name': 'Chase Total Checking',
        },
        {
          'id': '11',
          'merchant_name': 'Apple Store',
          'category': 'Shopping',
          'amount': 1299.00,
          'date': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
          'pending': false,
          'account_name': 'Chase Total Checking',
        },
        {
          'id': 'insight_3',
          'type': 'insight',
          'title': 'Budget Alert',
          'message': 'You\'ve reached 80% of your shopping budget',
          'icon': Icons.warning,
          'color': Colors.orange,
        },
        {
          'id': '12',
          'merchant_name': 'Chipotle',
          'category': 'Food & Dining',
          'amount': 12.75,
          'date': DateTime.now().subtract(const Duration(days: 16)).toIso8601String(),
          'pending': false,
          'account_name': 'Chase Total Checking',
        },
      ];
      
      // Calculate totals
      _calculateTotals(transactions.where((t) => t['type'] != 'insight').toList());
      
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _calculateTotals(List<Map<String, dynamic>> transactions) {
    double spending = 0;
    double income = 0;
    
    for (final transaction in transactions) {
      final amount = (transaction['amount'] ?? 0).toDouble();
      if (amount < 0) {
        income += amount.abs();
      } else {
        spending += amount;
      }
    }
    
    setState(() {
      _totalSpending = spending;
      _totalIncome = income;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar like overview
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const TransactionSearchScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Search transactions...',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 16,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.tune,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Transactions Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions (${_transactions.where((t) => t['type'] != 'insight').length})',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                      fontFamily: 'Geist',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _exportTransactions,
                    icon: Icon(
                      Icons.download,
                      color: isDark ? Colors.white : Colors.black,
                      size: 18,
                    ),
                    label: Text(
                      'Export',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Transactions List with Insights
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final item = _transactions[index];
                        if (item['type'] == 'insight') {
                          return _buildInsightCard(item, isDark);
                        }
                        return _buildTransactionTile(item, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInsightCard(Map<String, dynamic> insight, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (insight['color'] as Color).withOpacity(0.1),
            (insight['color'] as Color).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (insight['color'] as Color).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (insight['color'] as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight['icon'] as IconData,
              color: insight['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight['message'],
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransactionTile(Map<String, dynamic> transaction, bool isDark) {
    final amount = (transaction['amount'] ?? 0).toDouble();
    final isIncome = amount < 0;
    final displayAmount = amount.abs();
    final isPending = transaction['pending'] ?? false;
    final isRecurring = transaction['is_recurring'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Real merchant logo
            MerchantLogoWidget(
              merchantName: transaction['merchant_name'] ?? 'Unknown',
              category: transaction['category'],
              size: 48,
            ),
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction['merchant_name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                      if (isPending)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PENDING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                      if (isRecurring)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.repeat,
                            size: 18,
                            color: Colors.blue[400],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        transaction['category'] ?? 'General',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontFamily: 'Geist',
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatDate(DateTime.parse(transaction['date'])),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}\$${displayAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isIncome ? Colors.green[500] : (isDark ? Colors.white : Colors.black),
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction['account_name'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
  
  void _exportTransactions() {
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Export feature coming soon!')),

          );
}