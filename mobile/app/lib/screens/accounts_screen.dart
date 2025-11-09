import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Direct Supabase query - NO hard-coded data
      final response = await _supabase
          .from('accounts')
          .select('*')
          .eq('member_id', user.id);

      // Transform response to include balance as double from balance_cents
      final accounts = (response as List).map((account) {
        return {
          ...account,
          'balance': (account['balance_cents'] ?? 0) / 100.0,
        };
      }).toList();

      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CUSpinner(
                size: CUSpinnerSize.large,
                onLoaded: () {
                  WidgetJourneyLogger.logJourney(
                    userId: _authService.currentUser?.id ?? 'unknown',
                    widgetName: 'AccountsScreen',
                    action: 'loading_complete',
                    metadata: {'accountCount': _accounts.length},
                  );
                },
              ),
            )
          : _error != null
              ? _buildErrorState(context)
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: 24),
                            _buildTotalBalanceCard(context),
                            const SizedBox(height: 16),
                            _buildAccountsList(context),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            CUTypography(
              'Failed to load accounts',
              variant: CUTypographyVariant.h4,
              fontFamily: 'Geist',
            ),
            const SizedBox(height: 8),
            CUTypography(
              _error ?? 'Unknown error',
              variant: CUTypographyVariant.bodyMedium,
              fontFamily: 'Geist',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            CUButton(
              onPressed: _loadAccounts,
              variant: CUButtonVariant.primary,
              child: CUTypography(
                'Retry',
                variant: CUTypographyVariant.bodyMedium,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = _authService.currentUser;
    final firstName = user?.userMetadata?['first_name'] ?? 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CUTypography(
          'Your Accounts, $firstName',
          variant: CUTypographyVariant.h2,
          fontFamily: 'Geist',
        ),
        const SizedBox(height: 8),
        CUTypography(
          'Manage your accounts and view balances',
          variant: CUTypographyVariant.bodyLarge,
          fontFamily: 'Geist',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalBalanceCard(BuildContext context) {
    double totalBalance = 0.0;
    for (final account in _accounts) {
      totalBalance += (account['balance'] ?? 0.0);
    }

    return CUCard(
      variant: CUCardVariant.elevated,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CUTypography(
            'Total Balance',
            variant: CUTypographyVariant.bodyLarge,
            fontFamily: 'Geist',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          CUTypography(
            '\$${totalBalance.toStringAsFixed(2)}',
            variant: CUTypographyVariant.h1,
            fontFamily: 'Geist',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  context,
                  'Checking',
                  _getAccountBalance('checking'),
                  Icons.account_balance,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBalanceItem(
                  context,
                  'Savings',
                  _getAccountBalance('savings'),
                  Icons.savings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CUTypography(
                label,
                variant: CUTypographyVariant.bodySmall,
                fontFamily: 'Geist',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              CUTypography(
                '\$${amount.toStringAsFixed(2)}',
                variant: CUTypographyVariant.bodyLarge,
                fontFamily: 'Geist',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsList(BuildContext context) {
    if (_accounts.isEmpty) {
      return CUCard(
        variant: CUCardVariant.outlined,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.account_balance_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              CUTypography(
                'No accounts found',
                variant: CUTypographyVariant.h4,
                fontFamily: 'Geist',
              ),
              const SizedBox(height: 8),
              CUTypography(
                'Contact support to set up your first account',
                variant: CUTypographyVariant.bodyMedium,
                fontFamily: 'Geist',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CUTypography(
              'All Accounts',
              variant: CUTypographyVariant.h3,
              fontFamily: 'Geist',
            ),
            CUButton(
              onPressed: () {
                WidgetJourneyLogger.logJourney(
                  userId: _authService.currentUser?.id ?? 'unknown',
                  widgetName: 'AccountsScreen',
                  action: 'add_account_button_pressed',
                );
                _showAddAccountDialog(context);
              },
              variant: CUButtonVariant.ghost,
              leadingIcon: Icons.add,
              child: CUTypography(
                'Add Account',
                variant: CUTypographyVariant.bodyMedium,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._accounts.map((account) => _buildAccountCard(context, account)),
      ],
    );
  }

  Widget _buildAccountCard(BuildContext context, Map<String, dynamic> account) {
    final accountType = account['type'] ?? 'unknown';
    final accountName = account['name'] ?? 'Unnamed Account';
    final accountNumber = account['account_number'] ?? 'N/A';
    final balance = account['balance'] ?? 0.0;
    final status = account['status'] ?? 'unknown';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CUCard(
        variant: CUCardVariant.outlined,
        padding: EdgeInsets.zero,
        onTap: () {
          SystemChannels.platform.invokeMethod('HapticFeedback.mediumImpact');
          WidgetJourneyLogger.logJourney(
            userId: _authService.currentUser?.id ?? 'unknown',
            widgetName: 'AccountCard',
            action: 'account_tapped',
            metadata: {
              'accountId': account['id'],
              'accountType': accountType,
            },
          );
          _handleAccountTap(account);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CUAvatar(
                size: CUAvatarSize.large,
                child: Icon(
                  _getAccountIcon(accountType),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CUTypography(
                            accountName,
                            variant: CUTypographyVariant.h5,
                            fontFamily: 'Geist',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        CUBadge(
                          label: status.toUpperCase(),
                          variant: _getStatusBadgeVariant(status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    CUTypography(
                      accountType.toUpperCase(),
                      variant: CUTypographyVariant.bodySmall,
                      fontFamily: 'Geist',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CUTypography(
                      '****${accountNumber.length >= 4 ? accountNumber.substring(accountNumber.length - 4) : accountNumber}',
                      variant: CUTypographyVariant.bodySmall,
                      fontFamily: 'Geist',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CUTypography(
                    '\$${balance.toStringAsFixed(2)}',
                    variant: CUTypographyVariant.h5,
                    fontFamily: 'Geist',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  CUTypography(
                    'Balance',
                    variant: CUTypographyVariant.bodySmall,
                    fontFamily: 'Geist',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAccountIcon(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'checking':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'credit':
        return Icons.credit_card;
      case 'loan':
        return Icons.account_balance_wallet;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance;
    }
  }

  CUBadgeVariant _getStatusBadgeVariant(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return CUBadgeVariant.success;
      case 'pending':
        return CUBadgeVariant.warning;
      case 'suspended':
        return CUBadgeVariant.destructive;
      case 'closed':
        return CUBadgeVariant.secondary;
      default:
        return CUBadgeVariant.default_;
    }
  }

  double _getAccountBalance(String accountType) {
    final account = _accounts.firstWhere(
      (acc) => (acc['type'] ?? '').toLowerCase() == accountType.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );
    return account['balance'] ?? 0.0;
  }

  void _viewAccountDetails(BuildContext context, Map<String, dynamic> account) {
    WidgetJourneyLogger.logJourney(
      userId: _authService.currentUser?.id ?? 'unknown',
      widgetName: 'AccountDetailsDialog',
      action: 'dialog_opened',
      metadata: {'accountId': account['id']},
    );

    showDialog(
      context: context,
      builder: (context) => CUDialog(
        title: CUTypography(
          '${account['name']} Details',
          variant: CUTypographyVariant.h4,
          fontFamily: 'Geist',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Account Type', account['type'] ?? 'N/A'),
            _buildDetailRow(
                'Account Number', account['account_number'] ?? 'N/A'),
            _buildDetailRow(
                'Routing Number', account['routing_number'] ?? 'N/A'),
            _buildDetailRow('Balance',
                '\$${(account['balance'] ?? 0.0).toStringAsFixed(2)}'),
            _buildDetailRow('Status', account['status'] ?? 'N/A'),
            _buildDetailRow(
                'Opened',
                _formatDate(DateTime.parse(account['created_at'] ??
                    DateTime.now().toIso8601String()))),
          ],
        ),
        actions: [
          CUButton(
            onPressed: () {
              WidgetJourneyLogger.logJourney(
                userId: _authService.currentUser?.id ?? 'unknown',
                widgetName: 'AccountDetailsDialog',
                action: 'dialog_closed',
              );
              Navigator.pop(context);
            },
            variant: CUButtonVariant.ghost,
            child: CUTypography(
              'Close',
              variant: CUTypographyVariant.bodyMedium,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: CUTypography(
              '$label:',
              variant: CUTypographyVariant.bodyMedium,
              fontFamily: 'Geist',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: CUTypography(
              value,
              variant: CUTypographyVariant.bodyMedium,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  void _handleAccountTap(Map<String, dynamic> account) {
    SystemChannels.platform.invokeMethod('HapticFeedback.mediumImpact');
    _viewAccountDetails(context, account);
  }

  void _showAddAccountDialog(BuildContext context) {
    SystemChannels.platform.invokeMethod('HapticFeedback.lightImpact');
    WidgetJourneyLogger.logJourney(
      userId: _authService.currentUser?.id ?? 'unknown',
      widgetName: 'AddAccountDialog',
      action: 'dialog_opened',
    );

    showDialog(
      context: context,
      builder: (context) => CUDialog(
        title: CUTypography(
          'Add New Account',
          variant: CUTypographyVariant.h4,
          fontFamily: 'Geist',
        ),
        content: CUTypography(
          'Connect your bank account with Plaid to get started.',
          variant: CUTypographyVariant.bodyMedium,
          fontFamily: 'Geist',
        ),
        actions: [
          CUButton(
            onPressed: () {
              WidgetJourneyLogger.logJourney(
                userId: _authService.currentUser?.id ?? 'unknown',
                widgetName: 'AddAccountDialog',
                action: 'cancel_pressed',
              );
              Navigator.pop(context);
            },
            variant: CUButtonVariant.ghost,
            child: CUTypography(
              'Cancel',
              variant: CUTypographyVariant.bodyMedium,
              fontFamily: 'Geist',
            ),
          ),
          CUButton(
            onPressed: () {
              WidgetJourneyLogger.logJourney(
                userId: _authService.currentUser?.id ?? 'unknown',
                widgetName: 'AddAccountDialog',
                action: 'connect_account_pressed',
              );
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/plaid-demo');
            },
            variant: CUButtonVariant.primary,
            child: CUTypography(
              'Connect Account',
              variant: CUTypographyVariant.bodyMedium,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
