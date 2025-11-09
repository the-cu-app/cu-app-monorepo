/// CU ListView Widget
///
/// SCROLLABLE LIST
/// - CU styling
/// - Pull-to-refresh support
/// - Zero Material dependencies
///
/// Usage:
/// ```dart
/// CUListView(
///   children: [Item1(), Item2()],
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';
import '../primitives/index.dart';

class CUListView extends StatelessWidget {
  final List<Widget>? children;
  final IndexedWidgetBuilder? itemBuilder;
  final int? itemCount;
  final ScrollController? controller;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final double? spacing;

  const CUListView({
    Key? key,
    this.children,
    this.itemBuilder,
    this.itemCount,
    this.controller,
    this.shrinkWrap = false,
    this.padding,
    this.spacing,
  }) : assert(children != null || itemBuilder != null, 'Must provide children or itemBuilder'),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final listPadding = padding ?? EdgeInsets.all(CUSpacing.md);

    if (children != null) {
      if (spacing != null && spacing! > 0) {
        // Add spacing between items
        final spacedChildren = <Widget>[];
        for (int i = 0; i < children!.length; i++) {
          if (i > 0) {
            spacedChildren.add(CUSizedBox(height: spacing));
          }
          spacedChildren.add(children![i]);
        }
        return ListView(
          controller: controller,
          shrinkWrap: shrinkWrap,
          padding: listPadding,
          children: spacedChildren,
        );
      }
      return ListView(
        controller: controller,
        shrinkWrap: shrinkWrap,
        padding: listPadding,
        children: children!,
      );
    }

    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      padding: listPadding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final item = itemBuilder!(context, index);
        if (spacing != null && spacing! > 0 && index > 0) {
          return CUColumn(
            spacing: spacing,
            children: [
              CUSizedBox(height: spacing),
              item,
            ],
          );
        }
        return item;
      },
    );
  }
}
