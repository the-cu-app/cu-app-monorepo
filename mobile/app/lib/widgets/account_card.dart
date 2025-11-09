import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccountCard extends StatefulWidget {
  final Map<String, dynamic> account;
  final VoidCallback? onTap;
  final bool showActions;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.showActions = true,
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.account['balances']?['current'] ?? 0.0;
    final isNegative = balance < 0;
    final accountType = widget.account['type'] ?? 'unknown';
    final accountSubtype = widget.account['subtype'] ?? 'unknown';
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _animationController.forward();
              SystemChannels.platform.invokeMethod('HapticFeedback.lightImpact');
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _animationController.reverse();
              widget.onTap?.call();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _animationController.reverse();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: _getAccountGradient(accountType, isNegative),
                boxShadow: [
                  BoxShadow(
                    color: _getAccountColor(accountType).withOpacity(0.3),
                    blurRadius: _isPressed ? 8 : 12,
                    offset: Offset(0, _isPressed ? 2 : 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with icon and account info
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getAccountIcon(accountType),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.account['name'] ?? 'Unknown Account',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatAccountType(accountType)} • ${_formatAccountSubtype(accountSubtype)}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.account['mask'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '•••• ${widget.account['mask']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Balance section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Balance',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${balance.abs().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.account['balances']?['available'] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Available',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${widget.account['balances']['available'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        
                        // Account actions (if enabled)
                        if (widget.showActions) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildActionButton(
                                icon: Icons.swap_horiz,
                                label: 'Transfer',
                                onTap: () => _handleTransfer(),
                              ),
                              const SizedBox(width: 12),
                              _buildActionButton(
                                icon: Icons.analytics,
                                label: 'Insights',
                                onTap: () => _handleInsights(),
                              ),
                              const SizedBox(width: 12),
                              _buildActionButton(
                                icon: Icons.notifications,
                                label: 'Alerts',
                                onTap: () => _handleAlerts(),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          SystemChannels.platform.invokeMethod('HapticFeedback.selectionChanged');
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getAccountGradient(String accountType, bool isNegative) {
    if (isNegative) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.red.shade600,
          Colors.red.shade800,
        ],
      );
    }
    
    // Get gradient colors based on account type
    List<Color> gradientColors;
    switch (accountType) {
      case 'depository':
        gradientColors = [Colors.blue.shade600, Colors.blue.shade800];
        break;
      case 'credit':
        gradientColors = [Colors.purple.shade600, Colors.purple.shade800];
        break;
      case 'loan':
        gradientColors = [Colors.orange.shade600, Colors.orange.shade800];
        break;
      case 'investment':
        gradientColors = [Colors.green.shade600, Colors.green.shade800];
        break;
      default:
        gradientColors = [Colors.grey.shade600, Colors.grey.shade800];
    }
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
    );
  }

  Color _getAccountColor(String accountType) {
    switch (accountType) {
      case 'depository':
        return Colors.blue;
      case 'credit':
        return Colors.purple;
      case 'loan':
        return Colors.orange;
      case 'investment':
        return Colors.green;
      case 'brokerage':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getAccountIcon(String accountType) {
    switch (accountType) {
      case 'depository':
        return Icons.account_balance;
      case 'credit':
        return Icons.credit_card;
      case 'loan':
        return Icons.home;
      case 'investment':
        return Icons.trending_up;
      case 'brokerage':
        return Icons.show_chart;
      default:
        return Icons.account_balance_wallet;
    }
  }

  String _formatAccountType(String type) {
    switch (type) {
      case 'depository':
        return 'Deposit Account';
      case 'credit':
        return 'Credit Account';
      case 'loan':
        return 'Loan Account';
      case 'investment':
        return 'Investment';
      case 'brokerage':
        return 'Brokerage';
      default:
        return type.toUpperCase();
    }
  }

  String _formatAccountSubtype(String subtype) {
    switch (subtype) {
      case 'checking':
        return 'Checking';
      case 'savings':
        return 'Savings';
      case 'credit card':
        return 'Credit Card';
      case 'mortgage':
        return 'Mortgage';
      case 'hsa':
        return 'HSA';
      case 'cash management':
        return 'Cash Management';
      case 'brokerage':
        return 'Brokerage';
      default:
        return subtype.replaceAll('_', ' ').toUpperCase();
    }
  }

  void _handleTransfer() {
    // TODO: Implement transfer functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transfer from ${widget.account['name']}'),
        backgroundColor: _getAccountColor(widget.account['type'] ?? 'unknown'),
      ),
    );
  }

  void _handleInsights() {
    // TODO: Implement insights functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Insights for ${widget.account['name']}'),
        backgroundColor: _getAccountColor(widget.account['type'] ?? 'unknown'),
      ),
    );
  }

  void _handleAlerts() {
    // TODO: Implement alerts functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alerts for ${widget.account['name']}'),
        backgroundColor: _getAccountColor(widget.account['type'] ?? 'unknown'),
      ),
    );
  }
}
