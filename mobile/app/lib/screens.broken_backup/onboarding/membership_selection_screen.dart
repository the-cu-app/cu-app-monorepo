import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../../services/feature_service.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

/// Membership selection screen with beautiful card-based UI
class MembershipSelectionScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const MembershipSelectionScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<MembershipSelectionScreen> createState() => _MembershipSelectionScreenState();
}

class _MembershipSelectionScreenState extends State<MembershipSelectionScreen>
    with TickerProviderStateMixin {
  MembershipType? _selectedMembership;
  late List<AnimationController> _cardAnimations;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  final List<_MembershipOption> _options = [
    _MembershipOption(
      type: MembershipType.general,
      title: 'Personal',
      subtitle: 'For individuals and families',
      icon: Icons.person,
      color: const Color(0xFF4ECDC4),
      features: [
        'Unlimited debit cards',
        'Mobile check deposit',
        'Bill pay & transfers',
        'Savings goals',
        'Spending analytics',
        'Investment accounts',
      ],
      price: 'Free',
    ),
    _MembershipOption(
      type: MembershipType.business,
      title: 'Business',
      subtitle: 'For companies and teams',
      icon: Icons.business,
      color: const Color(0xFF6B5B95),
      features: [
        'Everything in Personal, plus:',
        'Employee cards',
        'Bulk payments',
        'Higher limits',
        'Multi-user access',
        'Accounting integration',
        'Priority support',
      ],
      price: '\$29/mo',
      isRecommended: true,
    ),
    _MembershipOption(
      type: MembershipType.premium,
      title: 'Premium',
      subtitle: 'Exclusive benefits',
      icon: Icons.diamond,
      color: const Color(0xFFF7B731),
      features: [
        'All features unlocked',
        'Unlimited everything',
        'Concierge service',
        'Premium rewards',
        'Travel benefits',
        'VIP support',
      ],
      price: '\$99/mo',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cardAnimations = List.generate(
      _options.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 500 + (index * 100)),
        vsync: this,
      ),
    );

    _fadeAnimations = _cardAnimations.map((controller) {
      return Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ));
    }).toList();

    _slideAnimations = _cardAnimations.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();

    // Start animations
    for (var controller in _cardAnimations) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _cardAnimations) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectMembership(MembershipType type) {
    setState(() {
      _selectedMembership = type;
    });
    
    // Update feature service
    FeatureService().updateMembershipType(type);
    
    // Auto-advance after selection
    Future.delayed(const Duration(milliseconds: 500), widget.onNext);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Title
          const Text(
            'Choose Your Plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the membership that fits your needs',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          
          // Membership cards
          Expanded(
            child: ListView.builder(
              itemCount: _options.length,
              itemBuilder: (context, index) {
                final option = _options[index];
                
                return SlideTransition(
                  position: _slideAnimations[index],
                  child: FadeTransition(
                    opacity: _fadeAnimations[index],
                    child: _buildMembershipCard(option, index),
                  ),
                );
              },
            ),
          ),
          
          // Continue button
          AnimatedOpacity(
            opacity: _selectedMembership != null ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 300),
            child: FilledButton(
              onPressed: _selectedMembership != null ? widget.onNext : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMembershipCard(_MembershipOption option, int index) {
    final isSelected = _selectedMembership == option.type;
    
    return GestureDetector(
      onTap: () => _selectMembership(option.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [option.color, option.color.withOpacity(0.7)]
                : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? option.color : Colors.white.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: option.color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Recommended badge
            if (option.isRecommended)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : option.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        option.icon,
                        color: isSelected ? Colors.white : option.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            option.subtitle,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          option.price,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (option.price != 'Free')
                          Text(
                            'per month',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Features list
                ...option.features.take(isSelected ? 10 : 3).map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: isSelected
                              ? Colors.white.withOpacity(0.9)
                              : option.color.withOpacity(0.8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                if (!isSelected && option.features.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+ ${option.features.length - 3} more features',
                      style: TextStyle(
                        color: option.color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipOption {
  final MembershipType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> features;
  final String price;
  final bool isRecommended;

  _MembershipOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.features,
    required this.price,
    this.isRecommended = false,
  });
}