import 'package:flutter/material.dart';
import '../services/feature_service.dart';

/// Widget that conditionally shows content based on feature flags
class FeatureGate extends StatelessWidget {
  final String featureKey;
  final Widget child;
  final Widget? fallback;
  final bool showLockedMessage;

  const FeatureGate({
    super.key,
    required this.featureKey,
    required this.child,
    this.fallback,
    this.showLockedMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final featureService = FeatureService();
    final isEnabled = featureService.isFeatureEnabled(featureKey);

    if (isEnabled) {
      return child;
    }

    if (fallback != null) {
      return fallback!;
    }

    if (showLockedMessage) {
      return _buildLockedFeature(context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildLockedFeature(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Business Feature',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upgrade to Business membership to unlock',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget to show enhanced features badge for business members
class FeatureBadge extends StatelessWidget {
  final String featureKey;
  final Widget child;

  const FeatureBadge({
    super.key,
    required this.featureKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final featureService = FeatureService();
    final display = featureService.getFeatureDisplay(featureKey);
    
    if (!display.showBadge) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (display.badgeText != null)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                display.badgeText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget to show feature limits
class FeatureLimit extends StatelessWidget {
  final String featureKey;
  final String limitKey;
  final Widget Function(dynamic limit) builder;

  const FeatureLimit({
    super.key,
    required this.featureKey,
    required this.limitKey,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final featureService = FeatureService();
    final limit = featureService.getFeatureLimit(featureKey, limitKey);
    
    return builder(limit);
  }
}

/// Widget to show different content based on membership
class MembershipContent extends StatelessWidget {
  final Widget generalContent;
  final Widget? businessContent;
  final Widget? premiumContent;

  const MembershipContent({
    super.key,
    required this.generalContent,
    this.businessContent,
    this.premiumContent,
  });

  @override
  Widget build(BuildContext context) {
    final featureService = FeatureService();
    
    switch (featureService.membershipType) {
      case MembershipType.business:
        return businessContent ?? generalContent;
      case MembershipType.premium:
        return premiumContent ?? businessContent ?? generalContent;
      case MembershipType.general:
      case MembershipType.student:
      default:
        return generalContent;
    }
  }
}

/// Widget to show enhancement options for business members
class EnhancementList extends StatelessWidget {
  final String featureKey;

  const EnhancementList({
    super.key,
    required this.featureKey,
  });

  @override
  Widget build(BuildContext context) {
    final featureService = FeatureService();
    final enhancements = featureService.getEnhancements(featureKey);
    
    if (enhancements.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                size: 16,
                color: Colors.blue,
              ),
              const SizedBox(width: 4),
              Text(
                'Business Enhancements',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...enhancements.map((enhancement) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 12,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatEnhancement(enhancement),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _formatEnhancement(String enhancement) {
    return enhancement
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1)
            : '')
        .join(' ');
  }
}