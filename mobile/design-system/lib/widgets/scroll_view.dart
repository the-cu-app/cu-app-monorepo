/// CU ScrollView Widget
///
/// SCROLLABLE CONTENT
/// - CU styling
/// - Zero Material dependencies
///
/// Usage:
/// ```dart
/// CUScrollView(
///   child: Content(),
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';

class CUScrollView extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollPhysics? physics;

  const CUScrollView({
    Key? key,
    required this.child,
    this.controller,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      padding: padding,
      scrollDirection: scrollDirection,
      reverse: reverse,
      physics: physics,
      child: child,
    );
  }
}
