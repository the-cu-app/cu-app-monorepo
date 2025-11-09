import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class SaberGlowTracedLogo extends StatefulWidget {
  final String svgPath;
  final double width;
  final double height;
  final Color glowColor;
  final Duration duration;
  final VoidCallback? onComplete;

  const SaberGlowTracedLogo({
    Key? key,
    required this.svgPath,
    this.width = 147,
    this.height = 32,
    this.glowColor = Colors.white,
    this.duration = const Duration(seconds: 2),
    this.onComplete,
  }) : super(key: key);

  @override
  State<SaberGlowTracedLogo> createState() => _SaberGlowTracedLogoState();
}

class _SaberGlowTracedLogoState extends State<SaberGlowTracedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward().then((_) {
      if (mounted && !_hasCompleted) {
        _hasCompleted = true;
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: SaberGlowPainter(
            svgPath: widget.svgPath,
            progress: _animation.value,
            glowColor: widget.glowColor,
          ),
        );
      },
    );
  }
}

class SaberGlowPainter extends CustomPainter {
  final String svgPath;
  final double progress;
  final Color glowColor;

  SaberGlowPainter({
    required this.svgPath,
    required this.progress,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _parseSvgPath(svgPath);
    final pathMetric = path.computeMetrics().first;
    final pathLength = pathMetric.length;
    
    // Calculate the traced portion
    final tracedLength = pathLength * progress;
    
    // Extract the traced path
    final tracedPath = pathMetric.extractPath(0.0, tracedLength);
    
    // Calculate glow intensity based on progress
    final glowIntensity = math.sin(progress * math.pi) * 0.5 + 0.5;
    
    // Draw multiple layers for glow effect (saber glow)
    for (int i = 5; i >= 0; i--) {
      final layerOpacity = (glowIntensity * (6 - i) / 6) * 0.6;
      final layerWidth = 2.0 + (i * 1.5);
      
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(layerOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = layerWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, i * 2.0);
      
      canvas.drawPath(tracedPath, glowPaint);
    }
    
    // Draw the main traced line
    final mainPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    canvas.drawPath(tracedPath, mainPaint);
    
    // Draw glowing dot at the end of the trace
    if (progress > 0 && progress < 1.0) {
      final currentPoint = pathMetric.getTangentForOffset(tracedLength);
      if (currentPoint != null) {
        // Outer glow
        final outerGlowPaint = Paint()
          ..color = glowColor.withOpacity(0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
        canvas.drawCircle(currentPoint.position, 6, outerGlowPaint);
        
        // Inner bright dot
        final dotPaint = Paint()
          ..color = glowColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(currentPoint.position, 3, dotPaint);
      }
    }
  }

  Path _parseSvgPath(String svgPath) {
    final path = Path();
    final commands = svgPath.split(RegExp(r'(?=[MLHVCSQTAZ])', caseSensitive: false));

    double currentX = 0;
    double currentY = 0;
    double startX = 0;
    double startY = 0;

    for (var command in commands) {
      if (command.isEmpty) continue;

      final type = command[0];
      final coords = command.substring(1).trim().split(RegExp(r'[ ,]+'));
      final values = coords.where((s) => s.isNotEmpty).map((s) => double.tryParse(s) ?? 0).toList();

      switch (type.toUpperCase()) {
        case 'M': // MoveTo
          if (values.length >= 2) {
            currentX = values[0];
            currentY = values[1];
            startX = currentX;
            startY = currentY;
            path.moveTo(currentX, currentY);
          }
          break;
        case 'L': // LineTo
          if (values.length >= 2) {
            currentX = values[0];
            currentY = values[1];
            path.lineTo(currentX, currentY);
          }
          break;
        case 'H': // Horizontal LineTo
          if (values.isNotEmpty) {
            currentX = values[0];
            path.lineTo(currentX, currentY);
          }
          break;
        case 'V': // Vertical LineTo
          if (values.isNotEmpty) {
            currentY = values[0];
            path.lineTo(currentX, currentY);
          }
          break;
        case 'C': // Cubic Bezier
          if (values.length >= 6) {
            path.cubicTo(
              values[0], values[1],
              values[2], values[3],
              values[4], values[5],
            );
            currentX = values[4];
            currentY = values[5];
          }
          break;
        case 'Z': // Close path
          path.close();
          currentX = startX;
          currentY = startY;
          break;
      }
    }

    return path;
  }

  @override
  bool shouldRepaint(SaberGlowPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowColor != glowColor;
  }
}

