import 'dart:async';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../services/feature_service.dart';
import '../widgets/profile_switcher.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'transfer_screen.dart';
import 'bill_pay_screen.dart';
import 'services_screen.dart';
import 'settings_screen.dart';
import '../services/banking_service.dart';

class HomeScreenRiverpod extends ConsumerStatefulWidget {
  final Function(bool) onThemeToggle;

  const HomeScreenRiverpod({super.key, required this.onThemeToggle});

  @override
  ConsumerState<HomeScreenRiverpod> createState() => _HomeScreenRiverpodState();
}

class _HomeScreenRiverpodState extends ConsumerState<HomeScreenRiverpod> {
  int _currentIndex = 0;
  bool _isBottomNavVisible = true;
  bool _isDarkMode = false;
  double _totalBalance = 213535.80;  // Default balance, never 0
  bool _isBalanceLoaded = false;
  ScrollController? _scrollController;
  Timer? _hideTimer;
  double _lastScrollOffset = 0.0;
  bool _isScrollingDown = false;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController!.addListener(_onScroll);
    _screens = [
      DashboardScreen(scrollController: _scrollController),
      const BillPayScreen(), // Pay screen
      const TransferScreen(),
      const TransactionsScreen(), // Activity/Transactions
      SettingsScreen(
        currentTheme: _isDarkMode,
        onThemeToggle: (isDark) {
          setState(() {
            _isDarkMode = isDark;
          });
          widget.onThemeToggle(isDark);
        },
      ), // More/Settings
    ];
    _loadTotalBalance();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTotalBalance() async {
    try {
      final bankingService = BankingService();
      final accounts = await bankingService.getAllAccounts();
      final balance = accounts.fold<double>(
        0.0,
        (sum, account) => sum + (account['balance'] ?? 0.0),
      );

      if (mounted) {
        setState(() {
          _totalBalance = balance > 0 ? balance : 213535.80;
          _isBalanceLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _totalBalance = 213535.80;
          _isBalanceLoaded = true;
        });
      }
    }
  }

  String _formatBalance(double balance) {
    if (balance >= 1000000) {
      final millions = balance / 1000000;
      if (millions >= 10) {
        return '${millions.toStringAsFixed(0)}M';
      } else {
        return '${millions.toStringAsFixed(1)}M';
      }
    } else if (balance >= 1000) {
      final thousands = balance / 1000;
      if (thousands >= 100) {
        return '${thousands.toStringAsFixed(0)}K';
      } else {
        return '${thousands.toStringAsFixed(1)}K';
      }
    } else {
      return balance.toStringAsFixed(0);
    }
  }

  void _onScroll() {
    if (_scrollController != null) {
      final offset = _scrollController!.offset;
      final delta = offset - _lastScrollOffset;
      
      // Detect scroll direction with high sensitivity
      if (delta > 0.5) {
        // Scrolling down - hide nav
        _isScrollingDown = true;
        if (_isBottomNavVisible && offset > 50) {
          setState(() {
            _isBottomNavVisible = false;
          });
        }
        
        // Reset timer for auto-show
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(seconds: 5), () {
          if (mounted && !_isBottomNavVisible) {
            setState(() {
              _isBottomNavVisible = true;
            });
          }
        });
      } else if (delta < -0.1) {
        // Scrolling up - show nav immediately with high sensitivity
        _isScrollingDown = false;
        if (!_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = true;
          });
        }
        _hideTimer?.cancel();
      }
      
      // Always show nav when at top
      if (offset <= 0) {
        if (!_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = true;
          });
        }
        _hideTimer?.cancel();
      }
      
      _lastScrollOffset = offset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);
    final profiles = ref.watch(profilesListProvider);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          // Desktop side navigation
          if (isDesktop)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              extended: true,
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: Text('Transactions'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.swap_horiz_outlined),
                  selectedIcon: Icon(Icons.swap_horiz),
                  label: Text('Transfer'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.apps_outlined),
                  selectedIcon: Icon(Icons.apps),
                  label: Text('Services'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
          
          // Main content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      // Mobile bottom navigation
      bottomNavigationBar: !isDesktop && _isBottomNavVisible
          ? Container(
              height: 75,
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
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCompactBalanceButton(),
                    _buildCompactNavItem(
                      icon: Icons.credit_card_rounded,
                      index: 1,
                    ),
                    _buildCompactNavItem(
                      icon: Icons.swap_horiz_rounded,
                      index: 2,
                    ),
                    _buildCompactNavItem(
                      icon: Icons.insights_rounded,
                      index: 3,
                    ),
                    _buildCompactNavItem(
                      icon: Icons.settings,
                      index: 4,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCompactBalanceButton() {
    final isSelected = _currentIndex == 0;
    final activeProfile = ref.watch(activeProfileProvider);

    return GestureDetector(
      onTap: () {
        if (_currentIndex == 0) {
          // Already on home - scroll to top
          if (_scrollController != null && _scrollController!.hasClients && _scrollController!.offset > 0) {
            _scrollController!.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        } else {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: activeProfile != null && 
                activeProfile.membershipType != MembershipType.business
            ? AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: !_isBalanceLoaded
                    ? Container(
                        key: const ValueKey('loading'),
                        width: 40,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )
                    : Text(
                        '\$${_formatBalance(_totalBalance)}',
                        key: const ValueKey('balance'),
                        style: TextStyle(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          fontFamily: 'Geist',
                        ),
                      ),
              )
            : Icon(
                Icons.home_rounded,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
      ),
    );
  }

  Widget _buildCompactNavItem({
    required IconData icon,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }

}