import 'package:flutter/material.dart';
import 'consistent_list_tile.dart';
import '../l10n/app_localizations.dart';
import '../services/sound_service.dart';

class TransactionHelpers {
  static Widget buildRecentTransactions(BuildContext context) {
    final theme = Theme.of(context);
    final transactions = _getRecentTransactions();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)?.recentTransactions ?? 'Recent Transactions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/transactions');
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: transactions.asMap().entries.map((entry) {
                final index = entry.key;
                final transaction = entry.value;
                final isLast = index == transactions.length - 1;
                
                return InkWell(
                  onTap: () {
                    SoundService().playButtonTap();
                    // Handle transaction tap - could show details
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: !isLast ? Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ) : null,
                    ),
                    child: Row(
                    children: [
                      _buildTransactionLogo(transaction),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction['merchant']!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Geist',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              transaction['date']!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        transaction['amount']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: transaction['amount']!.startsWith('+')
                              ? Colors.green
                              : theme.colorScheme.onSurface,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  static List<Map<String, dynamic>> _getRecentTransactions() {
    // Get the same transactions as used in the TransactionsScreen
    return [
      {
        'merchant': 'Starbucks',
        'category': 'Food & Coffee',
        'date': 'Today, 8:15 AM',
        'amount': '-\$5.75',
        'logo': '☕',
        'logoColor': const Color(0xFF00704A),
        'pending': true,
      },
      {
        'merchant': 'Tech Corp Payroll',
        'category': 'Transfer',
        'date': '3 days ago',
        'amount': '+\$3,500.00',
        'logo': '💰',
        'logoColor': Colors.green,
        'is_income': true,
        'is_recurring': true,
      },
      {
        'merchant': 'Whole Foods',
        'category': 'Food & Groceries',
        'date': 'Yesterday',
        'amount': '-\$89.99',
        'logo': '🛒',
        'logoColor': const Color(0xFF00704A),
      },
      {
        'merchant': 'Netflix',
        'category': 'Entertainment',
        'date': '5 days ago',
        'amount': '-\$15.99',
        'logo': 'N',
        'logoColor': const Color(0xFFE50914),
        'is_recurring': true,
      },
      {
        'merchant': 'Shell',
        'category': 'Transportation',
        'date': '1 week ago',
        'amount': '-\$45.00',
        'logo': '⛽',
        'logoColor': const Color(0xFFFFD400),
      },
    ];
  }
  
  static Widget _buildTransactionLogo(Map<String, dynamic> transaction) {
    final logo = transaction['logo'] ?? '';
    final logoColor = transaction['logoColor'] ?? Colors.grey;
    
    if (logo.length == 1 || logo.length == 2) {
      // Text logo (like 'N' for Netflix)
      return CircleAvatar(
        radius: 20,
        backgroundColor: logoColor.withOpacity(0.1),
        child: Text(
          logo,
          style: TextStyle(
            color: logoColor,
            fontWeight: FontWeight.bold,
            fontSize: logo.length == 1 ? 18 : 24,
          ),
        ),
      );
    } else {
      // Icon or emoji logo
      return CircleAvatar(
        radius: 20,
        backgroundColor: logoColor.withOpacity(0.1),
        child: Icon(
          _getTransactionIcon(transaction['category'] ?? ''),
          color: logoColor,
          size: 20,
        ),
      );
    }
  }
  
  static IconData _getTransactionIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & drink':
        return Icons.restaurant;
      case 'income':
        return Icons.account_balance_wallet;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'transportation':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt;
      default:
        return Icons.attach_money;
    }
  }
  
  static Color _getTransactionColor(String category) {
    switch (category.toLowerCase()) {
      case 'food & drink':
        return Colors.orange;
      case 'income':
        return Colors.green;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'transportation':
        return Colors.blue;
      case 'bills':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}