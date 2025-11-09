import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/feature_service.dart';
import '../providers/profile_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/sound_service.dart';

class MembershipServices extends ConsumerWidget {
  const MembershipServices({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final featureService = FeatureService();
    
    // Update feature service with current membership type
    if (activeProfile != null) {
      featureService.updateMembershipType(activeProfile.membershipType);
    }

    final services = _getServicesForMembership(
      activeProfile?.membershipType ?? MembershipType.general,
      featureService,
    );

    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            child: _buildServiceCard(context, service),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getServicesForMembership(
    MembershipType membershipType,
    FeatureService featureService,
  ) {
    final allServices = [
      {
        'icon': Icons.swap_horiz,
        'title': 'transfer',
        'subtitle': 'Send money',
        'feature': 'transfers',
        'route': '/transfer',
        'color': Colors.blue,
      },
      {
        'icon': Icons.receipt_long,
        'title': 'payBills',
        'subtitle': 'Pay bills',
        'feature': 'bill_pay',
        'route': '/bill-pay',
        'color': Colors.green,
      },
      {
        'icon': Icons.analytics,
        'title': 'spendingAnalytics',
        'subtitle': 'Spending insights',
        'feature': 'spending_analytics',
        'route': '/spending-analytics',
        'color': Colors.purple,
      },
      {
        'icon': Icons.account_balance,
        'title': 'connectAccounts',
        'subtitle': 'Link accounts',
        'feature': 'connect_accounts',
        'route': '/connect-accounts',
        'color': Colors.orange,
      },
      {
        'icon': Icons.credit_card,
        'title': 'cardManagement',
        'subtitle': 'Manage cards',
        'feature': 'cards',
        'route': '/cards',
        'color': Colors.red,
      },
      {
        'icon': Icons.savings,
        'title': 'Goals',
        'subtitle': 'Save money',
        'feature': 'savings_goals',
        'route': '/savings-goals',
        'color': Colors.teal,
      },
      {
        'icon': Icons.trending_up,
        'title': 'Investments',
        'subtitle': 'Grow wealth',
        'feature': 'investments',
        'route': '/investments',
        'color': Colors.indigo,
      },
      {
        'icon': Icons.business,
        'title': 'Business',
        'subtitle': 'Manage business',
        'feature': 'multi_user_access',
        'route': '/business',
        'color': Colors.brown,
      },
      {
        'icon': Icons.account_balance_wallet,
        'title': 'Loans',
        'subtitle': 'Apply for loans',
        'feature': 'loans',
        'route': '/loans',
        'color': Colors.deepOrange,
      },
      {
        'icon': Icons.payment,
        'title': 'Merchant',
        'subtitle': 'Accept payments',
        'feature': 'merchant_services',
        'route': '/merchant',
        'color': Colors.pink,
      },
      {
        'icon': Icons.people,
        'title': 'Payroll',
        'subtitle': 'Manage payroll',
        'feature': 'payroll',
        'route': '/payroll',
        'color': Colors.cyan,
      },
      {
        'icon': Icons.assessment,
        'title': 'netWorth',
        'subtitle': 'Track wealth',
        'feature': 'net_worth',
        'route': '/net-worth',
        'color': Colors.deepPurple,
      },
    ];

    // Filter services based on membership type and feature access
    final availableServices = allServices.where((service) {
      return featureService.isFeatureEnabled(service['feature'] as String);
    }).toList();

    // Add membership-specific badges
    for (var service in availableServices) {
      final enhancements = featureService.getEnhancements(service['feature'] as String);
      final badge = _getBadgeForMembership(membershipType, enhancements);
      if (badge != null) {
        service['badge'] = badge;
      }
    }

    return availableServices;
  }

  String? _getBadgeForMembership(MembershipType membershipType, List<String> enhancements) {
    switch (membershipType) {
      case MembershipType.premium:
        return 'PREMIUM';
      case MembershipType.business:
        return enhancements.isNotEmpty ? 'ENHANCED' : null;
      case MembershipType.fiduciary:
        return 'TRUST';
      case MembershipType.youth:
        return 'YOUTH';
      case MembershipType.student:
        return 'STUDENT';
      case MembershipType.general:
        return null;
    }
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    return InkWell(
      onTap: () {
        // Play button tap sound
        SoundService().playButtonTap();
        
        if (service['route'] != null) {
          // Play navigation sound
          SoundService().playNavigation();
          Navigator.of(context).pushNamed(service['route']);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (service['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    service['icon'],
                    color: service['color'],
                    size: 24,
                  ),
                ),
                if (service['badge'] != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _getBadgeColor(service['badge']),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        service['badge'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getLocalizedTitle(context, service['title']),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Geist',
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              service['subtitle'],
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontFamily: 'Geist',
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedTitle(BuildContext context, String titleKey) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return titleKey;
    
    switch (titleKey) {
      case 'transfer':
        return localizations.transfer;
      case 'payBills':
        return localizations.payBills;
      case 'spendingAnalytics':
        return localizations.spendingAnalytics;
      case 'connectAccounts':
        return localizations.connectAccounts;
      case 'cardManagement':
        return localizations.cardManagement;
      case 'netWorth':
        return localizations.netWorth;
      default:
        return titleKey;
    }
  }

  Color _getBadgeColor(String badge) {
    switch (badge) {
      case 'PREMIUM':
        return Colors.amber;
      case 'ENHANCED':
        return Colors.blue;
      case 'TRUST':
        return Colors.green;
      case 'YOUTH':
        return Colors.orange;
      case 'STUDENT':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}