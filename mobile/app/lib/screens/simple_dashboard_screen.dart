import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, Colors, CircularProgressIndicator;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:intl/intl.dart';
import '../services/plaid_service.dart';
import '../services/supabase_realtime_service.dart';

class SimpleDashboardScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final Function(Map<String, dynamic>)? onAccountSelected;

  const SimpleDashboardScreen({
    super.key,
    this.scrollController,
    this.onAccountSelected,
  });

  @override
  State<SimpleDashboardScreen> createState() => _SimpleDashboardScreenState();
}

class _SimpleDashboardScreenState extends State<SimpleDashboardScreen> {
  final PlaidService _plaidService = PlaidService();
  final SupabaseRealtimeService _realtimeService = SupabaseRealtimeService();
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  StreamSubscription? _accountsSubscription;
  StreamSubscription? _transactionsSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
    _loadPlaidData();
  }

  @override
  void dispose() {
    _accountsSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    // Listen to real-time account updates
    _accountsSubscription = _realtimeService.accountsStream.listen((accounts) {
      if (mounted) {
        setState(() {
          _accounts = accounts;
        });
        debugPrint('Real-time: Received ${accounts.length} accounts');
      }
    });

    // Listen to real-time transaction updates
    _transactionsSubscription = _realtimeService.transactionsStream.listen((transactions) {
      if (mounted) {
        setState(() {
          _transactions = transactions;
        });
        debugPrint('Real-time: Received ${transactions.length} transactions');
      }
    });
  }

  Future<void> _loadPlaidData() async {
    try {
      final accounts = await _plaidService.getAccounts();
      final transactions = await _plaidService.getTransactions();

      // Sync Plaid data to Supabase for real-time broadcasting
      await _realtimeService.syncPlaidToSupabase(
        accounts: accounts,
        transactions: transactions,
      );

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading Plaid data: $e');
      // Load mock data when Plaid fails
      if (mounted) {
        setState(() {
          _accounts = [
            {
              'account_id': '1',
              'id': '1',
              'name': 'Cash Account',
              'subtype': 'checking',
              'type': 'depository',
              'mask': '0929',
              'balance': 10.34,
              'available': 10.34,
              'balances': {'current': 10.34},
              'currency': 'USD',
              'institution': 'Mock Bank',
            },
            {
              'account_id': '2',
              'id': '2',
              'name': 'Savings',
              'subtype': 'savings',
              'type': 'depository',
              'mask': '8765',
              'balance': 2.84,
              'available': 2.84,
              'balances': {'current': 2.84},
              'currency': 'USD',
              'institution': 'Mock Bank',
            },
            {
              'account_id': '3',
              'id': '3',
              'name': 'Credit Card',
              'subtype': 'credit',
              'type': 'credit',
              'mask': '2341',
              'balance': 500.00,
              'available': 500.00,
              'balances': {'current': 500.00},
              'currency': 'USD',
              'institution': 'Mock Bank',
            },
          ];
          _transactions = [
            {
              'transaction_id': '1',
              'id': '1',
              'account_id': '1',
              'name': 'Whole Foods',
              'merchant_name': 'Whole Foods Market',
              'amount': 127.43,
              'date': '2024-11-04',
              'category': ['Food', 'Groceries'],
              'type': 'transaction',
              'pending': false,
            },
            {
              'transaction_id': '2',
              'id': '2',
              'account_id': '1',
              'name': 'Apple',
              'merchant_name': 'Apple',
              'amount': 999.00,
              'date': '2024-11-03',
              'category': ['Shopping', 'Electronics'],
              'type': 'transaction',
              'pending': false,
            },
          ];
          _isLoading = false;

          // Try to sync mock data to Supabase too
          _realtimeService.syncPlaidToSupabase(
            accounts: _accounts,
            transactions: _transactions,
          ).catchError((e) {
            debugPrint('Failed to sync mock data: $e');
          });
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '\$${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final now = DateTime.now();
    final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    final dateStr = _formatDate(now);

    // Calculate total balance from all accounts
    final totalBalance = _accounts.fold<double>(
      0.0,
      (sum, account) => sum + ((account['balances']?['current'] ?? 0.0) as num).toDouble(),
    );

    return Container(
      color: const Color(0xFFF5F5F5),
      child: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          // Credit Union Avatar Header
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            'assets/cu-app_logo.svg',
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Credit Union',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Total Balance Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              padding: const EdgeInsets.all(24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? Container(
                          width: 200,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        )
                      : Text(
                          _formatCurrency(totalBalance),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                            fontFamily: 'Geist',
                            height: 1.0,
                            letterSpacing: -1.5,
                          ),
                        ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBalanceActionButton(
                          'Transfer',
                          Icons.arrow_forward,
                          true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBalanceActionButton(
                          'Accounts',
                          Icons.account_balance,
                          false,
                        ),
                      ),
                    ],
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
                  child: CircularProgressIndicator(color: theme.colorScheme.primary),
                ),
              ),
            )
          else ...[
            // All Accounts Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Accounts',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                        fontFamily: 'Geist',
                      ),
                    ),
                    Text(
                      'Manage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // All Accounts List
            if (_accounts.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final account = _accounts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildSecondaryCard(account),
                      );
                    },
                    childCount: _accounts.length,
                  ),
                ),
              ),

            // Recent Activity Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ),

            // Recent Activity List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _transactions.length) return null;
                  final transaction = _transactions[index];

                  // Calculate running balance (balance before this transaction)
                  double runningBalance = 0.0;
                  final accountId = transaction['account_id'];
                  final account = _accounts.firstWhere(
                    (acc) => acc['account_id'] == accountId || acc['id'] == accountId,
                    orElse: () => {},
                  );

                  if (account.isNotEmpty) {
                    runningBalance = ((account['balances']?['current'] ?? 0.0) as num).toDouble();
                    // Add back all previous transactions to get balance before this one
                    for (int i = 0; i <= index; i++) {
                      if (_transactions[i]['account_id'] == accountId) {
                        final amt = (_transactions[i]['amount'] ?? 0.0) as num;
                        runningBalance += amt.toDouble();
                      }
                    }
                  }

                  return _buildActivityItem(transaction, runningBalance);
                },
                childCount: _transactions.length,
              ),
            ),

            SliverPadding(padding: const EdgeInsets.only(bottom: 120)),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceActionButton(String label, IconData icon, bool isPrimary) {
    return Opacity(
      opacity: 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.grey.shade900 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? Colors.white : Colors.grey.shade900,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : Colors.grey.shade900,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> account) {
    final balance = (account['balances']?['current'] ?? 0.0) as num;
    final mask = account['mask'] ?? '0000';
    final name = account['name'] ?? 'Cash Account';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Colored card header
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFCDFF00),
                    const Color(0xFFB8E600),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Row(
                      children: [
                        Icon(Icons.credit_card, size: 20, color: Colors.grey.shade900),
                        const SizedBox(width: 8),
                        Text(
                          '•• $mask',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Card artwork placeholder
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Container(
                      width: 80,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // White body
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name balance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(balance.toDouble()),
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Geist',
                      height: 1.0,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Account ••${mask.substring(mask.length - 4)} › ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton('Add money', Icons.add),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton('Withdraw', Icons.arrow_upward),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Earnings',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade900,
                            fontFamily: 'Geist',
                          ),
                        ),
                        Text(
                          '\$0 in Nov',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryCard(Map<String, dynamic> account) {
    final currentBalance = (account['balances']?['current'] ?? 0.0) as num;
    final availableBalance = (account['balances']?['available'] ?? account['available'] ?? currentBalance) as num;
    final name = account['name'] ?? 'Account';
    final subtype = account['subtype'] ?? 'checking';

    // Different colors for account types
    Color cardColor;
    IconData iconData;
    switch (subtype.toLowerCase()) {
      case 'savings':
        cardColor = const Color(0xFF10B981);
        iconData = Icons.savings_outlined;
        break;
      case 'credit':
        cardColor = const Color(0xFF6366F1);
        iconData = Icons.credit_card;
        break;
      default:
        cardColor = const Color(0xFF3B82F6);
        iconData = Icons.account_balance_wallet;
    }

    return GestureDetector(
      onTap: () {
        if (widget.onAccountSelected != null) {
          widget.onAccountSelected!(account);
        }
        // Navigate to account details screen
        Navigator.of(context).pushNamed(
          '/account-details',
          arguments: account,
        );
        debugPrint('Account tapped: ${account['name']}');
      },
      child: Container(
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
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(currentBalance.toDouble()),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Geist',
                      height: 1.0,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current Balance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatCurrency(availableBalance.toDouble())} Available',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardColor.withOpacity(0.1),
              ),
              child: Icon(
                iconData,
                size: 28,
                color: cardColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        // Handle action
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
              fontFamily: 'Geist',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> transaction, double previousBalance) {
    final amount = (transaction['amount'] ?? 0.0) as num;
    final isPositive = amount < 0; // Plaid: negative = credit
    final displayAmount = amount.abs().toDouble();
    final merchantName = transaction['merchant_name'] ?? transaction['name'] ?? 'Activity';
    final date = transaction['date'] ?? '';
    final category = (transaction['category'] as List?)?.firstOrNull ?? 'Other';

    // Generate logo URL for merchants
    final logo = transaction['logo_url'];
    String? logoUrl;
    if (logo != null && logo.isNotEmpty) {
      logoUrl = logo;
    } else if (merchantName.isNotEmpty) {
      // Generate clearbit logo URL
      final cleanName = merchantName.toLowerCase().replaceAll(' ', '');
      logoUrl = 'https://logo.clearbit.com/$cleanName.com';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
            ),
            child: logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.network(
                      logoUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.store_outlined,
                          size: 20,
                          color: Colors.grey.shade700,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.store_outlined,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  '$category • $date',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Previous balance: ${_formatCurrency(previousBalance)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontFamily: 'Geist',
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'}${_formatCurrency(displayAmount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.green.shade700 : Colors.grey.shade900,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
}
