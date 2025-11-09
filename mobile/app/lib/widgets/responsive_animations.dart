// Responsive Animation System for CU.APP
// Ensures smooth 1,2 transitions and animations across all devices

import 'package:flutter/material.dart';
import '../design_tokens/design_tokens.dart';

/// Responsive animation controller that adapts to device capabilities
class ResponsiveAnimationController extends AnimationController {
  final BuildContext context;
  final Duration baseDuration;
  final bool reduceMotion;

  ResponsiveAnimationController({
    required this.context,
    required TickerProvider vsync,
    this.baseDuration = AnimationDuration.normal,
    this.reduceMotion = false,
  }) : super(
          duration: _calculateDuration(baseDuration, reduceMotion),
          vsync: vsync,
        );

  static Duration _calculateDuration(Duration baseDuration, bool reduceMotion) {
    if (reduceMotion) {
      return const Duration(milliseconds: 100); // Minimal animation
    }
    return baseDuration;
  }

  /// Create a responsive animation with proper duration
  Animation<T> createResponsiveAnimation<T>({
    required T begin,
    required T end,
    Curve curve = AnimationCurves.easeInOut,
    Duration? duration,
  }) {
    final animationDuration = duration ?? this.duration;
    return Tween<T>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: this,
        curve: curve,
      ),
    );
  }
}

/// Responsive page transition widget
class ResponsivePageTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final PageTransitionType type;
  final bool reduceMotion;

  const ResponsivePageTransition({
    super.key,
    required this.child,
    required this.animation,
    this.type = PageTransitionType.slide,
    this.reduceMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    }

    switch (type) {
      case PageTransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: AnimationCurves.easeOut,
          )),
          child: child,
        );

      case PageTransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );

      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: AnimationCurves.easeOutBack,
          )),
          child: child,
        );

      case PageTransitionType.hero:
        return Hero(
          tag: 'page_${child.hashCode}',
          child: child,
        );
    }
  }
}

/// Responsive card animation widget
class ResponsiveCardAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool reduceMotion;
  final VoidCallback? onTap;
  final bool enableHover;

  const ResponsiveCardAnimation({
    super.key,
    required this.child,
    this.duration = AnimationDuration.normal,
    this.reduceMotion = false,
    this.onTap,
    this.enableHover = true,
  });

  @override
  State<ResponsiveCardAnimation> createState() =>
      _ResponsiveCardAnimationState();
}

class _ResponsiveCardAnimationState extends State<ResponsiveCardAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.reduceMotion
          ? const Duration(milliseconds: 100)
          : widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationCurves.easeOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: Elevation.card,
      end: Elevation.lg,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationCurves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (!widget.enableHover || widget.reduceMotion) return;

    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Material(
                elevation: _elevationAnimation.value,
                borderRadius: BorderRadius.circular(BorderRadius.card),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Responsive list item animation
class ResponsiveListItemAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final bool reduceMotion;
  final AnimationType type;

  const ResponsiveListItemAnimation({
    super.key,
    required this.child,
    required this.index,
    this.delay = Duration.zero,
    this.reduceMotion = false,
    this.type = AnimationType.slide,
  });

  @override
  State<ResponsiveListItemAnimation> createState() =>
      _ResponsiveListItemAnimationState();
}

class _ResponsiveListItemAnimationState
    extends State<ResponsiveListItemAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.reduceMotion
          ? const Duration(milliseconds: 100)
          : AnimationDuration.normal,
      vsync: this,
    );

    _animation = _createAnimation();

    // Start animation with delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _createAnimation() {
    switch (widget.type) {
      case AnimationType.slide:
        return Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: AnimationCurves.easeOut,
        ));

      case AnimationType.fade:
        return Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: AnimationCurves.easeIn,
        ));

      case AnimationType.scale:
        return Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: AnimationCurves.easeOutBack,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.type) {
          case AnimationType.slide:
            return Transform.translate(
              offset: Offset(0, _animation.value * 50),
              child: Opacity(
                opacity: 1.0 - _animation.value,
                child: widget.child,
              ),
            );

          case AnimationType.fade:
            return Opacity(
              opacity: _animation.value,
              child: widget.child,
            );

          case AnimationType.scale:
            return Transform.scale(
              scale: _animation.value,
              child: widget.child,
            );
        }
      },
    );
  }
}

/// Responsive button animation
class ResponsiveButtonAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool reduceMotion;
  final ButtonAnimationType type;

  const ResponsiveButtonAnimation({
    super.key,
    required this.child,
    this.onPressed,
    this.reduceMotion = false,
    this.type = ButtonAnimationType.scale,
  });

  @override
  State<ResponsiveButtonAnimation> createState() =>
      _ResponsiveButtonAnimationState();
}

