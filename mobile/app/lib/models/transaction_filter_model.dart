import 'package:flutter/material.dart';

class TransactionFilter {
  final String? searchQuery;
  final DateTimeRange? dateRange;
  final double? minAmount;
  final double? maxAmount;
  final List<String> selectedCategories;
  final List<String> selectedAccounts;
  final List<TransactionType> selectedTypes;
  final List<TransactionStatus> selectedStatuses;
  final TransactionSortOption sortBy;
  final bool sortAscending;

  // Quick filter presets
  final DateRangePreset? datePreset;

  TransactionFilter({
    this.searchQuery,
    this.dateRange,
    this.minAmount,
    this.maxAmount,
    this.selectedCategories = const [],
    this.selectedAccounts = const [],
    this.selectedTypes = const [],
    this.selectedStatuses = const [],
    this.sortBy = TransactionSortOption.date,
    this.sortAscending = false,
    this.datePreset,
  });

  TransactionFilter copyWith({
    String? searchQuery,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    List<String>? selectedCategories,
    List<String>? selectedAccounts,
    List<TransactionType>? selectedTypes,
    List<TransactionStatus>? selectedStatuses,
    TransactionSortOption? sortBy,
    bool? sortAscending,
    DateRangePreset? datePreset,
    bool clearDateRange = false,
    bool clearSearchQuery = false,
    bool clearAmountRange = false,
  }) {
    return TransactionFilter(
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      minAmount: clearAmountRange ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmountRange ? null : (maxAmount ?? this.maxAmount),
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedAccounts: selectedAccounts ?? this.selectedAccounts,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      datePreset: clearDateRange ? null : (datePreset ?? this.datePreset),
    );
  }

  bool get hasActiveFilters {
    return searchQuery != null ||
        dateRange != null ||
        minAmount != null ||
        maxAmount != null ||
        selectedCategories.isNotEmpty ||
        selectedAccounts.isNotEmpty ||
        selectedTypes.isNotEmpty ||
        selectedStatuses.isNotEmpty ||
        datePreset != null;
  }

  int get activeFilterCount {
    int count = 0;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (dateRange != null || datePreset != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (selectedCategories.isNotEmpty) count++;
    if (selectedAccounts.isNotEmpty) count++;
    if (selectedTypes.isNotEmpty) count++;
    if (selectedStatuses.isNotEmpty) count++;
    return count;
  }

  TransactionFilter clearAll() {
    return TransactionFilter(
      sortBy: sortBy,
      sortAscending: sortAscending,
    );
  }

  DateTimeRange? get effectiveDateRange {
    if (dateRange != null) return dateRange;
    if (datePreset == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (datePreset!) {
      case DateRangePreset.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 7)),
          end: today.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
        );
      case DateRangePreset.last30Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 30)),
          end: today.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
        );
      case DateRangePreset.last60Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 60)),
          end: today.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
        );
      case DateRangePreset.last90Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 90)),
          end: today.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
        );
      case DateRangePreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1)),
        );
      case DateRangePreset.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return DateTimeRange(
          start: lastMonth,
          end: DateTime(lastMonth.year, lastMonth.month + 1, 1).subtract(const Duration(microseconds: 1)),
        );
      case DateRangePreset.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year + 1, 1, 1).subtract(const Duration(microseconds: 1)),
        );
    }
  }
}

enum TransactionType {
  all,
  deposit,
  withdrawal,
  transfer,
  payment,
  refund,
  fee,
}

enum TransactionStatus {
  all,
  posted,
  pending,
  declined,
}

enum TransactionSortOption {
  date,
  amount,
  merchant,
  category,
}

enum DateRangePreset {
  last7Days,
  last30Days,
  last60Days,
  last90Days,
  thisMonth,
  lastMonth,
  thisYear,
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.all:
        return 'All Types';
      case TransactionType.deposit:
        return 'Deposits';
      case TransactionType.withdrawal:
        return 'Withdrawals';
      case TransactionType.transfer:
        return 'Transfers';
      case TransactionType.payment:
        return 'Payments';
      case TransactionType.refund:
        return 'Refunds';
      case TransactionType.fee:
        return 'Fees';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.all:
        return Icons.all_inclusive;
      case TransactionType.deposit:
        return Icons.arrow_downward;
      case TransactionType.withdrawal:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      case TransactionType.payment:
        return Icons.payment;
      case TransactionType.refund:
        return Icons.refresh;
      case TransactionType.fee:
        return Icons.attach_money;
    }
  }
}

extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.all:
        return 'All Statuses';
      case TransactionStatus.posted:
        return 'Posted';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.declined:
        return 'Declined';
    }
  }

  Color get color {
    switch (this) {
      case TransactionStatus.all:
        return Colors.grey;
      case TransactionStatus.posted:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.declined:
        return Colors.red;
    }
  }
}

extension TransactionSortOptionExtension on TransactionSortOption {
  String get displayName {
    switch (this) {
      case TransactionSortOption.date:
        return 'Date';
      case TransactionSortOption.amount:
        return 'Amount';
      case TransactionSortOption.merchant:
        return 'Merchant';
      case TransactionSortOption.category:
        return 'Category';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionSortOption.date:
        return Icons.calendar_today;
      case TransactionSortOption.amount:
        return Icons.attach_money;
      case TransactionSortOption.merchant:
        return Icons.store;
      case TransactionSortOption.category:
        return Icons.category;
    }
  }
}

extension DateRangePresetExtension on DateRangePreset {
  String get displayName {
    switch (this) {
      case DateRangePreset.last7Days:
        return 'Last 7 days';
      case DateRangePreset.last30Days:
        return 'Last 30 days';
      case DateRangePreset.last60Days:
        return 'Last 60 days';
      case DateRangePreset.last90Days:
        return 'Last 90 days';
      case DateRangePreset.thisMonth:
        return 'This month';
      case DateRangePreset.lastMonth:
        return 'Last month';
      case DateRangePreset.thisYear:
        return 'This year';
    }
  }
}

class TransactionSearchSuggestion {
  final String text;
  final TransactionSearchSuggestionType type;
  final dynamic data;

  TransactionSearchSuggestion({
    required this.text,
    required this.type,
    this.data,
  });
}

enum TransactionSearchSuggestionType {
  recent,
  merchant,
  category,
  amount,
}