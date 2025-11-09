import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:provider/provider.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileSwitcherScreen extends StatelessWidget {
  final Function(UserProfile) onProfileSelected;

  const ProfileSwitcherScreen({
    super.key,
    required this.onProfileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileService>(
      builder: (context, profileService, child) {
        final profiles = profileService.userProfiles;
        final currentProfile = profileService.currentProfile;

        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Switch Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a profile to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: profiles.length + 1,
                  itemBuilder: (context, index) {
                    if (index == profiles.length) {
                      // Add new profile button
                      return _buildAddProfileTile(context);
                    }
                    
                    final profile = profiles[index];
                    final isSelected = profile.id == currentProfile?.id;
                    
                    return _buildProfileTile(
                      context,
                      profile,
                      isSelected,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTile(
    BuildContext context,
    UserProfile profile,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: () => onProfileSelected(profile),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white
                      : _getProfileColor(profile.type),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Icon(
                    _getProfileIcon(profile.type),
                    color: isSelected 
                        ? Colors.black
                        : Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.type.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected 
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (profile.businessName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.businessName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected 
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddProfileTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to profile creation
          _showCreateProfileDialog(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.grey.shade600,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a new membership profile',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProfileTypeOption(
              context,
              ProfileType.business,
              'Apply for Business Membership',
              'Manage your business finances',
            ),
            const SizedBox(height: 12),
            _buildProfileTypeOption(
              context,
              ProfileType.youth,
              'Open Youth Account',
              'Start saving early (Under 18)',
            ),
            const SizedBox(height: 12),
            _buildProfileTypeOption(
              context,
              ProfileType.fiduciary,
              'Create Fiduciary Account',
              'Manage trust or estate',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTypeOption(
    BuildContext context,
    ProfileType type,
    String title,
    String subtitle,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // Navigate to profile creation flow
        CUSnackBar.show(context, message: Creating ${type.displayName} profile...);
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getProfileColor(type),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Icon(
                  _getProfileIcon(type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
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

  IconData _getProfileIcon(ProfileType type) {
    switch (type) {
      case ProfileType.personal:
        return Icons.person;
      case ProfileType.business:
        return Icons.business;
      case ProfileType.youth:
        return Icons.school;
      case ProfileType.fiduciary:
        return Icons.account_balance;
    }
  }
}