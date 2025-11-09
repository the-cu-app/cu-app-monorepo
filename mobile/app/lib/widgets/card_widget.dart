import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import 'particle_animation.dart';

class CardWidget extends StatefulWidget {
  final BankCard card;
  final VoidCallback? onTap;
  final bool showDetails;
  final bool isHero;
  
  const CardWidget({
    Key? key,
    required this.card,
    this.onTap,
    this.showDetails = false,
    this.isHero = false,
  }) : super(key: key);

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _toggleFlip() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final cardContent = AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final isShowingFront = _flipAnimation.value < 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(pi * _flipAnimation.value),
          child: isShowingFront
              ? _buildCardFront(context)
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _buildCardBack(context),
                ),
        );
      },
    );
    
    if (widget.isHero) {
      return Hero(
        tag: 'card_${card.id}',
        child: cardContent,
      );
    }
    
    return cardContent;
  }
  
  Widget _buildCardFront(BuildContext context) {
    final theme = Theme.of(context);
    final card = widget.card;
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: widget.showDetails && card.isVirtual ? _toggleFlip : widget.onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: _getCardGradient(card),
                ),
              ),
              
              // Particle animation for premium cards
              if (card.type == CardType.credit || card.metadata?['design'] == 'metal_black')
                ParticleAnimation(
                  particleColor: Colors.white.withOpacity(0.2),
                  numberOfParticles: 30,
                  speedFactor: 0.5,
                  child: const SizedBox.expand(),
                ),
              
              // Card content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Card type and status
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.isVirtual ? 'VIRTUAL CARD' : card.type.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                            if (card.isPrimary)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'PRIMARY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Network logo
                        _buildNetworkLogo(card.network),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Card number
                    Text(
                      widget.showDetails ? card.displayCardNumber : card.displayCardNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                        fontFamily: 'GeistMono',
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Card details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Cardholder name
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CARD HOLDER',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card.cardholderName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        // Expiration date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EXPIRES',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card.expirationDate,
                              style: TextStyle(
                                color: card.isExpired ? Colors.red.shade300 : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        // Lock indicator
                        if (card.controls.isLocked)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Chip
              if (card.metadata?['chip'] == true)
                Positioned(
                  left: 24,
                  top: 60,
                  child: Container(
                    width: 50,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade200,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: ChipPainter(),
                    ),
                  ),
                ),
              
              // Contactless indicator
              if (card.metadata?['contactless'] == true)
                Positioned(
                  right: 24,
                  bottom: 60,
                  child: Transform.rotate(
                    angle: pi / 2,
                    child: Icon(
                      Icons.wifi,
                      color: Colors.white.withOpacity(0.6),
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCardBack(BuildContext context) {
    final card = widget.card;
    
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _getCardGradient(card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Magnetic strip
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Container(
              height: 50,
              color: Colors.black87,
            ),
          ),
          
          // Card details
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                
                // Signature strip
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            card.cardholderName,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontFamily: 'Geist',
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                        ),
                        child: Text(
                          card.cvv,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'GeistMono',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // CVV label
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: card.cvv));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('CVV copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.copy,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'CVV',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Security info
                Text(
                  'This card is for online use only',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Tap to flip back
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_android),
              color: Colors.white70,
              onPressed: _toggleFlip,
            ),
          ),
        ],
      ),
    );
  }
  
  LinearGradient _getCardGradient(BankCard card) {
    if (card.metadata?['design'] == 'metal_black') {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey.shade900,
          Colors.black,
        ],
      );
    } else if (card.metadata?['design'] == 'metal_platinum') {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey.shade400,
          Colors.grey.shade600,
        ],
      );
    } else if (card.type == CardType.credit) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.purple.shade600,
          Colors.purple.shade900,
        ],
      );
    } else if (card.isVirtual) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.teal.shade400,
          Colors.teal.shade700,
        ],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.blue.shade600,
          Colors.blue.shade900,
        ],
      );
    }
  }
  
  Widget _buildNetworkLogo(CardNetwork network) {
    switch (network) {
      case CardNetwork.visa:
        return const Text(
          'VISA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        );
      case CardNetwork.mastercard:
        return Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                shape: BoxShape.circle,
              ),
            ),
            Transform.translate(
              offset: const Offset(-10, 0),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.orange.shade500,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      case CardNetwork.amex:
        return const Text(
          'AMEX',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        );
      case CardNetwork.discover:
        return const Text(
          'DISCOVER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
    }
  }
}

// Custom painter for chip design
class ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw chip contacts
    const double spacing = 8;
    const double lineHeight = 6;
    
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 4; j++) {
        canvas.drawLine(
          Offset(10 + j * spacing, 10 + i * (lineHeight + 2)),
          Offset(10 + j * spacing, 10 + i * (lineHeight + 2) + lineHeight),
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}