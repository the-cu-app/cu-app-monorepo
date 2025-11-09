/// CU Stack Primitive
///
/// STACKED LAYOUT
/// - Positioning helpers
/// - Zero Material dependencies
///
/// Usage:
/// ```dart
/// CUStack(
///   children: [
///     Positioned.fill(child: Background()),
///     Positioned(top: 0, child: Overlay()),
///   ],
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';

class CUStack extends StatelessWidget {
  final List<Widget> children;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final StackFit fit;
  final Clip clipBehavior;

  const CUStack({
    Key? key,
    required this.children,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.fit = StackFit.loose,
    this.clipBehavior = Clip.hardEdge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: alignment,
      textDirection: textDirection,
      fit: fit,
      clipBehavior: clipBehavior,
      children: children,
    );
  }
}
