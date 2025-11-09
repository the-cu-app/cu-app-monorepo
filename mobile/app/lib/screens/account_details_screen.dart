import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, Colors, CircularProgressIndicator, showModalBottomSheet;
import 'package:intl/intl.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../services/plaid_service.dart';

class AccountDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> account;

  const AccountDetailsScreen({
    super.key,
    required this.account,
  });

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final PlaidService _plaidService = PlaidService();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final allTransactions = await _plaidService.getTransactions();
      final accountId = widget.account['account_id'] ?? widget.account['id'];

      if (mounted) {
        setState(() {
          _transactions = allTransactions
              .where((tx) => tx['account_id'] == accountId)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _exportHistory() {
    // Navigate to export screen with this account's transactions
    Navigator.of(context).pushNamed(
      '/privacy/data-export',
      arguments: {
        'accountId': widget.account['account_id'] ?? widget.account['id'],
        'accountName': widget.account['name'],
        'transactions': _transactions,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final balance = (widget.account['balances']?['current'] ??
                     widget.account['balance'] ??
                     0.0) as num;
    final accountName = widget.account['name'] ?? 'Account';
    final mask = widget.account['mask'] ?? '****';
    final subtype = widget.account['subtype'] ?? 'checking';
    final isDesktop = MediaQuery.of(context).size.width > 800;

    // Different colors for account types
    Color accountColor;
    IconData iconData;
    switch (subtype.toLowerCase()) {
      case 'savings':
        accountColor = const Color(0xFF10B981);
        iconData = Icons.savings_outlined;
        break;
      case 'credit':
        accountColor = const Color(0xFF6366F1);
        iconData = Icons.credit_card;
        break;
      default:
        accountColor = const Color(0xFF3B82F6);
        iconData = Icons.account_balance_wallet;
    }

    return Container(
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
          ),
          child: CustomScrollView(
            slivers: [
              // Header with back button
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_back,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Back',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Account Card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accountColor,
                        accountColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: accountColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            iconData,
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
                                    fontFamily: 'Geist',
                                  ),
                                ),
                                Text(
                                  '•••• $mask',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontFamily: 'Geist',
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
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Geist',
                          height: 1.0,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          'Export',
                          Icons.download,
                          _exportHistory,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Opacity(
                          opacity: 0.4,
                          child: _buildQuickAction(
                            'Transfer',
                            Icons.arrow_forward,
                            () {},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Transactions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                          fontFamily: 'Geist',
                        ),
                      ),
                      Text(
                        '${_transactions.length} total',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading State
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Container(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                )
              // Transactions List
              else if (_transactions.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                            fontFamily: 'Geist',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Transactions will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _transactions.length) return null;
                      final transaction = _transactions[index];
                      return _buildTransactionItem(transaction);
                    },
                    childCount: _transactions.length,
                  ),
                ),

              SliverPadding(padding: const EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final amount = (transaction['amount'] ?? 0.0) as num;
    final isPositive = amount < 0; // Plaid: negative = credit
    final displayAmount = amount.abs().toDouble();
    final merchantName = transaction['merchant_name'] ??
                        transaction['name'] ??
                        'Transaction';
    final date = transaction['date'] ?? '';
    final category = (transaction['category'] as List?)?.firstOrNull ?? 'Other';

    // Generate logo URL for merchants
    final logo = transaction['logo_url'];
    String? logoUrl;
    if (logo != null && logo.isNotEmpty) {
      logoUrl = logo;
    } else if (merchantName.isNotEmpty) {
      final cleanName = merchantName.toLowerCase().replaceAll(' ', '');
      logoUrl = 'https://logo.clearbit.com/$cleanName.com';
    }

    return GestureDetector(
      onTap: () {
        // Show transaction details in bottom sheet
        _showTransactionDetails(transaction);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
              ),
              child: logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        logoUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.store_outlined,
                            size: 24,
                            color: Colors.grey.shade700,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.store_outlined,
                      size: 24,
                      color: Colors.grey.shade700,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$category • $date',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}\$${displayAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green.shade700 : Colors.grey.shade900,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    final amount = (transaction['amount'] ?? 0.0) as num;
    final isPositive = amount < 0;
    final displayAmount = amount.abs().toDouble();
    final merchantName = transaction['merchant_name'] ??
                        transaction['name'] ??
                        'Transaction';
    final date = transaction['date'] ?? '';
    final categories = (transaction['category'] as List?)?.join(', ') ?? 'Uncategorized';
    final pending = transaction['pending'] ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Transaction Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Merchant', merchantName),
            _buildDetailRow('Amount', '\$${displayAmount.toStringAsFixed(2)}'),
            _buildDetailRow('Type', isPositive ? 'Credit' : 'Debit'),
            _buildDetailRow('Date', date),
            _buildDetailRow('Category', categories),
            _buildDetailRow('Status', pending ? 'Pending' : 'Posted'),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Center(
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Geist',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
}
