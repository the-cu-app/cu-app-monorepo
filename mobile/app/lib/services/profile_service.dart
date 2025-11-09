import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  UserProfile? _currentProfile;
  List<UserProfile> _userProfiles = [];
  bool _isLoading = false;
  
  UserProfile? get currentProfile => _currentProfile;
  List<UserProfile> get userProfiles => _userProfiles;
  bool get isLoading => _isLoading;
  
  // Check if user has business profile
  bool get hasBusinessProfile => 
      _userProfiles.any((p) => p.type == ProfileType.business);
  
  // Check if user has youth profile
  bool get hasYouthProfile => 
      _userProfiles.any((p) => p.type == ProfileType.youth);
      
  // Get profile by type
  UserProfile? getProfileByType(ProfileType type) {
    try {
      return _userProfiles.firstWhere((p) => p.type == type);
    } catch (e) {
      return null;
    }
  }

  // Initialize and load profiles
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await loadUserProfiles();
      
      // Set current profile to primary or first available
      if (_userProfiles.isNotEmpty) {
        _currentProfile = _userProfiles.firstWhere(
          (p) => p.isPrimary,
          orElse: () => _userProfiles.first,
        );
      }
    } catch (e) {
      debugPrint('Error initializing profiles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all user profiles
  Future<void> loadUserProfiles() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // For demo, create mock profiles
      _userProfiles = _createMockProfiles(user.id);
      
      // In production, this would fetch from Supabase:
      // final response = await _supabase
      //     .from('user_profiles')
      //     .select()
      //     .eq('user_id', user.id)
      //     .order('created_at');
      // 
      // _userProfiles = (response as List)
      //     .map((json) => UserProfile.fromJson(json))
      //     .toList();
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      // Fallback to mock data
      _userProfiles = _createMockProfiles(user.id);
    }
  }

  // Create mock profiles for demo
  List<UserProfile> _createMockProfiles(String userId) {
    final now = DateTime.now();
    
    return [
      UserProfile(
        id: 'profile_personal_001',
        userId: userId,
        type: ProfileType.personal,
        displayName: 'Personal Account',
        createdAt: now.subtract(const Duration(days: 365)),
        lastUsedAt: now,
        isPrimary: true,
        permissions: ProfilePermissions.forProfileType(ProfileType.personal),
        limits: ProfileLimits.forProfileType(ProfileType.personal),
      ),
      UserProfile(
        id: 'profile_business_001',
        userId: userId,
        type: ProfileType.business,
        displayName: 'Tech Innovations LLC',
        businessName: 'Tech Innovations LLC',
        ein: '12-3456789',
        createdAt: now.subtract(const Duration(days: 180)),
        lastUsedAt: now.subtract(const Duration(days: 2)),
        permissions: ProfilePermissions.forProfileType(ProfileType.business),
        limits: ProfileLimits.forProfileType(ProfileType.business),
        metadata: {
          'industry': 'Technology',
          'employee_count': 25,
          'annual_revenue': '5M-10M',
        },
      ),
    ];
  }

  // Switch to a different profile
  Future<bool> switchProfile(UserProfile profile) async {
    if (profile.id == _currentProfile?.id) return true;
    
    try {
      // Update last used timestamp
      profile = profile.copyWith(lastUsedAt: DateTime.now());
      
      // In production, update in database
      // await _supabase
      //     .from('user_profiles')
      //     .update({'last_used_at': profile.lastUsedAt.toIso8601String()})
      //     .eq('id', profile.id);
      
      _currentProfile = profile;
      
      // Update in local list
      final index = _userProfiles.indexWhere((p) => p.id == profile.id);
      if (index != -1) {
        _userProfiles[index] = profile;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error switching profile: $e');
      return false;
    }
  }

  // Create a new profile
  Future<UserProfile?> createProfile({
    required ProfileType type,
    required String displayName,
    String? businessName,
    String? ein,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    try {
      final newProfile = UserProfile(
        id: 'profile_${type.name}_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        type: type,
        displayName: displayName,
        businessName: businessName,
        ein: ein,
        createdAt: DateTime.now(),
        isPrimary: _userProfiles.isEmpty,
        permissions: ProfilePermissions.forProfileType(type),
        limits: ProfileLimits.forProfileType(type),
        metadata: metadata,
      );
      
      // In production, save to database
      // final response = await _supabase
      //     .from('user_profiles')
      //     .insert(newProfile.toJson())
      //     .select()
      //     .single();
      // 
      // final savedProfile = UserProfile.fromJson(response);
      
      _userProfiles.add(newProfile);
      
      // If this is the first profile, set as current
      if (_currentProfile == null) {
        _currentProfile = newProfile;
      }
      
      notifyListeners();
      return newProfile;
    } catch (e) {
      debugPrint('Error creating profile: $e');
      return null;
    }
  }

  // Update profile
  Future<bool> updateProfile(UserProfile profile) async {
    try {
      // In production, update in database
      // await _supabase
      //     .from('user_profiles')
      //     .update(profile.toJson())
      //     .eq('id', profile.id);
      
      final index = _userProfiles.indexWhere((p) => p.id == profile.id);
      if (index != -1) {
        _userProfiles[index] = profile;
        
        // Update current if it's the same profile
        if (_currentProfile?.id == profile.id) {
          _currentProfile = profile;
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Delete profile (cannot delete primary profile)
  Future<bool> deleteProfile(String profileId) async {
    final profile = _userProfiles.firstWhere((p) => p.id == profileId);
    if (profile.isPrimary) return false;
    
    try {
      // In production, delete from database
      // await _supabase
      //     .from('user_profiles')
      //     .delete()
      //     .eq('id', profileId);
      
      _userProfiles.removeWhere((p) => p.id == profileId);
      
      // If deleted profile was current, switch to primary
      if (_currentProfile?.id == profileId) {
        _currentProfile = _userProfiles.firstWhere((p) => p.isPrimary);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting profile: $e');
      return false;
    }
  }

  // Clear all data (for logout)
  void clear() {
    _currentProfile = null;
    _userProfiles = [];
    _isLoading = false;
    notifyListeners();
  }
}