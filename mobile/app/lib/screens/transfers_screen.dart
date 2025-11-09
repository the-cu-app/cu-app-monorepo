import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../services/transfers_service.dart';
import '../services/banking_service.dart';
import '../services/auth_service.dart';
import '../services/widget_journey_logger.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  final TransfersService _transfersService = TransfersService();
  final BankingService _bankingService = BankingService();
  final AuthService _authService = AuthService();
  final WidgetJourneyLogger _logger = WidgetJourneyLogger();

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _recentTransfers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _logger.logView('transfers_screen');
    _loadTransferData();
  }

  Future<void> _loadTransferData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final accounts = await _bankingService.getUserAccounts();
      final transfers = await _transfersService.getTransferHistory();

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _recentTransfers = transfers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CUScaffold(
      body: _isLoading
          ? const Center(child: CUProgressIndicator())
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
                        _buildNewTransferSection(context),
                        const SizedBox(height: 16),
                        _buildRecentTransfers(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = _authService.currentUser;
    final firstName = user?.userMetadata?['first_name'] ?? 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transfers, $firstName',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Move money between accounts or send to others',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildNewTransferSection(BuildContext context) {
    return CUCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CUText(
              'New Transfer',
              style: CUTextStyle.h3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CUButton(
                    onPressed: () {
                      _logger.logInteraction('transfer_internal_button_tapped');
                      _showInternalTransferDialog(context);
                    },
                    text: 'Between My Accounts',
                    icon: Icons.swap_horiz,
                    type: CUButtonType.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CUButton(
                    onPressed: () {
                      _logger.logInteraction('transfer_external_button_tapped');
                      _showExternalTransferDialog(context);
                    },
                    text: 'To External Bank',
                    icon: Icons.send,
                    type: CUButtonType.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransfers(BuildContext context) {
    if (_recentTransfers.isEmpty) {
      return CUCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: CUText(
              'No recent transfers',
              style: CUTextStyle.bodyMedium,
            ),
          ),
        ),
      );
    }

    return CUCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CUText(
              'Recent Transfers',
              style: CUTextStyle.h3,
            ),
            const SizedBox(height: 16),
            ..._recentTransfers.take(5).map(
                  (transfer) => _buildTransferItem(context, transfer),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferItem(
      BuildContext context, Map<String, dynamic> transfer) {
    final amount = transfer['amount'] ?? 0.0;
    final type = transfer['type'] ?? '';
    final status = transfer['status'] ?? '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          _getTransferIcon(type),
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(_getTransferDescription(transfer)),
      subtitle: Text(
          '${_formatTransferType(type)} • ${_formatDate(DateTime.parse(transfer['created_at'] ?? DateTime.now().toIso8601String()))}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransferIcon(String type) {
    switch (type) {
      case 'internal_transfer':
        return Icons.swap_horiz;
      case 'external_transfer':
        return Icons.send;
      case 'zelle_transfer':
        return Icons.flash_on;
      default:
        return Icons.swap_horiz;
    }
  }

  String _formatTransferType(String type) {
    switch (type) {
      case 'internal_transfer':
        return 'Internal';
      case 'external_transfer':
        return 'External';
      case 'zelle_transfer':
        return 'Zelle';
      default:
        return 'Transfer';
    }
  }

  String _getTransferDescription(Map<String, dynamic> transfer) {
    final type = transfer['type'] ?? '';
    switch (type) {
      case 'internal_transfer':
        return 'Transfer between accounts';
      case 'external_transfer':
        return 'Transfer to ${transfer['external_bank_name'] ?? 'External Bank'}';
      case 'zelle_transfer':
        return 'Zelle to ${transfer['recipient_name'] ?? 'Recipient'}';
      default:
        return 'Transfer';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  void _showInternalTransferDialog(BuildContext context) {
    if (_accounts.length < 2) {
      _showErrorDialog(
          context, 'You need at least 2 accounts to make internal transfers.');
      return;
    }

    String? fromAccountId;
    String? toAccountId;
    final amountController = TextEditingController();
    final memoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Internal Transfer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'From Account',
                  border: OutlineInputBorder(),
                ),
                items: _accounts.map((account) {
                  return DropdownMenuItem<String>(
                    value: account['id'],
                    child: Text(
                        '${account['name']} (\$${(account['balance'] ?? 0.0).toStringAsFixed(2)})'),
                  );
                }).toList(),
                onChanged: (value) => fromAccountId = value,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'To Account',
                  border: OutlineInputBorder(),
                ),
                items: _accounts.map((account) {
                  return DropdownMenuItem<String>(
                    value: account['id'],
                    child: Text(
                        '${account['name']} (\$${(account['balance'] ?? 0.0).toStringAsFixed(2)})'),
                  );
                }).toList(),
                onChanged: (value) => toAccountId = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: memoController,
                decoration: const InputDecoration(
                  labelText: 'Memo (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (fromAccountId == null ||
                  toAccountId == null ||
                  amountController.text.isEmpty) {
                _showErrorDialog(
                    context, 'Please fill in all required fields.');
                return;
              }

              if (fromAccountId == toAccountId) {
                _showErrorDialog(
                    context, 'From and To accounts must be different.');
                return;
              }

              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                _showErrorDialog(context, 'Please enter a valid amount.');
                return;
              }

              Navigator.pop(context);
              await _processInternalTransfer(
                  fromAccountId!, toAccountId!, amount, memoController.text);
            },
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  void _showExternalTransferDialog(BuildContext context) {
    String? fromAccountId;
    final amountController = TextEditingController();
    final memoController = TextEditingController();
    final accountNumberController = TextEditingController();
    final routingNumberController = TextEditingController();
    final bankNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('External Transfer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'From Account',
                  border: OutlineInputBorder(),
                ),
                items: _accounts.map((account) {
                  return DropdownMenuItem<String>(
                    value: account['id'],
                    child: Text(
                        '${account['name']} (\$${(account['balance'] ?? 0.0).toStringAsFixed(2)})'),
                  );
                }).toList(),
                onChanged: (value) => fromAccountId = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: routingNumberController,
                decoration: const InputDecoration(
                  labelText: 'Routing Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: memoController,
                decoration: const InputDecoration(
                  labelText: 'Memo (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (fromAccountId == null ||
                  amountController.text.isEmpty ||
                  bankNameController.text.isEmpty ||
                  accountNumberController.text.isEmpty ||
                  routingNumberController.text.isEmpty) {
                _showErrorDialog(
                    context, 'Please fill in all required fields.');
                return;
              }

              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                _showErrorDialog(context, 'Please enter a valid amount.');
                return;
              }

              Navigator.pop(context);
              await _processExternalTransfer(
                fromAccountId!,
                accountNumberController.text,
                routingNumberController.text,
                bankNameController.text,
                amount,
                memoController.text,
              );
            },
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

  Future<void> _processInternalTransfer(String fromAccountId,
      String toAccountId, double amount, String memo) async {
    _showLoadingDialog(context, 'Processing transfer...');

    try {
      await _transfersService.processInternalTransfer(
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        amount: amount,
        memo: memo.isNotEmpty ? memo : null,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(context, 'Transfer completed successfully!');
        _loadTransferData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog(context, 'Transfer failed: ${e.toString()}');
      }
    }
  }

  Future<void> _processExternalTransfer(
      String fromAccountId,
      String accountNumber,
      String routingNumber,
      String bankName,
      double amount,
      String memo) async {
    _showLoadingDialog(context, 'Processing external transfer...');

    try {
      await _transfersService.processExternalTransfer(
        fromAccountId: fromAccountId,
        externalAccountNumber: accountNumber,
        externalRoutingNumber: routingNumber,
        externalBankName: bankName,
        amount: amount,
        memo: memo.isNotEmpty ? memo : null,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(
            context, 'External transfer initiated successfully!');
        _loadTransferData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog(context, 'Transfer failed: ${e.toString()}');
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
