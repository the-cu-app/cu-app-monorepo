import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import '../services/card_service.dart';
import '../widgets/card_widget.dart';
import 'card_controls_screen.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class CardDetailsScreen extends StatefulWidget {
  final BankCard card;
  
  const CardDetailsScreen({
    Key? key,
    required this.card,
  }) : super(key: key);

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> 
    with SingleTickerProviderStateMixin {
  final CardService _cardService = CardService();
  late AnimationController _lockAnimationController;
  late Animation<double> _lockAnimation;
  late BankCard _currentCard;
  
  @override
  void initState() {
    super.initState();
    _currentCard = widget.card;
    _lockAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _lockAnimation = CurvedAnimation(
      parent: _lockAnimationController,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  void dispose() {
    _lockAnimationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
          ),
          child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.1),
                          theme.colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                  
                  
                  // Card
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                      child: CardWidget(
                        card: _currentCard,
                        showDetails: true,
                        isHero: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (_currentCard.isVirtual)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _deleteVirtualCard,
                  tooltip: 'Delete Virtual Card',
                ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _showMoreOptions,
              ),
            ],
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  _buildQuickActions(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Card Info
                  _buildCardInfo(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Spending Limits
                  _buildSpendingLimits(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Card Controls
                  _buildCardControls(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Transactions (placeholder)
                  _buildRecentTransactions(theme),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionButton(
            icon: _currentCard.controls.isLocked ? Icons.lock_open : Icons.lock,
            label: _currentCard.controls.isLocked ? 'Unlock' : 'Lock',
            color: _currentCard.controls.isLocked ? Colors.green : Colors.orange,
            onTap: _toggleCardLock,
          ),
          if (!_currentCard.isVirtual)
            _buildQuickActionButton(
              icon: Icons.pin,
              label: 'View PIN',
              color: Colors.blue,
              onTap: _viewPin,
            ),
          if (_currentCard.isVirtual)
            _buildQuickActionButton(
              icon: Icons.copy,
              label: 'Copy Details',
              color: Colors.blue,
              onTap: _copyCardDetails,
            ),
          _buildQuickActionButton(
            icon: Icons.settings,
            label: 'Controls',
            color: Colors.purple,
            onTap: _navigateToControls,
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildInfoRow('Card Type', _currentCard.type.name.toUpperCase()),
              const Divider(height: 24),
              _buildInfoRow('Status', _currentCard.status.name.toUpperCase(),
                  valueColor: _getStatusColor(_currentCard.status)),
              const Divider(height: 24),
              _buildInfoRow('Network', _currentCard.network.name.toUpperCase()),
              if (_currentCard.isVirtual) ...[
                const Divider(height: 24),
                _buildInfoRow('Purpose', 
                    _currentCard.metadata?['purpose']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'GENERAL USE'),
              ],
              if (_currentCard.metadata?['rewards_program'] != null) ...[
                const Divider(height: 24),
                _buildInfoRow('Rewards', 
                    _currentCard.metadata!['rewards_program'].toString().toUpperCase()),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSpendingLimits(ThemeData theme) {
    final limits = _currentCard.limits;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spending Limits',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: _editLimits,
              child: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildLimitRow('Daily Spend', limits.dailySpendLimit),
              const SizedBox(height: 16),
              _buildLimitRow('Daily ATM', limits.dailyATMLimit),
              const SizedBox(height: 16),
              _buildLimitRow('Per Transaction', limits.singleTransactionLimit),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildLimitRow(String label, double amount) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCardControls(ThemeData theme) {
    final controls = _currentCard.controls;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Controls',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildControlTile(
                'Online Transactions',
                controls.onlineTransactions,
                Icons.language,
              ),
              _buildControlTile(
                'International Transactions',
                controls.internationalTransactions,
                Icons.flight,
              ),
              _buildControlTile(
                'ATM Withdrawals',
                controls.atmWithdrawals,
                Icons.atm,
              ),
              _buildControlTile(
                'Contactless Payments',
                controls.contactlessPayments,
                Icons.wifi,
              ),
              _buildControlTile(
                'Recurring Payments',
                controls.recurringPayments,
                Icons.repeat,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildControlTile(String title, bool isEnabled, IconData icon) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        color: isEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      trailing: Switch(
        value: isEnabled,
        onChanged: null, // Disabled in details view, edit in controls screen
      ),
    );
  }
  
  Widget _buildRecentTransactions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to transactions with filter for this card
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'No recent transactions',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor(CardStatus status) {
    switch (status) {
      case CardStatus.active:
        return Colors.green;
      case CardStatus.locked:
        return Colors.orange;
      case CardStatus.suspended:
        return Colors.red;
      case CardStatus.expired:
        return Colors.grey;
    }
  }
  
  void _toggleCardLock() async {
    _lockAnimationController.forward(from: 0);
    
    final success = await _cardService.toggleCardLock(_currentCard.id);
    
    if (success && mounted) {
      setState(() {
        _currentCard = _currentCard.copyWith(
          controls: _currentCard.controls.copyWith(
            isLocked: !_currentCard.controls.isLocked,
          ),
        );
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentCard.controls.isLocked
                ? 'Card locked successfully'
                : 'Card unlocked successfully',
          ),
          backgroundColor: _currentCard.controls.isLocked ? Colors.orange : Colors.green,
        ),
      );
    }
  }
  
  void _viewPin() {
    // Show PIN dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Card PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your PIN is:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '1234',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'GeistMono',
                    letterSpacing: 8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Never share your PIN with anyone',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  void _copyCardDetails() {
    if (_currentCard.isVirtual) {
      // For demo, we'll just show a message
      final details = '''
Card Number: ${_currentCard.displayCardNumber}
Expiry: ${_currentCard.expirationDate}
CVV: ${_currentCard.cvv}
''';
      
      Clipboard.setData(ClipboardData(text: details));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card details copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  void _navigateToControls() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardControlsScreen(card: _currentCard),
      ),
    ).then((updatedCard) {
      if (updatedCard != null && mounted) {
        setState(() {
          _currentCard = updatedCard;
        });
      }
    });
  }
  
  void _editLimits() {
    // Navigate to controls screen with limits tab selected
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardControlsScreen(
          card: _currentCard,
          initialTab: 1, // Limits tab
        ),
      ),
    ).then((updatedCard) {
      if (updatedCard != null && mounted) {
        setState(() {
          _currentCard = updatedCard;
        });
      }
    });
  }
  
  void _deleteVirtualCard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Virtual Card'),
          content: const Text(
            'Are you sure you want to delete this virtual card? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    
    if (confirm == true) {
      final success = await _cardService.deleteVirtualCard(_currentCard.id);
      
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Virtual card deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_currentCard.isVirtual)
                ListTile(
                  leading: const Icon(Icons.autorenew),
                  title: const Text('Replace Card'),
                  onTap: () {
                    Navigator.pop(context);
                    _requestReplacement();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.report_problem),
                title: const Text('Report Lost/Stolen'),
                onTap: () {
                  Navigator.pop(context);
                  _reportLostStolen();
                },
              ),
              if (!_currentCard.isPrimary)
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Set as Primary'),
                  onTap: () {
                    Navigator.pop(context);
                    _setAsPrimary();
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _requestReplacement() {
    // Show replacement reason dialog
    showDialog(
      context: context,
      builder: (context) {
        String reason = 'damaged';
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Request Card Replacement'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Why do you need a replacement?'),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: const Text('Card Damaged'),
                    value: 'damaged',
                    groupValue: reason,
                    onChanged: (value) => setState(() => reason = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Card Not Working'),
                    value: 'not_working',
                    groupValue: reason,
                    onChanged: (value) => setState(() => reason = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Other'),
                    value: 'other',
                    groupValue: reason,
                    onChanged: (value) => setState(() => reason = value!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    
                    final success = await _cardService.requestCardReplacement(
                      _currentCard.id,
                      reason,
                    );
                    
                    if (success && mounted) {
                      setState(() {
                        _currentCard = _currentCard.copyWith(
                          status: CardStatus.suspended,
                        );
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Replacement request submitted'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Request Replacement'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _reportLostStolen() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Card Lost/Stolen'),
          content: const Text(
            'This will immediately lock your card and prevent any unauthorized use. A replacement card will be sent to your registered address.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Lock the card
                await _cardService.toggleCardLock(_currentCard.id);
                
                // Request replacement
                await _cardService.requestCardReplacement(
                  _currentCard.id,
                  'lost_stolen',
                );
                
                if (mounted) {
                  setState(() {
                    _currentCard = _currentCard.copyWith(
                      status: CardStatus.suspended,
                      controls: _currentCard.controls.copyWith(isLocked: true),
                    );
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Card reported and locked. Replacement on the way.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Report & Lock Card'),
            ),
          ],
        );
      },
    );
  }
  
  void _setAsPrimary() {
    // In a real app, this would update the primary card status
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card set as primary'),
        backgroundColor: Colors.green,
      ),
    );
  }
}