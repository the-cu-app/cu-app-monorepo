import 'dart:math';
import 'package:flutter/material.dart';

class ParticleAnimation extends StatefulWidget {
  final Color particleColor;
  final int numberOfParticles;
  final double speedFactor;
  final Widget child;
  
  const ParticleAnimation({
    Key? key,
    this.particleColor = Colors.white24,
    this.numberOfParticles = 50,
    this.speedFactor = 1.0,
    required this.child,
  }) : super(key: key);

  @override
  State<ParticleAnimation> createState() => _ParticleAnimationState();
}

class _ParticleAnimationState extends State<ParticleAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    particles = List.generate(
      widget.numberOfParticles,
      (_) => Particle(random),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: particles,
                  animationValue: _controller.value,
                  color: widget.particleColor,
                  speedFactor: widget.speedFactor,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double speed;
  late double radius;
  late double opacity;
  final Random random;

  Particle(this.random) {
    reset();
  }

  void reset() {
    x = random.nextDouble();
    y = random.nextDouble();
    speed = 0.2 + random.nextDouble() * 0.8;
    radius = 1.0 + random.nextDouble() * 2.0;
    opacity = 0.3 + random.nextDouble() * 0.7;
  }

  void update(double speedFactor) {
    y -= speed * 0.01 * speedFactor;
    
    // Reset particle when it goes off screen
    if (y < -0.1) {
      y = 1.1;
      x = random.nextDouble();
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Color color;
  final double speedFactor;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.color,
    required this.speedFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update(speedFactor);
      
      final paint = Paint()
        ..color = color.withOpacity(particle.opacity * 0.5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}