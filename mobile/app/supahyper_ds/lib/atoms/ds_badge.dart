import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/borders.dart';

// Badge variants
enum DSBadgeVariant {
  primary,
  secondary,
  success,
  error,
  warning,
  info,
}

// Badge sizes
enum DSBadgeSize {
  small,
  medium,
  large,
}

// Badge component for status indicators
class DSBadge extends StatelessWidget {
  final String? label;
  final int? count;
  final DSBadgeVariant variant;
  final DSBadgeSize size;
  final Widget? child;
  final bool showDot;
  
  const DSBadge({
    super.key,
    this.label,
    this.count,
    this.variant = DSBadgeVariant.primary,
    this.size = DSBadgeSize.medium,
    this.child,
    this.showDot = false,
  }) : assert(
    label != null || count != null || showDot || child != null,
    'Badge must have label, count, showDot, or child',
  );
  
  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          child!,
          Positioned(
            top: -4,
            right: -4,
            child: _buildBadge(),
          ),
        ],
      );
    }
    
    return _buildBadge();
  }
  
  Widget _buildBadge() {
    if (showDot) {
      return Container(
        width: _getDotSize(),
        height: _getDotSize(),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          shape: BoxShape.circle,
          border: Border.all(
            color: DSColors.surface,
            width: 2,
          ),
        ),
      );
    }
    
    final displayText = count != null
        ? count! > 99 ? '99+' : count.toString()
        : label ?? '';
    
    return Container(
      constraints: BoxConstraints(
        minWidth: _getMinWidth(),
        minHeight: _getHeight(),
      ),
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: DSBorders.borderRadiusFull,
      ),
      child: Center(
        child: Text(
          displayText,
          style: _getTextStyle(),
        ),
      ),
    );
  }
  
  double _getDotSize() {
    switch (size) {
      case DSBadgeSize.small:
        return 6.0;
      case DSBadgeSize.medium:
        return 8.0;
      case DSBadgeSize.large:
        return 10.0;
    }
  }
  
  double _getMinWidth() {
    switch (size) {
      case DSBadgeSize.small:
        return 16.0;
      case DSBadgeSize.medium:
        return 20.0;
      case DSBadgeSize.large:
        return 24.0;
    }
  }
  
  double _getHeight() {
    switch (size) {
      case DSBadgeSize.small:
        return 16.0;
      case DSBadgeSize.medium:
        return 20.0;
      case DSBadgeSize.large:
        return 24.0;
    }
  }
  
  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case DSBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 4.0);
      case DSBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 6.0);
      case DSBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 8.0);
    }
  }
  
  Color _getBackgroundColor() {
    switch (variant) {
      case DSBadgeVariant.primary:
        return DSColors.primary;
      case DSBadgeVariant.secondary:
        return DSColors.secondary;
      case DSBadgeVariant.success:
        return DSColors.success;
      case DSBadgeVariant.error:
        return DSColors.error;
      case DSBadgeVariant.warning:
        return DSColors.warning;
      case DSBadgeVariant.info:
        return DSColors.info;
    }
  }
  
  TextStyle _getTextStyle() {
    TextStyle baseStyle;
    switch (size) {
      case DSBadgeSize.small:
        baseStyle = DSTypography.labelSmall;
        break;
      case DSBadgeSize.medium:
        baseStyle = DSTypography.labelMedium;
        break;
      case DSBadgeSize.large:
        baseStyle = DSTypography.labelLarge;
        break;
    }
    
    return baseStyle.copyWith(
      color: DSColors.textInverse,
      fontWeight: DSTypography.weightSemiBold,
    );
  }
}