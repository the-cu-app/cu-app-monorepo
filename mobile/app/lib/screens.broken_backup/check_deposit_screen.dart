import 'dart:io';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../models/check_deposit_model.dart';
import '../services/check_deposit_service.dart';
import '../services/banking_service.dart';
import '../services/profile_service.dart';
import 'check_capture_screen.dart';
import 'check_review_screen.dart';

class CheckDepositScreen extends StatefulWidget {
  const CheckDepositScreen({super.key});

  @override
  State<CheckDepositScreen> createState() => _CheckDepositScreenState();
}

class _CheckDepositScreenState extends State<CheckDepositScreen> {
  final _checkDepositService = CheckDepositService();
  final _bankingService = BankingService();
  final _profileService = ProfileService();
  
  CheckDeposit? _currentDeposit;
  CheckDepositLimits? _limits;
  List<Map<String, dynamic>> _accounts = [];
  String? _selectedAccountId;
  bool _isLoading = true;
  bool _canDeposit = true;
  String? _depositError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Load accounts
      final accounts = await _bankingService.getUserAccounts();
      final depositoryAccounts = accounts.where((account) {
        return account['type'] == 'depository';
      }).toList();

      // Load deposit limits
      final limits = await _checkDepositService.getDepositLimits();
      
      // Check if user can deposit
      final profile = _profileService.currentProfile;
      final canDeposit = profile?.permissions.canDeposit ?? false;

      setState(() {
        _accounts = depositoryAccounts;
        _limits = limits;
        _canDeposit = canDeposit;
        _isLoading = false;
        
        // Select first account by default
        if (_accounts.isNotEmpty) {
          _selectedAccountId = _accounts.first['id'];
        }
        
        // Check if any limits are exceeded
        if (!canDeposit) {
          _depositError = 'Your profile does not have deposit permissions';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _depositError = 'Failed to load deposit information';
      });
      print('Initialization error: $e');
    }
  }

  Future<void> _startDeposit() async {
    if (_selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Please select an account')),

          );
    }

    try {
      // Create new deposit
      final deposit = await _checkDepositService.createCheckDeposit(
        accountId: _selectedAccountId!,
      );
      
      setState(() {
        _currentDeposit = deposit;
      });
      
      // Start capture flow
      _captureCheckImages();
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Failed to start deposit: $e)),

          );
    }
  }

  Future<void> _captureCheckImages() async {
    if (_currentDeposit == null) return;

    // Capture front image
    final frontCaptured = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckCaptureScreen(
          side: CheckSide.front,
          onImageCaptured: (image) async {
            _currentDeposit = await _checkDepositService.updateDepositImages(
              deposit: _currentDeposit!,
              frontImage: image,
            );
          },
        ),
      ),
    );

    if (frontCaptured == null || !mounted) return;

    // Capture back image
    final backCaptured = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckCaptureScreen(
          side: CheckSide.back,
          onImageCaptured: (image) async {
            _currentDeposit = await _checkDepositService.updateDepositImages(
              deposit: _currentDeposit!,
              backImage: image,
            );
          },
        ),
      ),
    );

    if (backCaptured == null || !mounted) return;

    // Verify we have both images
    if (_currentDeposit!.frontImage != null && _currentDeposit!.backImage != null) {
      // Proceed to review
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CheckReviewScreen(
            deposit: _currentDeposit!,
          ),
        ),
      );

      if (result == true && mounted) {
        // Deposit completed, refresh the screen
        _initialize();
        setState(() {
          _currentDeposit = null;
        });
      }
    }
  }

  Future<void> _viewDepositHistory() async {
    try {
      final history = await _checkDepositService.getDepositHistory();
      
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => CheckDepositHistorySheet(deposits: history),
      );
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Failed to load history: $e)),

          );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit Check'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _viewDepositHistory,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Error or warning card
          if (_depositError != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _depositError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (!_canDeposit)
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Check deposits are not available for your account type.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                      ),
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
                    'Select Account',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_accounts.isEmpty)
                    const Text('No eligible accounts found')
                  else
                    ..._accounts.map((account) {
                      return RadioListTile<String>(
                        title: Text(account['name']),
                        subtitle: Text(
                          'Balance: \$${(account['balance'] ?? 0.0).toStringAsFixed(2)}',
                        ),
                        value: account['id'],
                        groupValue: _selectedAccountId,
                        onChanged: _canDeposit
                            ? (value) {
                                setState(() {
                                  _selectedAccountId = value;
                                });
                              }
                            : null,
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Limits card
          if (_limits != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deposit Limits',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildLimitRow(
                      'Per Check',
                      '\$${_limits!.transactionLimit.toStringAsFixed(2)}',
                    ),
                    _buildLimitRow(
                      'Daily Limit',
                      '\$${_limits!.remainingDailyAmount.toStringAsFixed(2)} remaining',
                    ),
                    _buildLimitRow(
                      'Monthly Limit',
                      '\$${_limits!.remainingMonthlyAmount.toStringAsFixed(2)} remaining',
                    ),
                    _buildLimitRow(
                      'Daily Count',
                      '${_limits!.remainingDailyCount} of ${_limits!.dailyCount} remaining',
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Start deposit button
          FilledButton.icon(
            onPressed: _canDeposit && _selectedAccountId != null ? _startDeposit : null,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Deposit'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
          const SizedBox(height: 16),

          // Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How to Deposit a Check',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionStep(
                    '1',
                    'Endorse your check',
                    'Sign the back of your check and write "For mobile deposit only"',
                  ),
                  _buildInstructionStep(
                    '2',
                    'Take photos',
                    'Capture clear images of both the front and back of your check',
                  ),
                  _buildInstructionStep(
                    '3',
                    'Enter amount',
                    'Verify the check amount and submit for processing',
                  ),
                  _buildInstructionStep(
                    '4',
                    'Keep your check',
                    'Store your check safely for 30 days, then destroy it',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// History bottom sheet
class CheckDepositHistorySheet extends StatelessWidget {
  final List<CheckDeposit> deposits;

  const CheckDepositHistorySheet({
    super.key,
    required this.deposits,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Deposit History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              // List
              Expanded(
                child: deposits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No deposits yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: deposits.length,
                        itemBuilder: (context, index) {
                          final deposit = deposits[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: deposit.status == CheckDepositStatus.completed
                                    ? Colors.green
                                    : deposit.status == CheckDepositStatus.failed
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context).colorScheme.primary,
                                child: Icon(
                                  deposit.status == CheckDepositStatus.completed
                                      ? Icons.check
                                      : deposit.status == CheckDepositStatus.failed
                                          ? Icons.close
                                          : Icons.hourglass_empty,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                '\$${deposit.amount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(deposit.statusDisplayName),
                                  if (deposit.referenceNumber != null)
                                    Text('Ref: ${deposit.referenceNumber}'),
                                ],
                              ),
                              trailing: Text(
                                _formatDate(deposit.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    
    return '${date.month}/${date.day}/${date.year}';
  }
}