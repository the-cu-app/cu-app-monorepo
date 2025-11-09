import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../services/feature_service.dart';
import '../widgets/profile_switcher.dart';
import '../widgets/payment_activity_panel.dart';
// import 'dashboard_screen.dart'; // Disabled - needs CU widgets
// import 'transactions_screen.dart'; // Disabled - needs CU widgets
import 'transfer_screen.dart';
import 'bill_pay_screen.dart';
import 'services_screen.dart';
import 'settings_screen.dart';
import 'simple_dashboard_screen.dart';
import '../services/banking_service.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

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
  double _totalBalance = 213535.80; // Default balance, never 0
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
      SimpleDashboardScreen(scrollController: _scrollController), // Using simple dashboard until CU widgets are ready
      const _PlaceholderScreen(title: 'Transfer'), // Transfer screen
      const _PlaceholderScreen(title: 'History'), // Recent transactions/history
      SettingsScreen(
        onThemeToggle: (isDark) {
          setState(() {
            _isDarkMode = isDark;
          });
          widget.onThemeToggle(isDark);
        },
        isDarkMode: _isDarkMode,
      ),
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
    final cuTheme = CUTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      color: cuTheme.colorScheme.background,
      child: Stack(
        children: [
          // Main content area
          Row(
            children: [
              // Desktop side navigation
              if (isDesktop)
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: cuTheme.colorScheme.surface,
                    border: Border(
                      right: BorderSide(
                        color: cuTheme.colorScheme.border.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDesktopNavItem(
                        icon: Icons.dashboard_outlined,
                        selectedIcon: Icons.dashboard,
                        label: 'Dashboard',
                        index: 0,
                        isSelected: _currentIndex == 0,
                      ),
                      _buildDesktopNavItem(
                        icon: Icons.swap_horiz_outlined,
                        selectedIcon: Icons.swap_horiz,
                        label: 'Transfer',
                        index: 1,
                        isSelected: _currentIndex == 1,
                      ),
                      _buildDesktopNavItem(
                        icon: Icons.history,
                        selectedIcon: Icons.history,
                        label: 'History',
                        index: 2,
                        isSelected: _currentIndex == 2,
                      ),
                      _buildDesktopNavItem(
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings,
                        label: 'Settings',
                        index: 3,
                        isSelected: _currentIndex == 3,
                      ),
                    ],
                  ),
                ),

              // Main content
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),

              // Desktop right panel - Payment Activity
              if (isDesktop) const PaymentActivityPanel(),
            ],
          ),

          // Mobile bottom navigation
          if (!isDesktop && _isBottomNavVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: cuTheme.colorScheme.surface,
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
                        icon: Icons.swap_horiz_rounded,
                        index: 1,
                      ),
                      _buildCompactNavItem(
                        icon: Icons.history,
                        index: 2,
                      ),
                      _buildCompactNavItem(
                        icon: Icons.settings,
                        index: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactBalanceButton() {
    final isSelected = _currentIndex == 0;
    final cuTheme = CUTheme.of(context);

    return GestureDetector(
      onTap: () {
        if (_currentIndex == 0) {
          // Already on home - scroll to top
          if (_scrollController != null &&
              _scrollController!.hasClients &&
              _scrollController!.offset > 0) {
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
        child: AnimatedSwitcher(
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
                        ? cuTheme.colorScheme.primary
                        : cuTheme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: 'Geist',
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCompactNavItem({
    required IconData icon,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final cuTheme = CUTheme.of(context);

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
              ? cuTheme.colorScheme.primary
              : cuTheme.colorScheme.onSurface.withOpacity(0.6),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildDesktopNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final cuTheme = CUTheme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? cuTheme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? cuTheme.colorScheme.primary
                  : cuTheme.colorScheme.onSurface.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? cuTheme.colorScheme.primary
                    : cuTheme.colorScheme.onSurface.withOpacity(0.6),
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Temporary placeholder for screens being migrated to CU components
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            '$title',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon with zero-Material design',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
