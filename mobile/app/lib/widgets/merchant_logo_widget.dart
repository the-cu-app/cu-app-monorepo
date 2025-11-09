import 'package:flutter/material.dart';

class MerchantLogoWidget extends StatelessWidget {
  final String merchantName;
  final String? category;
  final double size;
  
  const MerchantLogoWidget({
    super.key,
    required this.merchantName,
    this.category,
    this.size = 48,
  });
  
  // Map merchant names to logo URLs from CDNs
  static const Map<String, String> _logoUrls = {
    'starbucks': 'https://logo.clearbit.com/starbucks.com',
    'whole foods': 'https://logo.clearbit.com/wholefoodsmarket.com',
    'netflix': 'https://logo.clearbit.com/netflix.com',
    'shell': 'https://logo.clearbit.com/shell.com',
    'amazon': 'https://logo.clearbit.com/amazon.com',
    'target': 'https://logo.clearbit.com/target.com',
    'uber': 'https://logo.clearbit.com/uber.com',
    'spotify': 'https://logo.clearbit.com/spotify.com',
    'cvs pharmacy': 'https://logo.clearbit.com/cvs.com',
    'apple store': 'https://logo.clearbit.com/apple.com',
    'chipotle': 'https://logo.clearbit.com/chipotle.com',
    'home depot': 'https://logo.clearbit.com/homedepot.com',
    'nike': 'https://logo.clearbit.com/nike.com',
    'mcdonalds': 'https://logo.clearbit.com/mcdonalds.com',
    'walmart': 'https://logo.clearbit.com/walmart.com',
    'best buy': 'https://logo.clearbit.com/bestbuy.com',
    'costco': 'https://logo.clearbit.com/costco.com',
    'walgreens': 'https://logo.clearbit.com/walgreens.com',
    'chase': 'https://logo.clearbit.com/chase.com',
    'bank of america': 'https://logo.clearbit.com/bankofamerica.com',
    'wells fargo': 'https://logo.clearbit.com/wellsfargo.com',
    'venmo': 'https://logo.clearbit.com/venmo.com',
    'paypal': 'https://logo.clearbit.com/paypal.com',
    'zelle': 'https://logo.clearbit.com/zellepay.com',
  };
  
  String? _getLogoUrl() {
    final lowerName = merchantName.toLowerCase();
    
    // Try exact match first
    if (_logoUrls.containsKey(lowerName)) {
      return _logoUrls[lowerName];
    }
    
    // Try partial match
    for (final entry in _logoUrls.entries) {
      if (lowerName.contains(entry.key) || entry.key.contains(lowerName)) {
        return entry.value;
      }
    }
    
    return null;
  }
  
  IconData _getCategoryIcon() {
    final cat = (category ?? '').toLowerCase();
    
    if (cat.contains('food') || cat.contains('restaurant') || cat.contains('dining')) {
      return Icons.restaurant;
    } else if (cat.contains('coffee')) {
      return Icons.local_cafe;
    } else if (cat.contains('grocery') || cat.contains('market')) {
      return Icons.shopping_cart;
    } else if (cat.contains('transport') || cat.contains('gas')) {
      return Icons.directions_car;
    } else if (cat.contains('entertainment') || cat.contains('movie')) {
      return Icons.movie;
    } else if (cat.contains('shopping') || cat.contains('retail')) {
      return Icons.shopping_bag;
    } else if (cat.contains('health') || cat.contains('medical') || cat.contains('pharmacy')) {
      return Icons.medical_services;
    } else if (cat.contains('transfer') || cat.contains('payment')) {
      return Icons.swap_horiz;
    } else {
      return Icons.store;
    }
  }
  
  Color _getCategoryColor() {
    final cat = (category ?? '').toLowerCase();
    
    if (cat.contains('food') || cat.contains('dining')) {
      return Colors.orange.shade600;
    } else if (cat.contains('coffee')) {
      return Colors.brown.shade600;
    } else if (cat.contains('grocery')) {
      return Colors.green.shade600;
    } else if (cat.contains('transport')) {
      return Colors.blue.shade600;
    } else if (cat.contains('entertainment')) {
      return Colors.purple.shade600;
    } else if (cat.contains('shopping')) {
      return Colors.pink.shade600;
    } else if (cat.contains('health') || cat.contains('medical')) {
      return Colors.red.shade600;
    } else if (cat.contains('transfer')) {
      return Colors.teal.shade600;
    } else {
      return Colors.grey.shade600;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final logoUrl = _getLogoUrl();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: logoUrl != null
            ? Image.network(
                logoUrl,
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image fails
                  return Container(
                    color: _getCategoryColor().withOpacity(0.1),
                    child: Icon(
                      _getCategoryIcon(),
                      size: size * 0.5,
                      color: _getCategoryColor(),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: _getCategoryColor().withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: _getCategoryColor(),
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: _getCategoryColor().withOpacity(0.1),
                child: Icon(
                  _getCategoryIcon(),
                  size: size * 0.5,
                  color: _getCategoryColor(),
                ),
              ),
      ),
    );
  }
}