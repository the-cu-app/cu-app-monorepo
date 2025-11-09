import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MerchantLogoService {
  static final MerchantLogoService _instance = MerchantLogoService._internal();
  factory MerchantLogoService() => _instance;
  MerchantLogoService._internal();

  // Cache for merchant logos
  final Map<String, MerchantInfo> _cache = {};
  SharedPreferences? _prefs;

  // API endpoints (using Clearbit for logos)
  static const String _clearbitLogoApi = 'https://logo.clearbit.com/';
  static const String _brandfetchApi = 'https://cdn.brandfetch.io/';

  // Local merchant database
  static final Map<String, MerchantInfo> _merchantDatabase = {
    // Food & Dining
    'starbucks': MerchantInfo(
      name: 'Starbucks',
      domain: 'starbucks.com',
      primaryColor: Color(0xFF00704A),
      category: 'Food & Dining',
      subcategory: 'Coffee Shops',
    ),
    'mcdonalds': MerchantInfo(
      name: 'McDonald\'s',
      domain: 'mcdonalds.com',
      primaryColor: Color(0xFFFFC72C),
      category: 'Food & Dining',
      subcategory: 'Fast Food',
    ),
    'chipotle': MerchantInfo(
      name: 'Chipotle',
      domain: 'chipotle.com',
      primaryColor: Color(0xFF8B2C34),
      category: 'Food & Dining',
      subcategory: 'Fast Casual',
    ),
    'whole foods': MerchantInfo(
      name: 'Whole Foods',
      domain: 'wholefoodsmarket.com',
      primaryColor: Color(0xFF00674B),
      category: 'Food & Dining',
      subcategory: 'Groceries',
    ),
    'trader joe': MerchantInfo(
      name: 'Trader Joe\'s',
      domain: 'traderjoes.com',
      primaryColor: Color(0xFFD9002C),
      category: 'Food & Dining',
      subcategory: 'Groceries',
    ),
    
    // Shopping
    'amazon': MerchantInfo(
      name: 'Amazon',
      domain: 'amazon.com',
      primaryColor: Color(0xFFFF9900),
      category: 'Shopping',
      subcategory: 'E-commerce',
    ),
    'target': MerchantInfo(
      name: 'Target',
      domain: 'target.com',
      primaryColor: Color(0xFFCC0000),
      category: 'Shopping',
      subcategory: 'Retail',
    ),
    'walmart': MerchantInfo(
      name: 'Walmart',
      domain: 'walmart.com',
      primaryColor: Color(0xFF0071DC),
      category: 'Shopping',
      subcategory: 'Retail',
    ),
    'best buy': MerchantInfo(
      name: 'Best Buy',
      domain: 'bestbuy.com',
      primaryColor: Color(0xFF0046BE),
      category: 'Shopping',
      subcategory: 'Electronics',
    ),
    
    // Transportation
    'uber': MerchantInfo(
      name: 'Uber',
      domain: 'uber.com',
      primaryColor: Color(0xFF000000),
      category: 'Transportation',
      subcategory: 'Rideshare',
    ),
    'lyft': MerchantInfo(
      name: 'Lyft',
      domain: 'lyft.com',
      primaryColor: Color(0xFFFF00BF),
      category: 'Transportation',
      subcategory: 'Rideshare',
    ),
    'delta': MerchantInfo(
      name: 'Delta Airlines',
      domain: 'delta.com',
      primaryColor: Color(0xFF003366),
      category: 'Transportation',
      subcategory: 'Airlines',
    ),
    
    // Entertainment
    'netflix': MerchantInfo(
      name: 'Netflix',
      domain: 'netflix.com',
      primaryColor: Color(0xFFE50914),
      category: 'Entertainment',
      subcategory: 'Streaming',
    ),
    'spotify': MerchantInfo(
      name: 'Spotify',
      domain: 'spotify.com',
      primaryColor: Color(0xFF1DB954),
      category: 'Entertainment',
      subcategory: 'Streaming',
    ),
    'disney': MerchantInfo(
      name: 'Disney+',
      domain: 'disneyplus.com',
      primaryColor: Color(0xFF0083D0),
      category: 'Entertainment',
      subcategory: 'Streaming',
    ),
    'apple': MerchantInfo(
      name: 'Apple',
      domain: 'apple.com',
      primaryColor: Color(0xFF000000),
      category: 'Technology',
      subcategory: 'Electronics',
    ),
    
    // Utilities & Services
    'verizon': MerchantInfo(
      name: 'Verizon',
      domain: 'verizon.com',
      primaryColor: Color(0xFFEE0000),
      category: 'Utilities',
      subcategory: 'Phone',
    ),
    'at&t': MerchantInfo(
      name: 'AT&T',
      domain: 'att.com',
      primaryColor: Color(0xFF00A8E0),
      category: 'Utilities',
      subcategory: 'Phone',
    ),
    'comcast': MerchantInfo(
      name: 'Comcast',
      domain: 'comcast.com',
      primaryColor: Color(0xFF000000),
      category: 'Utilities',
      subcategory: 'Internet',
    ),
    
    // Gas Stations
    'shell': MerchantInfo(
      name: 'Shell',
      domain: 'shell.com',
      primaryColor: Color(0xFFFFCD00),
      category: 'Transportation',
      subcategory: 'Gas Station',
    ),
    'exxon': MerchantInfo(
      name: 'Exxon',
      domain: 'exxon.com',
      primaryColor: Color(0xFFED1C24),
      category: 'Transportation',
      subcategory: 'Gas Station',
    ),
    'chevron': MerchantInfo(
      name: 'Chevron',
      domain: 'chevron.com',
      primaryColor: Color(0xFF0066CC),
      category: 'Transportation',
      subcategory: 'Gas Station',
    ),
  };

  // Initialize service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCachedLogos();
  }

  // Load cached logos from local storage
  Future<void> _loadCachedLogos() async {
    final cachedData = _prefs?.getString('merchant_logos_cache');
    if (cachedData != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(cachedData);
        decoded.forEach((key, value) {
          _cache[key] = MerchantInfo.fromJson(value);
        });
      } catch (e) {
        debugPrint('Error loading cached logos: $e');
      }
    }
  }

  // Save cache to local storage
  Future<void> _saveCacheToStorage() async {
    final Map<String, dynamic> cacheData = {};
    _cache.forEach((key, value) {
      cacheData[key] = value.toJson();
    });
    await _prefs?.setString('merchant_logos_cache', jsonEncode(cacheData));
  }

  // Get merchant info and logo
  MerchantInfo getMerchantInfo(String merchantName) {
    final cleanName = _cleanMerchantName(merchantName);
    
    // Check cache first
    if (_cache.containsKey(cleanName)) {
      return _cache[cleanName]!;
    }
    
    // Check local database
    final searchKey = cleanName.toLowerCase();
    for (final entry in _merchantDatabase.entries) {
      if (searchKey.contains(entry.key)) {
        _cache[cleanName] = entry.value;
        _saveCacheToStorage();
        return entry.value;
      }
    }
    
    // Generate info for unknown merchant
    final unknownMerchant = MerchantInfo(
      name: cleanName,
      domain: _generateDomain(cleanName),
      primaryColor: _generateColor(cleanName),
      category: 'Other',
      subcategory: 'General',
    );
    
    _cache[cleanName] = unknownMerchant;
    _saveCacheToStorage();
    return unknownMerchant;
  }

  // Get logo URL
  String? getLogoUrl(String merchantName) {
    final info = getMerchantInfo(merchantName);
    if (info.domain != null) {
      // Use Clearbit API for logo
      return '$_clearbitLogoApi${info.domain}';
    }
    return null;
  }

  // Clean merchant name
  String _cleanMerchantName(String name) {
    return name
        .replaceAll(RegExp(r'\s+\d{4,}'), '') // Remove trailing numbers
        .replaceAll(RegExp(r'\s+#\d+'), '') // Remove store numbers
        .replaceAll(RegExp(r'\*'), '') // Remove asterisks
        .replaceAll(RegExp(r'\s+\-\s+.*'), '') // Remove descriptions after dash
        .trim();
  }

  // Generate domain from merchant name
  String _generateDomain(String merchantName) {
    final words = merchantName.toLowerCase().split(' ');
    if (words.isEmpty) return '';
    return '${words.first}.com';
  }

  // Generate color from merchant name (deterministic)
  Color _generateColor(String merchantName) {
    final hash = merchantName.hashCode;
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }

  // Get category icon
  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.bolt;
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      case 'services':
        return Icons.build;
      case 'fitness':
        return Icons.fitness_center;
      default:
        return Icons.store;
    }
  }

  // Batch fetch merchant info
  Future<Map<String, MerchantInfo>> batchGetMerchantInfo(List<String> merchantNames) async {
    final results = <String, MerchantInfo>{};
    
    for (final name in merchantNames) {
      results[name] = getMerchantInfo(name);
    }
    
    return results;
  }

  // Clear cache
  void clearCache() {
    _cache.clear();
    _prefs?.remove('merchant_logos_cache');
  }
}

