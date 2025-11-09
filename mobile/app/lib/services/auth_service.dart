import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../config/supabase_config.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const _storage = FlutterSecureStorage();
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Storage keys
  static const String _rememberMeKey = 'remember_me';
  static const String _emailKey = 'saved_email';
  static const String _biometricEnabledKey = 'biometric_enabled';

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Check if biometric authentication is available
  Future<bool> get isBiometricAvailable async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
      },
    );

    if (response.user != null) {
      // Create user profile in database
      await _createUserProfile(response.user!);
    }

    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // Save remember me preference
      await _storage.write(key: _rememberMeKey, value: rememberMe.toString());
      if (rememberMe) {
        await _storage.write(key: _emailKey, value: email);
      } else {
        await _storage.delete(key: _emailKey);
      }
    }

    return response;
  }

  // Sign in with biometric authentication
  Future<AuthResponse?> signInWithBiometric() async {
    try {
      // Check if biometric is available
      if (!await isBiometricAvailable) {
        throw Exception('Biometric authentication not available');
      }

      // Check if biometric is enabled for this user
      final biometricEnabled = await _storage.read(key: _biometricEnabledKey);
      if (biometricEnabled != 'true') {
        throw Exception('Biometric authentication not enabled');
      }

      // Get saved email
      final savedEmail = await _storage.read(key: _emailKey);
      if (savedEmail == null) {
        throw Exception('No saved email found');
      }

      // Authenticate with biometric
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Use biometric authentication to sign in to SUPAHYPER',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authenticated) {
        throw Exception('Biometric authentication failed');
      }

      // Get stored password (in real app, this would be encrypted)
      // For demo purposes, we'll use a placeholder
      final storedPassword = await _storage.read(key: 'stored_password');
      if (storedPassword == null) {
        throw Exception('No stored password found');
      }

      // Sign in with stored credentials
      return await _supabase.auth.signInWithPassword(
        email: savedEmail,
        password: storedPassword,
      );
    } catch (e) {
      print('Biometric sign in error: $e');
      return null;
    }
  }

  // Enable biometric authentication
  Future<bool> enableBiometric(String email, String password) async {
    try {
      if (!await isBiometricAvailable) {
        return false;
      }

      // Authenticate with biometric to enable it
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Enable biometric authentication for SUPAHYPER',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // Store credentials securely
        await _storage.write(key: _biometricEnabledKey, value: 'true');
        await _storage.write(key: _emailKey, value: email);
        await _storage.write(key: 'stored_password', value: password);
        return true;
      }

      return false;
    } catch (e) {
      print('Enable biometric error: $e');
      return false;
    }
  }

  // Disable biometric authentication
  Future<void> disableBiometric() async {
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: 'stored_password');
  }

  // Check if remember me is enabled
  Future<bool> get isRememberMeEnabled async {
    final rememberMe = await _storage.read(key: _rememberMeKey);
    return rememberMe == 'true';
  }

  // Get saved email
  Future<String?> get savedEmail async {
    return await _storage.read(key: _emailKey);
  }

  // Check if biometric is enabled
  Future<bool> get isBiometricEnabled async {
    final enabled = await _storage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _storage.deleteAll();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Update user profile
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
  }) async {
    if (currentUser == null) return;

    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;
    if (address != null) updates['address'] = address;

    await _supabase
        .from(SupabaseConfig.usersTable)
        .update(updates)
        .eq('id', currentUser!.id);
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;

    final response = await _supabase
        .from(SupabaseConfig.usersTable)
        .select()
        .eq('id', currentUser!.id)
        .single();

    return response;
  }

  // Create user profile in database
  Future<void> _createUserProfile(User user) async {
    await _supabase.from(SupabaseConfig.usersTable).insert({
      'id': user.id,
      'email': user.email,
      'first_name': user.userMetadata?['first_name'] ?? '',
      'last_name': user.userMetadata?['last_name'] ?? '',
      'phone_number': user.userMetadata?['phone_number'] ?? '',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Enable two-factor authentication
  Future<void> enableTwoFactor() async {
    // Implementation for 2FA setup
    // This would integrate with Supabase Auth MFA features
  }

  // Verify two-factor authentication
  Future<bool> verifyTwoFactor(String code) async {
    // Implementation for 2FA verification
    return true;
  }

  // Authenticate with biometric for sensitive operations
  Future<bool> authenticateForOperation(String reason) async {
    try {
      if (!await isBiometricAvailable) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  // Check if should require biometric for app launch
  Future<bool> shouldRequireBiometricForAppLaunch() async {
    final biometricForAppLaunch = await _storage.read(key: 'biometric_for_app_launch');
    return biometricForAppLaunch == 'true' && await isBiometricEnabled;
  }

  // Set biometric requirement for app launch
  Future<void> setBiometricForAppLaunch(bool required) async {
    await _storage.write(key: 'biometric_for_app_launch', value: required.toString());
  }

  // Check if should require biometric for transactions
  Future<bool> shouldRequireBiometricForTransactions() async {
    final biometricForTransactions = await _storage.read(key: 'biometric_for_transactions');
    return biometricForTransactions == 'true' && await isBiometricEnabled;
  }

  // Set biometric requirement for transactions
  Future<void> setBiometricForTransactions(bool required) async {
    await _storage.write(key: 'biometric_for_transactions', value: required.toString());
  }

  // Check if should require biometric for sensitive data
  Future<bool> shouldRequireBiometricForSensitiveData() async {
    final biometricForSensitive = await _storage.read(key: 'biometric_for_sensitive');
    return biometricForSensitive == 'true' && await isBiometricEnabled;
  }

  // Set biometric requirement for sensitive data
  Future<void> setBiometricForSensitiveData(bool required) async {
    await _storage.write(key: 'biometric_for_sensitive', value: required.toString());
  }

  // Get authentication state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
