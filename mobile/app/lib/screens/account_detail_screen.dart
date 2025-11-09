import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class AccountDetailScreen extends StatefulWidget {
  final Map<String, dynamic> account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  final AuthService _authService = AuthService();
  final SecurityService _securityService = SecurityService();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _showSensitiveData = false;

  @override
  void initState() {
    super.initState();
    _checkSecuritySettings();
  }

  Future<void> _checkSecuritySettings() async {
    final settings = await _securityService.getSecuritySettings();
    if (settings.biometricEnabled && settings.biometricForSensitiveData) {
      // Require authentication for sensitive data
      setState(() {
        _showSensitiveData = false;
      });
    } else {
      // No biometric required, show all data
      setState(() {
        _showSensitiveData = true;
        _isAuthenticated = true;
      });
    }
  }

  Future<void> _authenticateForSensitiveData() async {
    setState(() => _isLoading = true);
    
    final authenticated = await _authService.authenticateForOperation(
      'Authenticate to view account details',
    );
    
    setState(() {
      _isLoading = false;
      _isAuthenticated = authenticated;
      _showSensitiveData = authenticated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    
    print('Building account detail screen for: ${account['name']}');
    print('Account data: $account');
    
    final balance = account['balance'] ?? 0.0;
    final name = account['name'] ?? 'Account';
    final type = account['type'] ?? 'checking';
    final lastFour = account['lastFour'] ?? account['mask'] ?? '****';
    final accountId = account['account_id'] ?? account['id'] ?? '${name}_$lastFour';
    
    final accessibilityService = context.watch<AccessibilityService>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balanceColor = accessibilityService.getBalanceColor(balance, isDarkMode: isDarkMode);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Card
          Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _getAccountIcon(type),
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${type[0].toUpperCase()}${type.substring(1)} •••• $lastFour',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Current Balance',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_showSensitiveData)
                      Text(
                        '\$${_formatAmount(balance)}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: accessibilityService.useColorIndicators
                              ? balanceColor
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        semanticsLabel: accessibilityService.getBalanceSemanticLabel(
                          balance,
                          _formatAmount(balance),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Text(
                            '••••••••',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            FilledButton.icon(
                              onPressed: _authenticateForSensitiveData,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Authenticate to View'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
          ),
          const SizedBox(height: 32),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            context,
            icon: Icons.send,
            label: 'Transfer',
            onPressed: () {
              // Navigate to transfer screen
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            icon: Icons.payment,
            label: 'Pay Bill',
            onPressed: () {
              // Navigate to bill pay
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            icon: Icons.history,
            label: 'Transaction History',
            onPressed: () {
              // Show transaction history
            },
          ),
          
          const SizedBox(height: 32),
          
          // Recent Transactions
          if (_showSensitiveData) ...[
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildDemoTransactions(context, accessibilityService, isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDemoTransactions(
    BuildContext context,
    AccessibilityService accessibilityService,
    bool isDarkMode,
  ) {
    final transactions = [
      {'merchant': 'Coffee Shop', 'amount': -5.25, 'date': 'Today'},
      {'merchant': 'Salary Deposit', 'amount': 3500.00, 'date': 'Yesterday'},
      {'merchant': 'Electric Company', 'amount': -125.00, 'date': '2 days ago'},
      {'merchant': 'Online Transfer', 'amount': -200.00, 'date': '3 days ago'},
    ];

    return transactions.map((transaction) {
      final amount = transaction['amount'] as double;
      final amountColor = accessibilityService.getBalanceColor(amount, isDarkMode: isDarkMode);
      
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            child: Icon(
              amount > 0 ? Icons.add : Icons.remove,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(transaction['merchant'] as String),
          subtitle: Text(transaction['date'] as String),
          trailing: Text(
            '${amount > 0 ? '+' : ''}\$${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accessibilityService.useColorIndicators
                  ? amountColor
                  : Theme.of(context).colorScheme.onSurface,
            ),
            semanticsLabel: '${amount > 0 ? 'Credit' : 'Debit'} of ${amount.abs().toStringAsFixed(2)} dollars',
          ),
        ),
      );
    }).toList();
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

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }
}