/// CU Padding Primitive
///
/// SPACING WRAPPER
/// - CU spacing tokens
/// - Zero Material dependencies
///
/// Usage:
/// ```dart
/// CUPadding(
///   padding: CUSpacing.md,
///   child: Text('Content'),
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';

class CUPadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CUPadding({
    Key? key,
    required this.child,
    required this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child,
    );
  }
}
