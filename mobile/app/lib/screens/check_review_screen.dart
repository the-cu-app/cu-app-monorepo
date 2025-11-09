import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/check_deposit_model.dart';
import '../services/check_deposit_service.dart';
import '../services/banking_service.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class CheckReviewScreen extends StatefulWidget {
  final CheckDeposit deposit;
  
  const CheckReviewScreen({
    super.key,
    required this.deposit,
  });

  @override
  State<CheckReviewScreen> createState() => _CheckReviewScreenState();
}

class _CheckReviewScreenState extends State<CheckReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _checkNumberController = TextEditingController();
  final _checkDepositService = CheckDepositService();
  final _bankingService = BankingService();
  
  bool _isProcessing = false;
  double? _ocrAmount;
  bool _isLoadingOCR = false;
  List<Map<String, dynamic>> _accounts = [];
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.deposit.accountId;
    _checkNumberController.text = widget.deposit.checkNumber ?? '';
    if (widget.deposit.amount > 0) {
      _amountController.text = widget.deposit.amount.toStringAsFixed(2);
    }
    _loadAccounts();
    _performOCR();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _checkNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _bankingService.getUserAccounts();
      // Filter to only show depository accounts
      final depositoryAccounts = accounts.where((account) {
        return account['type'] == 'depository';
      }).toList();
      
      setState(() {
        _accounts = depositoryAccounts;
      });
    } catch (e) {
      print('Error loading accounts: $e');
    }
  }

  Future<void> _performOCR() async {
    if (widget.deposit.frontImage == null) return;
    
    setState(() {
      _isLoadingOCR = true;
    });
    
    try {
      final amount = await _checkDepositService.extractAmountFromCheck(
        widget.deposit.frontImage!,
      );
      
      if (amount != null && mounted) {
        setState(() {
          _ocrAmount = amount;
          _amountController.text = amount.toStringAsFixed(2);
        });
        
        // Show OCR result
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check amount detected: \$${amount.toStringAsFixed(2)}'),
            action: SnackBarAction(
              label: 'Change',
              onPressed: () {
                _amountController.clear();
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('OCR error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOCR = false;
        });
      }
    }
  }

  Future<void> _submitDeposit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final amount = double.parse(_amountController.text);
      
      // Validate amount
      final error = await _checkDepositService.validateAmount(amount);
      if (error != null) {
        if (!mounted) return;
        _showError(error);
        return;
      }
      
      // Update deposit details
      final updatedDeposit = await _checkDepositService.updateDepositDetails(
        deposit: widget.deposit,
        amount: amount,
        checkNumber: _checkNumberController.text.trim(),
      );
      
      // Navigate to confirmation screen
      if (!mounted) return;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CheckDepositConfirmationScreen(
            deposit: updatedDeposit.copyWith(accountId: _selectedAccountId ?? updatedDeposit.accountId),
          ),
        ),
      );
      
      if (result == true && mounted) {
        // Return to main screen
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to process deposit: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Check Details'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Check images preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check Images',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: widget.deposit.frontImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          widget.deposit.frontImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.image_not_supported),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Front'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: widget.deposit.backImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          widget.deposit.backImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.image_not_supported),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Back'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Account selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deposit To',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Select Account',
                        border: OutlineInputBorder(),
                      ),
                      items: _accounts.map((account) {
                        return DropdownMenuItem<String>(
                          value: account['id'],
                          child: Text(
                            '${account['name']} - \$${(account['balance'] ?? 0.0).toStringAsFixed(2)}',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAccountId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an account';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Check details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$ ',
                        border: const OutlineInputBorder(),
                        suffixIcon: _isLoadingOCR
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the check amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    if (_ocrAmount != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Detected amount: \$${_ocrAmount!.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _checkNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Check Number (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Submit button
            FilledButton(
              onPressed: _isProcessing ? null : _submitDeposit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Continue'),
            ),
            
            const SizedBox(height: 16),
            
            // Info text
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Funds are typically available within 1-2 business days.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Confirmation Screen
class CheckDepositConfirmationScreen extends StatefulWidget {
  final CheckDeposit deposit;
  
  const CheckDepositConfirmationScreen({
    super.key,
    required this.deposit,
  });

  @override
  State<CheckDepositConfirmationScreen> createState() => _CheckDepositConfirmationScreenState();
}

class _CheckDepositConfirmationScreenState extends State<CheckDepositConfirmationScreen> {
  final _checkDepositService = CheckDepositService();
  final _bankingService = BankingService();
  bool _isSubmitting = false;
  CheckDeposit? _completedDeposit;
  Map<String, dynamic>? _account;

  @override
  void initState() {
    super.initState();
    _loadAccountDetails();
  }

  Future<void> _loadAccountDetails() async {
    try {
      final account = await _bankingService.getAccountDetails(widget.deposit.accountId);
      setState(() {
        _account = account;
      });
    } catch (e) {
      print('Error loading account: $e');
    }
  }

  Future<void> _confirmDeposit() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _checkDepositService.submitDeposit(widget.deposit);
      
      setState(() {
        _completedDeposit = result;
        _isSubmitting = false;
      });

      if (result.status == CheckDepositStatus.completed) {
        _showSuccessDialog(result);
      } else {
        _showFailureDialog(result);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to submit deposit: $e');
    }
  }

  void _showSuccessDialog(CheckDeposit deposit) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('Deposit Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${deposit.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Reference: ${deposit.referenceNumber}'),
            const SizedBox(height: 16),
            const Text(
              'Your deposit is being processed. Funds will be available within 1-2 business days.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
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

  void _showFailureDialog(CheckDeposit deposit) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('Deposit Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              deposit.failureReason ?? 'An error occurred while processing your deposit.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, false);
            },
            child: const Text('Try Again'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Deposit'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deposit Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    'Amount',
                    '\$${widget.deposit.amount.toStringAsFixed(2)}',
                    isHighlighted: true,
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'To Account',
                    _account?['name'] ?? 'Loading...',
                  ),
                  if (_account != null)
                    _buildSummaryRow(
                      'Current Balance',
                      '\$${(_account!['balance'] ?? 0.0).toStringAsFixed(2)}',
                    ),
                  if (widget.deposit.checkNumber?.isNotEmpty == true) ...[
                    const Divider(),
                    _buildSummaryRow(
                      'Check Number',
                      widget.deposit.checkNumber!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Check images
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check Images',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1.6,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                widget.deposit.frontImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1.6,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                widget.deposit.backImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Action buttons
          FilledButton(
            onPressed: _isSubmitting ? null : _confirmDeposit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit Deposit'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: const Text('Back to Edit'),
          ),
          
          const SizedBox(height: 24),
          
          // Terms
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Terms & Security',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By submitting this deposit, you confirm that you are the payee or authorized to deposit this check. Funds are subject to verification and may be held according to our funds availability policy.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: isHighlighted
                ? Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    )
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}