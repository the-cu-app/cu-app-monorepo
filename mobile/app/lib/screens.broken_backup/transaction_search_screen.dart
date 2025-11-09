import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter/services.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../models/transaction_filter_model.dart';
import '../services/banking_service.dart';
import '../services/plaid_service.dart';
import '../widgets/transaction_filter_sheet.dart';
import 'dart:async';

class TransactionSearchScreen extends StatefulWidget {
  const TransactionSearchScreen({super.key});

  @override
  State<TransactionSearchScreen> createState() => _TransactionSearchScreenState();
}

class _TransactionSearchScreenState extends State<TransactionSearchScreen> {
  final BankingService _bankingService = BankingService();
  final PlaidService _plaidService = PlaidService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebouncer;
  
  // State variables
  TransactionFilter _filter = TransactionFilter();
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  List<Map<String, dynamic>> _accounts = [];
  List<String> _categories = [];
  List<TransactionSearchSuggestion> _searchSuggestions = [];
  List<String> _searchHistory = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchFocusNode.addListener(() {
      setState(() {
        _showSuggestions = _searchFocusNode.hasFocus && 
            (_searchController.text.isEmpty || _searchSuggestions.isNotEmpty);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load accounts
      final accounts = await _bankingService.getUserAccounts();
      
      // Load transactions
      List<Map<String, dynamic>> transactions = [];
      if (_plaidService.hasLinkedAccounts) {
        transactions = await _plaidService.getTransactions(
          startDate: DateTime.now().subtract(const Duration(days: 90)).toIso8601String().split('T')[0],
          endDate: DateTime.now().toIso8601String().split('T')[0],
        );
      } else {
        transactions = await _bankingService.searchTransactions();
      }

      // Extract categories
      final categoriesSet = <String>{};
      for (final transaction in transactions) {
        if (transaction['category'] != null) {
          if (transaction['category'] is List) {
            categoriesSet.addAll((transaction['category'] as List).cast<String>());
          } else if (transaction['category'] is String) {
            categoriesSet.add(transaction['category']);
          }
        }
        if (transaction['primary_category'] != null) {
          categoriesSet.add(transaction['primary_category']);
        }
      }

      setState(() {
        _accounts = accounts;
        _categories = categoriesSet.toList()..sort();
        _allTransactions = transactions;
        _filteredTransactions = transactions;
        _isLoading = false;
      });
      
      // Load search history (would be from local storage in real app)
      _loadSearchHistory();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading data: $e');
    }
  }

  void _loadSearchHistory() {
    // In a real app, load from SharedPreferences
    _searchHistory = [
      'Starbucks',
      'Amazon',
      'Groceries',
      'Gas',
    ];
  }

  void _onSearchChanged(String query) {
    _searchDebouncer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _filter = _filter.copyWith(clearSearchQuery: true);
        _showSuggestions = true;
        _generateSearchSuggestions('');
      });
      _applyFilters();
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _filter = _filter.copyWith(searchQuery: query);
        _generateSearchSuggestions(query);
      });
      _applyFilters();
    });
  }

  void _generateSearchSuggestions(String query) {
    final suggestions = <TransactionSearchSuggestion>[];
    
    if (query.isEmpty) {
      // Show search history
      for (final historyItem in _searchHistory.take(5)) {
        suggestions.add(TransactionSearchSuggestion(
          text: historyItem,
          type: TransactionSearchSuggestionType.recent,
        ));
      }
    } else {
      // Generate suggestions based on query
      final lowerQuery = query.toLowerCase();
      
      // Merchant suggestions
      final merchants = <String>{};
      for (final transaction in _allTransactions) {
        final merchantName = (transaction['merchant_name'] ?? 
                           transaction['clean_name'] ?? 
                           transaction['name'] ?? '').toString().toLowerCase();
        if (merchantName.contains(lowerQuery)) {
          merchants.add(transaction['merchant_name'] ?? transaction['name']);
        }
      }
      
      for (final merchant in merchants.take(3)) {
        suggestions.add(TransactionSearchSuggestion(
          text: merchant,
          type: TransactionSearchSuggestionType.merchant,
        ));
      }
      
      // Category suggestions
      for (final category in _categories) {
        if (category.toLowerCase().contains(lowerQuery)) {
          suggestions.add(TransactionSearchSuggestion(
            text: category,
            type: TransactionSearchSuggestionType.category,
            data: category,
          ));
        }
      }
      
      // Amount suggestions
      if (RegExp(r'^\d+\.?\d*$').hasMatch(query)) {
        final amount = double.tryParse(query);
        if (amount != null) {
          suggestions.add(TransactionSearchSuggestion(
            text: 'Amount: \$$query',
            type: TransactionSearchSuggestionType.amount,
            data: amount,
          ));
          suggestions.add(TransactionSearchSuggestion(
            text: 'Amount greater than \$$query',
            type: TransactionSearchSuggestionType.amount,
            data: {'min': amount},
          ));
          suggestions.add(TransactionSearchSuggestion(
            text: 'Amount less than \$$query',
            type: TransactionSearchSuggestionType.amount,
            data: {'max': amount},
          ));
        }
      }
    }
    
    setState(() {
      _searchSuggestions = suggestions.take(8).toList();
    });
  }

  void _selectSuggestion(TransactionSearchSuggestion suggestion) {
    switch (suggestion.type) {
      case TransactionSearchSuggestionType.recent:
      case TransactionSearchSuggestionType.merchant:
        _searchController.text = suggestion.text;
        _filter = _filter.copyWith(searchQuery: suggestion.text);
        break;
      case TransactionSearchSuggestionType.category:
        _filter = _filter.copyWith(
          selectedCategories: [..._filter.selectedCategories, suggestion.data],
        );
        _searchController.clear();
        break;
      case TransactionSearchSuggestionType.amount:
        if (suggestion.data is Map) {
          final data = suggestion.data as Map;
          _filter = _filter.copyWith(
            minAmount: data['min'],
            maxAmount: data['max'],
          );
        }
        _searchController.clear();
        break;
    }
    
    setState(() {
      _showSuggestions = false;
    });
    _searchFocusNode.unfocus();
    _applyFilters();
    
    // Add to search history
    if (!_searchHistory.contains(suggestion.text)) {
      _searchHistory.insert(0, suggestion.text);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _isSearching = true;
    });

    // Apply all filters
    List<Map<String, dynamic>> filtered = List.from(_allTransactions);
    
    // Search query filter
    if (_filter.searchQuery != null && _filter.searchQuery!.isNotEmpty) {
      final query = _filter.searchQuery!.toLowerCase();
      filtered = filtered.where((transaction) {
        final merchantName = (transaction['merchant_name'] ?? 
                            transaction['clean_name'] ?? 
                            transaction['name'] ?? '').toString().toLowerCase();
        final category = (transaction['category'] ?? '').toString().toLowerCase();
        final amount = transaction['amount']?.toString() ?? '';
        
        return merchantName.contains(query) ||
               category.contains(query) ||
               amount.contains(query);
      }).toList();
    }
    
    // Date range filter
    if (_filter.effectiveDateRange != null) {
      filtered = filtered.where((transaction) {
        final dateStr = transaction['date'] ?? transaction['created_at'];
        if (dateStr == null) return false;
        
        final date = DateTime.parse(dateStr);
        return date.isAfter(_filter.effectiveDateRange!.start) &&
               date.isBefore(_filter.effectiveDateRange!.end);
      }).toList();
    }
    
    // Amount range filter
    if (_filter.minAmount != null || _filter.maxAmount != null) {
      filtered = filtered.where((transaction) {
        final amount = (transaction['amount'] ?? 0).abs().toDouble();
        if (_filter.minAmount != null && amount < _filter.minAmount!) return false;
        if (_filter.maxAmount != null && amount > _filter.maxAmount!) return false;
        return true;
      }).toList();
    }
    
    // Category filter
    if (_filter.selectedCategories.isNotEmpty) {
      filtered = filtered.where((transaction) {
        final category = transaction['primary_category'] ?? 
                        transaction['category'] ?? 
                        'Other';
        return _filter.selectedCategories.contains(category);
      }).toList();
    }
    
    // Account filter
    if (_filter.selectedAccounts.isNotEmpty) {
      filtered = filtered.where((transaction) {
        final accountId = transaction['account_id'];
        return _filter.selectedAccounts.contains(accountId);
      }).toList();
    }
    
    // Type filter
    if (_filter.selectedTypes.isNotEmpty && 
        !_filter.selectedTypes.contains(TransactionType.all)) {
      filtered = filtered.where((transaction) {
        final amount = (transaction['amount'] ?? 0).toDouble();
        final type = _getTransactionType(transaction, amount);
        return _filter.selectedTypes.contains(type);
      }).toList();
    }
    
    // Status filter
    if (_filter.selectedStatuses.isNotEmpty && 
        !_filter.selectedStatuses.contains(TransactionStatus.all)) {
      filtered = filtered.where((transaction) {
        final isPending = transaction['pending'] ?? false;
        final status = isPending ? TransactionStatus.pending : TransactionStatus.posted;
        return _filter.selectedStatuses.contains(status);
      }).toList();
    }
    
    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      
      switch (_filter.sortBy) {
        case TransactionSortOption.date:
          final dateA = DateTime.parse(a['date'] ?? a['created_at'] ?? '');
          final dateB = DateTime.parse(b['date'] ?? b['created_at'] ?? '');
          comparison = dateB.compareTo(dateA);
          break;
        case TransactionSortOption.amount:
          final amountA = (a['amount'] ?? 0).abs().toDouble();
          final amountB = (b['amount'] ?? 0).abs().toDouble();
          comparison = amountB.compareTo(amountA);
          break;
        case TransactionSortOption.merchant:
          final merchantA = (a['merchant_name'] ?? a['name'] ?? '').toString();
          final merchantB = (b['merchant_name'] ?? b['name'] ?? '').toString();
          comparison = merchantA.compareTo(merchantB);
          break;
        case TransactionSortOption.category:
          final categoryA = (a['category'] ?? 'Other').toString();
          final categoryB = (b['category'] ?? 'Other').toString();
          comparison = categoryA.compareTo(categoryB);
          break;
      }
      
      return _filter.sortAscending ? -comparison : comparison;
    });
    
    setState(() {
      _filteredTransactions = filtered;
      _isSearching = false;
    });
  }

  TransactionType _getTransactionType(Map<String, dynamic> transaction, double amount) {
    final category = (transaction['category'] ?? '').toString().toLowerCase();
    final description = (transaction['description'] ?? transaction['name'] ?? '').toString().toLowerCase();
    
    if (category.contains('transfer') || description.contains('transfer')) {
      return TransactionType.transfer;
    } else if (category.contains('deposit') || amount < 0) {
      return TransactionType.deposit;
    } else if (category.contains('payment') || description.contains('payment')) {
      return TransactionType.payment;
    } else if (category.contains('refund') || description.contains('refund')) {
      return TransactionType.refund;
    } else if (category.contains('fee') || description.contains('fee')) {
      return TransactionType.fee;
    } else {
      return TransactionType.withdrawal;
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFilterSheet(
        filter: _filter,
        categories: _categories,
        accounts: _accounts,
        onApply: (newFilter) {
          setState(() {
            _filter = newFilter;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filter = _filter.copyWith(clearSearchQuery: true);
      _showSuggestions = false;
    });
    _searchFocusNode.unfocus();
    _applyFilters();
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _filter = _filter.clearAll();
      _showSuggestions = false;
    });
    _searchFocusNode.unfocus();
    _applyFilters();
  }

  void _exportTransactions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              subtitle: const Text('Download transactions as PDF report'),
              onTap: () {
                Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(PDF export coming soon!')),

          );
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              subtitle: const Text('Download transactions as spreadsheet'),
              onTap: () {
                Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(CSV export coming soon!')),

          );
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              subtitle: const Text('Share transaction summary'),
              onTap: () {
                Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Share feature coming soon!')),

          );
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with search bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Back button and title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Search Transactions',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                      if (_filter.hasActiveFilters)
                        TextButton(
                          onPressed: _clearAllFilters,
                          child: const Text('Clear All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Search bar
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search merchants, amounts, categories...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : IconButton(
                              icon: Badge(
                                label: Text(_filter.activeFilterCount.toString()),
                                isLabelVisible: _filter.activeFilterCount > 0,
                                child: const Icon(Icons.filter_list),
                              ),
                              onPressed: _showFilterSheet,
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    ),
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                  ),
                  
                  // Filter chips
                  if (_filter.hasActiveFilters) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (_filter.datePreset != null || _filter.dateRange != null)
                            _buildFilterChip(
                              label: _filter.datePreset?.displayName ?? 'Custom Date',
                              onDelete: () {
                                setState(() {
                                  _filter = _filter.copyWith(clearDateRange: true);
                                });
                                _applyFilters();
                              },
                            ),
                          if (_filter.minAmount != null || _filter.maxAmount != null)
                            _buildFilterChip(
                              label: _getAmountRangeLabel(),
                              onDelete: () {
                                setState(() {
                                  _filter = _filter.copyWith(clearAmountRange: true);
                                });
                                _applyFilters();
                              },
                            ),
                          ..._filter.selectedCategories.map((category) =>
                            _buildFilterChip(
                              label: category,
                              onDelete: () {
                                setState(() {
                                  _filter = _filter.copyWith(
                                    selectedCategories: _filter.selectedCategories
                                        .where((c) => c != category)
                                        .toList(),
                                  );
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                          ..._filter.selectedAccounts.map((accountId) {
                            final account = _accounts.firstWhere(
                              (a) => a['id'] == accountId,
                              orElse: () => {'name': 'Account'},
                            );
                            return _buildFilterChip(
                              label: account['name'],
                              onDelete: () {
                                setState(() {
                                  _filter = _filter.copyWith(
                                    selectedAccounts: _filter.selectedAccounts
                                        .where((a) => a != accountId)
                                        .toList(),
                                  );
                                });
                                _applyFilters();
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Search suggestions
            if (_showSuggestions && _searchSuggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _searchSuggestions[index];
                    return ListTile(
                      leading: Icon(
                        _getSuggestionIcon(suggestion.type),
                        size: 20,
                      ),
                      title: Text(suggestion.text),
                      onTap: () => _selectSuggestion(suggestion),
                    );
                  },
                ),
              ),
            
            // Results header
            if (!_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredTransactions.length} transactions found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      children: [
                        // Sort button
                        TextButton.icon(
                          onPressed: () => _showSortMenu(),
                          icon: Icon(_filter.sortBy.icon, size: 16),
                          label: Text(_filter.sortBy.displayName),
                        ),
                        // Export button
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: _filteredTransactions.isNotEmpty ? _exportTransactions : null,
                          tooltip: 'Export',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            // Results list
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onDelete}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onDelete,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  String _getAmountRangeLabel() {
    if (_filter.minAmount != null && _filter.maxAmount != null) {
      return '\$${_filter.minAmount!.toStringAsFixed(0)} - \$${_filter.maxAmount!.toStringAsFixed(0)}';
    } else if (_filter.minAmount != null) {
      return '> \$${_filter.minAmount!.toStringAsFixed(0)}';
    } else {
      return '< \$${_filter.maxAmount!.toStringAsFixed(0)}';
    }
  }

  IconData _getSuggestionIcon(TransactionSearchSuggestionType type) {
    switch (type) {
      case TransactionSearchSuggestionType.recent:
        return Icons.history;
      case TransactionSearchSuggestionType.merchant:
        return Icons.store;
      case TransactionSearchSuggestionType.category:
        return Icons.category;
      case TransactionSearchSuggestionType.amount:
        return Icons.attach_money;
    }
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort By',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Switch(
                    value: _filter.sortAscending,
                    onChanged: (value) {
                      setState(() {
                        _filter = _filter.copyWith(sortAscending: value);
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            ...TransactionSortOption.values.map((option) => ListTile(
              leading: Icon(option.icon),
              title: Text(option.displayName),
              trailing: _filter.sortBy == option 
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() {
                  _filter = _filter.copyWith(sortBy: option);
                });
                _applyFilters();
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Searching transactions...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search terms',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Filters'),
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    final groupedTransactions = <String, List<Map<String, dynamic>>>{};
    for (final transaction in _filteredTransactions) {
      final dateStr = transaction['date'] ?? transaction['created_at'];
      final date = DateTime.parse(dateStr);
      final key = _getDateGroupKey(date);
      
      if (!groupedTransactions.containsKey(key)) {
        groupedTransactions[key] = [];
      }
      groupedTransactions[key]!.add(transaction);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final dateGroup = groupedTransactions.keys.elementAt(index);
        final transactions = groupedTransactions[dateGroup]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                dateGroup,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Transactions for this date
            ...transactions.map((transaction) => 
              _buildTransactionTile(transaction)
            ),
          ],
        );
      },
    );
  }

  String _getDateGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else if (transactionDate.isAfter(today.subtract(const Duration(days: 7)))) {
      // This week
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[transactionDate.weekday - 1];
    } else {
      // Older
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}${date.year != now.year ? ', ${date.year}' : ''}';
    }
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final amount = (transaction['amount'] ?? 0).toDouble();
    final isDebit = amount > 0; // In Plaid, positive amounts are debits
    final displayAmount = amount.abs();
    
    // Get transaction details
    final merchantName = transaction['clean_name'] ?? 
                        transaction['merchant_name'] ?? 
                        transaction['name'] ?? 
                        'Unknown';
    final category = transaction['primary_category'] ?? 
                    transaction['category'] ?? 
                    'Other';
    final isPending = transaction['pending'] ?? false;
    final isRecurring = transaction['is_recurring'] ?? false;
    
    // Highlight search term
    String displayName = merchantName;
    if (_filter.searchQuery != null && _filter.searchQuery!.isNotEmpty) {
      final query = _filter.searchQuery!.toLowerCase();
      final lowerName = merchantName.toLowerCase();
      if (lowerName.contains(query)) {
        // Would implement actual text highlighting here
        displayName = merchantName;
      }
    }
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getCategoryColor(category).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _getCategoryIcon(category),
          color: _getCategoryColor(category),
          size: 24,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: 'Geist',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isPending)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PENDING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          if (isRecurring)
            Container(
              margin: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.repeat,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
      subtitle: Text(
        category,
        style: TextStyle(
          fontSize: 14,
          color: theme.colorScheme.onSurfaceVariant,
          fontFamily: 'Geist',
        ),
      ),
      trailing: Text(
        '${isDebit ? '-' : '+'}\$${displayAmount.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDebit 
              ? (isDark ? Colors.white : Colors.black)
              : Colors.green.shade600,
          fontFamily: 'GeistMono',
        ),
      ),
      onTap: () {
        // Navigate to transaction details
        // TODO: Implement transaction details screen
      },
    );
  }

  Color _getCategoryColor(String category) {
    final categoryLower = category.toLowerCase();
    
    if (categoryLower.contains('food') || categoryLower.contains('restaurant')) {
      return Colors.orange.shade600;
    } else if (categoryLower.contains('transport')) {
      return Colors.blue.shade600;
    } else if (categoryLower.contains('shop')) {
      return Colors.purple.shade600;
    } else if (categoryLower.contains('entertainment')) {
      return Colors.pink.shade600;
    } else if (categoryLower.contains('health')) {
      return Colors.red.shade600;
    } else if (categoryLower.contains('transfer')) {
      return Colors.green.shade600;
    } else {
      return Colors.grey.shade600;
    }
  }

  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    
    if (categoryLower.contains('food') || categoryLower.contains('restaurant')) {
      return Icons.restaurant;
    } else if (categoryLower.contains('transport')) {
      return Icons.directions_car;
    } else if (categoryLower.contains('shop')) {
      return Icons.shopping_bag;
    } else if (categoryLower.contains('entertainment')) {
      return Icons.movie;
    } else if (categoryLower.contains('health')) {
      return Icons.local_hospital;
    } else if (categoryLower.contains('transfer')) {
      return Icons.swap_horiz;
    } else {
      return Icons.receipt;
    }
  }
}