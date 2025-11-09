import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../supahyper_ds.dart';

// Enhanced connect account screen with advanced animations
class DSConnectAccountScreen extends StatefulWidget {
  final VoidCallback? onConnect;
  final VoidCallback? onLogin;
  
  const DSConnectAccountScreen({
    super.key,
    this.onConnect,
    this.onLogin,
  });
  
  @override
  State<DSConnectAccountScreen> createState() => _DSConnectAccountScreenState();
}

class _DSConnectAccountScreenState extends State<DSConnectAccountScreen> 
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _heroController;
  late AnimationController _cardController;
  late AnimationController _particleController;
  late AnimationController _featureController;
  late AnimationController _fadeController;
  
  // Animations
  late Animation<double> _heroScale;
  late Animation<double> _heroRotation;
  late Animation<Offset> _heroFloat;
  late Animation<double> _cardRotation;
  late Animation<double> _particleRotation;
  late List<Animation<Offset>> _featureSlides;
  late Animation<double> _fadeAnimation;
  
  // State
  bool _isConnecting = false;
  
  // Particle system
  final List<Particle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _startAnimations();
  }
  
  void _initializeAnimations() {
    // Hero animation controller
    _heroController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    // Card 3D rotation controller
    _cardController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    // Feature cards stagger controller
    _featureController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Fade controller
    _fadeController = AnimationController(
      duration: DSMotion.durationSlower,
      vsync: this,
    );
    
    // Setup animations
    _heroScale = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: DSMotion.smooth,
    ));
    
    _heroRotation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: DSMotion.smooth,
    ));
    
    _heroFloat = Tween<Offset>(
      begin: const Offset(0, -0.01),
      end: const Offset(0, 0.01),
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: DSMotion.smooth,
    ));
    
    _cardRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.linear,
    ));
    
    _particleRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: DSMotion.decelerate,
    ));
    
    // Feature card stagger animations
    _featureSlides = List.generate(4, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _featureController,
        curve: Interval(
          index * 0.1,
          0.6 + index * 0.1,
          curve: DSMotion.spring,
        ),
      ));
    });
  }
  
  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 3 + 1,
        speed: random.nextDouble() * 0.5 + 0.5,
      ));
    }
  }
  
  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _featureController.forward();
  }
  
  @override
  void dispose() {
    _heroController.dispose();
    _cardController.dispose();
    _particleController.dispose();
    _featureController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Animated particle background
            _buildParticleBackground(),
            
            // Main content
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: DSSpacing.pagePadding,
                      child: Column(
                        children: [
                          const SizedBox(height: DSSpacing.space8),
                          
                          // Hero section with 3D card
                          _buildHeroSection(),
                          
                          const SizedBox(height: DSSpacing.space12),
                          
                          // Title and subtitle
                          _buildHeader(),
                          
                          const SizedBox(height: DSSpacing.space10),
                          
                          // Security badge
                          _buildSecurityBadge(),
                          
                          const SizedBox(height: DSSpacing.space12),
                          
                          // Feature cards
                          _buildFeatures(),
                          
                          const SizedBox(height: DSSpacing.space20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Fixed bottom CTA buttons
            _buildBottomCTA(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particleRotation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            rotation: _particleRotation.value,
          ),
          child: Container(),
        );
      },
    );
  }
  
  Widget _buildHeroSection() {
    return SizedBox(
      height: 280,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _heroScale,
          _heroRotation,
          _heroFloat,
          _cardRotation,
        ]),
        builder: (context, child) {
          return SlideTransition(
            position: _heroFloat,
            child: Transform.scale(
              scale: _heroScale.value,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_cardRotation.value * 0.3)
                  ..rotateZ(_heroRotation.value),
                child: _build3DCard(),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _build3DCard() {
    return Container(
      width: 320,
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2D2D2D),
          ],
        ),
        borderRadius: DSBorders.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: DSColors.primary.withOpacity(0.3),
            offset: const Offset(0, 20),
            blurRadius: 40,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Holographic overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: DSBorders.borderRadiusXl,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.2),
                    Colors.purple.withOpacity(0.1),
                    Colors.pink.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          
          // Card content
          Padding(
            padding: DSSpacing.insetLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DSText(
                      'SUPAHYPER',
                      variant: DSTextVariant.titleLarge,
                      color: Colors.white,
                      fontWeight: DSTypography.weightBold,
                    ),
                    const DSIcon(
                      Icons.contactless,
                      size: DSIconSize.lg,
                      color: Colors.white,
                    ),
                  ],
                ),
                const Spacer(),
                DSText.mono(
                  '**** **** **** 2025',
                  color: Colors.white70,
                ),
                const SizedBox(height: DSSpacing.space2),
                DSText(
                  'MEMBER SINCE 2025',
                  variant: DSTextVariant.labelSmall,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        DSText(
          DSStrings.connectTitle,
          variant: DSTextVariant.headlineLarge,
          fontWeight: DSTypography.weightBold,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DSSpacing.space3),
        DSText(
          DSStrings.connectSubtitle,
          variant: DSTextVariant.bodyLarge,
          color: DSColors.textSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildSecurityBadge() {
    return Container(
      padding: DSSpacing.insetLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DSColors.surfaceElevated,
            DSColors.surface,
          ],
        ),
        borderRadius: DSBorders.borderRadiusXl,
        border: Border.all(
          color: DSColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: DSSpacing.insetMd,
            decoration: BoxDecoration(
              color: DSColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const DSIcon(
              Icons.security,
              size: DSIconSize.xl,
              color: DSColors.primary,
            ),
          ),
          const SizedBox(height: DSSpacing.space4),
          DSText(
            DSStrings.connectSecurityTitle,
            variant: DSTextVariant.titleLarge,
            fontWeight: DSTypography.weightBold,
          ),
          const SizedBox(height: DSSpacing.space2),
          DSText(
            DSStrings.connectSecurityDescription,
            variant: DSTextVariant.bodyMedium,
            color: DSColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatures() {
    final features = [
      {
        'icon': Icons.rocket_launch,
        'title': DSStrings.featureSpeedTitle,
        'description': DSStrings.featureSpeedDescription,
        'color': Colors.blue,
      },
      {
        'icon': Icons.link,
        'title': DSStrings.featureLegacyTitle,
        'description': DSStrings.featureLegacyDescription,
        'color': Colors.green,
      },
      {
        'icon': Icons.verified_user,
        'title': DSStrings.featureKYCTitle,
        'description': DSStrings.featureKYCDescription,
        'color': Colors.orange,
      },
      {
        'icon': Icons.cleaning_services,
        'title': DSStrings.featureMXTitle,
        'description': DSStrings.featureMXDescription,
        'color': Colors.purple,
      },
    ];
    
    return Column(
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        
        return SlideTransition(
          position: _featureSlides[index],
          child: _buildFeatureCard(feature),
        );
      }).toList(),
    );
  }
  
  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    return Container(
      margin: const EdgeInsets.only(bottom: DSSpacing.space4),
      padding: DSSpacing.insetMd,
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: DSBorders.borderRadiusLg,
        border: Border.all(
          color: DSColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: DSSpacing.insetSm,
            decoration: BoxDecoration(
              color: (feature['color'] as Color).withOpacity(0.1),
              borderRadius: DSBorders.borderRadiusMd,
            ),
            child: Icon(
              feature['icon'],
              size: DSSpacing.iconMd,
              color: feature['color'],
            ),
          ),
          const SizedBox(width: DSSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  feature['title'],
                  variant: DSTextVariant.titleMedium,
                  fontWeight: DSTypography.weightSemiBold,
                ),
                const SizedBox(height: DSSpacing.space1),
                DSText(
                  feature['description'],
                  variant: DSTextVariant.bodySmall,
                  color: DSColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomCTA() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          DSSpacing.space6,
          DSSpacing.space6,
          DSSpacing.space6,
          DSSpacing.space10,
        ),
        decoration: BoxDecoration(
          color: DSColors.background,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              DSColors.background.withOpacity(0),
              DSColors.background,
              DSColors.background,
            ],
          ),
        ),
        child: Column(
          children: [
            DSButton(
              label: _isConnecting ? DSStrings.statusConnecting : DSStrings.btnConnect,
              onPressed: _isConnecting ? null : _handleConnect,
              variant: DSButtonVariant.primary,
              size: DSButtonSize.large,
              isFullWidth: true,
              isLoading: _isConnecting,
            ),
            const SizedBox(height: DSSpacing.space3),
            DSButton(
              label: DSStrings.btnLogin,
              onPressed: _isConnecting ? null : widget.onLogin,
              variant: DSButtonVariant.secondary,
              size: DSButtonSize.large,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleConnect() async {
    setState(() => _isConnecting = true);
    
    if (widget.onConnect != null) {
      widget.onConnect!();
    }
    
    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isConnecting = false);
    }
  }
}

// Particle class for background animation
class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  
  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

// Custom painter for particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double rotation;
  
  ParticlePainter({
    required this.particles,
    required this.rotation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DSColors.primary.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    for (final particle in particles) {
      final offset = Offset(
        particle.x * size.width + math.cos(rotation * particle.speed) * 20,
        particle.y * size.height + math.sin(rotation * particle.speed) * 20,
      );
      
      canvas.drawCircle(offset, particle.size, paint);
    }
  }
  
  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}