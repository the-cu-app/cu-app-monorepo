import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter/services.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/banking_service.dart';
import '../widgets/services_scroll.dart';
import '../widgets/membership_services.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_switcher.dart';
import '../services/feature_service.dart';
import '../widgets/transaction_helpers.dart';
import '../widgets/consistent_list_tile.dart';
import '../widgets/typewriter_text.dart';
import '../helpers/account_helper.dart';
import '../l10n/app_localizations.dart';
import '../widgets/weather_time_widget.dart';
import '../services/sound_service.dart';
import '../models/account_type_config.dart';
import 'game_screen.dart';
import 'chat_onboarding_screen.dart';
import 'account_detail_screen.dart';
import 'code_demo_screen.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Material 3 Search Delegate
class BankingSearchDelegate extends SearchDelegate {
  final ThemeData theme;
  final UserProfile? activeProfile;

  BankingSearchDelegate({required this.theme, this.activeProfile});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 18,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        border: InputBorder.none,
      ),
    );
  }

  @override
  String get searchFieldLabel => 'Search transactions, accounts, services...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
      IconButton(
        icon: CircleAvatar(
          radius: 16,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: activeProfile != null
              ? Text(
                  activeProfile!.initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    fontFamily: 'Geist',
                  ),
                )
              : Icon(
                  Icons.person_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
        ),
        onPressed: () {
          // Show profile switcher
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: const Text('Personal Account'),
                    subtitle: const Text('View profile details'),
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Account Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to settings
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () {
                      Navigator.pop(context);
                      // Sign out
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches(context);
    }
    return _buildSearchResults(context);
  }

  Widget _buildRecentSearches(BuildContext context) {
    final recentSearches = [
      'Starbucks',
      'Transfer to savings',
      'Last month statement',
      'Bill pay',
      'ATM near me',
    ];

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Recent Searches',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...recentSearches.map((search) => ListTile(
          leading: const Icon(Icons.history),
          title: Text(search),
          onTap: () {
            query = search;
            showResults(context);
          },
        )),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.qr_code_scanner),
          title: const Text('Scan to Pay'),
          onTap: () {
            close(context, null);
            // Navigate to QR scanner
          },
        ),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: const Text('Find ATM'),
          onTap: () {
            close(context, null);
            // Navigate to ATM locator
          },
        ),
        ListTile(
          leading: const Icon(Icons.support_agent),
          title: const Text('Contact Support'),
          onTap: () {
            close(context, null);
            // Navigate to support
          },
        ),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    // Filter results based on query
    final results = _getSearchResults(query);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          leading: Icon(result['icon'] as IconData),
          title: Text(result['title'] as String),
          subtitle: Text(result['subtitle'] as String),
          trailing: result['trailing'] as Widget?,
          onTap: () {
            close(context, result);
            // Handle result tap
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getSearchResults(String query) {
    // Mock search results - in production, this would query actual data
    final allResults = [
      {
        'title': 'Transfer Money',
        'subtitle': 'Send money to accounts or contacts',
        'icon': Icons.swap_horiz,
      },
      {
        'title': 'Pay Bills',
        'subtitle': 'Pay your bills online',
        'icon': Icons.receipt,
      },
      {
        'title': 'Starbucks',
        'subtitle': '-\$5.25 • Today at 8:15 AM',
        'icon': Icons.coffee,
      },
      {
        'title': 'Checking Account',
        'subtitle': 'Chase Bank • ****0000 • \$110.00',
        'icon': Icons.account_balance,
      },
    ];

    if (query.isEmpty) return allResults;
    
    return allResults.where((result) {
      final title = (result['title'] as String).toLowerCase();
      final subtitle = (result['subtitle'] as String).toLowerCase();
      final q = query.toLowerCase();
      return title.contains(q) || subtitle.contains(q);
    }).toList();
  }
}

class DashboardScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const DashboardScreen({super.key, this.scrollController});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  final BankingService _bankingService = BankingService();
  double _totalBalance = 0.0;
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;
  late AnimationController _typewriterController;
  String _currentPlaceholder = '';
  int _placeholderIndex = 0;
  int _charIndex = 0;
  List<String> _placeholderTexts = [];
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));
    
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _initializePlaceholderTexts();
    _startTypewriterAnimation();
    _loadData();
  }
  
  void _initializePlaceholderTexts() {
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
    } else if (hour >= 17 || hour < 5) {
      greeting = 'Good evening';
    }
    
    _placeholderTexts = [
      '$greeting! What can I help you with?',
      'Search "transfer money"',
      'Try "pay credit card"',
      'Find "ATM near me"',
      'Look up "last month statement"',
      'Search "spending insights"',
      'Try "set up bill pay"',
      'Find "mortgage rates"',
    ];
  }
  
  void _startTypewriterAnimation() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_charIndex < _placeholderTexts[_placeholderIndex].length) {
          _currentPlaceholder = _placeholderTexts[_placeholderIndex].substring(0, _charIndex + 1);
          _charIndex++;
        } else {
          // Wait for 3 seconds before fading to next
          timer.cancel();
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _fadeToNextPlaceholder();
            }
          });
        }
      });
    });
  }
  
  void _fadeToNextPlaceholder() {
    // Fade out current text
    _typewriterController.forward().then((_) {
      if (!mounted) return;
      
      setState(() {
        // Move to next placeholder
        _placeholderIndex = (_placeholderIndex + 1) % _placeholderTexts.length;
        _charIndex = 0;
        _currentPlaceholder = '';
      });
      
      // Reset animation and start typing next text
      _typewriterController.reset();
      _startTypewriterAnimation();
    });
  }
  
  @override
  void dispose() {
    _gradientController.dispose();
    _typewriterController.dispose();
    _typewriterTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      print('Loading accounts data from banking service...');
      final accounts = await _bankingService.getUserAccounts();
      print('Received ${accounts.length} accounts from banking service');
      
      final balance = accounts.fold<double>(
        0.0,
        (sum, account) => sum + (account['balance'] ?? 0.0),
      );

      setState(() {
        _accounts = accounts;
        _totalBalance = balance;
        _isLoading = false;
      });
      
      print('Dashboard updated with ${accounts.length} accounts and balance \$${balance.toStringAsFixed(2)}');
    } catch (e) {
      print('Error in dashboard _loadData: $e');
      // Fallback to demo data if API fails
      final demoAccounts = [
        {
          'name': 'Chase Total Checking',
          'institution': 'Chase Bank',
          'balance': 2547.89,
          'type': 'checking',
          'is_primary': true,
          'is_pinned': true,
          'mask': '1234',
          'lastFour': '1234',
          'account_id': 'chase_checking_1234',
        },
        {
          'name': 'Chase Savings Plus',
          'institution': 'Chase Bank',
          'balance': 12500.00,
          'type': 'savings',
          'is_pinned': false,
          'mask': '5678',
          'lastFour': '5678',
          'account_id': 'chase_savings_5678',
        },
        {
          'name': 'Amex Gold Card',
          'institution': 'American Express',
          'balance': -1250.45,
          'type': 'credit',
          'is_pinned': true,
          'mask': '9012',
          'lastFour': '9012',
          'account_id': 'amex_credit_9012',
        },
        {
          'name': 'Wells Fargo Checking',
          'institution': 'Wells Fargo',
          'balance': 3421.67,
          'type': 'checking',
          'is_pinned': false,
          'mask': '3456',
          'lastFour': '3456',
          'account_id': 'wells_checking_3456',
        },
        {
          'name': 'Student Loan',
          'institution': 'Sallie Mae',
          'balance': -25000.00,
          'type': 'loan',
          'is_pinned': false,
          'mask': '7890',
          'lastFour': '7890',
          'account_id': 'sallie_loan_7890',
        },
      ];

      final demoBalance = demoAccounts.fold<double>(
        0.0,
        (sum, account) => sum + (account['balance'] as double? ?? 0.0),
      );

      setState(() {
        _accounts = demoAccounts;
        _totalBalance = demoBalance;
        _isLoading = false;
      });
    }
  }

  void _navigateToTransfers(BuildContext context) {
    SoundService().playTransfer();
    Navigator.of(context).pushNamed('/transfer');
  }

  void _navigateToBillPay(BuildContext context) {
    // Navigate to bill pay screen
  }

  void _navigateToInvestments(BuildContext context) {
    // Navigate to investments screen
  }

  void _navigateToBudget(BuildContext context) {
    // Navigate to budget screen
  }

  void _showMoreActions(BuildContext context) {
    // Show more actions dialog
  }

  void _showCustomizeQuickActions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customize Quick Actions'),
        content: const Text('Customization coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _showDepositDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deposit Money'),
        content: const Text('Deposit functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);
    final profiles = ref.watch(profilesListProvider);
    
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top profile bar
                _buildProfileBar(activeProfile, profiles),
                Expanded(
                  child: CustomScrollView(
                    controller: widget.scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            
                            // Weather and Time Widget
                            const WeatherTimeWidget(),
                            
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                              child: _buildAnimatedBalanceCard(),
                            ),
                            const SizedBox(height: 16),
                            _buildAccountsSection(),
                            const SizedBox(height: 24),
                            _buildGameCard(context),
                            const SizedBox(height: 24),
                            _buildChatCard(context),
                            const SizedBox(height: 24),
                            _buildCodeDemoCard(context),
                            const SizedBox(height: 24),
                            const MembershipServices(),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildQuickActions(context),
                            ),
                            const SizedBox(height: 24),
                            TransactionHelpers.buildRecentTransactions(context),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                children: [
                                  const Text('Chat Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final activeProfile = ref.watch(activeProfileProvider);
    
    return GestureDetector(
      onTap: () {
        SoundService().playButtonTap();
        showSearch(
          context: context,
          delegate: BankingSearchDelegate(
            theme: theme, 
            activeProfile: activeProfile,
          ),
        );
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark 
              ? Colors.grey.shade900.withOpacity(0.5)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: _typewriterController,
                builder: (context, child) {
                  return AnimatedOpacity(
                    opacity: _typewriterController.value > 0.5 ? 2.0 - (_typewriterController.value * 2) : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _currentPlaceholder.isEmpty ? 'Search...' : _currentPlaceholder,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontSize: 16,
                        fontFamily: 'Geist',
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: () {
                  SoundService().playButtonTap();
                  // Show profile options
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      margin: const EdgeInsets.only(top: 100),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle bar
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outline.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            margin: const EdgeInsets.only(bottom: 20),
                          ),
                          // Profile header
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(
                                  'KK',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kyle Kusche',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                  Text(
                                    'Premium Member',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Profile options
                          _buildProfileOption(
                            context,
                            Icons.person_outline,
                            'View Profile',
                            'Manage your personal information',
                            () => Navigator.pop(context),
                          ),
                          _buildProfileOption(
                            context,
                            Icons.add_circle_outline,
                            'Add Account',
                            'Connect business or additional accounts',
                            () {
                              Navigator.pop(context);
                              _showAddAccountDialog(context);
                            },
                          ),
                          _buildProfileOption(
                            context,
                            Icons.settings_outlined,
                            'Settings',
                            'App preferences and security',
                            () {
                              Navigator.pop(context);
                              Navigator.of(context).pushNamed('/accessibility');
                            },
                          ),
                          _buildProfileOption(
                            context,
                            Icons.logout,
                            'Sign Out',
                            'Logout from your account',
                            () => Navigator.pop(context),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    'KK',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        SoundService().playButtonTap();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBar(UserProfile? activeProfile, List<UserProfile> profiles) {
    final theme = Theme.of(context);
    
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: theme.colorScheme.surface,
        child: Row(
          children: [
            const Spacer(),
            // KK Profile avatar with enhanced styling
            Container(
              child: InkWell(
                onTap: () {
                  SoundService().playButtonTap();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      margin: const EdgeInsets.only(top: 100),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle bar
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outline.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            margin: const EdgeInsets.only(bottom: 20),
                          ),
                          // Profile header with membership outline
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Color(0xFFF7B731), // Premium gold outline
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'KK',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimary,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kyle Kusche',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFF7B731).withOpacity(0.2),
                                          Color(0xFFFFD700).withOpacity(0.2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Color(0xFFF7B731).withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'Premium Member',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFF7B731),
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Geist',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Profile options
                          _buildProfileOption(
                            context,
                            Icons.person_outline,
                            'View Profile',
                            'Manage your personal information',
                            () => Navigator.pop(context),
                          ),
                          _buildProfileOption(
                            context,
                            Icons.add_circle_outline,
                            'Add Account',
                            'Connect business or additional accounts',
                            () {
                              Navigator.pop(context);
                              _showAddAccountDialog(context);
                            },
                          ),
                          _buildProfileOption(
                            context,
                            Icons.settings_outlined,
                            'Settings',
                            'App preferences and security',
                            () {
                              Navigator.pop(context);
                              Navigator.of(context).pushNamed('/accessibility');
                            },
                          ),
                          _buildProfileOption(
                            context,
                            Icons.logout,
                            'Sign Out',
                            'Logout from your account',
                            () => Navigator.pop(context),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    border: Border.all(
                      color: Color(0xFFF7B731), // Premium gold outline
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'KK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileAvatarWithInitials(UserProfile profile) {
    final theme = Theme.of(context);
    final initials = '${profile.firstName[0]}${profile.lastName[0]}'.toUpperCase();
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getMembershipColor(profile.membershipType).withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Color _getMembershipColor(MembershipType type) {
    switch (type) {
      case MembershipType.general:
        return const Color(0xFF4ECDC4);
      case MembershipType.business:
        return const Color(0xFF6B5B95);
      case MembershipType.youth:
        return const Color(0xFFFF6B6B);
      case MembershipType.fiduciary:
        return const Color(0xFF1DB954);
      case MembershipType.premium:
        return const Color(0xFFF7B731);
      case MembershipType.student:
        return const Color(0xFF9B59B6);
    }
  }

  String _formatBalance(double balance) {
    if (balance >= 1000000) {
      final millions = balance / 1000000;
      return '${millions.toStringAsFixed(1)}M';
    } else if (balance >= 1000) {
      final thousands = balance / 1000;
      return '${thousands.toStringAsFixed(0)}K';
    } else {
      return balance.toStringAsFixed(0);
    }
  }
  
  Widget _buildAppBar() {
    final theme = Theme.of(context);

    return SliverAppBar(
      floating: false,
      pinned: false,
      toolbarHeight: 60,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      leadingWidth: 56,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        '\$${_formatBalance(_totalBalance)}',
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
      ],
    );
  }

  Widget _buildAnimatedBalanceCard() {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_totalBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 42,
              color: theme.colorScheme.onSurface,
              fontFamily: 'Geist',
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _navigateToTransfers(context),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Transfer'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).pushNamed('/accounts'),
                  icon: const Icon(Icons.account_balance, size: 18),
                  label: const Text('Accounts'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? Colors.grey.shade900 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.transparent : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${_totalBalance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 36,
                color: isDark ? Colors.white : Colors.black,
                fontFamily: 'GeistMono',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _navigateToTransfers(context),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Add Money',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _navigateToTransfers(context),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Transfer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)?.quickActions ?? 'Quick Actions',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showCustomizeQuickActions(context),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Customize'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const MembershipServices(),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool isPrimary = false,
    bool isPinned = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isPrimary ? Colors.black : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : Colors.black,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Geist',
                ),
              ),
              if (isPinned) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.push_pin,
                  color: isPrimary ? Colors.white : Colors.grey.shade600,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const GameScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 160,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade400,
                  Colors.blue.shade400,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.gamepad,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.yellow.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '🎮 PLAY',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'CU.APP Game Zone',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Take a break and play Flappy Bird! Compete for high scores.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontFamily: 'Geist',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.yellow, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'High: 0',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.people, color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '1.2k',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeDemoCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CodeDemoScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 160,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black87,
                  Colors.grey.shade900,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.terminal,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '💻 VIEW CODE',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'See How We Built This App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 6),
                TypewriterText(
                  text: 'Built with Flutter + Supabase. Enterprise-grade white-label banking platform...',
                  style: TextStyle(
                    color: Colors.green.shade400,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.code, color: Colors.green, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Flutter',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.layers, color: Colors.blue, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Supabase',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.analytics, color: Colors.orange, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Strategy',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ChatOnboardingScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 160,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade400,
                  Colors.teal.shade400,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '💬 ASK AI',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'CU.APPGPT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your intelligent banking assistant. Ask questions about your finances, get insights, or request help with transactions.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontFamily: 'Geist',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.yellow, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Smart Insights',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.security, color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Secure',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.speed, color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Fast',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsSection() {
    final theme = Theme.of(context);
    final pinnedAccounts = _accounts.where((acc) => acc['is_pinned'] == true).toList();
    final unpinnedAccounts = _accounts.where((acc) => acc['is_pinned'] != true).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pinned accounts horizontal scroll
        if (pinnedAccounts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Pinned',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Geist',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: pinnedAccounts.length,
              itemBuilder: (context, index) {
                final account = pinnedAccounts[index];
                return _buildAccountCard(account, theme, true);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // All accounts vertical list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Accounts',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Geist',
                ),
              ),
              TextButton(
                onPressed: () {
                  // Show account management
                },
                child: Text(
                  'Manage',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Vertical scrollable accounts list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _accounts.length,
          itemBuilder: (context, index) {
            final account = _accounts[index];
            return _buildVerticalAccountCard(account, theme);
          },
        ),
      ],
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account, ThemeData theme, bool isPinned) {
    final isPrimary = account['is_primary'] == true;
    final accountConfig = AccountHelper.getAccountConfig(account);
    final displayName = AccountHelper.getAccountDisplayName(account);
    final accountMask = AccountHelper.getAccountMask(account);
    final accountIcon = AccountHelper.getAccountIcon(account);
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: InkWell(
          onTap: () {
            print('Navigating to account details: $displayName');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AccountDetailScreen(account: account),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accountConfig.primaryColor.withOpacity(0.05),
                  accountConfig.secondaryColor.withOpacity(0.1),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accountConfig.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          accountIcon,
                          size: 20,
                          color: accountConfig.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Geist',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${accountConfig.shortName} $accountMask',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PRIMARY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Balance section
                  Text(
                    AccountHelper.formatBalance(account),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Geist',
                      color: accountConfig.primaryColor,
                    ),
                    semanticsLabel: AccountHelper.getBalanceSemanticLabel(account),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalAccountCard(Map<String, dynamic> account, ThemeData theme) {
    final isPrimary = account['is_primary'] == true;
    final isPinned = account['is_pinned'] == true;
    final accountConfig = AccountHelper.getAccountConfig(account);
    final displayName = AccountHelper.getAccountDisplayName(account);
    final accountMask = AccountHelper.getAccountMask(account);
    final accountIcon = AccountHelper.getAccountIcon(account);
    final statusInfo = AccountHelper.getAccountStatus(account);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: accountConfig.primaryColor.withOpacity(0.1),
            child: Icon(
              accountIcon,
              color: accountConfig.primaryColor,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPrimary)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PRIMARY',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${accountConfig.shortName} $accountMask',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'Geist',
                ),
              ),
              if (statusInfo.status != 'Active')
                Text(
                  statusInfo.status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusInfo.color,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                  ),
                ),
            ],
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AccountHelper.formatBalanceCompact(account),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Geist',
                  color: accountConfig.primaryColor,
                ),
                semanticsLabel: AccountHelper.getBalanceSemanticLabel(account),
              ),
              if (isPinned)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.push_pin,
                    size: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          onTap: () {
            print('Navigating to vertical account details: $displayName');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AccountDetailScreen(account: account),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add Account',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select the type of account you\'d like to add to your membership:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 24),
                _buildAccountTypeOption(
                  context,
                  'Business Account',
                  'Separate business banking and transactions',
                  Icons.business,
                  theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                _buildAccountTypeOption(
                  context,
                  'Joint Account',
                  'Shared account with another member',
                  Icons.people,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildAccountTypeOption(
                  context,
                  'Savings Account',
                  'Additional savings with competitive rates',
                  Icons.savings,
                  Colors.orange,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountTypeOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        // Handle account creation logic here
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text($title creation coming soon!)),

          );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
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
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

}

