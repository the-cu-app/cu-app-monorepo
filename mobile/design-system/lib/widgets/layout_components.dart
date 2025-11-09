import 'package:flutter/widgets.dart';
import 'ff_zero_material_foundation.dart';

/// Zero-Material Layout Components for Financial Institution Apps
///
/// This file contains layout and structural components built without Material dependencies.

// ============================================================================
// CU LOADING WIDGET - Full Page Loading State
// ============================================================================

class CULoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const CULoadingWidget({
    Key? key,
    this.message,
    this.size = CUSize.iconLarge,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FFTheme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: _CULoadingSpinner(
              color: color ?? theme.colorScheme.primary,
              strokeWidth: 4.0,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: FFSpacing.lg),
            Text(
              message!,
              style: FFTypographyScale.bodyMedium.toTextStyle(
                color: theme.colorScheme.neutral,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// CU ERROR WIDGET - Error Display
// ============================================================================

class CUErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final Color? color;

  const CUErrorWidget({
    Key? key,
    required this.message,
    this.onRetry,
    this.icon,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FFTheme.of(context);
    final errorColor = color ?? theme.colorScheme.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FFSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? const IconData(0xe160), // error_outline equivalent
              size: CUSize.iconLarge,
              color: errorColor,
            ),
            const SizedBox(height: FFSpacing.lg),
            Text(
              'Something went wrong',
              style: FFTypographyScale.titleMedium.toTextStyle(
                color: errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FFSpacing.md),
            Text(
              message,
              style: FFTypographyScale.bodyMedium.toTextStyle(
                color: theme.colorScheme.neutral,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: FFSpacing.xl),
              _CURetryButton(onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CU PROGRESS INDICATOR - Linear Progress Bar
// ============================================================================

class CUProgressIndicator extends StatelessWidget {
  final double value;
  final Color? backgroundColor;
  final Color? valueColor;
  final double height;

  const CUProgressIndicator({
    Key? key,
    required this.value,
    this.backgroundColor,
    this.valueColor,
    this.height = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FFTheme.of(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: valueColor ?? theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CU STEP INDICATOR - Multi-Step Progress
// ============================================================================

class CUStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color? completedColor;
  final Color? currentColor;
  final Color? remainingColor;
  final double height;

  const CUStepIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    this.completedColor,
    this.currentColor,
    this.remainingColor,
    this.height = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FFTheme.of(context);
    final completed = completedColor ?? theme.colorScheme.success;
    final current = currentColor ?? theme.colorScheme.primary;
    final remaining = remainingColor ?? theme.colorScheme.surface;

    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;

        return Expanded(
          child: Container(
            height: height,
            margin: EdgeInsets.only(
              right: index < totalSteps - 1 ? FFSpacing.xs : 0,
            ),
            decoration: BoxDecoration(
              color: isCompleted
                  ? completed
                  : isCurrent
                      ? current
                      : remaining,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        );
      }),
    );
  }
}

// ============================================================================
// CU LIST TILE - List Item
// ============================================================================

class CUListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const CUListTile({
    Key? key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FFTheme.of(context);

    Widget content = Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: FFSpacing.md,
            vertical: FFSpacing.sm,
          ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: FFSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  DefaultTextStyle(
                    style: FFTypographyScale.bodyLarge.toTextStyle(
                      color: theme.colorScheme.onBackground,
                    ),
                    child: title!,
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: FFSpacing.xs),
                  DefaultTextStyle(
                    style: FFTypographyScale.bodyMedium.toTextStyle(
                      color: theme.colorScheme.neutral,
                    ),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: FFSpacing.md),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

// ============================================================================
// CU DIVIDER - Horizontal Separator
// ============================================================================

class CUDivider extends StatelessWidget {
  final double height;
  final double thickness;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const CUDivider({
    Key? key,
    this.height = 1.0,
    this.thickness = 1.0,
    this.color,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FFTheme.of(context);

    return Container(
      height: height,
      margin: margin,
      color: color ?? theme.colorScheme.divider,
    );
  }
}

// ============================================================================
// CU CHECKBOX - Checkbox Input
// ============================================================================

class CUCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? checkColor;

  const CUCheckbox({
    Key? key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.checkColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FFTheme.of(context);
    final active = activeColor ?? theme.colorScheme.primary;
    final check = checkColor ?? theme.colorScheme.onPrimary;

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: value ? active : Colors.transparent,
          border: Border.all(
            color: value ? active : theme.colorScheme.border,
            width: CUSize.borderMedium,
          ),
          borderRadius: BorderRadius.circular(CURadius.xs),
        ),
        child: value
            ? Icon(
                const IconData(0xe5ca), // check icon
                size: 16,
                color: check,
              )
            : null,
      ),
    );
  }
}

// ============================================================================
// CU SWITCH - Toggle Switch
// ============================================================================

class CUSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  const CUSwitch({
    Key? key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FFTheme.of(context);
    final active = activeColor ?? theme.colorScheme.primary;
    final inactive = inactiveColor ?? theme.colorScheme.surface;

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: CUAnimation.fast,
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          color: value ? active : inactive,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? active : theme.colorScheme.border,
            width: CUSize.borderThin,
          ),
        ),
        child: AnimatedAlign(
          duration: CUAnimation.fast,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: CUElevation.getShadow(CUElevation.low),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PRIVATE HELPER WIDGETS
// ============================================================================

class _CULoadingSpinner extends StatefulWidget {
  final Color color;
  final double strokeWidth;

  const _CULoadingSpinner({
    required this.color,
    required this.strokeWidth,
  });

  @override
  State<_CULoadingSpinner> createState() => _CULoadingSpinnerState();
}

class _CULoadingSpinnerState extends State<_CULoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _LoadingSpinnerPainter(
            progress: _controller.value,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _LoadingSpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _LoadingSpinnerPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = -1.5708;
    final sweepAngle = 4.71239 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + (6.28319 * progress),
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LoadingSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _CURetryButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CURetryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = FFTheme.of(context);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FFSpacing.lg,
          vertical: FFSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary,
            width: CUSize.borderMedium,
          ),
          borderRadius: BorderRadius.circular(CURadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              const IconData(0xe5d5), // refresh icon
              size: CUSize.iconMedium,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: FFSpacing.sm),
            Text(
              'Try Again',
              style: FFTypographyScale.labelLarge.toTextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
