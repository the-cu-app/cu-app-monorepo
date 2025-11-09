import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/colors.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';

// Switch component for binary choices
class DSSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? description;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool enableHaptics;
  
  const DSSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.description,
    this.activeColor,
    this.inactiveColor,
    this.enableHaptics = true,
  });
  
  @override
  State<DSSwitch> createState() => _DSSwitchState();
}

class _DSSwitchState extends State<DSSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  late Animation<Color?> _colorAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DSMotion.microInteraction,
      vsync: this,
    );
    
    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DSMotion.smooth,
    ));
    
    _colorAnimation = ColorTween(
      begin: widget.inactiveColor ?? DSColors.surfaceContainer,
      end: widget.activeColor ?? DSColors.primary,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DSMotion.smooth,
    ));
    
    if (widget.value) {
      _animationController.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(DSSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleTap() {
    if (widget.onChanged == null) return;
    
    if (widget.enableHaptics) {
      SystemChannels.platform.invokeMethod('HapticFeedback.lightImpact');
    }
    
    widget.onChanged!(!widget.value);
  }
  
  @override
  Widget build(BuildContext context) {
    Widget switchWidget = GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: 51.0,
            height: 31.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(31.0),
              color: _colorAnimation.value,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: DSMotion.microInteraction,
                    alignment: widget.value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    curve: DSMotion.smooth,
                    child: Container(
                      width: 27.0,
                      height: 27.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DSColors.surface,
                        boxShadow: [
                          BoxShadow(
                            color: DSColors.overlay.withOpacity(0.2),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    
    if (widget.label != null || widget.description != null) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: DSColors.textPrimary,
                    ),
                  ),
                if (widget.description != null) ...[
                  const SizedBox(height: DSSpacing.space1),
                  Text(
                    widget.description!,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: DSColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: DSSpacing.space4),
          switchWidget,
        ],
      );
    }
    
    return switchWidget;
  }
}