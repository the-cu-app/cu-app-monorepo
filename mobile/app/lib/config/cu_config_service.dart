import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enterprise-grade CU Configuration Service
/// Loads credit union branding, features, and limits from Supabase
class CUConfigService extends ChangeNotifier {
  static final CUConfigService _instance = CUConfigService._internal();
  factory CUConfigService() => _instance;
  CUConfigService._internal();

  final _supabase = Supabase.instance.client;

  // CU Branding
  String _cuId = 'demo';
  String _cuName = 'Demo Credit Union';
  String _cuDomain = 'demo.cu.app';
  String _cuShortName = 'DCU';
  String _logoUrl = '';
  String _primaryColor = '#0066CC';
  String _secondaryColor = '#4CAF50';

  // CU Details
  String _charterNumber = '';
  int _memberCount = 0;
  String _routingNumber = '';
  String _phone = '';
  String _supportEmail = '';

  // Feature Configuration
  Map<String, dynamic> _features = {};
  Map<String, dynamic> _limits = {};
  Map<String, dynamic> _apiEndpoints = {};

  bool _isInitialized = false;

  // Getters
  String get cuId => _cuId;
  String get cuName => _cuName;
  String get cuDomain => _cuDomain;
  String get cuShortName => _cuShortName;
  String get logoUrl => _logoUrl;
  String get primaryColor => _primaryColor;
  String get secondaryColor => _secondaryColor;
  String get charterNumber => _charterNumber;
  int get memberCount => _memberCount;
  String get routingNumber => _routingNumber;
  String get phone => _phone;
  String get supportEmail => _supportEmail;
  bool get isInitialized => _isInitialized;

  /// Initialize CU configuration from Supabase
  Future<void> initialize({required String cuId}) async {
    try {
      _cuId = cuId;

      // Load CU configuration from Supabase
      final response = await _supabase
          .from('domains')
          .select('''
            *,
            branding(*),
            features(*),
            cu_details(*),
            api_endpoints(*)
          ''')
          .eq('domain_name', '$cuId.app')
          .single();

      // Set branding
      if (response['branding'] != null) {
        final branding = response['branding'];
        _primaryColor = branding['primary_color'] ?? _primaryColor;
        _secondaryColor = branding['secondary_color'] ?? _secondaryColor;
        _logoUrl = branding['logo_url'] ?? '';
      }

      // Set CU details
      if (response['cu_details'] != null) {
        final details = response['cu_details'];
        _cuName = details['name'] ?? response['display_name'] ?? _cuName;
        _cuShortName = details['short_name'] ?? _cuName.substring(0, 3).toUpperCase();
        _charterNumber = details['charter_number'] ?? '';
        _memberCount = details['members'] ?? 0;
        _routingNumber = details['routing_number'] ?? '';
        _phone = details['phone'] ?? '';
        _supportEmail = details['email'] ?? 'support@$cuDomain';
      } else {
        _cuName = response['display_name'] ?? _cuName;
        _cuShortName = _cuName.substring(0, 3).toUpperCase();
      }

      _cuDomain = response['domain_name'] ?? _cuDomain;

      // Set features
      if (response['features'] != null) {
        _features = Map<String, dynamic>.from(response['features']);
      }

      // Set API endpoints
      if (response['api_endpoints'] != null) {
        _apiEndpoints = Map<String, dynamic>.from(response['api_endpoints']);
      }

      _isInitialized = true;
      notifyListeners();

      debugPrint('✅ CU Config initialized: $_cuName ($_cuShortName)');
    } catch (e) {
      debugPrint('❌ Failed to load CU config: $e');
      // Use demo defaults
      _setDemoDefaults();
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Check if a feature is enabled
  bool isFeatureEnabled(String featureKey) {
    return _features[featureKey] == true;
  }

  /// Get feature limit
  dynamic getLimit(String limitKey) {
    return _limits[limitKey];
  }

  /// Get API endpoint
  String getApiEndpoint(String endpointKey) {
    return _apiEndpoints[endpointKey] ?? '';
  }

  /// Get support URL for redesign requests
  String getSupportUrl() {
    return 'https://www.google.com/search?q=${Uri.encodeComponent(_cuName)}+redesign+request';
  }

  /// Get test email for development
  String getTestEmail(String type) {
    return 'test.$type@$_cuDomain';
  }

  /// Get product name with CU branding
  String getProductName(String baseProduct) {
    return '$_cuShortName $baseProduct';
  }

  /// Set demo defaults for testing
  void _setDemoDefaults() {
    _cuId = 'demo';
    _cuName = 'Demo Credit Union';
    _cuDomain = 'demo.cu.app';
    _cuShortName = 'DCU';
    _supportEmail = 'support@demo.cu.app';
    _features = {
      'core_banking': true,
      'transfers': true,
      'bill_pay': true,
      'mobile_deposit': true,
      'cards': true,
      'p2p_payments': true,
      'insights': true,
    };
  }

  /// Reset configuration
  void reset() {
    _isInitialized = false;
    _features.clear();
    _limits.clear();
    _apiEndpoints.clear();
    notifyListeners();
  }
}
