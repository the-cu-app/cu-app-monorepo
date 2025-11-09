/// CU Column Primitive
///
/// VERTICAL LAYOUT
/// - CU spacing tokens
/// - Theme alignment
/// - Zero Material dependencies
///
/// Usage:
/// ```dart
/// CUColumn(
///   spacing: CUSpacing.md,
///   children: [Widget1(), Widget2()],
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';

class CUColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final double? spacing;

  const CUColumn({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.spacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (spacing == null || spacing == 0) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        textBaseline: textBaseline,
        children: children,
      );
    }

    // Add spacing between children
    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        spacedChildren.add(SizedBox(height: spacing));
      }
      spacedChildren.add(children[i]);
    }

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      children: spacedChildren,
    );
  }
}
