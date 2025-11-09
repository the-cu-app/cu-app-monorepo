/// CU Expanded Primitive
///
/// FLEX EXPANSION
/// - Flex control
/// - Zero Material dependencies
///
/// Usage:
/// ```dart
/// CUExpanded(
///   flex: 2,
///   child: Content(),
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';

class CUExpanded extends StatelessWidget {
  final Widget child;
  final int flex;

  const CUExpanded({
    Key? key,
    required this.child,
    this.flex = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: child,
    );
  }
}