// Merchant info model
class MerchantInfo {
  final String name;
  final String? domain;
  final Color primaryColor;
  final String category;
  final String subcategory;
  final String? logoUrl;

  MerchantInfo({
    required this.name,
    this.domain,
    required this.primaryColor,
    required this.category,
    required this.subcategory,
    this.logoUrl,
  });

  factory MerchantInfo.fromJson(Map<String, dynamic> json) {
    return MerchantInfo(
      name: json['name'],
      domain: json['domain'],
      primaryColor: Color(json['primaryColor']),
      category: json['category'],
      subcategory: json['subcategory'],
      logoUrl: json['logoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'domain': domain,
      'primaryColor': primaryColor.value,
      'category': category,
      'subcategory': subcategory,
      'logoUrl': logoUrl,
    };
  }
}

// Merchant logo widget
class MerchantLogo extends StatelessWidget {
  final String merchantName;
  final double size;
  final bool showFallback;

  const MerchantLogo({
    super.key,
    required this.merchantName,
    this.size = 40,
    this.showFallback = true,
  });

  @override
  Widget build(BuildContext context) {
    final logoService = MerchantLogoService();
    final merchantInfo = logoService.getMerchantInfo(merchantName);
    final logoUrl = logoService.getLogoUrl(merchantName);

    if (logoUrl != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.network(
            logoUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallback(merchantInfo, context);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildFallback(merchantInfo, context);
            },
          ),
        ),
      );
    }

    return _buildFallback(merchantInfo, context);
  }

  Widget _buildFallback(MerchantInfo info, BuildContext context) {
    if (!showFallback) return const SizedBox.shrink();
    
    final initial = info.name.isNotEmpty ? info.name[0].toUpperCase() : '?';
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: info.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}