/// CU Image Primitive
///
/// IMAGE DISPLAY
/// - Loading states
/// - Error handling
/// - Zero Material dependencies
///
/// Usage:
/// ```dart
/// CUImage(
///   'https://example.com/image.jpg',
///   width: 100,
///   height: 100,
/// )
/// ```
import 'package:flutter/widgets.dart';
import '../foundation/index.dart';
import 'icon.dart';
import 'loading_spinner.dart';

class CUImage extends StatelessWidget {
  final String src;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CUImage(
    this.src, {
    Key? key,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return Image.network(
      src,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: theme.colors.surface,
              child: Center(
                child: CULoadingSpinner(color: theme.colors.primary),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: theme.colors.surface,
              child: CUIcon(
                icon: IconData(0xe000), // placeholder icon
                color: theme.colors.neutral,
                size: width != null && height != null ? (width! < height! ? width! : height!) / 2 : 24,
              ),
            );
      },
    );
  }
}
