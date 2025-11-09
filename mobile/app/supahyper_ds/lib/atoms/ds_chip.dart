import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/borders.dart';
import '../tokens/motion.dart';

// Chip variants
enum DSChipVariant {
  filled,
  outlined,
  elevated,
}

// Chip component for tags and selections
class DSChip extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool selected;
  final bool enabled;
  final DSChipVariant variant;
  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final Color? foregroundColor;
  
  const DSChip({
    super.key,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.onTap,
    this.onDelete,
    this.selected = false,
    this.enabled = true,
    this.variant = DSChipVariant.filled,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.foregroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final isInteractive = onTap != null || onDelete != null;
    
    Widget chip = AnimatedContainer(
      duration: DSMotion.microInteraction,
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.space3,
        vertical: DSSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: DSBorders.borderRadiusFull,
        border: _getBorder(),
        boxShadow: _getShadow(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: DSSpacing.iconSm,
              color: _getForegroundColor(),
            ),
            const SizedBox(width: DSSpacing.space1),
          ],
          Text(
            label,
            style: DSTypography.labelMedium.copyWith(
              color: _getForegroundColor(),
              fontWeight: selected ? DSTypography.weightSemiBold : DSTypography.weightMedium,
            ),
          ),
          if (trailingIcon != null && onDelete == null) ...[
            const SizedBox(width: DSSpacing.space1),
            Icon(
              trailingIcon,
              size: DSSpacing.iconSm,
              color: _getForegroundColor(),
            ),
          ],
          if (onDelete != null) ...[
            const SizedBox(width: DSSpacing.space1),
            GestureDetector(
              onTap: enabled ? onDelete : null,
              child: Icon(
                Icons.close,
                size: DSSpacing.iconSm,
                color: _getForegroundColor(),
              ),
            ),
          ],
        ],
      ),
    );
    
    if (isInteractive && enabled && onTap != null) {
      chip = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: DSBorders.borderRadiusFull,
          child: chip,
        ),
      );
    }
    
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: chip,
    );
  }
  
  Color _getBackgroundColor() {
    if (!enabled) return DSColors.disabled;
    
    if (selected) {
      return selectedBackgroundColor ?? DSColors.primary;
    }
    
    switch (variant) {
      case DSChipVariant.filled:
        return backgroundColor ?? DSColors.surfaceContainer;
      case DSChipVariant.outlined:
      case DSChipVariant.elevated:
        return backgroundColor ?? DSColors.surface;
    }
  }
  
  Color _getForegroundColor() {
    if (!enabled) return DSColors.textDisabled;
    
    if (selected) {
      return foregroundColor ?? DSColors.textInverse;
    }
    
    return foregroundColor ?? DSColors.textPrimary;
  }
  
  Border? _getBorder() {
    if (variant == DSChipVariant.outlined) {
      return Border.all(
        color: selected ? DSColors.primary : DSColors.border,
        width: 1.0,
      );
    }
    return null;
  }
  
  List<BoxShadow>? _getShadow() {
    if (variant == DSChipVariant.elevated && enabled) {
      return [
        BoxShadow(
          color: DSColors.overlay.withOpacity(0.08),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ];
    }
    return null;
  }
}