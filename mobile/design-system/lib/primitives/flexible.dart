/// CU Flexible Primitive
///
/// FLEXIBLE LAYOUT
/// - Flex control
/// - Zero Material dependencies
///
/// Usage:
/// ```dart
/// CUFlexible(
///   flex: 1,
///   child: Content(),
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';

class CUFlexible extends StatelessWidget {
  final Widget child;
  final int flex;
  final FlexFit fit;

  const CUFlexible({
    Key? key,
    required this.child,
    this.flex = 1,
    this.fit = FlexFit.loose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: flex,
      fit: fit,
      child: child,
    );
  }
}
