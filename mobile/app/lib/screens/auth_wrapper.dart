import 'package:flutter/material.dart';
import 'home.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class AuthWrapper extends StatelessWidget {
  final Function(bool)? onThemeToggle;

  const AuthWrapper({super.key, this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    // For now, just show the login screen
    return const LoginScreen();
  }
}
