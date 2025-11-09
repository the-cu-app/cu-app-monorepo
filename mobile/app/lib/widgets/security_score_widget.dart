import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/security_model.dart';

class SecurityScoreWidget extends StatefulWidget {
  final double score;
  final SecurityLevel level;
  final VoidCallback? onTap;

  const SecurityScoreWidget({
    super.key,
    required this.score,
    required this.level,
    this.onTap,
  });

  @override
  State<SecurityScoreWidget> createState() => _SecurityScoreWidgetState();
}

class _SecurityScoreWidgetState extends State<SecurityScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.score,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(SecurityScoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _scoreAnimation = Tween<double>(
        begin: oldWidget.score,
        end: widget.score,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(double score) {
    if (score <= 0.33) {
      return Theme.of(context).colorScheme.error;
    } else if (score <= 0.66) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Security Score',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _scoreAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(180, 180),
                        painter: _SecurityScorePainter(
                          score: _scoreAnimation.value,
                          color: _getScoreColor(_scoreAnimation.value),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.1),
                        ),
                      );
                    },
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _scoreAnimation,
                        builder: (context, child) {
                          return Text(
                            '${(_scoreAnimation.value * 100).toInt()}',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(_scoreAnimation.value),
                                ),
                          );
                        },
                      ),
                      Text(
                        widget.level.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _getSecurityMessage(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (widget.onTap != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: widget.onTap,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View Recommendations'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getSecurityMessage() {
    switch (widget.level) {
      case SecurityLevel.low:
        return 'Your account security needs improvement. Tap to see recommendations.';
      case SecurityLevel.medium:
        return 'Your account has moderate security. There\'s room for improvement.';
      case SecurityLevel.high:
        return 'Excellent! Your account is well-protected.';
    }
  }
}

class _SecurityScorePainter extends CustomPainter {
  final double score;
  final Color color;
  final Color backgroundColor;

  _SecurityScorePainter({
    required this.score,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 20.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Draw score arc
    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * score;

    canvas.drawArc(rect, startAngle, sweepAngle, false, scorePaint);
  }

  @override
  bool shouldRepaint(covariant _SecurityScorePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class SecurityScoreMiniWidget extends StatelessWidget {
  final double score;
  final SecurityLevel level;
  final VoidCallback? onTap;

  const SecurityScoreMiniWidget({
    super.key,
    required this.score,
    required this.level,
    this.onTap,
  });

  Color _getScoreColor(BuildContext context, double score) {
    if (score <= 0.33) {
      return Theme.of(context).colorScheme.error;
    } else if (score <= 0.66) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(context, score);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scoreColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scoreColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.security,
              color: scoreColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security: ${level.displayName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scoreColor,
                        ),
                  ),
                  Text(
                    '${(score * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scoreColor.withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}