import 'package:flutter/material.dart';
import '../models/account_type_config.dart';

/// Helper class for standardized account operations and display logic
class AccountHelper {
  /// Get account type configuration from account data
  static AccountTypeConfig getAccountConfig(Map<String, dynamic> account) {
    return AccountTypeRegistry.getConfigFromAccount(account);
  }

  /// Get display balance with proper formatting for account type
  static double getDisplayBalance(Map<String, dynamic> account) {
    final config = getAccountConfig(account);
    final balance = _extractBalance(account);
    
    // Credit accounts show debt as positive amounts
    if (config.category == AccountCategory.credit) {
      return balance.abs();
    }
    
    return balance;
  }

  /// Get available balance (for credit/debit cards with limits)
  static double getAvailableBalance(Map<String, dynamic> account) {
    final config = getAccountConfig(account);
    final available = account['available']?.toDouble() ?? 
                     account['balances']?['available']?.toDouble() ?? 0.0;
    
    if (config.category == AccountCategory.credit) {
      // For credit cards, available = credit limit - current balance
      final limit = account['credit_limit']?.toDouble() ?? 
                   account['balances']?['limit']?.toDouble() ?? 0.0;
      final balance = _extractBalance(account).abs();
      return (limit - balance).clamp(0.0, limit);
    }
    
    return available;
  }

  /// Format balance as string with proper account context
  static String formatBalance(Map<String, dynamic> account, {bool showCurrency = true}) {
    final config = getAccountConfig(account);
    final balance = getDisplayBalance(account);
    final currency = showCurrency ? '\$' : '';
    
    switch (config.category) {
      case AccountCategory.credit:
        if (balance == 0) {
          return '${currency}0.00';
        }
        return '${currency}${balance.toStringAsFixed(2)} owed';
      
      case AccountCategory.loan:
        return '${currency}${balance.toStringAsFixed(2)} remaining';
      
      default:
        return '${currency}${_formatCurrency(balance)}';
    }
  }

  /// Format balance for compact display (with K/M suffixes)
  static String formatBalanceCompact(Map<String, dynamic> account) {
    final balance = getDisplayBalance(account);
    return _formatCurrencyCompact(balance);
  }

  /// Get semantic label for accessibility
  static String getBalanceSemanticLabel(Map<String, dynamic> account) {
    final config = getAccountConfig(account);
    final balance = getDisplayBalance(account);
    
    switch (config.category) {
      case AccountCategory.credit:
        if (balance == 0) {
          return 'Zero balance on ${config.displayName}';
        }
        return '${_formatCurrency(balance)} owed on ${config.displayName}';
      
      case AccountCategory.loan:
        return '${_formatCurrency(balance)} remaining on ${config.displayName}';
      
      default:
        final sign = balance >= 0 ? '' : 'negative ';
        return '${sign}${_formatCurrency(balance.abs())} in ${config.displayName}';
    }
  }

  /// Get account icon with consistent mapping
  static IconData getAccountIcon(Map<String, dynamic> account) {
    final config = getAccountConfig(account);
    return config.icon;
  }

  /// Get account colors for UI display
  static List<Color> getAccountColors(Map<String, dynamic> account) {
    final config = getAccountConfig(account);
    return config.gradientColors;
  }

  /// Get primary color for account
  static Color getAccountPrimaryColor(Map<String, dynamic> account) {
    final config = getAccountConfig(account);
    return config.primaryColor;
  }

  /// Check if account supports negative balances
  static bool supportsNegativeBalance(Map<String, dynamic> account) {
    final config = getAccountConfig(account);
    return config.supportsNegativeBalance;
  }

  /// Get available actions for this account type
  static List<String> getAvailableActions(Map<String, dynamic> account) {
    final config = getAccountConfig(account);
    final status = account['status']?.toString().toLowerCase() ?? 'active';
    
    // If account is not active, only allow viewing
    if (status != 'active') {
      return ['view_details', 'view_transactions'];
    }
    
    return config.availableActions;
  }

  /// Check if account can be used as transfer source
  static bool canTransferFrom(Map<String, dynamic> account) {
    final config = getAccountConfig(account);
    final status = account['status']?.toString().toLowerCase() ?? 'active';
    
    return status == 'active' && config.canTransferFrom;
  }

  /// Check if account can be used as transfer destination
  static bool canTransferTo(Map<String, dynamic> account) {
    final config = getAccountConfig(account);
    final status = account['status']?.toString().toLowerCase() ?? 'active';
    
    return status == 'active' && config.canTransferTo;
  }

