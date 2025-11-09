import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'auth/login_screen_riverpod.dart';
import '../home.dart';

class AuthWrapper extends StatelessWidget {
  final Function(bool)? onThemeToggle;

  const AuthWrapper({super.key, this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          return Home(onThemeToggle: onThemeToggle ?? (bool isDark) {});
        } else {
          return const LoginScreenRiverpod();
        }
      },
    );
  }
}
