import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../models/zelle_model.dart';
import '../services/zelle_service.dart';
import '../services/banking_service.dart';
import '../services/transfers_service.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class ZelleSendScreen extends StatefulWidget {
  final ZelleRecipient? recipient;
  
  const ZelleSendScreen({
    super.key,
    this.recipient,
  });

  @override
  State<ZelleSendScreen> createState() => _ZelleSendScreenState();
}

class _ZelleSendScreenState extends State<ZelleSendScreen>
    with TickerProviderStateMixin {
  final ZelleService _zelleService = ZelleService();
  final BankingService _bankingService = BankingService();
  final TransfersService _transfersService = TransfersService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _recipientEmailController = TextEditingController();
  final _recipientNameController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  ZelleRecipient? _selectedRecipient;
  List<Map<String, dynamic>> _accounts = [];
  String? _selectedAccountId;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  
  // Delivery speed
  String _deliverySpeed = 'instant';
  
  @override
  void initState() {
    super.initState();
    _selectedRecipient = widget.recipient;
    if (_selectedRecipient != null) {
      _recipientEmailController.text = _selectedRecipient!.email;
      _recipientNameController.text = _selectedRecipient!.name;
    }
    _initializeAnimations();
    _loadAccounts();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    _recipientEmailController.dispose();
    _recipientNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    
    try {
      final accounts = await _bankingService.getUserAccounts();
      setState(() {
        _accounts = accounts;
        if (accounts.isNotEmpty) {
          _selectedAccountId = accounts.first['id'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load accounts';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectRecipient() async {
    final recipients = await _zelleService.getEnrolledRecipients();
    
    if (!mounted) return;
    
    final selected = await showModalBottomSheet<ZelleRecipient>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Select Recipient',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: recipients.length,
                  itemBuilder: (context, index) {
                    final recipient = recipients[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(recipient.name[0].toUpperCase()),
                      ),
                      title: Text(recipient.name),
                      subtitle: Text(recipient.email),
                      trailing: recipient.isEnrolled
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () => Navigator.pop(context, recipient),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    if (selected != null) {
      setState(() {
        _selectedRecipient = selected;
        _recipientEmailController.text = selected.email;
        _recipientNameController.text = selected.name;
      });
    }
  }
  
  Future<void> _sendMoney() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amount = double.parse(_amountController.text);
    
    // Check if biometric authentication is required for large amounts
    if (amount >= 500) {
      final isAuthenticated = await _authenticateWithBiometrics();
      if (!isAuthenticated) {
        setState(() {
          _errorMessage = 'Authentication required for amounts over \$500';
        });
        return;
      }
    }
    
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    
    try {
      // Verify recipient if not already selected
      if (_selectedRecipient == null) {
        // Add recipient
        final recipient = await _zelleService.addRecipient(
          name: _recipientNameController.text,
          email: _recipientEmailController.text,
        );
        _selectedRecipient = recipient;
      }
      
      if (_selectedRecipient == null) {
        throw Exception('Failed to add recipient');
      }
      
      // Verify recipient
      final verification = await _zelleService.verifyRecipient(_selectedRecipient!.id);
      if (!verification['verified']) {
        throw Exception(verification['message'] ?? 'Recipient verification failed');
      }
      
      // Show warning if recipient is not enrolled
      if (verification['warning'] != null && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Recipient Not Enrolled'),
            content: Text(verification['warning']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Send Anyway'),
              ),
            ],
          ),
        );
        
        if (proceed != true) {
          setState(() => _isSending = false);
          return;
        }
      }
      
      // Process the transfer
      final result = await _transfersService.processZelleTransfer(
        fromAccountId: _selectedAccountId!,
        recipientEmail: _selectedRecipient!.email,
        recipientName: _selectedRecipient!.name,
        recipientId: _selectedRecipient!.id,
        amount: amount,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
      );
      
      // Create Zelle transaction record
      await _zelleService.sendMoney(
        recipientId: _selectedRecipient!.id,
        fromAccountId: _selectedAccountId!,
        amount: amount,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
      );
      
      // Show success
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSuccessDialog(amount);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSending = false;
      });
      HapticFeedback.vibrate();
    }
  }
  
  Future<bool> _authenticateWithBiometrics() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) return true; // Skip if not available
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to send large payment',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      return authenticated;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }
  
  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 64,
        ),
        title: const Text('Payment Sent!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Sent to ${_selectedRecipient!.name}'),
            if (_deliverySpeed == 'instant')
              const Text(
                'Available immediately',
                style: TextStyle(color: Colors.green),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true); // Return to previous screen
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
        title: const Text('Send with Zelle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to transaction history
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Recipient section
                        _buildRecipientSection(),
                        const SizedBox(height: 24),
                        
                        // Amount input
                        _buildAmountInput(),
                        const SizedBox(height: 24),
                        
                        // Account selector
                        _buildAccountSelector(),
                        const SizedBox(height: 24),
                        
                        // Memo field
                        _buildMemoField(),
                        const SizedBox(height: 24),
                        
                        // Delivery speed (always instant for Zelle)
                        _buildDeliverySpeed(),
                        const SizedBox(height: 24),
                        
                        // Limits info
                        _buildLimitsInfo(limits),
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
                        
                        // Send button
                        FilledButton(
                          onPressed: _isSending ? null : _sendMoney,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Send Money',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildRecipientSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recipient',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedRecipient != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    _selectedRecipient!.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  _selectedRecipient!.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(_selectedRecipient!.email),
                trailing: TextButton(
                  onPressed: _selectRecipient,
                  child: const Text('Change'),
                ),
              ),
            ] else ...[
              TextFormField(
                controller: _recipientEmailController,
                decoration: InputDecoration(
                  labelText: 'Email or Phone',
                  prefixIcon: const Icon(Icons.email),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.contacts),
                    onPressed: _selectRecipient,
                  ),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter recipient email or phone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _recipientNameController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter recipient name';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAmountInput() {
    final limits = _zelleService.getZelleLimits();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Amount',
              style: TextStyle(
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
                if (amount < limits['min_amount']) {
                  return 'Minimum amount is \$${limits['min_amount']}';
                }
                if (amount > limits['max_amount']) {
                  return 'Maximum amount is \$${limits['max_amount']}';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccountSelector() {
    if (_accounts.isEmpty) return const SizedBox.shrink();
    
    final selectedAccount = _accounts.firstWhere(
      (acc) => acc['id'] == _selectedAccountId,
      orElse: () => _accounts.first,
    );
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'From Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showAccountSelector(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedAccount['name'] ?? 'Unknown Account',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Balance: \$${selectedAccount['balance']?.toStringAsFixed(2) ?? '0.00'}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAccountSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._accounts.map((account) => ListTile(
                  leading: const Icon(Icons.account_balance),
                  title: Text(account['name'] ?? 'Unknown Account'),
                  subtitle: Text(
                    'Balance: \$${account['balance']?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                  selected: account['id'] == _selectedAccountId,
                  onTap: () {
                    setState(() => _selectedAccountId = account['id']);
                    Navigator.pop(context);
                  },
                )),
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
  
  Widget _buildDeliverySpeed() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Speed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instant Delivery',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Money available in minutes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'No Fee',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
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
  
  Widget _buildLimitsInfo(Map<String, dynamic> limits) {
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
                  'Zelle Limits',
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
              'Daily: \$${limits['daily_limit']?.toStringAsFixed(0)}\n'
              'Weekly: \$${limits['weekly_limit']?.toStringAsFixed(0)}\n'
              'Per transaction: \$${limits['max_amount']?.toStringAsFixed(0)}',
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