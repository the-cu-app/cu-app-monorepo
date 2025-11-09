import 'package:flutter/material.dart';
import '../services/bill_pay_service.dart';
import '../services/banking_service.dart';
import '../services/auth_service.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class BillPayScreen extends StatefulWidget {
  const BillPayScreen({super.key});

  @override
  State<BillPayScreen> createState() => _BillPayScreenState();
}

class _BillPayScreenState extends State<BillPayScreen> with SingleTickerProviderStateMixin {
  final BillPayService _billPayService = BillPayService();
  final BankingService _bankingService = BankingService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _payees = [];
  List<Map<String, dynamic>> _scheduledPayments = [];
  List<Map<String, dynamic>> _recentPayments = [];
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBillPayData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBillPayData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load payees
      final payees = await _billPayService.getUserPayees();

      // Load scheduled payments
      final scheduledPayments = await _billPayService.getScheduledPayments();
      
      // Load recent payments (mock data for now)
      final recentPayments = [
        {'name': 'Netflix', 'amount': 15.99, 'date': DateTime.now().subtract(Duration(days: 2))},
        {'name': 'Spotify', 'amount': 9.99, 'date': DateTime.now().subtract(Duration(days: 5))},
        {'name': 'Electric Bill', 'amount': 125.50, 'date': DateTime.now().subtract(Duration(days: 7))},
      ];

      // Load user accounts
      final accounts = await _bankingService.getUserAccounts();

