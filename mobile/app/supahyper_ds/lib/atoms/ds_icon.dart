import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

// Icon sizes
enum DSIconSize {
  xs,
  sm,
  md,
  lg,
  xl,
  xxl,
  xxxl,
}

// Icon component with consistent sizing
class DSIcon extends StatelessWidget {
  final IconData icon;
  final DSIconSize size;
  final Color? color;
  final String? semanticLabel;
  
  const DSIcon(
    this.icon, {
    super.key,
    this.size = DSIconSize.md,
    this.color,
    this.semanticLabel,
  });
  
  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: _getSize(),
      color: color ?? DSColors.textPrimary,
      semanticLabel: semanticLabel,
    );
  }
  
  double _getSize() {
    switch (size) {
      case DSIconSize.xs:
        return DSSpacing.iconXs;
      case DSIconSize.sm:
        return DSSpacing.iconSm;
      case DSIconSize.md:
        return DSSpacing.iconMd;
      case DSIconSize.lg:
        return DSSpacing.iconLg;
      case DSIconSize.xl:
        return DSSpacing.iconXl;
      case DSIconSize.xxl:
        return DSSpacing.icon2xl;
      case DSIconSize.xxxl:
        return DSSpacing.icon3xl;
    }
  }
  
  // Factory constructors for semantic icons
  factory DSIcon.success(IconData icon, {Key? key, DSIconSize size = DSIconSize.md}) => DSIcon(
    icon,
    key: key,
    size: size,
    color: DSColors.success,
  );
  
  factory DSIcon.error(IconData icon, {Key? key, DSIconSize size = DSIconSize.md}) => DSIcon(
    icon,
    key: key,
    size: size,
    color: DSColors.error,
  );
  
  factory DSIcon.warning(IconData icon, {Key? key, DSIconSize size = DSIconSize.md}) => DSIcon(
    icon,
    key: key,
    size: size,
    color: DSColors.warning,
  );
  
  factory DSIcon.info(IconData icon, {Key? key, DSIconSize size = DSIconSize.md}) => DSIcon(
    icon,
    key: key,
    size: size,
    color: DSColors.info,
  );
  
  factory DSIcon.disabled(IconData icon, {Key? key, DSIconSize size = DSIconSize.md}) => DSIcon(
    icon,
    key: key,
    size: size,
    color: DSColors.textDisabled,
  );
}