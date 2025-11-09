import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Colors, Curves;
import '../foundation/colors.dart';
import '../foundation/typography.dart';
import '../foundation/spacing.dart';
import '../foundation/radius.dart';
import '../foundation/elevation.dart';
import '../foundation/animation.dart';
import '../foundation/size.dart';
import '../foundation/theme.dart';

/// Zero-Material Core Components for Financial Institution Apps
///
/// This file contains fundamental UI components built WITHOUT any Material dependencies.
/// All components are built using pure Flutter widgets and custom rendering.

// ============================================================================
// CU APP - Root Application Widget
// ============================================================================

class CUApp extends StatelessWidget {
  final Widget home;
  final CUThemeData? theme;
  final CUThemeData? darkTheme;
  final bool isDarkMode;
  final String title;
  final GlobalKey<NavigatorState>? navigatorKey;
  final bool debugShowCheckedModeBanner;
  final List<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final List<Locale> supportedLocales;
  final Map<String, WidgetBuilder>? routes;

  const CUApp({
    Key? key,
    required this.home,
    this.theme,
    this.darkTheme,
    this.isDarkMode = false,
    this.title = '',
    this.navigatorKey,
    this.debugShowCheckedModeBanner = true,
    this.localizationsDelegates,
    this.supportedLocales = const <Locale>[Locale('en', '')],
    this.routes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = isDarkMode
        ? (darkTheme ?? theme ?? CUThemeData.dark)
        : (theme ?? CUThemeData.light);

    return WidgetsApp(
      navigatorKey: navigatorKey,
      title: title,
      color: effectiveTheme.colorScheme.primary,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      onGenerateRoute: (settings) {
        // Check named routes first
        if (routes != null && routes!.containsKey(settings.name)) {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) {
              return routes![settings.name]!(context);
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        }
        return null;
      },
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return builder(context);
          },
          transitionsBuilder: (BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
      },
      home: CUTheme(
        themeData: effectiveTheme,
        child: home,
      ),
    );
  }
}

// ============================================================================
// CU SCACUOLD - Page Layout Structure
// ============================================================================

class CUScacuold extends StatelessWidget {
  final Widget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final Widget? bottomBar;
  final Widget? floatingActionButton;

  const CUScacuold({
    Key? key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.padding,
    this.bottomBar,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return Container(
      color: backgroundColor ?? theme.colorScheme.background,
      child: Column(
        children: [
          if (appBar != null) appBar!,
          Expanded(
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: body,
            ),
          ),
          if (bottomBar != null) bottomBar!,
        ],
      ),
    );
  }
}

// ============================================================================
// CU APP BAR - Top Navigation Bar
// ============================================================================

class CUAppBar extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final bool showShadow;

  const CUAppBar({
    Key? key,
    this.leading,
    this.title,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 56.0,
    this.showShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary;
    final fgColor = foregroundColor ?? theme.colorScheme.onPrimary;

    return Container(
      height: height + MediaQuery.of(context).padding.top,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: showShadow ? CUElevation.getShadow(CUElevation.low) : null,
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Row(
        children: [
          if (leading != null)
            Padding(
              padding: const EdgeInsets.only(left: CUSpacing.sm),
              child: leading!,
            ),
          if (title != null)
            Expanded(
              child: DefaultTextStyle(
                style: CUTypography.titleLarge.copyWith(color: fgColor),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CUSpacing.md),
                  child: title!,
                ),
              ),
            ),
          if (actions != null)
            ...actions!.map((action) => Padding(
                  padding: const EdgeInsets.only(right: CUSpacing.sm),
                  child: action,
                )),
        ],
      ),
    );
  }
}

// ============================================================================
// CU BUTTON - Clickable Button Component
// ============================================================================

enum CUButtonVariant { primary, secondary, text, outlined }

class CUButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final CUButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final bool isLoading;
  final Widget? icon;
  final EdgeInsetsGeometry? padding;

  const CUButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.variant = CUButtonVariant.primary,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = CUSize.buttonHeight,
    this.isLoading = false,
    this.icon,
    this.padding,
  }) : super(key: key);

  @override
  State<CUButton> createState() => _CUButtonState();
}

