/// CU Wrap Primitive
///
/// WRAPPING LAYOUT
/// - CU spacing tokens
/// - Zero Material dependencies
///
/// Usage:
/// ```dart
/// CUWrap(
///   spacing: CUSpacing.md,
///   runSpacing: CUSpacing.sm,
///   children: [Widget1(), Widget2()],
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';

class CUWrap extends StatelessWidget {
  final List<Widget> children;
  final Axis direction;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAlignment;
  final WrapAlignment runAlignment;
  final double spacing;
  final double runSpacing;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final Clip clipBehavior;

  const CUWrap({
    Key? key,
    required this.children,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.crossAlignment = WrapCrossAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.clipBehavior = Clip.none,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: direction,
      alignment: alignment,
      crossAlignment: crossAlignment,
      runAlignment: runAlignment,
      spacing: spacing,
      runSpacing: runSpacing,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      clipBehavior: clipBehavior,
      children: children,
    );
  }
}
