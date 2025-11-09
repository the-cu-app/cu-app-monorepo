import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/feature_service.dart';
import '../config/cu_config_service.dart';

/// Test user profiles
class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final MembershipType membershipType;
  final String avatarUrl;
  final bool isActive;
  final Map<String, dynamic> metadata;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.membershipType,
    this.avatarUrl = '',
    this.isActive = false,
    this.metadata = const {},
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    MembershipType? membershipType,
    String? avatarUrl,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      membershipType: membershipType ?? this.membershipType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  String get displayName => '$firstName $lastName';
  
  String get initials {
    String firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }
  
  String get membershipName {
    switch (membershipType) {
      case MembershipType.general:
        return 'Personal';
      case MembershipType.business:
        return 'Business';
      case MembershipType.youth:
        return 'Youth';
      case MembershipType.fiduciary:
        return 'Fiduciary';
      case MembershipType.premium:
        return 'Premium';
      case MembershipType.student:
        return 'Student';
    }
  }

  String get membershipIcon {
    switch (membershipType) {
      case MembershipType.general:
        return '👤';
      case MembershipType.business:
        return '💼';
      case MembershipType.youth:
        return '🎓';
      case MembershipType.fiduciary:
        return '🏛️';
      case MembershipType.premium:
        return '💎';
      case MembershipType.student:
        return '📚';
    }
  }
}

/// Test user credentials
class TestCredentials {
  static const String password = "123asdfghjkl;'";
  
  static final List<UserProfile> testProfiles = [
    UserProfile(
      id: 'test-user-general',
      email: 'test.general@${CUConfigService().cuDomain}',
      firstName: 'Kyle',
      lastName: 'Kusche',
      membershipType: MembershipType.general,
      avatarUrl: 'https://api.dicebear.com/7.x/initials/svg?seed=KK&backgroundColor=4ECDC4',
      metadata: {
        'accountNumber': '1001234567',
        'joinDate': '2024-01-15',
        'branch': 'Main Street',
      },
    ),
    UserProfile(
      id: 'test-user-business',
      email: 'test.business@${CUConfigService().cuDomain}',
      firstName: 'Kyle',
      lastName: 'Kusche (Business)',
      membershipType: MembershipType.business,
      avatarUrl: 'https://api.dicebear.com/7.x/initials/svg?seed=KB&backgroundColor=6B5B95',
      metadata: {
        'accountNumber': '2001234567',
        'businessName': 'Kusche Enterprises',
        'ein': '12-3456789',
        'joinDate': '2023-06-10',
      },
    ),
    UserProfile(
      id: 'test-user-youth',
      email: 'test.youth@${CUConfigService().cuDomain}',
      firstName: 'Kyle',
      lastName: 'Jr',
      membershipType: MembershipType.youth,
      avatarUrl: 'https://api.dicebear.com/7.x/initials/svg?seed=KJ&backgroundColor=FF6B6B',
      metadata: {
        'accountNumber': '3001234567',
        'age': 16,
        'school': 'Central High',
        'parentAccount': '1001234567',
      },
    ),
    UserProfile(
      id: 'test-user-fiduciary',
      email: 'test.fiduciary@${CUConfigService().cuDomain}',
      firstName: 'Kyle',
      lastName: 'Kusche (Trust)',
      membershipType: MembershipType.fiduciary,
      avatarUrl: 'https://api.dicebear.com/7.x/initials/svg?seed=KT&backgroundColor=1DB954',
      metadata: {
        'accountNumber': '4001234567',
        'trustName': 'Kusche Family Trust',
        'trustees': ['Kyle Kusche', 'Jane Kusche'],
        'establishedDate': '2022-03-20',
      },
    ),
  ];

  static UserProfile? authenticate(String email, String password) {
    if (password != TestCredentials.password) return null;
    
    try {
      return testProfiles.firstWhere(
        (profile) => profile.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Profile management state
class ProfileState {
  final List<UserProfile> profiles;
  final UserProfile? activeProfile;
  final bool isLoading;
  final String? error;

  ProfileState({
    this.profiles = const [],
    this.activeProfile,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    List<UserProfile>? profiles,
    UserProfile? activeProfile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profiles: profiles ?? this.profiles,
      activeProfile: activeProfile ?? this.activeProfile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Profile notifier for managing multiple profiles
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(ProfileState());

  void loadProfiles() {
    state = state.copyWith(isLoading: true);
    
    // In a real app, this would load from persistent storage
    // For now, we'll use test profiles if logged in
    state = state.copyWith(
      profiles: [], // Start empty, will be populated on login
      isLoading: false,
    );
  }

  void addProfile(UserProfile profile) {
    final updatedProfiles = [...state.profiles, profile];
    final isFirstProfile = state.profiles.isEmpty;
    
    state = state.copyWith(
      profiles: updatedProfiles,
      activeProfile: isFirstProfile ? profile : state.activeProfile,
    );
    
    // Update feature service with active profile's membership
    if (isFirstProfile) {
      FeatureService().updateMembershipType(profile.membershipType);
    }
  }

  void switchProfile(String profileId) {
    final profile = state.profiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => state.activeProfile!,
    );
    
    if (profile.id != state.activeProfile?.id) {
      // Update all profiles to mark the new one as active
      final updatedProfiles = state.profiles.map((p) {
        return p.copyWith(isActive: p.id == profileId);
      }).toList();
      
      state = state.copyWith(
        profiles: updatedProfiles,
        activeProfile: profile,
      );
      
      // Update feature service with new membership type
      FeatureService().updateMembershipType(profile.membershipType);
    }
  }

  void removeProfile(String profileId) {
    final updatedProfiles = state.profiles.where((p) => p.id != profileId).toList();
    
    // If we removed the active profile, switch to the first remaining one
    UserProfile? newActive = state.activeProfile;
    if (state.activeProfile?.id == profileId && updatedProfiles.isNotEmpty) {
      newActive = updatedProfiles.first;
      FeatureService().updateMembershipType(newActive.membershipType);
    } else if (updatedProfiles.isEmpty) {
      newActive = null;
    }
    
    state = state.copyWith(
      profiles: updatedProfiles,
      activeProfile: newActive,
    );
  }

  void clearProfiles() {
    state = ProfileState();
  }

  void loginWithTestAccount(String email, String password) {
    state = state.copyWith(isLoading: true, error: null);
    
    final profile = TestCredentials.authenticate(email, password);
    
    if (profile != null) {
      // Check if profile already exists
      final existingIndex = state.profiles.indexWhere((p) => p.id == profile.id);
      
      if (existingIndex == -1) {
        // Add new profile
        addProfile(profile.copyWith(isActive: true));
      } else {
        // Switch to existing profile
        switchProfile(profile.id);
      }
      
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid email or password',
      );
    }
  }
}

/// Providers
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});

final activeProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(profileProvider).activeProfile;
});

final profilesListProvider = Provider<List<UserProfile>>((ref) {
  return ref.watch(profileProvider).profiles;
});