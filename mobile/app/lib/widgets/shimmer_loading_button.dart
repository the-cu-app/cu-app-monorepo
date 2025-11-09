import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Colors;
import 'dart:math' as math;

class ShimmerLoadingButton extends StatefulWidget {
  final bool isLoading;
  final String label;
  final String loadingLabel;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final EdgeInsets padding;

  const ShimmerLoadingButton({
    super.key,
    required this.isLoading,
    required this.label,
    required this.loadingLabel,
    this.onPressed,
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
    this.borderRadius = 100,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  @override
  State<ShimmerLoadingButton> createState() => _ShimmerLoadingButtonState();
}

class _ShimmerLoadingButtonState extends State<ShimmerLoadingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onPressed,
      child: Container(
        width: double.infinity,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.isLoading
              ? widget.backgroundColor.withOpacity(0.8)
              : widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: widget.isLoading
            ? _buildShimmerText()
            : Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildShimmerText() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                math.max(0.0, _shimmerController.value - 0.3),
                math.max(0.0, _shimmerController.value),
                math.min(_shimmerController.value + 0.3, 1.0),
              ],
              colors: [
                widget.textColor.withOpacity(0.3),
                widget.textColor,
                widget.textColor.withOpacity(0.3),
              ],
            ).createShader(bounds);
          },
          child: Center(
            child: Text(
              widget.loadingLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.textColor,
                fontFamily: 'Geist',
              ),
            ),
          ),
        );
      },
    );
  }
}
