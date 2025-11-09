import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/borders.dart';

// Avatar sizes
enum DSAvatarSize {
  xs,
  sm,
  md,
  lg,
  xl,
  xxl,
}

// Avatar shapes
enum DSAvatarShape {
  circle,
  square,
}

// Avatar component for user profiles
class DSAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final String? initials;
  final IconData? icon;
  final DSAvatarSize size;
  final DSAvatarShape shape;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onTap;
  final Widget? badge;
  
  const DSAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.initials,
    this.icon,
    this.size = DSAvatarSize.md,
    this.shape = DSAvatarShape.circle,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
    this.badge,
  });
  
  @override
  Widget build(BuildContext context) {
    final avatarSize = _getSize();
    
    Widget avatar = Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? DSColors.primary,
        borderRadius: _getBorderRadius(),
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null ? _buildContent() : null,
    );
    
    if (badge != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: badge!,
          ),
        ],
      );
    }
    
    if (onTap != null) {
      avatar = InkWell(
        onTap: onTap,
        borderRadius: _getBorderRadius(),
        child: avatar,
      );
    }
    
    return avatar;
  }
  
  Widget _buildContent() {
    if (icon != null) {
      return Center(
        child: Icon(
          icon,
          size: _getIconSize(),
          color: foregroundColor ?? DSColors.textInverse,
        ),
      );
    }
    
    final displayText = _getDisplayText();
    if (displayText != null) {
      return Center(
        child: Text(
          displayText,
          style: _getTextStyle(),
        ),
      );
    }
    
    return Center(
      child: Icon(
        Icons.person,
        size: _getIconSize(),
        color: foregroundColor ?? DSColors.textInverse,
      ),
    );
  }
  
  String? _getDisplayText() {
    if (initials != null) {
      return initials!.toUpperCase();
    }
    
    if (name != null) {
      final parts = name!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }
    
    return null;
  }
  
  double _getSize() {
    switch (size) {
      case DSAvatarSize.xs:
        return 24.0;
      case DSAvatarSize.sm:
        return 32.0;
      case DSAvatarSize.md:
        return 40.0;
      case DSAvatarSize.lg:
        return 56.0;
      case DSAvatarSize.xl:
        return 72.0;
      case DSAvatarSize.xxl:
        return 96.0;
    }
  }
  
  double _getIconSize() {
    switch (size) {
      case DSAvatarSize.xs:
        return 16.0;
      case DSAvatarSize.sm:
        return 20.0;
      case DSAvatarSize.md:
        return 24.0;
      case DSAvatarSize.lg:
        return 32.0;
      case DSAvatarSize.xl:
        return 40.0;
      case DSAvatarSize.xxl:
        return 48.0;
    }
  }
  
  BorderRadius _getBorderRadius() {
    if (shape == DSAvatarShape.circle) {
      return DSBorders.borderRadiusFull;
    }
    
    switch (size) {
      case DSAvatarSize.xs:
      case DSAvatarSize.sm:
        return DSBorders.borderRadiusXs;
      case DSAvatarSize.md:
        return DSBorders.borderRadiusSm;
      case DSAvatarSize.lg:
        return DSBorders.borderRadiusMd;
      case DSAvatarSize.xl:
      case DSAvatarSize.xxl:
        return DSBorders.borderRadiusLg;
    }
  }
  
  TextStyle _getTextStyle() {
    TextStyle baseStyle;
    switch (size) {
      case DSAvatarSize.xs:
        baseStyle = DSTypography.labelSmall;
        break;
      case DSAvatarSize.sm:
        baseStyle = DSTypography.labelSmall;
        break;
      case DSAvatarSize.md:
        baseStyle = DSTypography.labelMedium;
        break;
      case DSAvatarSize.lg:
        baseStyle = DSTypography.titleMedium;
        break;
      case DSAvatarSize.xl:
        baseStyle = DSTypography.titleLarge;
        break;
      case DSAvatarSize.xxl:
        baseStyle = DSTypography.headlineSmall;
        break;
    }
    
    return baseStyle.copyWith(
      color: foregroundColor ?? DSColors.textInverse,
      fontWeight: DSTypography.weightSemiBold,
    );
  }
}