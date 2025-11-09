/// CU Spacer Primitive
///
/// SPACING FILLER
/// - CU spacing tokens
/// - Zero Material dependencies
///
/// Usage:
/// ```dart
/// CURow(
///   children: [
///     Widget1(),
///     CUSpacer(),
///     Widget2(),
///   ],
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';

class CUSpacer extends StatelessWidget {
  final int flex;

  const CUSpacer({
    Key? key,
    this.flex = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Spacer(flex: flex);
  }
}
