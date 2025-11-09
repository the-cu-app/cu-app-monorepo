import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/feature_service.dart';

/// Current user provider
final currentUserProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((event) => event.session?.user);
});

/// Auth state notifier for managing authentication
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState.initial());
  
  final _supabase = Supabase.instance.client;
  
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        state = AuthState.authenticated(response.user!);
      } else {
        state = const AuthState.error('Failed to sign in');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  Future<void> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    state = const AuthState.loading();
    
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      
      if (response.user != null) {
        // Create user profile
        await _createUserProfile(response.user!, metadata);
        state = AuthState.authenticated(response.user!);
      } else {
        state = const AuthState.error('Failed to create account');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  Future<void> _createUserProfile(User user, Map<String, dynamic> metadata) async {
    final membershipType = metadata['membership_type'] ?? 'general';
    
    await _supabase.from('user_profiles').insert({
      'user_id': user.id,
      'email': user.email,
      'first_name': metadata['first_name'],
      'last_name': metadata['last_name'],
      'membership_type': membershipType,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Update feature service
    await FeatureService().updateMembershipType(
      MembershipType.values.firstWhere(
        (m) => m.name == membershipType,
        orElse: () => MembershipType.general,
      ),
    );
  }
  
  Future<void> signOut() async {
    state = const AuthState.loading();
    
    try {
      await _supabase.auth.signOut();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  Future<void> switchProfile(String profileId) async {
    // Profile switching logic
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    try {
      // Update active profile
      await _supabase.from('user_profiles').update({
        'is_active': false,
      }).eq('user_id', user.id);
      
      await _supabase.from('user_profiles').update({
        'is_active': true,
      }).eq('id', profileId);
      
      // Reload user data
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}

/// Auth state
class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;
  
  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });
  
  const AuthState.initial() : this();
  
  const AuthState.loading() : this(isLoading: true);
  
  const AuthState.authenticated(User user) : this(user: user);
  
  const AuthState.unauthenticated() : this();
  
  const AuthState.error(String error) : this(error: error);
  
  bool get isAuthenticated => user != null;
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});