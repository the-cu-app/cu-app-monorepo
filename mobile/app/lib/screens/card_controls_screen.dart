import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import '../services/card_service.dart';
import '../widgets/particle_animation.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class CardControlsScreen extends StatefulWidget {
  final BankCard card;
  final int initialTab;
  
  const CardControlsScreen({
    Key? key,
    required this.card,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<CardControlsScreen> createState() => _CardControlsScreenState();
}

class _CardControlsScreenState extends State<CardControlsScreen> 
    with SingleTickerProviderStateMixin {
  final CardService _cardService = CardService();
  late TabController _tabController;
  late BankCard _card;
  late CardControls _controls;
  late CardLimits _limits;
  bool _hasChanges = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _card = widget.card;
    _controls = _card.controls;
    _limits = _card.limits;
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          if (shouldPop && mounted) {
            Navigator.pop(context, _card);
          }
          return false;
        }
        Navigator.pop(context, _card);
        return false;
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Card Controls'),
          backgroundColor: theme.colorScheme.surface,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'General'),
              Tab(text: 'Limits'),
              Tab(text: 'Security'),
              Tab(text: 'Restrictions'),
            ],
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
          ),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _saveChanges,
                child: const Text('Save'),
              ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralTab(),
            _buildLimitsTab(),
            _buildSecurityTab(),
            _buildRestrictionsTab(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGeneralTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Lock Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _controls.isLocked 
                  ? Colors.orange.withOpacity(0.1) 
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _controls.isLocked ? Colors.orange : Colors.green,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _controls.isLocked ? Icons.lock : Icons.lock_open,
                  color: _controls.isLocked ? Colors.orange : Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _controls.isLocked ? 'Card is Locked' : 'Card is Active',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _controls.isLocked ? Colors.orange : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _controls.isLocked 
                            ? 'All transactions are blocked'
                            : 'Card can be used for transactions',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: !_controls.isLocked,
                  onChanged: (value) {
                    setState(() {
                      _controls = _controls.copyWith(isLocked: !value);
                      _hasChanges = true;
                    });
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Transaction Types',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Transaction controls
          _buildControlTile(
            'Online Transactions',
            'Allow purchases from websites and apps',
            Icons.language,
            _controls.onlineTransactions,
            (value) => setState(() {
              _controls = _controls.copyWith(onlineTransactions: value);
              _hasChanges = true;
            }),
          ),
          _buildControlTile(
            'ATM Withdrawals',
            'Allow cash withdrawals from ATMs',
            Icons.atm,
            _controls.atmWithdrawals,
            (value) => setState(() {
              _controls = _controls.copyWith(atmWithdrawals: value);
              _hasChanges = true;
            }),
          ),
          _buildControlTile(
            'Contactless Payments',
            'Allow tap-to-pay transactions',
            Icons.wifi,
            _controls.contactlessPayments,
            (value) => setState(() {
              _controls = _controls.copyWith(contactlessPayments: value);
              _hasChanges = true;
            }),
          ),
          _buildControlTile(
            'Recurring Payments',
            'Allow subscription and recurring charges',
            Icons.repeat,
            _controls.recurringPayments,
            (value) => setState(() {
              _controls = _controls.copyWith(recurringPayments: value);
              _hasChanges = true;
            }),
          ),
          
          const SizedBox(height: 24),
          
          // Notifications
          Text(
            'Notifications',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildControlTile(
            'Transaction Alerts',
            'Get notified for every transaction',
            Icons.notifications,
            _controls.notificationsEnabled,
            (value) => setState(() {
              _controls = _controls.copyWith(notificationsEnabled: value);
              _hasChanges = true;
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLimitsTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ParticleAnimation(
            particleColor: theme.colorScheme.primary.withOpacity(0.05),
            numberOfParticles: 10,
            speedFactor: 0.2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.primaryContainer.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Spending limits help you stay within budget and add an extra layer of security',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildLimitSlider(
            'Daily Spending Limit',
            _limits.dailySpendLimit,
            0,
            10000,
            (value) => setState(() {
              _limits = _limits.copyWith(dailySpendLimit: value);
              _hasChanges = true;
            }),
          ),
          
          _buildLimitSlider(
            'Daily ATM Limit',
            _limits.dailyATMLimit,
            0,
            2000,
            (value) => setState(() {
              _limits = _limits.copyWith(dailyATMLimit: value);
              _hasChanges = true;
            }),
          ),
          
          _buildLimitSlider(
            'Single Transaction Limit',
            _limits.singleTransactionLimit,
            0,
            5000,
            (value) => setState(() {
              _limits = _limits.copyWith(singleTransactionLimit: value);
              _hasChanges = true;
            }),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Category Limits',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set spending limits for specific categories',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          ...SpendingCategory.all.map((category) {
            final limit = _limits.categoryLimits[category] ?? 0.0;
            return _buildCategoryLimit(category, limit);
          }),
          
          const SizedBox(height: 24),
          
          // Transaction count limit
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Daily Transaction Count'),
            subtitle: Text('Maximum transactions per day: ${_limits.dailyTransactionCount}'),
            trailing: SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _limits.dailyTransactionCount > 1
                        ? () => setState(() {
                              _limits = _limits.copyWith(
                                dailyTransactionCount: _limits.dailyTransactionCount - 1,
                              );
                              _hasChanges = true;
                            })
                        : null,
                  ),
                  Text(
                    '${_limits.dailyTransactionCount}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() {
                      _limits = _limits.copyWith(
                        dailyTransactionCount: _limits.dailyTransactionCount + 1,
                      );
                      _hasChanges = true;
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSecurityTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'International Usage',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildControlTile(
            'International Transactions',
            'Allow usage outside your home country',
            Icons.flight,
            _controls.internationalTransactions,
            (value) => setState(() {
              _controls = _controls.copyWith(internationalTransactions: value);
              _hasChanges = true;
            }),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Allowed Countries',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select countries where this card can be used',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'US', 'CA', 'UK', 'FR', 'DE', 'JP', 'AU'
            ].map((country) {
              final isSelected = _controls.allowedCountries.contains(country);
              return FilterChip(
                label: Text(country),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    final countries = List<String>.from(_controls.allowedCountries);
                    if (selected) {
                      countries.add(country);
                    } else {
                      countries.remove(country);
                    }
                    _controls = _controls.copyWith(allowedCountries: countries);
                    _hasChanges = true;
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Additional Security',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.security,
                color: theme.colorScheme.secondary,
              ),
            ),
            title: const Text('Change PIN'),
            subtitle: const Text('Update your card PIN'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changePin,
          ),
          
          if (_card.isVirtual)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.refresh,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              title: const Text('Regenerate CVV'),
              subtitle: const Text('Get a new security code'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _regenerateCvv,
            ),
        ],
      ),
    );
  }
  
  Widget _buildRestrictionsTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blocked Categories',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prevent transactions in these categories',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Gambling',
              'Adult Content',
              'Cryptocurrency',
              'Gaming',
              'Alcohol',
              'Tobacco',
            ].map((category) {
              final isBlocked = _controls.blockedCategories.contains(category);
              return FilterChip(
                label: Text(category),
                selected: isBlocked,
                selectedColor: Colors.red.withOpacity(0.2),
                onSelected: (selected) {
                  setState(() {
                    final categories = List<String>.from(_controls.blockedCategories);
                    if (selected) {
                      categories.add(category);
                    } else {
                      categories.remove(category);
                    }
                    _controls = _controls.copyWith(blockedCategories: categories);
                    _hasChanges = true;
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Blocked Merchants',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add specific merchants to block',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_controls.blockedMerchants.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.block,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No blocked merchants',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_controls.blockedMerchants.length, (index) {
              final merchant = _controls.blockedMerchants[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(merchant),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      final merchants = List<String>.from(_controls.blockedMerchants);
                      merchants.removeAt(index);
                      _controls = _controls.copyWith(blockedMerchants: merchants);
                      _hasChanges = true;
                    });
                  },
                ),
              );
            }),
          
          const SizedBox(height: 16),
          
          OutlinedButton.icon(
            onPressed: _addBlockedMerchant,
            icon: const Icon(Icons.add),
            label: const Text('Add Blocked Merchant'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value 
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: value 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: _controls.isLocked ? null : onChanged,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLimitSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\$${value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
              thumbColor: theme.colorScheme.primary,
              overlayColor: theme.colorScheme.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max ~/ 100).toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryLimit(String category, double limit) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(category),
      subtitle: limit > 0 
          ? Text('\$${limit.toStringAsFixed(0)} daily limit')
          : Text(
              'No limit set',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
      trailing: OutlinedButton(
        onPressed: () => _setCategoryLimit(category),
        child: Text(limit > 0 ? 'Edit' : 'Set'),
      ),
    );
  }
  
  void _setCategoryLimit(String category) {
    final currentLimit = _limits.categoryLimits[category] ?? 0.0;
    final controller = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '',
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set $category Limit'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Daily limit',
              prefixText: '\$',
              hintText: '0',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final newLimit = double.tryParse(controller.text) ?? 0;
                setState(() {
                  final categoryLimits = Map<String, double>.from(_limits.categoryLimits);
                  if (newLimit > 0) {
                    categoryLimits[category] = newLimit;
                  } else {
                    categoryLimits.remove(category);
                  }
                  _limits = _limits.copyWith(categoryLimits: categoryLimits);
                  _hasChanges = true;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
  
  void _addBlockedMerchant() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Block Merchant'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Merchant name',
              hintText: 'e.g., Store Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final merchant = controller.text.trim();
                if (merchant.isNotEmpty) {
                  setState(() {
                    final merchants = List<String>.from(_controls.blockedMerchants);
                    merchants.add(merchant);
                    _controls = _controls.copyWith(blockedMerchants: merchants);
                    _hasChanges = true;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }
  
  void _changePin() {
    // Show PIN change dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change PIN'),
          content: const Text('You will receive instructions via SMS to change your PIN.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN change instructions sent via SMS'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Send Instructions'),
            ),
          ],
        );
      },
    );
  }
  
  void _regenerateCvv() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Regenerate CVV'),
          content: const Text(
            'This will generate a new security code for your virtual card. The old code will no longer work.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('New CVV generated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Regenerate'),
            ),
          ],
        );
      },
    );
  }
  
  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Do you want to save them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () async {
                await _saveChanges();
                if (mounted) Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  Future<void> _saveChanges() async {
    // Show saving indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Saving changes...'),
            ],
          ),
        );
      },
    );
    
    // Update controls
    if (_controls != _card.controls) {
      await _cardService.updateCardControls(_card.id, _controls);
    }
    
    // Update limits
    if (_limits != _card.limits) {
      await _cardService.updateCardLimits(_card.id, _limits);
    }
    
    // Update card
    setState(() {
      _card = _card.copyWith(
        controls: _controls,
        limits: _limits,
      );
      _hasChanges = false;
    });
    
    // Close saving dialog
    if (mounted) Navigator.pop(context);
    
    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Changes saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}