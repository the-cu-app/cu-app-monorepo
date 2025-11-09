import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../src/one_two_transition.dart';
import 'simple_dashboard_screen.dart';
import 'transactions_screen.dart';
import 'transfer_screen.dart';
import 'services_screen.dart';
import 'settings_screen.dart';
import 'profile_switcher_screen.dart';
import 'account_details_screen.dart';
import 'cards_screen.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class AdaptiveHomeScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;

  const AdaptiveHomeScreen({super.key, required this.onThemeToggle});

  @override
  State<AdaptiveHomeScreen> createState() => _AdaptiveHomeScreenState();
}

class _AdaptiveHomeScreenState extends State<AdaptiveHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _profileAnimationController;
  late CurvedAnimation _railAnimation;
  late CurvedAnimation _profileAnimation;
  
  bool _showMediumLayout = false;
  bool _showLargeLayout = false;
  bool _showProfileSwitcher = false;
  
  int _selectedIndex = 0;
  Map<String, dynamic>? _selectedAccount;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Screen definitions
  late final List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      label: 'Dashboard',
      labelEs: 'Inicio',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _NavigationItem(
      label: 'Cards',
      labelEs: 'Tarjetas',
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card,
    ),
    _NavigationItem(
      label: 'Transactions',
      labelEs: 'Transacciones',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _NavigationItem(
      label: 'Transfer',
      labelEs: 'Transferir',
      icon: Icons.swap_horiz_outlined,
      selectedIcon: Icons.swap_horiz,
    ),
    _NavigationItem(
      label: 'Services',
      labelEs: 'Servicios',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view,
    ),
    _NavigationItem(
      label: 'Settings',
      labelEs: 'Configuración',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _railAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0),
    );
    
    _profileAnimation = CurvedAnimation(
      parent: _profileAnimationController,
      curve: Curves.easeInOut,
    );
    
    // Initialize profile service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileService>().initialize();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _profileAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.of(context).size.width;
    const mediumBreakpoint = 800.0;
    const largeBreakpoint = 1200.0;

    if (width >= largeBreakpoint) {
      _showMediumLayout = false;
      _showLargeLayout = true;
      _controller.forward();
    } else if (width >= mediumBreakpoint) {
      _showMediumLayout = true;
      _showLargeLayout = false;
      _controller.forward();
    } else {
      _showMediumLayout = false;
      _showLargeLayout = false;
      _controller.reverse();
    }
  }

  void _toggleProfileSwitcher() {
    setState(() {
      _showProfileSwitcher = !_showProfileSwitcher;
      if (_showProfileSwitcher) {
        _profileAnimationController.forward();
      } else {
        _profileAnimationController.reverse();
      }
    });
  }

  Widget _buildProfileHeader(ProfileService profileService) {
    final currentProfile = profileService.currentProfile;
    if (currentProfile == null) return const SizedBox.shrink();

    return InkWell(
      onTap: _toggleProfileSwitcher,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getProfileColor(currentProfile.type),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  currentProfile.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentProfile.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    currentProfile.type.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: _showProfileSwitcher ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.expand_more,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProfileColor(ProfileType type) {
    switch (type) {
      case ProfileType.personal:
        return Colors.blue;
      case ProfileType.business:
        return Colors.green;
      case ProfileType.youth:
        return Colors.orange;
      case ProfileType.fiduciary:
        return Colors.purple;
    }
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      extended: _showLargeLayout,
      backgroundColor: Colors.white,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
          _showProfileSwitcher = false;
        });
      },
      selectedIconTheme: const IconThemeData(
        color: Colors.black,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: Colors.grey.shade400,
        size: 24,
      ),
      selectedLabelTextStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Colors.grey.shade400,
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      leading: null,
      destinations: _navigationItems
          .map((item) => NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              ))
          .toList(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        elevation: 0, // No shadow
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: _navigationItems
            .map((item) => BottomNavigationBarItem(
                  icon: SizedBox(
                    width: 48, // 48px touch target
                    height: 48,
                    child: Center(
                      child: Icon(
                        item.icon,
                        size: 32, // 32px icon
                      ),
                    ),
                  ),
                  activeIcon: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Icon(
                        item.selectedIcon,
                        size: 32,
                      ),
                    ),
                  ),
                  label: item.labelEs, // Spanish label
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBody() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    Widget screen = switch (_selectedIndex) {
      0 => SimpleDashboardScreen(
          scrollController: ScrollController(),
          onAccountSelected: (account) {
            setState(() {
              _selectedAccount = account;
            });
          },
        ),
      1 => const CardsScreen(),
      2 => const TransactionsScreen(),
      3 => const TransferScreen(),
      4 => const ServicesScreen(),
      5 => SettingsScreen(
          currentTheme: isDarkMode,
          onThemeToggle: widget.onThemeToggle,
        ),
      _ => const SizedBox.shrink(),
    };

    if (_showMediumLayout || _showLargeLayout) {
      // Desktop layout with panels
      return Row(
        children: [
          if (_showProfileSwitcher)
            AnimatedBuilder(
              animation: _profileAnimation,
              builder: (context, child) {
                return Container(
                  width: 300 * _profileAnimation.value,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: _profileAnimation.value > 0.1
                      ? FadeTransition(
                          opacity: _profileAnimation,
                          child: ProfileSwitcherScreen(
                            onProfileSelected: (profile) async {
                              final profileService = context.read<ProfileService>();
                              await profileService.switchProfile(profile);
                              _toggleProfileSwitcher();
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
          Expanded(
            child: _selectedAccount != null && _selectedIndex == 0
                ? OneTwoTransition(
                    animation: _railAnimation,
                    one: screen,
                    two: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          left: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ),
                      child: _buildDetailPanel(),
                    ),
                  )
                : screen,
          ),
        ],
      );
    } else {
      // Mobile layout - Navigate to account details
      if (_selectedAccount != null && _selectedIndex == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AccountDetailsScreen(account: _selectedAccount!),
            ),
          ).then((_) {
            setState(() {
              _selectedAccount = null;
            });
          });
        });
      }
      return screen;
    }
  }

  Widget _buildDetailPanel() {
    // Show account details if an account is selected on desktop
    if (_selectedAccount != null && _selectedIndex == 0) {
      return AccountDetailsScreen(account: _selectedAccount!);
    }
    
    // Otherwise show placeholder
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select an account to view details',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          key: _scaffoldKey,
          appBar: _showMediumLayout || _showLargeLayout ? AppBar(
            title: Text(_navigationItems[_selectedIndex].label),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: false,
            actions: [
              Consumer<ProfileService>(
                builder: (context, profileService, child) {
                  final currentProfile = profileService.currentProfile;
                  if (currentProfile == null) return const SizedBox.shrink();
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: InkWell(
                      onTap: _toggleProfileSwitcher,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _getProfileColor(currentProfile.type),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  currentProfile.displayName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentProfile.displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ) : null,
          body: Row(
            children: [
              if (_showMediumLayout || _showLargeLayout)
                _buildNavigationRail(),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
          bottomNavigationBar: !_showMediumLayout && !_showLargeLayout
              ? _buildBottomNavigationBar()
              : null,
        );
      },
    );
  }
}

class _NavigationItem {
  final String label;
  final String labelEs; // Spanish label
  final IconData icon;
  final IconData selectedIcon;

  _NavigationItem({
    required this.label,
    required this.labelEs,
    required this.icon,
    required this.selectedIcon,
  });
}