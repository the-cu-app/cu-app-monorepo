import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class CameraOverlayWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showGuideLines;
  final VoidCallback? onCapture;
  final VoidCallback? onCancel;

  const CameraOverlayWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.showGuideLines = true,
    this.onCapture,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark overlay with cut-out
        CustomPaint(
          size: Size.infinite,
          painter: OverlayPainter(
            overlayColor: Colors.black.withValues(alpha: 0.7),
          ),
        ),
        // Corner guides
        if (showGuideLines) ...[
          // Top left corner
          Positioned(
            top: 80,
            left: 20,
            child: _buildCornerGuide(
              topLeft: true,
              topRight: false,
              bottomLeft: false,
              bottomRight: false,
            ),
          ),
          // Top right corner
          Positioned(
            top: 80,
            right: 20,
            child: _buildCornerGuide(
              topLeft: false,
              topRight: true,
              bottomLeft: false,
              bottomRight: false,
            ),
          ),
          // Bottom left corner
          Positioned(
            bottom: 200,
            left: 20,
            child: _buildCornerGuide(
              topLeft: false,
              topRight: false,
              bottomLeft: true,
              bottomRight: false,
            ),
          ),
          // Bottom right corner
          Positioned(
            bottom: 200,
            right: 20,
            child: _buildCornerGuide(
              topLeft: false,
              topRight: false,
              bottomLeft: false,
              bottomRight: true,
            ),
          ),
        ],
        // Instructions
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Column(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        // Control buttons
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel button
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                // Capture button
                GestureDetector(
                  onTap: onCapture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera,
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                ),
                // Placeholder for symmetry
                const SizedBox(width: 64),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerGuide({
    required bool topLeft,
    required bool topRight,
    required bool bottomLeft,
    required bool bottomRight,
  }) {
    return CustomPaint(
      size: const Size(60, 60),
      painter: CornerGuidePainter(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
        color: Colors.green,
      ),
    );
  }
}

class OverlayPainter extends CustomPainter {
  final Color overlayColor;

  OverlayPainter({required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    // Create path for the overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create cut-out rectangle
    const margin = 20.0;
    const topMargin = 120.0;
    const bottomMargin = 240.0;
    
    final cutoutRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        margin,
        topMargin,
        size.width - margin,
        size.height - bottomMargin,
      ),
      const Radius.circular(12),
    );

    // Subtract the cutout from the path
    path.addRRect(cutoutRect);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CornerGuidePainter extends CustomPainter {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;
  final Color color;

  CornerGuidePainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const lineLength = 30.0;

    if (topLeft) {
      // Horizontal line
      canvas.drawLine(
        const Offset(0, 0),
        const Offset(lineLength, 0),
        paint,
      );
      // Vertical line
      canvas.drawLine(
        const Offset(0, 0),
        const Offset(0, lineLength),
        paint,
      );
    } else if (topRight) {
      // Horizontal line
      canvas.drawLine(
        Offset(size.width - lineLength, 0),
        Offset(size.width, 0),
        paint,
      );
      // Vertical line
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, lineLength),
        paint,
      );
    } else if (bottomLeft) {
      // Horizontal line
      canvas.drawLine(
        Offset(0, size.height),
        Offset(lineLength, size.height),
        paint,
      );
      // Vertical line
      canvas.drawLine(
        Offset(0, size.height - lineLength),
        Offset(0, size.height),
        paint,
      );
    } else if (bottomRight) {
      // Horizontal line
      canvas.drawLine(
        Offset(size.width - lineLength, size.height),
        Offset(size.width, size.height),
        paint,
      );
      // Vertical line
      canvas.drawLine(
        Offset(size.width, size.height - lineLength),
        Offset(size.width, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}