class _CUButtonState extends State<CUButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BoxBorder? border;

    switch (widget.variant) {
      case CUButtonVariant.primary:
        backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
        foregroundColor = widget.foregroundColor ?? theme.colorScheme.onPrimary;
        break;
      case CUButtonVariant.secondary:
        backgroundColor = widget.backgroundColor ?? theme.colorScheme.secondary;
        foregroundColor =
            widget.foregroundColor ?? theme.colorScheme.onSecondary;
        break;
      case CUButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = widget.foregroundColor ?? theme.colorScheme.primary;
        border = Border.all(
          color: theme.colorScheme.border,
          width: CUSize.borderMedium,
        );
        break;
      case CUButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor = widget.foregroundColor ?? theme.colorScheme.primary;
        break;
    }

    if (!isEnabled) {
      backgroundColor = backgroundColor.withOpacity(0.4);
      foregroundColor = foregroundColor.withOpacity(0.4);
    } else if (_isPressed) {
      backgroundColor = Color.lerp(backgroundColor, Colors.black, 0.1)!;
    }

    return GestureDetector(
      onTapDown: isEnabled ? _handleTapDown : null,
      onTapUp: isEnabled ? _handleTapUp : null,
      onTapCancel: isEnabled ? _handleTapCancel : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: CUAnimation.fast,
        curve: CUAnimation.standard,
        width: widget.width,
        height: widget.height,
        padding: widget.padding ??
            const EdgeInsets.symmetric(
              horizontal: CUSpacing.lg,
              vertical: CUSpacing.md,
            ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(CURadius.md),
          border: border,
          boxShadow: widget.variant == CUButtonVariant.primary ||
                  widget.variant == CUButtonVariant.secondary
              ? CUElevation.getShadow(CUElevation.low)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isLoading)
              SizedBox(
                width: CUSize.iconSmall,
                height: CUSize.iconSmall,
                child: CULoadingSpinner(color: foregroundColor),
              )
            else if (widget.icon != null) ...[
              widget.icon!,
              const SizedBox(width: CUSpacing.sm),
            ],
            DefaultTextStyle(
              style: CUTypography.labelLarge.copyWith(
                color: foregroundColor,
              ),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CU AVATAR - Circle Avatar with Letter/Image
// ============================================================================

class CUAvatar extends StatelessWidget {
  final String text;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final String? imageUrl;
  final IconData? icon;

  const CUAvatar({
    Key? key,
    required this.text,
    this.size = 40,
    this.backgroundColor,
    this.textColor,
    this.imageUrl,
    this.icon,
  }) : super(key: key);

  Color _generateColor(String text) {
    // Generate a color based on the text hash
    final hash = text.hashCode;
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF97316), // Orange
      const Color(0xFFEF4444), // Red
      const Color(0xFF06B6D4), // Cyan
    ];
    return colors[hash.abs() % colors.length];
  }

  String _getInitials(String text) {
    final words = text.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? _generateColor(text);
    final fgColor = textColor ?? Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: imageUrl != null ? Colors.white : bgColor,
        shape: BoxShape.circle,
        border: imageUrl != null
            ? Border.all(color: Colors.grey.shade200, width: 1)
            : null,
      ),
      child: imageUrl != null
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to initials if image fails to load
                  return Center(
                    child: Text(
                      _getInitials(text),
                      style: TextStyle(
                        color: fgColor,
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                      ),
                    ),
                  );
                },
              ),
            )
          : Center(
              child: icon != null
                  ? Icon(
                      icon,
                      color: fgColor,
                      size: size * 0.5,
                    )
                  : Text(
                      _getInitials(text),
                      style: TextStyle(
                        color: fgColor,
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                      ),
                    ),
            ),
    );
  }
}

// ============================================================================
// CU TEXT FIELD - Input Field
// ============================================================================

class CUTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? sucuixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final bool enabled;

  const CUTextField({
    Key? key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.sucuixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CUTextField> createState() => _CUTextFieldState();
}

class _CUTextFieldState extends State<CUTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final hasError = widget.errorText != null;

    Color borderColor;
    if (hasError) {
      borderColor = theme.colorScheme.error;
    } else if (_isFocused) {
      borderColor = theme.colorScheme.primary;
    } else {
      borderColor = theme.colorScheme.border;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: CUTypography.labelMedium.copyWith(
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: CUSpacing.xs),
        ],
        Container(
          decoration: BoxDecoration(
            color: widget.enabled
                ? theme.colorScheme.surface
                : theme.colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(CURadius.sm),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? CUSize.borderMedium : CUSize.borderThin,
            ),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: CUSpacing.md),
                  child: widget.prefixIcon!,
                ),
                const SizedBox(width: CUSpacing.sm),
              ],
              Expanded(
                child: EditableText(
                  controller: widget.controller ?? TextEditingController(),
                  focusNode: _focusNode,
                  style: CUTypography.bodyLarge.copyWith(
                    color: theme.colorScheme.onBackground,
                  ),
                  cursorColor: theme.colorScheme.primary,
                  backgroundCursorColor: theme.colorScheme.primary,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  maxLines: widget.maxLines,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                ),
              ),
              if (widget.sucuixIcon != null) ...[
                const SizedBox(width: CUSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(right: CUSpacing.md),
                  child: widget.sucuixIcon!,
                ),
              ],
            ],
          ),
        ),
        if (widget.helperText != null || widget.errorText != null) ...[
          const SizedBox(height: CUSpacing.xs),
          Text(
            widget.errorText ?? widget.helperText!,
            style: CUTypography.bodySmall.copyWith(
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.neutral,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// CU LOADING SPINNER - Loading Indicator
// ============================================================================

class CULoadingSpinner extends StatefulWidget {
  final Color? color;
  final double size;
  final double strokeWidth;

  const CULoadingSpinner({
    Key? key,
    this.color,
    this.size = CUSize.iconMedium,
    this.strokeWidth = 3.0,
  }) : super(key: key);

  @override
  State<CULoadingSpinner> createState() => _CULoadingSpinnerState();
}

class _CULoadingSpinnerState extends State<CULoadingSpinner>
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
    final theme = CUTheme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _LoadingSpinnerPainter(
              progress: _controller.value,
              color: color,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
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

    const startAngle = -1.5708; // -90 degrees in radians
    final sweepAngle = 4.71239 * progress; // 270 degrees * progress

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + (6.28319 * progress), // Full rotation
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

// ============================================================================
// CU ICON - Icon Widget
// ============================================================================

class CUIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;

  const CUIcon({
    Key? key,
    required this.icon,
    this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return Icon(
      icon,
      size: size ?? CUSize.iconMedium,
      color: color ?? theme.colorScheme.onBackground,
    );
  }
}

// ============================================================================
// CU CARD - Zero-Material Card with Custom Tap Feedback
// ============================================================================

class CUCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Border? border;
  final bool enableFeedback;

  const CUCard({
    Key? key,
    required this.child,
    this.onTap,
    this.color,
    this.elevation,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.enableFeedback = true,
  }) : super(key: key);

  @override
  State<CUCard> createState() => _CUCardState();
}

class _CUCardState extends State<CUCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.enableFeedback) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableFeedback) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableFeedback) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final cardColor = widget.color ?? theme.colorScheme.surface;
    final radius = widget.borderRadius ?? CURadius.md;

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isPressed && widget.enableFeedback
                      ? Color.lerp(cardColor, Colors.black, 0.05)
                      : cardColor,
                  borderRadius: BorderRadius.circular(radius),
                  border: widget.border ?? Border.all(
                    color: theme.colorScheme.border.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: widget.elevation != null
                      ? CUElevation.getShadow(widget.elevation!)
                      : CUElevation.getShadow(CUElevation.low),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(CUSpacing.md),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

// ============================================================================
// CU OUTLINED CARD - Card with Outline Border (No Shadow)
// ============================================================================

class CUOutlinedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final bool enableFeedback;

  const CUOutlinedCard({
    Key? key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.padding,
    this.margin,
    this.borderRadius,
    this.enableFeedback = true,
  }) : super(key: key);

  @override
  State<CUOutlinedCard> createState() => _CUOutlinedCardState();
}

class _CUOutlinedCardState extends State<CUOutlinedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.enableFeedback) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableFeedback) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableFeedback) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.surface;
    final borderCol = widget.borderColor ?? theme.colorScheme.border;
    final radius = widget.borderRadius ?? CURadius.md;

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isPressed && widget.enableFeedback
                      ? Color.lerp(bgColor, Colors.black, 0.03)
                      : bgColor,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: _isPressed && widget.enableFeedback
                        ? borderCol.withValues(alpha: 0.8)
                        : borderCol,
                    width: widget.borderWidth ?? 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(CUSpacing.md),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