      setState(() {
        _payees = payees;
        _scheduledPayments = scheduledPayments;
        _recentPayments = recentPayments;
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _buildHeader(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPaymentTabs(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Send tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (_payees.isNotEmpty) ...[  
                              _buildQuickPaySection(context),
                              const SizedBox(height: 24),
                            ],
                            _buildRecentPayments(context),
                            const SizedBox(height: 24),
                            _buildZelleSection(context),
                            const SizedBox(height: 24),
                            _buildPayeesList(context),
                          ],
                        ),
                      ),
                      // Request tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildRequestSection(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Payments',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildPaymentTabs(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.black,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Send'),
            Tab(text: 'Request'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickPaySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Pay',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickPayForm(context),
      ],
    );
  }

  Widget _buildQuickPayForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();
    final _descriptionController = TextEditingController();
    String? _selectedAccount;
    String? _selectedPayee;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedAccount,
                  decoration: InputDecoration(
                    hintText: 'From Account',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _accounts
                      .map((account) => DropdownMenuItem<String>(
                            value: account['id'],
                            child: Text(
                                '${account['name']} - \$${(account['balance'] ?? 0.0).toStringAsFixed(2)}'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAccount = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Please select an account';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPayee,
                  decoration: InputDecoration(
                    hintText: 'Select Payee',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Select Payee'),
                    ),
                    ..._payees.map((payee) => DropdownMenuItem<String>(
                          value: payee['id'],
                          child: Text(payee['name']),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPayee = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Please select a payee';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _processQuickPayment(
                    context,
                    _formKey,
                    _selectedAccount,
                    _selectedPayee,
                    _amountController.text,
                    _descriptionController.text,
                  ),
                  icon: const Icon(Icons.payment),
                  label: const Text('Pay Now'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _schedulePayment(
                    context,
                    _formKey,
                    _selectedAccount,
                    _selectedPayee,
                    _amountController.text,
                    _descriptionController.text,
                  ),
                  icon: const Icon(Icons.schedule),
                  label: const Text('Schedule'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledPayments(BuildContext context) {
    if (_scheduledPayments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Scheduled Payments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Schedule payments to avoid late fees',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scheduled Payments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () => _showScheduledPaymentsDialog(context),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._scheduledPayments.take(3).map(
                  (payment) => _buildScheduledPaymentItem(context, payment),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledPaymentItem(
    BuildContext context,
    Map<String, dynamic> payment,
  ) {
    final amount = payment['amount'] ?? 0.0;
    final nextPaymentDate = DateTime.parse(
        payment['next_payment_date'] ?? DateTime.now().toIso8601String());
    final frequency = payment['frequency'] ?? 'monthly';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.schedule,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        payment['payee_name'] ?? 'Payee',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        'Next: ${_formatDate(nextPaymentDate)} • $frequency',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          TextButton(
            onPressed: () => _cancelScheduledPayment(context, payment['id']),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPayeesList(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Payees',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () => _showAddPayeeDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Payee'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_payees.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Payees Added',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add payees to make bill payments easier',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._payees.map((payee) => _buildPayeeItem(context, payee)),
          ],
        ),
      ),
    );
  }

  Widget _buildPayeeItem(BuildContext context, Map<String, dynamic> payee) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.person,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        payee['name'] ?? 'Payee',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        payee['account_number'] ?? 'No account number',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'edit':
              _editPayee(context, payee);
              break;
            case 'delete':
              _deletePayee(context, payee['id']);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _processQuickPayment(
    BuildContext context,
    GlobalKey<FormState> formKey,
    String? accountId,
    String? payeeId,
    String amount,
    String description,
  ) async {
    if (!formKey.currentState!.validate()) return;

    try {
      await _billPayService.processImmediatePayment(
        accountId: accountId!,
        payeeId: payeeId!,
        amount: double.parse(amount),
        memo: description,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment processed successfully!')),
        );
        _loadBillPayData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    }
  }

  Future<void> _schedulePayment(
    BuildContext context,
    GlobalKey<FormState> formKey,
    String? accountId,
    String? payeeId,
    String amount,
    String description,
  ) async {
    if (!formKey.currentState!.validate()) return;

    // Show frequency selection dialog
    final frequency = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('One-time'),
              onTap: () => Navigator.pop(context, 'one-time'),
            ),
            ListTile(
              title: const Text('Monthly'),
              onTap: () => Navigator.pop(context, 'monthly'),
            ),
            ListTile(
              title: const Text('Quarterly'),
              onTap: () => Navigator.pop(context, 'quarterly'),
            ),
            ListTile(
              title: const Text('Annually'),
              onTap: () => Navigator.pop(context, 'annually'),
            ),
          ],
        ),
      ),
    );

    if (frequency != null) {
      try {
        await _billPayService.schedulePayment(
          payeeId: payeeId!,
          accountId: accountId!,
          amount: double.parse(amount),
          nextPaymentDate: DateTime.now(),
          frequency: frequency,
          memo: description,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment scheduled successfully!')),
          );
          _loadBillPayData(); // Refresh data
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to schedule payment: $e')),
          );
        }
      }
    }
  }

  Future<void> _cancelScheduledPayment(
      BuildContext context, String paymentId) async {
    try {
      await _billPayService.cancelScheduledPayment(paymentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled successfully!')),
        );
        _loadBillPayData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel payment: $e')),
        );
      }
    }
  }

  void _showScheduledPaymentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Scheduled Payments'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _scheduledPayments.length,
            itemBuilder: (context, index) {
              final payment = _scheduledPayments[index];
              return ListTile(
                title: Text(payment['payee_name'] ?? 'Payee'),
                subtitle:
                    Text('\$${(payment['amount'] ?? 0.0).toStringAsFixed(2)}'),
                trailing: Text(_formatDate(DateTime.parse(
                    payment['next_payment_date'] ??
                        DateTime.now().toIso8601String()))),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddPayeeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Payee'),
        content: const Text('Contact SUPAHYPER to add new payees.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editPayee(BuildContext context, Map<String, dynamic> payee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${payee['name']}'),
        content: const Text('Payee editing feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePayee(BuildContext context, String payeeId) async {
    try {
      await _billPayService.deletePayee(payeeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payee deleted successfully!')),
        );
        _loadBillPayData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete payee: $e')),
        );
      }
    }
  }

  Widget _buildRecentPayments(BuildContext context) {
    if (_recentPayments.isEmpty) {
      return Container();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...(_recentPayments.map((payment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.payment,
                        color: Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _formatDate(payment['date']),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-\$${(payment['amount'] ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList()),
      ],
    );
  }

  Widget _buildZelleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6B3AA0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Zelle®',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Send money with Zelle',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.person_add_alt_1, color: Colors.grey.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Send to a new recipient',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRequestSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'Share your payment link',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'supahyper.com/pay/username',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy link',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share),
                    tooltip: 'Share',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.qr_code),
                    tooltip: 'QR Code',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Request from contacts',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No contacts yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {},
                child: const Text('Import contacts'),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
}
