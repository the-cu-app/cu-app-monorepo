/// CU SizedBox Primitive
///
/// SIZE CONSTRAINTS
/// - CU spacing tokens
/// - Zero Material dependencies
///
/// Usage:
/// ```dart
/// CUSizedBox(
///   width: CUSpacing.xl,
///   height: CUSpacing.xl,
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';

class CUSizedBox extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;

  const CUSizedBox({
    Key? key,
    this.child,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }
}
