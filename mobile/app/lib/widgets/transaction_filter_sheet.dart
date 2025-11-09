import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_filter_model.dart';

class TransactionFilterSheet extends StatefulWidget {
  final TransactionFilter filter;
  final List<String> categories;
  final List<Map<String, dynamic>> accounts;
  final Function(TransactionFilter) onApply;

  const TransactionFilterSheet({
    super.key,
    required this.filter,
    required this.categories,
    required this.accounts,
    required this.onApply,
  });

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late TransactionFilter _tempFilter;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  DateTimeRange? _customDateRange;
  
  @override
  void initState() {
    super.initState();
    _tempFilter = widget.filter;
    
    // Initialize amount controllers
    if (_tempFilter.minAmount != null) {
      _minAmountController.text = _tempFilter.minAmount!.toStringAsFixed(0);
    }
    if (_tempFilter.maxAmount != null) {
      _maxAmountController.text = _tempFilter.maxAmount!.toStringAsFixed(0);
    }
    
    _customDateRange = _tempFilter.dateRange;
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _tempFilter = _tempFilter.copyWith(
          dateRange: picked,
          datePreset: null,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Transactions',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempFilter = TransactionFilter();
                      _minAmountController.clear();
                      _maxAmountController.clear();
                      _customDateRange = null;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          
          // Filter sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Date Range Section
                _buildSectionHeader('Date Range'),
                Wrap(
                  spacing: 8,
                  children: [
                    ...DateRangePreset.values.map((preset) => 
                      ChoiceChip(
                        label: Text(preset.displayName),
                        selected: _tempFilter.datePreset == preset,
                        onSelected: (selected) {
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(
                              datePreset: selected ? preset : null,
                              clearDateRange: selected,
                            );
                          });
                        },
                      ),
                    ),
                    ActionChip(
                      label: Text(_customDateRange != null 
                          ? '${_formatDate(_customDateRange!.start)} - ${_formatDate(_customDateRange!.end)}'
                          : 'Custom Range'),
                      avatar: const Icon(Icons.calendar_today, size: 18),
                      backgroundColor: _customDateRange != null 
                          ? theme.colorScheme.primaryContainer
                          : null,
                      onPressed: _selectCustomDateRange,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Amount Range Section
                _buildSectionHeader('Amount Range'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAmountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Min Amount',
                          prefixText: '\$',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          final amount = double.tryParse(value);
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(minAmount: amount);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _maxAmountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Max Amount',
                          prefixText: '\$',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          final amount = double.tryParse(value);
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(maxAmount: amount);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Transaction Type Section
                _buildSectionHeader('Transaction Type'),
                Wrap(
                  spacing: 8,
                  children: TransactionType.values.map((type) => 
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(type.icon, size: 16),
                          const SizedBox(width: 4),
                          Text(type.displayName),
                        ],
                      ),
                      selected: type == TransactionType.all 
                          ? _tempFilter.selectedTypes.isEmpty
                          : _tempFilter.selectedTypes.contains(type),
                      onSelected: (selected) {
                        setState(() {
                          if (type == TransactionType.all) {
                            _tempFilter = _tempFilter.copyWith(selectedTypes: []);
                          } else {
                            final types = List<TransactionType>.from(_tempFilter.selectedTypes);
                            if (selected) {
                              types.add(type);
                            } else {
                              types.remove(type);
                            }
                            _tempFilter = _tempFilter.copyWith(selectedTypes: types);
                          }
                        });
                      },
                    ),
                  ).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Status Section
                _buildSectionHeader('Transaction Status'),
                Wrap(
                  spacing: 8,
                  children: TransactionStatus.values.map((status) => 
                    FilterChip(
                      label: Text(status.displayName),
                      selected: status == TransactionStatus.all 
                          ? _tempFilter.selectedStatuses.isEmpty
                          : _tempFilter.selectedStatuses.contains(status),
                      onSelected: (selected) {
                        setState(() {
                          if (status == TransactionStatus.all) {
                            _tempFilter = _tempFilter.copyWith(selectedStatuses: []);
                          } else {
                            final statuses = List<TransactionStatus>.from(_tempFilter.selectedStatuses);
                            if (selected) {
                              statuses.add(status);
                            } else {
                              statuses.remove(status);
                            }
                            _tempFilter = _tempFilter.copyWith(selectedStatuses: statuses);
                          }
                        });
                      },
                    ),
                  ).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Categories Section
                _buildSectionHeader('Categories'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All Categories'),
                      selected: _tempFilter.selectedCategories.isEmpty,
                      onSelected: (selected) {
                        setState(() {
                          _tempFilter = _tempFilter.copyWith(selectedCategories: []);
                        });
                      },
                    ),
                    ...widget.categories.map((category) => 
                      FilterChip(
                        label: Text(category),
                        selected: _tempFilter.selectedCategories.contains(category),
                        onSelected: (selected) {
                          setState(() {
                            final categories = List<String>.from(_tempFilter.selectedCategories);
                            if (selected) {
                              categories.add(category);
                            } else {
                              categories.remove(category);
                            }
                            _tempFilter = _tempFilter.copyWith(selectedCategories: categories);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Accounts Section
                if (widget.accounts.isNotEmpty) ...[
                  _buildSectionHeader('Accounts'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All Accounts'),
                        selected: _tempFilter.selectedAccounts.isEmpty,
                        onSelected: (selected) {
                          setState(() {
                            _tempFilter = _tempFilter.copyWith(selectedAccounts: []);
                          });
                        },
                      ),
                      ...widget.accounts.map((account) => 
                        FilterChip(
                          label: Text(account['name'] ?? 'Account'),
                          selected: _tempFilter.selectedAccounts.contains(account['id']),
                          onSelected: (selected) {
                            setState(() {
                              final accounts = List<String>.from(_tempFilter.selectedAccounts);
                              if (selected) {
                                accounts.add(account['id']);
                              } else {
                                accounts.remove(account['id']);
                              }
                              _tempFilter = _tempFilter.copyWith(selectedAccounts: accounts);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
          
          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(_tempFilter);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply Filters${_tempFilter.activeFilterCount > 0 ? ' (${_tempFilter.activeFilterCount})' : ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontFamily: 'Geist',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}