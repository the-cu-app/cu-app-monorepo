import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter/services.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../services/banking_service.dart';
import '../widgets/account_card.dart';
import '../widgets/animated_page.dart';
import '../config/cu_config_service.dart';

class PlaidDemoScreen extends StatefulWidget {
  const PlaidDemoScreen({super.key});

  @override
  State<PlaidDemoScreen> createState() => _PlaidDemoScreenState();
}

class _PlaidDemoScreenState extends State<PlaidDemoScreen> {
  final BankingService _bankingService = BankingService();
  bool _isLoading = false;
  String _status = 'Ready to connect';
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _transactions = [];

  // Rich test data configurations
  final List<Map<String, dynamic>> _testConfigurations = [
    {
      'name': 'Simple Test (user_good)',
      'description': 'Basic sandbox test with standard credentials',
      'config': null, // Use simple method
    },
    {
      'name': 'John Doe - Full Portfolio',
      'description':
          'Complete financial profile with checking, savings, credit, and investments',
      'config': {
        'seed': 'john-doe-full-portfolio',
        'override_accounts': [
          {
            'type': 'depository',
            'subtype': 'checking',
            'starting_balance': 2500.00,
            'meta': {
              'name': 'Primary Checking',
              'official_name': 'Chase Total Checking',
              'mask': '0000'
            },
            'identity': {
              'names': ['John Doe'],
              'phone_numbers': [
                {'primary': true, 'type': 'mobile', 'data': '555-0123'}
              ],
              'emails': [
                {
                  'primary': true,
                  'type': 'primary',
                  'data': 'test.john.doe@${CUConfigService().cuDomain}'
                }
              ],
              'addresses': [
                {
                  'primary': true,
                  'data': {
                    'city': 'San Francisco',
                    'region': 'CA',
                    'street': '123 Market Street',
                    'postal_code': '94105',
                    'country': 'US'
                  }
                }
              ]
            },
            'transactions': [
              {
                'date_transacted': '2024-01-15',
                'date_posted': '2024-01-15',
                'currency': 'USD',
                'amount': -89.99,
                'description': 'Netflix Subscription'
              },
              {
                'date_transacted': '2024-01-14',
                'date_posted': '2024-01-14',
                'currency': 'USD',
                'amount': -45.67,
                'description': 'Whole Foods Market'
              },
              {
                'date_transacted': '2024-01-13',
                'date_posted': '2024-01-13',
                'currency': 'USD',
                'amount': 3500.00,
                'description': 'Salary Deposit - Tech Corp'
              },
              {
                'date_transacted': '2024-01-12',
                'date_posted': '2024-01-12',
                'currency': 'USD',
                'amount': -120.00,
                'description': 'Electric Bill'
              },
              {
                'date_transacted': '2024-01-11',
                'date_posted': '2024-01-11',
                'currency': 'USD',
                'amount': -25.50,
                'description': 'Uber Ride'
              }
            ]
          },
          {
            'type': 'depository',
            'subtype': 'savings',
            'starting_balance': 15000.00,
            'meta': {
              'name': 'High Yield Savings',
              'official_name': 'Chase Premier Savings',
              'mask': '1111'
            },
            'transactions': [
              {
                'date_transacted': '2024-01-01',
                'date_posted': '2024-01-01',
                'currency': 'USD',
                'amount': 500.00,
                'description': 'Monthly Savings Transfer'
              }
            ]
          },
          {
            'type': 'credit',
            'subtype': 'credit card',
            'starting_balance': -2500.00,
            'meta': {
              'name': 'Chase Freedom Unlimited',
              'official_name': 'Chase Freedom Unlimited Credit Card',
              'mask': '2222',
              'limit': 10000.00
            },
            'liability': {
              'type': 'credit',
              'purchase_apr': 18.24,
              'balance_transfer_apr': 20.24,
              'cash_apr': 25.24,
              'special_apr': 0,
              'last_payment_amount': 300.00,
              'minimum_payment_amount': 75.00
            },
            'transactions': [
              {
                'date_transacted': '2024-01-10',
                'date_posted': '2024-01-10',
                'currency': 'USD',
                'amount': -150.00,
                'description': 'Amazon Purchase'
              },
              {
                'date_transacted': '2024-01-08',
                'date_posted': '2024-01-08',
                'currency': 'USD',
                'amount': -89.99,
                'description': 'Spotify Premium'
              }
            ]
          },
          {
            'type': 'investment',
            'subtype': 'brokerage',
            'starting_balance': 25000.00,
            'meta': {
              'name': 'Investment Account',
              'official_name': 'Chase Investment Services',
              'mask': '3333'
            },
            'holdings': [
              {
                'institution_price': 150.25,
                'institution_price_as_of': '2024-01-15',
                'cost_basis': 145.00,
                'quantity': 100,
                'currency': 'USD',
                'security': {
                  'ticker_symbol': 'AAPL',
                  'name': 'Apple Inc.',
                  'currency': 'USD'
                }
              },
              {
                'institution_price': 3200.00,
                'institution_price_as_of': '2024-01-15',
                'cost_basis': 3100.00,
                'quantity': 5,
                'currency': 'USD',
                'security': {
                  'ticker_symbol': 'GOOGL',
                  'name': 'Alphabet Inc.',
                  'currency': 'USD'
                }
              }
            ],
            'investment_transactions': [
              {
                'date': '2024-01-10',
                'name': 'Buy AAPL',
                'quantity': 10,
                'price': 150.25,
                'fees': 4.95,
                'type': 'buy',
                'currency': 'USD',
                'security': {'ticker_symbol': 'AAPL', 'currency': 'USD'}
              }
            ]
          }
        ]
      }
    },
    {
      'name': 'Sarah Johnson - Business Owner',
      'description':
          'Business banking with multiple accounts and business credit',
      'config': {
        'seed': 'sarah-johnson-business',
        'override_accounts': [
          {
            'type': 'depository',
            'subtype': 'business',
            'starting_balance': 45000.00,
            'meta': {
              'name': 'Business Checking',
              'official_name': 'Chase Business Complete Banking',
              'mask': '4444'
            },
            'identity': {
              'names': ['Sarah Johnson'],
              'emails': [
                {
                  'primary': true,
                  'type': 'primary',
                  'data': 'test.sarah@${CUConfigService().cuDomain}'
                }
              ]
            },
            'transactions': [
              {
                'date_transacted': '2024-01-15',
                'date_posted': '2024-01-15',
                'currency': 'USD',
                'amount': 15000.00,
                'description': 'Client Payment - TechCorp'
              },
              {
                'date_transacted': '2024-01-14',
                'date_posted': '2024-01-14',
                'currency': 'USD',
                'amount': -2500.00,
                'description': 'Payroll - Employee Salaries'
              },
              {
                'date_transacted': '2024-01-13',
                'date_posted': '2024-01-13',
                'currency': 'USD',
                'amount': -800.00,
                'description': 'Office Rent'
              }
            ]
          },
          {
            'type': 'credit',
            'subtype': 'credit card',
            'starting_balance': -5000.00,
            'meta': {
              'name': 'Business Credit Card',
              'official_name': 'Chase Ink Business Preferred',
              'mask': '5555',
              'limit': 25000.00
            },
            'liability': {
              'type': 'credit',
              'purchase_apr': 16.24,
              'balance_transfer_apr': 18.24,
              'cash_apr': 22.24,
              'special_apr': 0,
              'last_payment_amount': 500.00,
              'minimum_payment_amount': 150.00
            }
          }
        ]
      }
    },
    {
      'name': 'Mike Chen - Student',
      'description': 'Student with checking, savings, and student loans',
      'config': {
        'seed': 'mike-chen-student',
        'override_accounts': [
          {
            'type': 'depository',
            'subtype': 'checking',
            'starting_balance': 800.00,
            'meta': {
              'name': 'Student Checking',
              'official_name': 'Chase College Checking',
              'mask': '6666'
            },
            'identity': {
              'names': ['Mike Chen'],
              'emails': [
                {
                  'primary': true,
                  'type': 'primary',
                  'data': 'test.mike.chen@${CUConfigService().cuDomain}'
                }
              ]
            },
            'transactions': [
              {
                'date_transacted': '2024-01-15',
                'date_posted': '2024-01-15',
                'currency': 'USD',
                'amount': -15.99,
                'description': 'Spotify Student'
              },
              {
                'date_transacted': '2024-01-14',
                'date_posted': '2024-01-14',
                'currency': 'USD',
                'amount': -8.50,
                'description': 'Campus Coffee'
              },
              {
                'date_transacted': '2024-01-13',
                'date_posted': '2024-01-13',
                'currency': 'USD',
                'amount': 1200.00,
                'description': 'Part-time Job Paycheck'
              }
            ]
          },
          {
            'type': 'loan',
            'subtype': 'student',
            'starting_balance': -25000.00,
            'meta': {
              'name': 'Federal Student Loan',
              'official_name': 'Direct Subsidized Loan'
            },
            'liability': {
              'type': 'student',
              'origination_date': '2022-08-15',
              'principal': 25000.00,
              'nominal_apr': 4.99,
              'loan_name': 'Federal Direct Student Loan',
              'repayment_model': {
                'type': 'standard',
                'non_repayment_months': 36,
                'repayment_months': 120
              }
            }
          }
        ]
      }
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Plaid Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AnimatedPage(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              CustomAnimatedWidget(
                delay: const Duration(milliseconds: 100),
                child: _buildHeader(),
              ),
              const SizedBox(height: 32),

              // Test Configurations
              CustomAnimatedWidget(
                delay: const Duration(milliseconds: 200),
                child: _buildTestConfigurations(),
              ),
              const SizedBox(height: 32),

              // Status
              CustomAnimatedWidget(
                delay: const Duration(milliseconds: 300),
                child: _buildStatus(),
              ),
              const SizedBox(height: 24),

              // Accounts
              if (_accounts.isNotEmpty)
                CustomAnimatedWidget(
                  delay: const Duration(milliseconds: 400),
                  child: _buildAccounts(),
                ),

              // Transactions
              if (_transactions.isNotEmpty)
                CustomAnimatedWidget(
                  delay: const Duration(milliseconds: 500),
                  child: _buildTransactions(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plaid Sandbox Demo',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect with rich test data from Plaid\'s sandbox environment',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildTestConfigurations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Configurations',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        ..._testConfigurations.map((config) => _buildConfigCard(config)),
      ],
    );
  }

  Widget _buildConfigCard(Map<String, dynamic> config) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config['name'],
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config['description'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed:
                      _isLoading ? null : () => _connectWithConfig(config),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Connect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _status,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildAccounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connected Accounts',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        ..._accounts.map((account) => _buildAccountCard(account)),
      ],
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final balance = account['balances']?['current'] ?? 0.0;
    final isNegative = balance < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getAccountIcon(account['type']),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account['name'] ?? 'Unknown Account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '${account['type']} • ${account['subtype']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${balance.abs().toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isNegative
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                if (account['mask'] != null)
                  Text(
                    '•••• ${account['mask']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        ..._transactions
            .take(10)
            .map((transaction) => _buildTransactionCard(transaction)),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final amount = transaction['amount'] ?? 0.0;
    final isNegative = amount < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTransactionIcon(transaction['description']),
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['description'] ?? 'Unknown Transaction',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    _formatDate(transaction['date']),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '${isNegative ? '-' : '+'}\$${amount.abs().toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isNegative
                        ? Theme.of(context).colorScheme.error
                        : Colors.green,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAccountIcon(String? type) {
    switch (type) {
      case 'depository':
        return Icons.account_balance;
      case 'credit':
        return Icons.credit_card;
      case 'loan':
        return Icons.home;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }

  IconData _getTransactionIcon(String? description) {
    if (description == null) return Icons.receipt;

    final desc = description.toLowerCase();
    if (desc.contains('netflix') || desc.contains('spotify'))
      return Icons.play_circle;
    if (desc.contains('amazon') || desc.contains('purchase'))
      return Icons.shopping_bag;
    if (desc.contains('salary') || desc.contains('paycheck')) return Icons.work;
    if (desc.contains('uber') || desc.contains('ride'))
      return Icons.directions_car;
    if (desc.contains('bill') || desc.contains('electric'))
      return Icons.receipt_long;
    if (desc.contains('food') || desc.contains('coffee'))
      return Icons.restaurant;

    return Icons.receipt;
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.month}/${parsed.day}/${parsed.year}';
    } catch (e) {
      return date;
    }
  }

  Future<void> _connectWithConfig(Map<String, dynamic> config) async {
    setState(() {
      _isLoading = true;
      _status = 'Connecting with ${config['name']}...';
    });

    try {
      // Haptic feedback
      SystemChannels.platform.invokeMethod('HapticFeedback.lightImpact');

      // Create public token - use simple method if no config
      final publicToken = config['config'] == null
          ? await _bankingService.createSimpleSandboxToken()
          : await _bankingService.createSandboxPublicToken(
              config: config['config'],
            );

      setState(() {
        _status = 'Exchanging token...';
      });

      // Exchange for access token
      await _bankingService.exchangePublicToken(publicToken);

      setState(() {
        _status = 'Fetching accounts...';
      });

      // Get accounts
      final accounts = await _bankingService.getAccounts();

      setState(() {
        _status = 'Creating test transactions...';
      });

      // Create some test transactions for the sandbox item
      await _bankingService.createTestTransactions();

      setState(() {
        _status = 'Fetching transactions...';
      });

      // Get transactions (with error handling for PRODUCT_NOT_READY)
      List<Map<String, dynamic>> transactions = [];
      try {
        transactions = await _bankingService.getTransactions();
      } catch (e) {
        if (e.toString().contains('PRODUCT_NOT_READY')) {
          setState(() {
            _status =
                'Transactions not ready yet (normal for new sandbox items)';
          });
          // Wait a bit and try again
          await Future.delayed(const Duration(seconds: 2));
          try {
            transactions = await _bankingService.getTransactions();
          } catch (e2) {
            debugPrint('Transactions still not ready: $e2');
            transactions = [];
          }
        } else {
          rethrow;
        }
      }

      setState(() {
        _isLoading = false;
        _status = 'Successfully connected!';
        _accounts = accounts;
        _transactions = transactions;
      });

      // Success haptic
      SystemChannels.platform.invokeMethod('HapticFeedback.mediumImpact');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: ${e.toString()}';
      });

      // Error haptic
      SystemChannels.platform.invokeMethod('HapticFeedback.heavyImpact');
    }
  }
}