class _ResponsiveButtonAnimationState extends State<ResponsiveButtonAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.reduceMotion
          ? const Duration(milliseconds: 50)
          : AnimationDuration.fast,
      vsync: this,
    );

    _animation = _createAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _createAnimation() {
    switch (widget.type) {
      case ButtonAnimationType.scale:
        return Tween<double>(
          begin: 1.0,
          end: 0.95,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: AnimationCurves.easeInOut,
        ));

      case ButtonAnimationType.bounce:
        return Tween<double>(
          begin: 1.0,
          end: 1.1,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: AnimationCurves.bounce,
        ));
    }
  }

  void _handlePress() {
    if (widget.reduceMotion) {
      widget.onPressed?.call();
      return;
    }

    _controller.forward().then((_) {
      _controller.reverse();
    });

    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handlePress,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Responsive loading animation
class ResponsiveLoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final bool reduceMotion;
  final LoadingAnimationType type;

  const ResponsiveLoadingAnimation({
    super.key,
    this.size = 24.0,
    this.color,
    this.reduceMotion = false,
    this.type = LoadingAnimationType.spinner,
  });

  @override
  State<ResponsiveLoadingAnimation> createState() =>
      _ResponsiveLoadingAnimationState();
}

class _ResponsiveLoadingAnimationState extends State<ResponsiveLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.reduceMotion
          ? const Duration(milliseconds: 1000)
          : const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = _createAnimation();

    if (!widget.reduceMotion) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _createAnimation() {
    switch (widget.type) {
      case LoadingAnimationType.spinner:
        return Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.linear,
        ));

      case LoadingAnimationType.pulse:
        return Tween<double>(
          begin: 0.5,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));

      case LoadingAnimationType.bounce:
        return Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.bounce,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;

    if (widget.reduceMotion) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.type) {
          case LoadingAnimationType.spinner:
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                value: _animation.value,
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            );

          case LoadingAnimationType.pulse:
            return Transform.scale(
              scale: _animation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            );

          case LoadingAnimationType.bounce:
            return Transform.translate(
              offset: Offset(0, -_animation.value * 10),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            );
        }
      },
    );
  }
}

/// Responsive stagger animation for lists
class ResponsiveStaggerAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final bool reduceMotion;
  final AnimationType type;

  const ResponsiveStaggerAnimation({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.reduceMotion = false,
    this.type = AnimationType.slide,
  });

  @override
  State<ResponsiveStaggerAnimation> createState() =>
      _ResponsiveStaggerAnimationState();
}

class _ResponsiveStaggerAnimationState
    extends State<ResponsiveStaggerAnimation> {
  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return Column(
        children: widget.children,
      );
    }

    return Column(
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        return ResponsiveListItemAnimation(
          index: index,
          delay: Duration(
              milliseconds: index * widget.staggerDelay.inMilliseconds),
          reduceMotion: widget.reduceMotion,
          type: widget.type,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Responsive hero animation
class ResponsiveHeroAnimation extends StatelessWidget {
  final Widget child;
  final String tag;
  final bool reduceMotion;
  final Duration duration;

  const ResponsiveHeroAnimation({
    super.key,
    required this.child,
    required this.tag,
    this.reduceMotion = false,
    this.duration = AnimationDuration.pageTransition,
  });

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return child;
    }

    return Hero(
      tag: tag,
      child: child,
      transitionOnUserGestures: true,
      flightShuttleBuilder:
          (context, animation, direction, fromContext, toContext) {
        return ResponsivePageTransition(
          animation: animation,
          type: PageTransitionType.scale,
          child: child,
        );
      },
    );
  }
}

// Enums

enum PageTransitionType {
  slide,
  fade,
  scale,
  hero,
}

enum AnimationType {
  slide,
  fade,
  scale,
}

enum ButtonAnimationType {
  scale,
  bounce,
}

enum LoadingAnimationType {
  spinner,
  pulse,
  bounce,
}

/// Utility class for responsive animation helpers
class ResponsiveAnimationHelper {
  /// Check if user prefers reduced motion
  static bool shouldReduceMotion(BuildContext context) {
    // In a real app, this would check accessibility settings
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// Get appropriate animation duration based on device and preferences
  static Duration getAnimationDuration(
      BuildContext context, Duration baseDuration) {
    if (shouldReduceMotion(context)) {
      return const Duration(milliseconds: 100);
    }

    // Reduce animation duration on slower devices
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    if (devicePixelRatio < 2.0) {
      return Duration(
          milliseconds: (baseDuration.inMilliseconds * 0.7).round());
    }

    return baseDuration;
  }

  /// Create a responsive animation controller
  static ResponsiveAnimationController createController({
    required BuildContext context,
    required TickerProvider vsync,
    Duration duration = AnimationDuration.normal,
  }) {
    return ResponsiveAnimationController(
      context: context,
      vsync: vsync,
      baseDuration: getAnimationDuration(context, duration),
      reduceMotion: shouldReduceMotion(context),
    );
  }
}

