import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:intl/intl.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class AccountDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> account;

  const AccountDetailsScreen({
    super.key,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(symbol: '\$');
    final balance = account['balance'] ?? 0.0;
    final accountType = account['type'] ?? 'checking';
    final accountName = account['name'] ?? 'Account';
    final lastFour = account['lastFour'] ?? '****';
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Account Details'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black,
                        Colors.grey.shade800,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getAccountIcon(accountType),
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  accountName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '•••• $lastFour',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Available Balance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        numberFormat.format(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatAccountType(accountType),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Quick Actions
                Row(
                  children: [
                    _buildQuickAction(
                      context,
                      Icons.send,
                      'Transfer',
                      () {},
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      context,
                      Icons.download,
                      'Deposit',
                      () {},
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      context,
                      Icons.receipt_long,
                      'Statements',
                      () {},
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to transactions with filter
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._buildRecentTransactions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: Colors.black,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecentTransactions() {
    final transactions = [
      {
        'merchant': 'Starbucks Coffee',
        'amount': -4.95,
        'date': DateTime.now().subtract(const Duration(hours: 2)),
        'icon': Icons.coffee,
      },
      {
        'merchant': 'Amazon Purchase',
        'amount': -29.99,
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'icon': Icons.shopping_bag,
      },
      {
        'merchant': 'Direct Deposit',
        'amount': 2500.00,
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'icon': Icons.account_balance,
      },
      {
        'merchant': 'Gas Station',
        'amount': -45.20,
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'icon': Icons.local_gas_station,
      },
    ];

    return transactions
        .map((tx) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      tx['icon'] as IconData,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx['merchant'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDate(tx['date'] as DateTime),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: '\$').format(tx['amount']),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: (tx['amount'] as double) > 0
                          ? Colors.green
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'savings':
        return Icons.savings;
      case 'credit':
        return Icons.credit_card;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }

  String _formatAccountType(String type) {
    switch (type.toLowerCase()) {
      case 'savings':
        return 'Savings Account';
      case 'credit':
        return 'Credit Card';
      case 'investment':
        return 'Investment Account';
      default:
        return 'Checking Account';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}