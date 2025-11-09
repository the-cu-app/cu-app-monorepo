import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter/services.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:provider/provider.dart';
import '../services/banking_service.dart';
import '../services/profile_service.dart';
import '../services/security_service.dart';
import '../widgets/services_scroll.dart';
import '../widgets/security_score_widget.dart';
import '../models/profile_model.dart';
import '../models/security_model.dart';
import '../services/accessibility_service.dart';
import 'account_detail_screen.dart';
import 'security_settings_screen.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class EnhancedDashboardScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final Function(Map<String, dynamic>)? onAccountSelected;

  const EnhancedDashboardScreen({
    super.key,
    this.scrollController,
    this.onAccountSelected,
  });

  @override
  State<EnhancedDashboardScreen> createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen> {
  final BankingService _bankingService = BankingService();
  final SecurityService _securityService = SecurityService();
  double _totalBalance = 0.0;
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;
  SecuritySettings _securitySettings = SecuritySettings.empty();

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSecuritySettings();
  }

  Future<void> _loadData() async {
    try {
      final accounts = await _bankingService.getUserAccounts();
      final balance = accounts.fold<double>(
        0.0,
        (sum, account) => sum + (account['balance'] ?? 0.0),
      );

      setState(() {
        _accounts = accounts;
        _totalBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to demo data if API fails
      final demoAccounts = [
        {
          'name': 'Personal Checking',
          'type': 'checking',
          'balance': 145234.67,
          'lastFour': '4829',
        },
        {
          'name': 'Business Premier',
          'type': 'checking',
          'balance': 892451.23,
          'lastFour': '7156',
        },
        {
          'name': 'Personal Savings',
          'type': 'savings',
          'balance': 68301.13,
          'lastFour': '9234',
        },
        {
          'name': 'Business Reserve',
          'type': 'savings',
          'balance': 250000.00,
          'lastFour': '3892',
        },
      ];

      setState(() {
        _accounts = demoAccounts;
        _totalBalance = demoAccounts.fold<double>(
          0.0,
          (sum, account) => sum + ((account['balance'] ?? 0.0) as double),
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSecuritySettings() async {
    final settings = await _securityService.getSecuritySettings();
    if (mounted) {
      setState(() {
        _securitySettings = settings;
      });
    }
  }

  // Filter accounts based on current profile
  List<Map<String, dynamic>> _getFilteredAccounts() {
    final profileService = context.watch<ProfileService>();
    final currentProfile = profileService.currentProfile;
    
    if (currentProfile == null) return _accounts;
    
    switch (currentProfile.type) {
      case ProfileType.business:
        return _accounts.where((account) => 
          account['name'].toString().toLowerCase().contains('business')
        ).toList();
      case ProfileType.youth:
        return _accounts.where((account) => 
          account['type'] == 'savings' && 
          !account['name'].toString().toLowerCase().contains('business')
        ).toList();
      case ProfileType.fiduciary:
        return _accounts.where((account) => 
          account['name'].toString().toLowerCase().contains('trust') ||
          account['name'].toString().toLowerCase().contains('estate')
        ).toList();
      default:
        return _accounts.where((account) => 
          !account['name'].toString().toLowerCase().contains('business')
        ).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileService = context.watch<ProfileService>();
    final currentProfile = profileService.currentProfile;
    final filteredAccounts = _getFilteredAccounts();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1200 : double.infinity,
          ),
          child: CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black,
                          Colors.grey.shade900,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (currentProfile != null) ...[
                            Text(
                              currentProfile.displayName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            'Total Balance',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${_formatAmount(_totalBalance)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          
              // Profile-specific alerts
              if (currentProfile != null && currentProfile.type == ProfileType.youth)
                SliverToBoxAdapter(
                  child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Youth account: Parental approval required for transfers',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
              
              // Security Score Card (temporarily removed for debugging)
              /* SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isDesktop ? 16 : 8,
                ),
                sliver: SliverToBoxAdapter(
                  child: SecurityScoreMiniWidget(
                    score: _securitySettings.securityScore,
                    level: _securitySettings.securityLevel,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SecuritySettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ), */
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Text(
                    'Accounts',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ),
              ),
              
              _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final account = filteredAccounts[index];
                        return _buildAccountCard(account);
                      },
                      childCount: filteredAccounts.length,
                    ),
                  ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Text(
                    'Quick Services',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: ServicesScroll(),
                ),
              ),
          
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final balance = account['balance'] ?? 0.0;
    final name = account['name'] ?? 'Account';
    final type = account['type'] ?? 'checking';
    final lastFour = account['lastFour'] ?? '****';
    final accountId = '${name}_$lastFour'; // Unique ID for Hero animation
    
    final accessibilityService = context.watch<AccessibilityService>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balanceColor = accessibilityService.getBalanceColor(balance, isDarkMode: isDarkMode);
    final semanticLabel = accessibilityService.getBalanceSemanticLabel(balance, _formatAmount(balance));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Hero(
        tag: 'account_$accountId',
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (widget.onAccountSelected != null) {
                widget.onAccountSelected!(account);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountDetailScreen(account: account),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Semantics(
                label: '$name account ending in $lastFour. $semanticLabel',
                child: Row(
                  children: [
                    Hero(
                      tag: 'account_icon_$accountId',
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getAccountIcon(type),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 28,
                          semanticLabel: '${type.capitalize()} account',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${type.capitalize()} •••• $lastFour',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${_formatAmount(balance)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: accessibilityService.useColorIndicators
                                ? balanceColor
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          semanticsLabel: semanticLabel,
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                          semanticLabel: 'View account details',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'savings':
        return Icons.savings;
      case 'credit':
        return Icons.credit_card;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }
}