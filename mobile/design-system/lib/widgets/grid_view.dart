/// CU GridView Widget
///
/// SCROLLABLE GRID
/// - CU spacing
/// - Responsive columns
/// - Zero Material dependencies
///
/// Usage:
/// ```dart
/// CUGridView(
///   crossAxisCount: 2,
///   spacing: CUSpacing.md,
///   children: [Item1(), Item2()],
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';

class CUGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final ScrollController? controller;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;

  const CUGridView({
    Key? key,
    required this.children,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 0,
    this.mainAxisSpacing = 0,
    this.childAspectRatio = 1.0,
    this.controller,
    this.shrinkWrap = false,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final gridPadding = padding ?? EdgeInsets.all(CUSpacing.md);

    return GridView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      padding: gridPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
