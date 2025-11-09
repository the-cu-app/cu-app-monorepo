import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, Colors, CircularProgressIndicator;
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../services/plaid_service.dart';

class PaymentActivityPanel extends StatefulWidget {
  const PaymentActivityPanel({super.key});

  @override
  State<PaymentActivityPanel> createState() => _PaymentActivityPanelState();
}

class _PaymentActivityPanelState extends State<PaymentActivityPanel> {
  final PlaidService _plaidService = PlaidService();
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentActivity();
  }

  Future<void> _loadRecentActivity() async {
    try {
      final transactions = await _plaidService.getTransactions();
      if (mounted) {
        setState(() {
          _recentActivity = transactions.take(15).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading activity: $e');
      if (mounted) {
        setState(() {
          _recentActivity = [
            {
              'transaction_id': '1',
              'name': 'Whole Foods',
              'merchant_name': 'Whole Foods Market',
              'amount': 127.43,
              'date': '2024-11-04',
              'category': ['Food', 'Groceries'],
              'type': 'transaction',
            },
            {
              'transaction_id': '2',
              'name': 'Apple',
              'merchant_name': 'Apple',
              'amount': 999.00,
              'date': '2024-11-03',
              'category': ['Shopping', 'Electronics'],
              'type': 'transaction',
            },
            {
              'transaction_id': '3',
              'name': 'Starbucks',
              'merchant_name': 'Starbucks',
              'amount': 5.75,
              'date': '2024-11-03',
              'category': ['Food', 'Coffee'],
              'type': 'transaction',
            },
            {
              'transaction_id': '4',
              'name': 'Netflix',
              'merchant_name': 'Netflix',
              'amount': 15.99,
              'date': '2024-11-02',
              'category': ['Entertainment', 'Streaming'],
              'type': 'transaction',
            },
            {
              'transaction_id': '5',
              'name': 'Shell Gas Station',
              'merchant_name': 'Shell',
              'amount': 45.00,
              'date': '2024-11-01',
              'category': ['Transportation', 'Gas'],
              'type': 'transaction',
            },
          ];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.border.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recent transactions',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          ),

          // Activity List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _recentActivity.length,
                    itemBuilder: (context, index) {
                      final transaction = _recentActivity[index];
                      return _buildActivityItem(transaction, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> transaction, CUThemeData theme) {
    final amount = (transaction['amount'] ?? 0.0) as num;
    final isPositive = amount < 0; // Plaid: negative = credit
    final displayAmount = amount.abs().toDouble();
    final merchantName = transaction['merchant_name'] ?? transaction['name'] ?? 'Activity';
    final date = transaction['date'] ?? '';
    final category = (transaction['category'] as List?)?.firstOrNull ?? 'Other';

    // Format date to be more compact (Nov 4)
    String formattedDate = date;
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final month = months[int.parse(parts[1]) - 1];
        final day = int.parse(parts[2]);
        formattedDate = '$month $day';
      }
    } catch (e) {
      // Keep original format if parsing fails
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.border.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  merchantName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Geist',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isPositive ? '+' : '-'}\$${displayAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPositive
                      ? const Color(0xFF10B981)
                      : theme.colorScheme.onSurface,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontFamily: 'Geist',
                ),
              ),
              Text(
                ' • ',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
