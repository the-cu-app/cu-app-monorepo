// Copyright 2021 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, Scaffold, IndexedStack, BoxShadow, Offset, AnimatedPositioned, Curves, IconTheme, IconThemeData;
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/services_screen.dart';
import 'screens/settings_screen.dart';
import 'services/banking_service.dart';

class Home extends StatefulWidget {
  final Function(bool) onThemeToggle;

  const Home({super.key, required this.onThemeToggle});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  bool _isBottomNavVisible = true;
  bool _isDarkMode = false;
  double _totalBalance = 0.0;
  ScrollController? _scrollController;
  Timer? _hideTimer;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController!.addListener(_onScroll);
    _screens = [
      DashboardScreen(scrollController: _scrollController),
      const TransactionsScreen(),
      const TransferScreen(),
      const ServicesScreen(),
      SettingsScreen(
        currentTheme: _isDarkMode,
        onThemeToggle: (isDark) {
          setState(() {
            _isDarkMode = isDark;
          });
          widget.onThemeToggle(isDark);
        },
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
      // Import the banking service to get real balance
      final bankingService = BankingService();
      final accounts = await bankingService.getUserAccounts();
      final balance = accounts.fold<double>(
        0.0,
        (sum, account) => sum + (account['balance'] ?? 0.0),
      );

      setState(() {
        _totalBalance = balance;
      });
    } catch (e) {
      // Fallback to demo balance if API fails
      setState(() {
        _totalBalance = 213535.80;
      });
    }
  }

  String _formatBalance(double balance) {
    if (balance >= 1000000) {
      // Millions: $1.2M, $5.7M, etc.
      final millions = balance / 1000000;
      if (millions >= 10) {
        return '${millions.toStringAsFixed(0)}M';
      } else {
        return '${millions.toStringAsFixed(1)}M';
      }
    } else if (balance >= 1000) {
      // Thousands: $213.5K, $45.2K, etc.
      final thousands = balance / 1000;
      if (thousands >= 100) {
        return '${thousands.toStringAsFixed(0)}K';
      } else {
        return '${thousands.toStringAsFixed(1)}K';
      }
    } else {
      // Under $1000: $45, $123, etc.
      return balance.toStringAsFixed(0);
    }
  }

  void _onScroll() {
    if (_scrollController != null) {
      final offset = _scrollController!.offset;

      if (offset > 100) {
        // Hide bottom nav when scrolling down
        if (_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = false;
          });
        }

        // Cancel existing timer and start new one
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _isBottomNavVisible = true;
            });
          }
        });
      } else {
        // Show bottom nav when at top
        if (!_isBottomNavVisible) {
          setState(() {
            _isBottomNavVisible = true;
          });
        }
        _hideTimer?.cancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _isBottomNavVisible
          ? Container(
              height: 60 + MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.border,
                    width: 1,
                  ),
                ),
                boxShadow: CUElevation.getShadow(CUElevation.low),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: SizedBox(
                  height: 60,
                  child: Stack(
                    children: [
                      // Animated indicator bar
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        left: _currentIndex * (MediaQuery.of(context).size.width / 5) + 
                              (MediaQuery.of(context).size.width / 5 - 40) / 2,
                        top: 0,
                        child: Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      
                      // Navigation items
                      Row(
                        children: [
                          _buildCustomNavItem(
                            0,
                            Text(
                              '\$${_formatBalance(_totalBalance)}',
                              style: CUTypography.labelLarge.toTextStyle(
                                color: _currentIndex == 0
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.neutral,
                              ),
                            ),
                          ),
                          _buildCustomNavItem(1, Icon(Icons.receipt_long, size: 24)),
                          _buildCustomNavItem(2, Icon(Icons.swap_horiz, size: 24)),
                          _buildCustomNavItem(3, Icon(Icons.grid_view, size: 24)),
                          _buildCustomNavItem(4, Icon(Icons.settings, size: 24)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCustomNavItem(int index, Widget child) {
    final theme = CUTheme.of(context);
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: SizedBox(
          height: 60,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: IconTheme(
                data: IconThemeData(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.neutral,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
