import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'home_screen_riverpod.dart';

class Home extends StatelessWidget {
  final Function(bool)? onThemeToggle;

  const Home({super.key, this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return CUScacuold(
      appBar: CUAppBar(
        title: const Text(
          'CU_APP Banking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              // Simple logout - just navigate back
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const LoginScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(Icons.logout, color: theme.colorScheme.onPrimary),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance, size: 100, color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              'Welcome to CU_APP Banking',
              style: CUTypography.headlineMedium.copyWith(
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your member-facing banking app',
              style: CUTypography.bodyLarge.copyWith(
                color: theme.colorScheme.onBackground.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
      bottomBar: _buildBottomNav(context, theme),
    );
  }

  Widget _buildBottomNav(BuildContext context, CUThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, theme, Icons.home, 'Home', true),
              _buildNavItem(context, theme, Icons.account_balance, 'Accounts', false),
              _buildNavItem(context, theme, Icons.swap_horiz, 'Transfer', false),
              _buildNavItem(context, theme, Icons.credit_card, 'Cards', false),
              _buildNavItem(context, theme, Icons.settings, 'Settings', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    CUThemeData theme,
    IconData icon,
    String label,
    bool isActive,
  ) {
    final color = isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: () {
        // Handle navigation
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: CUTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return CUScacuold(
      appBar: CUAppBar(
        title: const Text(
          'Login',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance, size: 100, color: theme.colorScheme.primary),
              const SizedBox(height: 30),
              Text(
                'CU_APP Banking',
                style: CUTypography.headlineLarge.copyWith(
                  color: theme.colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: CUButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            HomeScreenRiverpod(onThemeToggle: (isDark) {}),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ),
                    );
                  },
                  child: const Text('Login (Demo)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
