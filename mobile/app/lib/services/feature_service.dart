import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Feature flag service for managing feature access based on membership type
/// and other configuration settings
class FeatureService extends ChangeNotifier {
  static final FeatureService _instance = FeatureService._internal();
  factory FeatureService() => _instance;
  FeatureService._internal();

  final _supabase = Supabase.instance.client;
  
  // Current user's membership type
  MembershipType _membershipType = MembershipType.general;
  
  // Feature configuration cache
  Map<String, FeatureConfig> _featureConfigs = {};
  
  // Override flags for testing
  Map<String, bool> _overrides = {};
  
  MembershipType get membershipType => _membershipType;

  /// Initialize the feature service with user data
  Future<void> initialize() async {
    await _loadUserMembership();
    await _loadFeatureConfigs();
    notifyListeners();
  }

  /// Load user's membership type from database
  Future<void> _loadUserMembership() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('user_profiles')
          .select('membership_type')
          .eq('user_id', user.id)
          .single();

      final membershipStr = response['membership_type'] as String? ?? 'general';
      _membershipType = MembershipType.values.firstWhere(
        (m) => m.name == membershipStr,
        orElse: () => MembershipType.general,
      );
    } catch (e) {
      print('Error loading membership type: $e');
      _membershipType = MembershipType.general;
    }
  }

  /// Load feature configurations
  Future<void> _loadFeatureConfigs() async {
    // Define default feature configurations
    // Both memberships get most features, with some enhancements for business
    
    _featureConfigs = {
      // Core Banking Features - Available to ALL
      'cards': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        businessEnhancements: ['virtual_cards', 'bulk_card_orders', 'employee_cards'],
      ),
      
      'transfers': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        limits: {
          'general': {'daily': 10000, 'monthly': 50000},
          'business': {'daily': 100000, 'monthly': 1000000},
        },
      ),
      
      'bill_pay': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        businessEnhancements: ['bulk_payments', 'vendor_management', 'approval_workflow'],
      ),
      
      'mobile_deposit': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        limits: {
          'general': {'daily': 5000, 'monthly': 20000},
          'business': {'daily': 50000, 'monthly': 500000},
        },
      ),
      
      // Analytics Features - Available to ALL
      'spending_analytics': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        businessEnhancements: ['category_management', 'export_reports', 'team_analytics'],
      ),
      
      'budgets': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        businessEnhancements: ['department_budgets', 'multi_user_budgets'],
      ),
      
      'net_worth': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
      ),
      
      // Investment Features
      'investments': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        businessEnhancements: ['business_investment_accounts', 'treasury_management'],
      ),
      
      // Loan Features
      'loans': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        businessEnhancements: ['business_loans', 'line_of_credit', 'equipment_financing'],
      ),
      
      // Account Features
      'connect_accounts': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        limits: {
          'general': {'max_connections': 10},
          'business': {'max_connections': 50},
        },
      ),
      
      'savings_goals': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
      ),
      
      // Business-Specific Features
      'multi_user_access': FeatureConfig(
        enabled: true,
        generalAccess: false, // Business only
        businessAccess: true,
      ),
      
      'accounting_integration': FeatureConfig(
        enabled: true,
        generalAccess: false, // Business only
        businessAccess: true,
      ),
      
      'payroll': FeatureConfig(
        enabled: true,
        generalAccess: false, // Business only
        businessAccess: true,
      ),
      
      'merchant_services': FeatureConfig(
        enabled: true,
        generalAccess: false, // Business only
        businessAccess: true,
      ),
      
      // Enhanced Features for Business
      'wire_transfers': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        limits: {
          'general': {'requires_verification': true, 'daily': 25000},
          'business': {'requires_verification': false, 'daily': 500000},
        },
      ),
      
      'ach_transfers': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        businessEnhancements: ['batch_ach', 'ach_positive_pay'],
      ),
      
      // Security Features - Available to ALL
      'two_factor_auth': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
      ),
      
      'biometric_auth': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
      ),
      
      // Support Features
      'chat_support': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        businessEnhancements: ['priority_support', 'dedicated_rep'],
      ),
      
      'document_upload': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        limits: {
          'general': {'storage_gb': 5},
          'business': {'storage_gb': 100},
        },
      ),
      
      // Rewards and Benefits
      'cashback': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        limits: {
          'general': {'rate': 0.01}, // 1% cashback
          'business': {'rate': 0.02}, // 2% cashback
        },
      ),
      
      'atm_fee_reimbursement': FeatureConfig(
        enabled: true,
        generalAccess: true,
        businessAccess: true,
        limits: {
          'general': {'monthly_reimbursement': 10},
          'business': {'monthly_reimbursement': 50},
        },
      ),
    };
  }

  /// Check if a feature is enabled for the current user
  bool isFeatureEnabled(String featureKey) {
    // Check for override first
    if (_overrides.containsKey(featureKey)) {
      return _overrides[featureKey]!;
    }

    final config = _featureConfigs[featureKey];
    if (config == null || !config.enabled) return false;

    switch (_membershipType) {
      case MembershipType.general:
        return config.generalAccess;
      case MembershipType.business:
        return config.businessAccess;
      case MembershipType.premium:
        // Premium gets everything
        return true;
      case MembershipType.student:
        // Student gets same as general for now
        return config.generalAccess;
      case MembershipType.youth:
        // Youth gets general features but with restrictions
        return config.generalAccess && !_isRestrictedForYouth(featureKey);
      case MembershipType.fiduciary:
        // Fiduciary gets limited features for trust management
        return config.generalAccess && _isAllowedForFiduciary(featureKey);
    }
  }
  
  /// Check if feature is restricted for youth accounts
  bool _isRestrictedForYouth(String featureKey) {
    final restrictedFeatures = [
      'wire_transfers',
      'merchant_services',
      'loans',
      'investments',
      'ach_transfers',
      'payroll',
    ];
    return restrictedFeatures.contains(featureKey);
  }
  
  /// Check if feature is allowed for fiduciary accounts
  bool _isAllowedForFiduciary(String featureKey) {
    final allowedFeatures = [
      'transfers',
      'bill_pay',
      'investments',
      'net_worth',
      'spending_analytics',
      'cards',
      'mobile_deposit',
      'savings_goals',
      'budgets',
      'two_factor_auth',
      'biometric_auth',
    ];
    return allowedFeatures.contains(featureKey);
  }

  /// Get feature limit for the current user
  dynamic getFeatureLimit(String featureKey, String limitKey) {
    final config = _featureConfigs[featureKey];
    if (config == null) return null;

    final limits = config.limits;
    if (limits == null) return null;

    final membershipLimits = limits[_membershipType.name] ?? limits['general'];
    return membershipLimits?[limitKey];
  }

  /// Check if user has a specific enhancement
  bool hasEnhancement(String featureKey, String enhancement) {
    if (_membershipType != MembershipType.business) return false;

    final config = _featureConfigs[featureKey];
    return config?.businessEnhancements?.contains(enhancement) ?? false;
  }

  /// Get all enhancements for a feature
  List<String> getEnhancements(String featureKey) {
    if (_membershipType != MembershipType.business) return [];

    final config = _featureConfigs[featureKey];
    return config?.businessEnhancements ?? [];
  }

  /// Override a feature flag (for testing/demos)
  void setOverride(String featureKey, bool enabled) {
    _overrides[featureKey] = enabled;
    notifyListeners();
  }

  /// Clear all overrides
  void clearOverrides() {
    _overrides.clear();
    notifyListeners();
  }

  /// Update membership type
  Future<void> updateMembershipType(MembershipType type) async {
    _membershipType = type;
    
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase
            .from('user_profiles')
            .update({'membership_type': type.name})
            .eq('user_id', user.id);
      }
    } catch (e) {
      print('Error updating membership type: $e');
    }
    
    notifyListeners();
  }

  /// Get display configuration for UI
  FeatureDisplay getFeatureDisplay(String featureKey) {
    final config = _featureConfigs[featureKey];
    final isEnabled = isFeatureEnabled(featureKey);
    final enhancements = getEnhancements(featureKey);
    
    return FeatureDisplay(
      enabled: isEnabled,
      showBadge: enhancements.isNotEmpty && _membershipType == MembershipType.business,
      badgeText: _membershipType == MembershipType.business ? 'Enhanced' : null,
      enhancements: enhancements,
    );
  }

  /// Check if user should see business features
  bool get isBusinessMember => _membershipType == MembershipType.business;
  
  /// Check if user should see premium features
  bool get isPremiumMember => _membershipType == MembershipType.premium;
  
  /// Get membership display name
  String get membershipDisplayName {
    switch (_membershipType) {
      case MembershipType.general:
        return 'Personal';
      case MembershipType.business:
        return 'Business';
      case MembershipType.premium:
        return 'Premium';
      case MembershipType.student:
        return 'Student';
      case MembershipType.youth:
        return 'Youth';
      case MembershipType.fiduciary:
        return 'Fiduciary';
    }
  }
}

/// Membership types
enum MembershipType {
  general,    // Personal/General membership
  business,   // Business membership with enhanced features
  premium,    // Premium membership with all features
  student,    // Student membership with special pricing
  youth,      // Youth membership for minors
  fiduciary,  // Fiduciary/Trust accounts
}

/// Feature configuration
class FeatureConfig {
  final bool enabled;
  final bool generalAccess;
  final bool businessAccess;
  final Map<String, dynamic>? limits;
  final List<String>? businessEnhancements;

  FeatureConfig({
    required this.enabled,
    required this.generalAccess,
    required this.businessAccess,
    this.limits,
    this.businessEnhancements,
  });
}

/// Feature display configuration for UI
class FeatureDisplay {
  final bool enabled;
  final bool showBadge;
  final String? badgeText;
  final List<String> enhancements;

  FeatureDisplay({
    required this.enabled,
    required this.showBadge,
    this.badgeText,
    required this.enhancements,
  });
}