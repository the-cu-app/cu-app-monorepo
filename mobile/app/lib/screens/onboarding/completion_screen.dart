import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'dart:math' as math;
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../../config/cu_config_service.dart';

/// Completion screen - celebratory finish to onboarding
class CompletionScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const CompletionScreen({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _checkmarkController;
  late Animation<double> _checkmarkAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _checkmarkAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _checkmarkController,
      curve: const Interval(0, 0.6, curve: Curves.elasticOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _checkmarkController,
      curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _checkmarkController,
      curve: const Interval(0.5, 1, curve: Curves.easeIn),
    ));
    
    // Generate confetti particles
    _generateConfetti();
    
    // Start animations
    _checkmarkController.forward();
    _confettiController.repeat();
  }

  void _generateConfetti() {
    final random = math.Random();
    const colors = [
      Color(0xFF1DB954),
      Color(0xFF6B5B95),
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFFF7B731),
    ];
    
    for (int i = 0; i < 50; i++) {
      _particles.add(_ConfettiParticle(
        color: colors[random.nextInt(colors.length)],
        x: random.nextDouble(),
        y: random.nextDouble() * 0.5 - 0.5,
        size: random.nextDouble() * 10 + 5,
        speed: random.nextDouble() * 2 + 1,
        rotation: random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _checkmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti animation
        AnimatedBuilder(
          animation: _confettiController,
          builder: (context, child) {
            return CustomPaint(
              painter: _ConfettiPainter(
                particles: _particles,
                progress: _confettiController.value,
              ),
              size: Size.infinite,
            );
          },
        ),
        
        // Main content
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const SizedBox(height: 40),
              // Animated checkmark
              AnimatedBuilder(
                animation: _checkmarkController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _checkmarkAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1DB954).withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Success message
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'You\'re All Set!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to your new banking experience',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Quick tips
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Tips to Get Started',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTip(
                              Icons.account_balance_wallet,
                              'Add funds to your account to start',
                              const Color(0xFF4ECDC4),
                            ),
                            _buildTip(
                              Icons.credit_card,
                              'Create your first virtual card instantly',
                              const Color(0xFFF7B731),
                            ),
                            _buildTip(
                              Icons.link,
                              'Connect your other bank accounts',
                              const Color(0xFF6B5B95),
                            ),
                            _buildTip(
                              Icons.settings,
                              'Customize your experience in Settings',
                              const Color(0xFFFF6B6B),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Test account info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1DB954).withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Test Accounts Available',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'General: test.general@${CUConfigService().cuDomain}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'Business: test.business@${CUConfigService().cuDomain}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'Youth: test.youth@${CUConfigService().cuDomain}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'Fiduciary: test.fiduciary@${CUConfigService().cuDomain}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Password: 123asdfghjkl;\'',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Start button
                      FilledButton(
                        onPressed: widget.onComplete,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1DB954),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 60,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Start Banking',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

  Widget _buildTip(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double rotation;

  _ConfettiParticle({
    required this.color,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.rotation,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1 - progress * 0.5)
        ..style = PaintingStyle.fill;
      
      final y = (particle.y + progress * particle.speed) * size.height;
      final x = particle.x * size.width + 
          math.sin(progress * 2 * math.pi + particle.rotation) * 50;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + progress * 2 * math.pi);
      
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size * 0.6,
      );
      
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}