/// CU Container Primitive
///
/// LAYOUT WRAPPER
/// - Theme colors, padding, constraints
/// - Zero Material dependencies
/// - Ultra thin design
///
/// Usage:
/// ```dart
/// CUContainer(
///   padding: CUSpacing.md,
///   color: theme.colors.surface,
///   child: Text('Content'),
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';

class CUContainer extends StatelessWidget {
  final Widget? child;
  final Color? color;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final Decoration? decoration;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;

  const CUContainer({
    Key? key,
    this.child,
    this.color,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.constraints,
    this.decoration,
    this.alignment,
    this.clipBehavior = Clip.none,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final bgColor = backgroundColor ?? color ?? theme.colors.surface;

    Widget container = Container(
      width: width,
      height: height,
      constraints: constraints,
      padding: padding,
      margin: margin,
      decoration: decoration ??
          BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(CURadius.sm),
          ),
      alignment: alignment,
      clipBehavior: clipBehavior,
      child: child,
    );

    return container;
  }
}
