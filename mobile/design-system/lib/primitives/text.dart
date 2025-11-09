/// CU Text Primitive
///
/// TEXT DISPLAY
/// - CUTypography integration
/// - Theme colors
/// - Zero Material dependencies
/// - Ultra thin design
///
/// Usage:
/// ```dart
/// CUText(
///   'Hello World',
///   style: CUTypography.titleLarge,
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';

class CUText extends StatelessWidget {
  final String data;
  final CUTypographyStyle? style;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;
  final TextWidthBasis? textWidthBasis;

  const CUText(
    this.data, {
    Key? key,
    this.style,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textWidthBasis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final textColor = color ?? theme.colors.onBackground;
    final textStyle = style?.toTextStyle(color: textColor) ??
        CUTypography.bodyMedium.toTextStyle(color: textColor);

    return Text(
      data,
      style: textStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
      textWidthBasis: textWidthBasis,
    );
  }
}
