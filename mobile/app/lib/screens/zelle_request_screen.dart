import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/zelle_model.dart';
import '../services/zelle_service.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class ZelleRequestScreen extends StatefulWidget {
  final ZelleRecipient? recipient;
  final bool isSplitBill;
  
  const ZelleRequestScreen({
    super.key,
    this.recipient,
    this.isSplitBill = false,
  });

  @override
  State<ZelleRequestScreen> createState() => _ZelleRequestScreenState();
}

class _ZelleRequestScreenState extends State<ZelleRequestScreen>
    with SingleTickerProviderStateMixin {
  final ZelleService _zelleService = ZelleService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  
  late TabController _tabController;
  
  List<ZelleRecipient> _selectedRecipients = [];
  bool _isRequesting = false;
  String? _errorMessage;
  
  // Split bill options
  bool _equalSplit = true;
  Map<String, TextEditingController> _customAmountControllers = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isSplitBill ? 1 : 2,
      vsync: this,
    );
    
    if (widget.recipient != null) {
      _selectedRecipients = [widget.recipient!];
    }
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    _tabController.dispose();
    _customAmountControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
  
  Future<void> _selectRecipients() async {
    final recipients = await _zelleService.getAllRecipients();
    
    if (!mounted) return;
    
    final selected = await showDialog<List<ZelleRecipient>>(
      context: context,
      builder: (context) => _RecipientSelectionDialog(
        recipients: recipients,
        selectedRecipients: _selectedRecipients,
        multiple: widget.isSplitBill || _tabController.index == 1,
      ),
    );
    
    if (selected != null) {
      setState(() {
        _selectedRecipients = selected;
        _updateCustomAmountControllers();
      });
    }
  }
  
  void _updateCustomAmountControllers() {
    // Remove controllers for deselected recipients
    _customAmountControllers.removeWhere((id, controller) {
      if (!_selectedRecipients.any((r) => r.id == id)) {
        controller.dispose();
        return true;
      }
      return false;
    });
    
    // Add controllers for new recipients
    for (final recipient in _selectedRecipients) {
      if (!_customAmountControllers.containsKey(recipient.id)) {
        _customAmountControllers[recipient.id] = TextEditingController();
      }
    }
  }
  
  Future<void> _requestMoney() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRecipients.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one recipient';
      });
      return;
    }
    
    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });
    
    try {
      if (widget.isSplitBill || _tabController.index == 1) {
        // Split bill
        final totalAmount = double.parse(_amountController.text);
        final customAmounts = <String, double>{};
        
        if (!_equalSplit) {
          // Validate custom amounts
          double customTotal = 0;
          for (final entry in _customAmountControllers.entries) {
            final amount = double.tryParse(entry.value.text) ?? 0;
            if (amount <= 0) {
              throw Exception('Please enter valid amounts for all recipients');
            }
            customAmounts[entry.key] = amount;
            customTotal += amount;
          }
          
          if ((customTotal - totalAmount).abs() > 0.01) {
            throw Exception('Individual amounts must add up to total amount');
          }
        }
        
        final requests = await _zelleService.splitBill(
          recipientIds: _selectedRecipients.map((r) => r.id).toList(),
          totalAmount: totalAmount,
          memo: _memoController.text.isEmpty ? null : _memoController.text,
          equalSplit: _equalSplit,
          customAmounts: _equalSplit ? null : customAmounts,
        );
        
        if (requests.isEmpty) {
          throw Exception('Failed to create payment requests');
        }
        
        if (mounted) {
          _showSuccessDialog(requests.length, totalAmount);
        }
      } else {
        // Single request
        final recipient = _selectedRecipients.first;
        final amount = double.parse(_amountController.text);
        
        final request = await _zelleService.requestMoney(
          recipientId: recipient.id,
          amount: amount,
          memo: _memoController.text.isEmpty ? null : _memoController.text,
        );
        
        if (request == null) {
          throw Exception('Failed to create payment request');
        }
        
        if (mounted) {
          _showSuccessDialog(1, amount);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isRequesting = false;
      });
      HapticFeedback.vibrate();
    }
  }
  
  void _showSuccessDialog(int requestCount, double amount) {
    final isSplit = requestCount > 1;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 64,
        ),
        title: Text(isSplit ? 'Split Bill Sent!' : 'Request Sent!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSplit) ...[
              Text(
                'Total: \$${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Sent to $requestCount people'),
              if (_equalSplit)
                Text(
                  '\$${(amount / requestCount).toStringAsFixed(2)} each',
                  style: const TextStyle(color: Colors.grey),
                ),
            ] else ...[
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Requested from ${_selectedRecipients.first.name}'),
            ],
            const SizedBox(height: 8),
            const Text(
              'Recipients will be notified',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final limits = _zelleService.getZelleLimits();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSplitBill ? 'Split Bill' : 'Request Money'),
        bottom: widget.isSplitBill
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Request'),
                  Tab(text: 'Split Bill'),
                ],
              ),
      ),
      body: Form(
        key: _formKey,
        child: widget.isSplitBill
            ? _buildSplitBillContent()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildRequestContent(),
                  _buildSplitBillContent(),
                ],
              ),
      ),
    );
  }
  
  Widget _buildRequestContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Recipient
          _buildRecipientSection(multiple: false),
          const SizedBox(height: 24),
          
          // Amount
          _buildAmountInput(),
          const SizedBox(height: 24),
          
          // Memo
          _buildMemoField(),
          const SizedBox(height: 24),
          
          // Info
          _buildRequestInfo(),
          const SizedBox(height: 24),
          
          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          
          // Request button
          FilledButton(
            onPressed: _isRequesting ? null : _requestMoney,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isRequesting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Send Request',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSplitBillContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total amount
          _buildAmountInput(label: 'Total Bill Amount'),
          const SizedBox(height: 24),
          
          // Recipients
          _buildRecipientSection(multiple: true),
          const SizedBox(height: 24),
          
          // Split type
          _buildSplitTypeSelector(),
          const SizedBox(height: 24),
          
          // Custom amounts (if not equal split)
          if (!_equalSplit) ...[
            _buildCustomAmounts(),
            const SizedBox(height: 24),
          ],
          
          // Memo
          _buildMemoField(),
          const SizedBox(height: 24),
          
          // Info
          _buildSplitBillInfo(),
          const SizedBox(height: 24),
          
          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          
          // Split button
          FilledButton(
            onPressed: _isRequesting ? null : _requestMoney,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isRequesting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Split & Request',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecipientSection({required bool multiple}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  multiple ? 'Recipients' : 'Request From',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectedRecipients.isNotEmpty && multiple)
                  Text(
                    '${_selectedRecipients.length} selected',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedRecipients.isEmpty) ...[
              OutlinedButton.icon(
                onPressed: _selectRecipients,
                icon: const Icon(Icons.add),
                label: Text(multiple ? 'Add Recipients' : 'Select Recipient'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedRecipients.map((recipient) => Chip(
                      avatar: CircleAvatar(
                        child: Text(recipient.name[0].toUpperCase()),
                      ),
                      label: Text(recipient.name),
                      onDeleted: multiple
                          ? () {
                              setState(() {
                                _selectedRecipients.remove(recipient);
                                _updateCustomAmountControllers();
                              });
                            }
                          : null,
                    ))
                    .toList(),
              ),
              if (multiple) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _selectRecipients,
                  icon: const Icon(Icons.add),
                  label: const Text('Add More'),
                ),
              ] else ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _selectRecipients,
                  child: const Text('Change'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAmountInput({String label = 'Amount'}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            if (_tabController.index == 1 && _selectedRecipients.length > 1 && _equalSplit) ...[
              const SizedBox(height: 8),
              Text(
                'Each person will be charged: \$${_calculateSplitAmount()}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _calculateSplitAmount() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount > 0 && _selectedRecipients.isNotEmpty) {
      return (amount / _selectedRecipients.length).toStringAsFixed(2);
    }
    return '0.00';
  }
  
  Widget _buildSplitTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Split Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Equal Split'),
                  icon: Icon(Icons.format_align_center),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Custom Amounts'),
                  icon: Icon(Icons.edit),
                ),
              ],
              selected: {_equalSplit},
              onSelectionChanged: (value) {
                setState(() {
                  _equalSplit = value.first;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomAmounts() {
    final totalAmount = double.tryParse(_amountController.text) ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Individual Amounts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._selectedRecipients.map((recipient) {
              final controller = _customAmountControllers[recipient.id]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        recipient.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Required';
                          }
                          final amount = double.tryParse(value!);
                          if (amount == null || amount <= 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (totalAmount > 0) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildMemoField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Memo (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                hintText: 'What\'s this for?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRequestInfo() {
    final limits = _zelleService.getZelleLimits();
    
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Request Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Requests expire in ${limits['request_expiration_days']} days\n'
              'Recipients will receive an email notification\n'
              'You\'ll be notified when the request is paid',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSplitBillInfo() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Split Bill Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Each person will receive a separate payment request\n'
              'You can track individual payments in your activity\n'
              'Recipients have 7 days to pay their share',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Recipient selection dialog
class _RecipientSelectionDialog extends StatefulWidget {
  final List<ZelleRecipient> recipients;
  final List<ZelleRecipient> selectedRecipients;
  final bool multiple;
  
  const _RecipientSelectionDialog({
    required this.recipients,
    required this.selectedRecipients,
    required this.multiple,
  });

  @override
  State<_RecipientSelectionDialog> createState() => _RecipientSelectionDialogState();
}

class _RecipientSelectionDialogState extends State<_RecipientSelectionDialog> {
  late List<ZelleRecipient> _selected;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedRecipients);
  }
  
  List<ZelleRecipient> get _filteredRecipients {
    if (_searchQuery.isEmpty) return widget.recipients;
    
    final query = _searchQuery.toLowerCase();
    return widget.recipients.where((recipient) {
      return recipient.name.toLowerCase().contains(query) ||
          recipient.email.toLowerCase().contains(query);
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.multiple ? 'Select Recipients' : 'Select Recipient'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search contacts',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredRecipients.length,
                itemBuilder: (context, index) {
                  final recipient = _filteredRecipients[index];
                  final isSelected = _selected.contains(recipient);
                  
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(recipient.name[0].toUpperCase()),
                    ),
                    title: Text(recipient.name),
                    subtitle: Text(recipient.email),
                    trailing: widget.multiple
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value ?? false) {
                                  _selected.add(recipient);
                                } else {
                                  _selected.remove(recipient);
                                }
                              });
                            },
                          )
                        : isSelected
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                    onTap: () {
                      if (widget.multiple) {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(recipient);
                          } else {
                            _selected.add(recipient);
                          }
                        });
                      } else {
                        Navigator.pop(context, [recipient]);
                      }
                    },
                  );
                },
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
        if (widget.multiple)
          FilledButton(
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.pop(context, _selected),
            child: Text('Select (${_selected.length})'),
          ),
      ],
    );
  }
}