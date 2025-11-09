import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../services/feature_service.dart';
import 'consistent_list_tile.dart';

/// Profile switcher bottom sheet
class ProfileSwitcherBottomSheet extends ConsumerStatefulWidget {
  const ProfileSwitcherBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileSwitcherBottomSheet(),
    );
  }

  @override
  ConsumerState<ProfileSwitcherBottomSheet> createState() => _ProfileSwitcherBottomSheetState();
}

class _ProfileSwitcherBottomSheetState extends ConsumerState<ProfileSwitcherBottomSheet> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_shimmerController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _switchProfile(UserProfile profile) async {
    // Animate out
    await _animationController.reverse();
    
    // Switch profile
    ref.read(profileProvider.notifier).switchProfile(profile.id);
    
    // Close sheet
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _addAccount() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed('/login', arguments: {'isAddAccount': true});
    }
  }

  void _signOut() async {
    await _animationController.reverse();
    ref.read(authProvider.notifier).signOut();
    ref.read(profileProvider.notifier).clearProfiles();
    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesListProvider);
    final activeProfile = ref.watch(activeProfileProvider);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: isDesktop ? 600 : double.infinity,
            ),
            margin: isDesktop 
                ? EdgeInsets.symmetric(
                    horizontal: (MediaQuery.of(context).size.width - 600) / 2,
                    vertical: 40,
                  )
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(24),
                bottom: isDesktop ? const Radius.circular(24) : Radius.zero,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Switch Profile',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      if (activeProfile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Logged in as ${activeProfile.firstName} ${activeProfile.lastName}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Profile list
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Current profiles
                      ...profiles.map((profile) {
                        final isActive = profile.id == activeProfile?.id;
                        return _buildProfileTile(
                          profile: profile,
                          isActive: isActive,
                          onTap: () => _switchProfile(profile),
                          theme: theme,
                        );
                      }),
                      
                      const Divider(height: 32),
                      
                      // Add account option
                      ConsistentListTile(
                        leading: ConsistentListTileLeading(
                          icon: Icons.add,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          iconColor: theme.colorScheme.onPrimaryContainer,
                        ),
                        title: const ConsistentListTileTitle(text: 'Add Another Membership'),
                        subtitle: const ConsistentListTileSubtitle(text: 'Sign in with a different profile'),
                        onTap: _addAccount,
                      ),
                      
                      // Sign out option
                      ConsistentListTile(
                        leading: ConsistentListTileLeading(
                          icon: Icons.logout,
                          backgroundColor: theme.colorScheme.errorContainer,
                          iconColor: theme.colorScheme.onErrorContainer,
                        ),
                        title: const ConsistentListTileTitle(text: 'Sign Out All'),
                        subtitle: const ConsistentListTileSubtitle(text: 'Sign out from all memberships'),
                        onTap: _signOut,
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTile({
    required UserProfile profile,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: isActive
          ? Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFD700), // Gold
                    const Color(0xFF9B59B6), // Purple
                    const Color(0xFFFF69B4), // Pink
                  ],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildTileContent(profile, isActive, onTap, theme),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: _buildTileContent(profile, isActive, onTap, theme),
            ),
    );
  }

  Widget _buildTileContent(UserProfile profile, bool isActive, VoidCallback onTap, ThemeData theme) {
    return ConsistentListTile(
        isSelected: isActive,
        enabled: !isActive,
        leading: Stack(
          children: [
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        _getMembershipColor(profile.membershipType).withOpacity(0.3),
                        _getMembershipColor(profile.membershipType).withOpacity(0.6),
                        _getMembershipColor(profile.membershipType).withOpacity(0.3),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      transform: GradientRotation(_shimmerAnimation.value * 2 * 3.14159),
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getMembershipColor(profile.membershipType).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${profile.firstName[0]}${profile.lastName[0]}'.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getMembershipColor(profile.membershipType),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (isActive)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 10,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
        title: ConsistentListTileTitle(
          text: profile.displayName,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
        subtitle: ConsistentListTileSubtitle(
          text: '${profile.membershipName.replaceAll(' Membership', '')} Membership',
        ),
        trailing: isActive
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                  ),
                ),
              )
            : null,
        onTap: onTap,
    );
  }

  Color _getMembershipColor(MembershipType type) {
    switch (type) {
      case MembershipType.general:
        return const Color(0xFF4ECDC4);
      case MembershipType.business:
        return const Color(0xFF6B5B95);
      case MembershipType.youth:
        return const Color(0xFFFF6B6B);
      case MembershipType.fiduciary:
        return const Color(0xFF1DB954);
      case MembershipType.premium:
        return const Color(0xFFF7B731);
      case MembershipType.student:
        return const Color(0xFF9B59B6);
    }
  }
}

/// Profile avatar widget for app bar
class ProfileAvatar extends ConsumerWidget {
  final double size;
  
  const ProfileAvatar({
    super.key,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final theme = Theme.of(context);

    if (activeProfile == null) {
      return const CircleAvatar(
        child: Icon(Icons.person),
      );
    }

    return GestureDetector(
      onTap: () => ProfileSwitcherBottomSheet.show(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _getMembershipColor(activeProfile.membershipType).withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            activeProfile.membershipIcon,
            style: TextStyle(fontSize: size * 0.5),
          ),
        ),
      ),
    );
  }

  Color _getMembershipColor(MembershipType type) {
    switch (type) {
      case MembershipType.general:
        return const Color(0xFF4ECDC4);
      case MembershipType.business:
        return const Color(0xFF6B5B95);
      case MembershipType.youth:
        return const Color(0xFFFF6B6B);
      case MembershipType.fiduciary:
        return const Color(0xFF1DB954);
      case MembershipType.premium:
        return const Color(0xFFF7B731);
      case MembershipType.student:
        return const Color(0xFF9B59B6);
    }
  }
}