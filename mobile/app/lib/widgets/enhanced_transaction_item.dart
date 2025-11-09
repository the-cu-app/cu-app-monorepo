import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/merchant_logo_service.dart';

class EnhancedTransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onTap;
  final bool showAccountName;

  const EnhancedTransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.showAccountName = false,
  });

  @override
  Widget build(BuildContext context) {
    final amount = (transaction['amount'] ?? 0.0).toDouble();
    final merchantName =
        transaction['merchant_name'] ?? transaction['name'] ?? 'Unknown';
    final category =
        transaction['primary_category'] ?? transaction['category'] ?? 'Other';
    final date = DateTime.tryParse(transaction['date'] ?? '') ?? DateTime.now();
    final isPending = transaction['pending'] ?? false;
    final isRecurring = transaction['is_recurring'] ?? false;
    final isSubscription = transaction['is_subscription'] ?? false;

    final isDebit = amount > 0;
    final displayAmount = amount.abs();

    final logoService = MerchantLogoService();
    final merchantInfo = logoService.getMerchantInfo(merchantName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => _showTransactionDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Merchant logo
              Hero(
                tag: 'merchant_logo_${transaction['id']}',
                child: MerchantLogo(
                  merchantName: merchantName,
                  size: 48,
                ),
              ),
              const SizedBox(width: 16),

              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Merchant name with badges
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            merchantInfo.name,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isRecurring || isSubscription) ...[
                          const SizedBox(width: 8),
                          _buildBadge(
                            context,
                            isSubscription ? 'Subscription' : 'Recurring',
                            Colors.blue,
                          ),
                        ],
                        if (isPending) ...[
                          const SizedBox(width: 8),
                          _buildBadge(context, 'Pending', Colors.orange),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Category and date
                    Row(
                      children: [
                        Icon(
                          logoService.getCategoryIcon(category),
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDate(date),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),

                    // Account name if requested
                    if (showAccountName &&
                        transaction['account_name'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        transaction['account_name'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDebit ? '-' : '+'}\$${displayAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDebit
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.green.shade700,
                        ),
                  ),
                  if (isPending) ...[
                    const SizedBox(height: 2),
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: Colors.orange.shade700,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat('EEEE').format(date);
    } else if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  void _showTransactionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailsSheet(
        transaction: transaction,
      ),
    );
  }
}

// Transaction details sheet
class TransactionDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailsSheet({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final amount = (transaction['amount'] ?? 0.0).toDouble();
    final merchantName =
        transaction['merchant_name'] ?? transaction['name'] ?? 'Unknown';
    final category =
        transaction['primary_category'] ?? transaction['category'] ?? 'Other';
    final subcategory = transaction['subcategory'] ?? '';
    final date = DateTime.tryParse(transaction['date'] ?? '') ?? DateTime.now();
    final isPending = transaction['pending'] ?? false;
    final isRecurring = transaction['is_recurring'] ?? false;
    final isSubscription = transaction['is_subscription'] ?? false;
    final paymentChannel = transaction['payment_channel'] ?? 'other';

    final logoService = MerchantLogoService();
    final merchantInfo = logoService.getMerchantInfo(merchantName);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Merchant logo and name
                  Hero(
                    tag: 'merchant_logo_${transaction['id']}',
                    child: MerchantLogo(
                      merchantName: merchantName,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    merchantInfo.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Amount
                  Text(
                    '${amount > 0 ? '-' : '+'}\$${amount.abs().toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: amount > 0
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.green.shade700,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Details
                  _buildDetailSection(
                    context,
                    'Transaction Details',
                    [
                      _buildDetailRow(context, 'Date',
                          DateFormat('EEEE, MMMM d, yyyy').format(date)),
                      _buildDetailRow(
                          context, 'Time', DateFormat('h:mm a').format(date)),
                      _buildDetailRow(context, 'Category',
                          '$category${subcategory.isNotEmpty ? ' • $subcategory' : ''}'),
                      _buildDetailRow(context, 'Payment Method',
                          _formatPaymentChannel(paymentChannel)),
                      _buildDetailRow(
                          context, 'Status', isPending ? 'Pending' : 'Posted'),
                      if (transaction['account_name'] != null)
                        _buildDetailRow(
                            context, 'Account', transaction['account_name']),
                      if (transaction['transaction_id'] != null)
                        _buildDetailRow(context, 'Transaction ID',
                            transaction['transaction_id'],
                            isMonospace: true),
                    ],
                  ),

                  // Tags
                  if (isRecurring || isSubscription) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (isSubscription)
                          Chip(
                            label: const Text('Subscription'),
                            avatar: const Icon(Icons.repeat, size: 18),
                            backgroundColor: Colors.blue.shade50,
                            labelStyle: TextStyle(color: Colors.blue.shade700),
                          ),
                        if (isRecurring && !isSubscription)
                          Chip(
                            label: const Text('Recurring'),
                            avatar: const Icon(Icons.autorenew, size: 18),
                            backgroundColor: Colors.purple.shade50,
                            labelStyle:
                                TextStyle(color: Colors.purple.shade700),
                          ),
                      ],
                    ),
                  ],

                  // Actions
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement dispute
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text('Report Issue'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            // TODO: Implement receipt view
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.receipt_outlined),
                          label: const Text('View Receipt'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPaymentChannel(String channel) {
    switch (channel.toLowerCase()) {
      case 'online':
        return 'Online';
      case 'in_store':
        return 'In Store';
      case 'atm':
        return 'ATM';
      case 'other':
        return 'Card';
      default:
        return channel;
    }
  }
}
