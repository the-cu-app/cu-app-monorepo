import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Colors, Icons;
import '../foundation/colors.dart';
import '../foundation/typography.dart';
import '../foundation/spacing.dart';
import '../foundation/radius.dart';
import '../foundation/elevation.dart';
import '../foundation/theme.dart';

/// Banking-Specific Components for 1033/FDX Compliance
///
/// Components designed specifically for financial institution apps
/// with Section 1033 compliance and FDX integration.

// ============================================================================
// CU ACCOUNT CARD - Display Account Information
// ============================================================================

class CUAccountCard extends StatelessWidget {
  final String accountName;
  final String accountNumber;
  final double balance;
  final String accountType;
  final VoidCallback? onTap;
  final Color? accentColor;

  const CUAccountCard({
    Key? key,
    required this.accountName,
    required this.accountNumber,
    required this.balance,
    required this.accountType,
    this.onTap,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(CUSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(CURadius.lg),
          boxShadow: CUElevation.getShadow(CUElevation.medium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              accountName,
              style: CUTypography.titleMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: CUSpacing.xs),
            Text(
              '•••• ${accountNumber.substring(accountNumber.length - 4)}',
              style: CUTypography.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: CUSpacing.lg),
            Text(
              'Available Balance',
              style: CUTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: CUSpacing.xs),
            Text(
              '\$${balance.toStringAsFixed(2)}',
              style: CUTypography.displaySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CU TRANSACTION LIST - FDX-Compliant Transaction Display
// ============================================================================

class CUTransactionList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final Function(Map<String, dynamic>)? onTransactionTap;

  const CUTransactionList({
    Key? key,
    required this.transactions,
    this.onTransactionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return CUTransactionListItem(
          transaction: tx,
          onTap: onTransactionTap != null ? () => onTransactionTap!(tx) : null,
        );
      },
    );
  }
}

class CUTransactionListItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onTap;

  const CUTransactionListItem({
    Key? key,
    required this.transaction,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final amount = (transaction['amount'] ?? 0.0) as num;
    final isPositive = amount < 0; // Plaid: negative = credit
    final merchantName = transaction['merchant_name'] ?? transaction['name'] ?? 'Transaction';
    final date = transaction['date'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: CUSpacing.sm),
        padding: const EdgeInsets.all(CUSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(CURadius.md),
          border: Border.all(color: theme.colorScheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchantName,
                    style: CUTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: CUSpacing.xs),
                  Text(
                    date,
                    style: CUTypography.bodySmall.copyWith(
                      color: theme.colorScheme.neutral,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}\$${amount.abs().toStringAsFixed(2)}',
              style: CUTypography.titleMedium.copyWith(
                color: isPositive ? theme.colorScheme.positive : theme.colorScheme.negative,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CU CONSENT BANNER - Section 1033 Consent UI
// ============================================================================

class CUConsentBanner extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isVisible;

  const CUConsentBanner({
    Key? key,
    required this.title,
    required this.description,
    required this.onAccept,
    required this.onDecline,
    this.isVisible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = CUTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(CUSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(CURadius.md),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CUSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(CURadius.sm),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: CUSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: CUTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CUSpacing.md),
          Text(
            description,
            style: CUTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: CUSpacing.lg),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onDecline,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: CUSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(CURadius.full),
                      border: Border.all(color: theme.colorScheme.border),
                    ),
                    child: Center(
                      child: Text(
                        'Decline',
                        style: CUTypography.labelLarge,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CUSpacing.md),
              Expanded(
                child: GestureDetector(
                  onTap: onAccept,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: CUSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(CURadius.full),
                    ),
                    child: Center(
                      child: Text(
                        'Accept',
                        style: CUTypography.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CU PURPOSE INDICATOR - Purpose Validation Display
// ============================================================================

class CUPurposeIndicator extends StatelessWidget {
  final String purpose;
  final bool isValid;
  final DateTime timestamp;

  const CUPurposeIndicator({
    Key? key,
    required this.purpose,
    required this.isValid,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(CUSpacing.md),
      decoration: BoxDecoration(
        color: isValid
            ? theme.colorScheme.positive.withOpacity(0.1)
            : theme.colorScheme.negative.withOpacity(0.1),
        borderRadius: BorderRadius.circular(CURadius.sm),
        border: Border.all(
          color: isValid ? theme.colorScheme.positive : theme.colorScheme.negative,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isValid ? theme.colorScheme.positive : theme.colorScheme.negative,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: CUSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purpose,
                  style: CUTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Validated: ${_formatTimestamp(timestamp)}',
                  style: CUTypography.bodySmall.copyWith(
                    color: theme.colorScheme.neutral,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// CU DATA ACCESS LOG - Privacy Audit Display
// ============================================================================

class CUDataAccessLog extends StatelessWidget {
  final List<Map<String, dynamic>> accessLogs;

  const CUDataAccessLog({
    Key? key,
    required this.accessLogs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: accessLogs.length,
      itemBuilder: (context, index) {
        final log = accessLogs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: CUSpacing.sm),
          padding: const EdgeInsets.all(CUSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(CURadius.md),
            border: Border.all(color: theme.colorScheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: CUSpacing.xs),
                  Text(
                    log['timestamp'] ?? '',
                    style: CUTypography.bodySmall.copyWith(
                      color: theme.colorScheme.neutral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CUSpacing.xs),
              Text(
                log['accessor'] ?? 'Unknown',
                style: CUTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Purpose: ${log['purpose'] ?? 'Not specified'}',
                style: CUTypography.bodyMedium,
              ),
              Text(
                'Data: ${log['dataType'] ?? 'Unknown'}',
                style: CUTypography.bodySmall.copyWith(
                  color: theme.colorScheme.neutral,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// CU MASKED PII - PII Masking Component
// ============================================================================

class CUMaskedPII extends StatefulWidget {
  final String value;
  final String maskCharacter;
  final int visibleCharacters;
  final bool canUnmask;

  const CUMaskedPII({
    Key? key,
    required this.value,
    this.maskCharacter = '•',
    this.visibleCharacters = 4,
    this.canUnmask = true,
  }) : super(key: key);

  @override
  State<CUMaskedPII> createState() => _CUMaskedPIIState();
}

class _CUMaskedPIIState extends State<CUMaskedPII> {
  bool _isUnmasked = false;

  String get _displayValue {
    if (_isUnmasked) return widget.value;

    if (widget.value.length <= widget.visibleCharacters) {
      return widget.maskCharacter * widget.value.length;
    }

    final masked = widget.maskCharacter * (widget.value.length - widget.visibleCharacters);
    final visible = widget.value.substring(widget.value.length - widget.visibleCharacters);
    return '$masked$visible';
  }

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return GestureDetector(
      onTap: widget.canUnmask ? () => setState(() => _isUnmasked = !_isUnmasked) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _displayValue,
            style: CUTypography.bodyLarge.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
          if (widget.canUnmask) ...[
            const SizedBox(width: CUSpacing.sm),
            Icon(
              _isUnmasked ? Icons.visibility_off : Icons.visibility,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}