  /// Check if transfer is allowed between two accounts
  static bool canTransferBetween(
    Map<String, dynamic> fromAccount,
    Map<String, dynamic> toAccount,
  ) {
    if (!canTransferFrom(fromAccount) || !canTransferTo(toAccount)) {
      return false;
    }
    
    final fromConfig = getAccountConfig(fromAccount);
    final toConfig = getAccountConfig(toAccount);
    
    // Business rule: Investment accounts require settlement period
    if (fromConfig.category == AccountCategory.investment && 
        toConfig.category == AccountCategory.depository) {
      // Check if settlement period has passed (simplified)
      return true; // In real app, check actual settlement rules
    }
    
    return true;
  }

  /// Get account status display info
  static AccountStatusInfo getAccountStatus(Map<String, dynamic> account) {
    final status = account['status']?.toString().toLowerCase() ?? 'active';
    
    switch (status) {
      case 'active':
        return AccountStatusInfo(
          status: 'Active',
          color: Colors.green,
          icon: Icons.check_circle,
          allowTransactions: true,
        );
      case 'pending':
        return AccountStatusInfo(
          status: 'Pending',
          color: Colors.orange,
          icon: Icons.schedule,
          allowTransactions: false,
        );
      case 'suspended':
        return AccountStatusInfo(
          status: 'Suspended',
          color: Colors.red,
          icon: Icons.pause_circle,
          allowTransactions: false,
        );
      case 'closed':
        return AccountStatusInfo(
          status: 'Closed',
          color: Colors.grey,
          icon: Icons.cancel,
          allowTransactions: false,
        );
      default:
        return AccountStatusInfo(
          status: 'Unknown',
          color: Colors.grey,
          icon: Icons.help,
          allowTransactions: false,
        );
    }
  }

  /// Get account nickname or default name
  static String getAccountDisplayName(Map<String, dynamic> account) {
    final nickname = account['nickname']?.toString();
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }
    
    final name = account['name']?.toString() ?? '';
    if (name.isNotEmpty) {
      return name;
    }
    
    final config = getAccountConfig(account);
    return config.displayName;
  }

  /// Get account mask/last four digits
  static String getAccountMask(Map<String, dynamic> account) {
    final mask = account['mask']?.toString() ?? 
                account['lastFour']?.toString() ?? 
                account['account_number']?.toString().replaceAll(RegExp(r'.*(\d{4})'), '**** \$1') ??
                '****';
    
    if (mask.length == 4 && !mask.contains('*')) {
      return '•••• $mask';
    }
    
    return mask;
  }

  /// Check if account should show interest rate
  static bool shouldShowInterestRate(Map<String, dynamic> account) {
    final config = getAccountConfig(account);
    return config.showInterestRate;
  }

  /// Check if account should show rewards points
  static bool shouldShowRewardsPoints(Map<String, dynamic> account) {
    final config = getAccountConfig(account);
    return config.showRewardsPoints;
  }

  /// Get interest rate if available
  static double? getInterestRate(Map<String, dynamic> account) {
    final rate = account['interest_rate']?.toDouble() ?? 
                account['apy']?.toDouble() ?? 
                account['apr']?.toDouble();
    
    return rate;
  }

  /// Get rewards points if available
  static int? getRewardsPoints(Map<String, dynamic> account) {
    final points = account['rewards_points']?.toInt() ?? 
                  account['points']?.toInt();
    
    return points;
  }

  // Private helper methods

  static double _extractBalance(Map<String, dynamic> account) {
    return account['balance']?.toDouble() ?? 
           account['balances']?['current']?.toDouble() ?? 
           0.0;
  }

  static String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }

  static String _formatCurrencyCompact(double amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      if (millions >= 10) {
        return '\$${millions.toStringAsFixed(0)}M';
      } else {
        return '\$${millions.toStringAsFixed(1)}M';
      }
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      if (thousands >= 100) {
        return '\$${thousands.toStringAsFixed(0)}K';
      } else {
        return '\$${thousands.toStringAsFixed(1)}K';
      }
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }
}

/// Account status information for display
class AccountStatusInfo {
  final String status;
  final Color color;
  final IconData icon;
  final bool allowTransactions;

  const AccountStatusInfo({
    required this.status,
    required this.color,
    required this.icon,
    required this.allowTransactions,
  });
}