import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/borders.dart';
import '../tokens/shadows.dart';
import '../tokens/motion.dart';

// Button variants
enum DSButtonVariant {
  primary,
  secondary,
  tertiary,
  danger,
  success,
  ghost,
}

// Button sizes
enum DSButtonSize {
  small,
  medium,
  large,
}

// Primary button component with multiple variants
class DSButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final DSButtonVariant variant;
  final DSButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final bool enableHaptics;
  
  const DSButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = DSButtonVariant.primary,
    this.size = DSButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.enableHaptics = true,
  });
  
  @override
  State<DSButton> createState() => _DSButtonState();
}

class _DSButtonState extends State<DSButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DSMotion.microInteraction,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DSMotion.smooth,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    _animationController.forward();
    if (widget.enableHaptics) {
      SystemChannels.platform.invokeMethod('HapticFeedback.lightImpact');
    }
  }
  
  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }
  
  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: DSMotion.microInteraction,
              width: widget.isFullWidth ? double.infinity : null,
              padding: _getPadding(),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: DSBorders.borderRadiusLg,
                border: _getBorder(),
                boxShadow: _getShadow(),
              ),
              child: Row(
                mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: _getIconSize(),
                      height: _getIconSize(),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
                      ),
                    ),
                    const SizedBox(width: DSSpacing.space2),
                  ] else if (widget.leadingIcon != null) ...[
                    Icon(
                      widget.leadingIcon,
                      size: _getIconSize(),
                      color: _getTextColor(),
                    ),
                    const SizedBox(width: DSSpacing.space2),
                  ],
                  Text(
                    widget.label,
                    style: _getTextStyle(),
                  ),
                  if (widget.trailingIcon != null && !widget.isLoading) ...[
                    const SizedBox(width: DSSpacing.space2),
                    Icon(
                      widget.trailingIcon,
                      size: _getIconSize(),
                      color: _getTextColor(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  EdgeInsetsGeometry _getPadding() {
    switch (widget.size) {
      case DSButtonSize.small:
        return DSSpacing.buttonPaddingSmall;
      case DSButtonSize.medium:
        return DSSpacing.buttonPaddingMedium;
      case DSButtonSize.large:
        return DSSpacing.buttonPaddingLarge;
    }
  }
  
  Color _getBackgroundColor() {
    final isDisabled = widget.onPressed == null;
    
    if (isDisabled) return DSColors.disabled;
    
    switch (widget.variant) {
      case DSButtonVariant.primary:
        return _isPressed ? DSColors.primaryDark : DSColors.primary;
      case DSButtonVariant.secondary:
        return _isPressed ? DSColors.surfaceContainer : DSColors.surfaceVariant;
      case DSButtonVariant.tertiary:
        return _isPressed ? DSColors.surfaceVariant : Colors.transparent;
      case DSButtonVariant.danger:
        return _isPressed ? DSColors.errorDark : DSColors.error;
      case DSButtonVariant.success:
        return _isPressed ? DSColors.successDark : DSColors.success;
      case DSButtonVariant.ghost:
        return _isPressed ? DSColors.hover : Colors.transparent;
    }
  }
  
  Color _getTextColor() {
    final isDisabled = widget.onPressed == null;
    
    if (isDisabled) return DSColors.textDisabled;
    
    switch (widget.variant) {
      case DSButtonVariant.primary:
        return DSColors.textInverse;
      case DSButtonVariant.secondary:
        return DSColors.textPrimary;
      case DSButtonVariant.tertiary:
        return DSColors.textPrimary;
      case DSButtonVariant.danger:
        return DSColors.textInverse;
      case DSButtonVariant.success:
        return DSColors.textInverse;
      case DSButtonVariant.ghost:
        return DSColors.textPrimary;
    }
  }
  
  TextStyle _getTextStyle() {
    TextStyle baseStyle;
    switch (widget.size) {
      case DSButtonSize.small:
        baseStyle = DSTypography.labelMedium;
        break;
      case DSButtonSize.medium:
        baseStyle = DSTypography.labelLarge;
        break;
      case DSButtonSize.large:
        baseStyle = DSTypography.titleMedium;
        break;
    }
    return baseStyle.copyWith(
      color: _getTextColor(),
      fontWeight: DSTypography.weightSemiBold,
    );
  }
  
  double _getIconSize() {
    switch (widget.size) {
      case DSButtonSize.small:
        return DSSpacing.iconSm;
      case DSButtonSize.medium:
        return DSSpacing.iconMd;
      case DSButtonSize.large:
        return DSSpacing.iconLg;
    }
  }
  
  Border? _getBorder() {
    if (widget.variant == DSButtonVariant.secondary ||
        widget.variant == DSButtonVariant.tertiary ||
        widget.variant == DSButtonVariant.ghost) {
      return DSBorders.borderThin;
    }
    return null;
  }
  
  List<BoxShadow>? _getShadow() {
    if (widget.onPressed == null || 
        widget.variant == DSButtonVariant.tertiary ||
        widget.variant == DSButtonVariant.ghost) {
      return null;
    }
    return _isPressed ? null : DSShadows.buttonShadow;
  }
}