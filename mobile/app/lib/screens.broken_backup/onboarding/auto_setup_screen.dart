import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'dart:async';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class AutoSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const AutoSetupScreen({
    super.key,
    required this.onComplete,
  });
  
  @override
  State<AutoSetupScreen> createState() => _AutoSetupScreenState();
}

class _AutoSetupScreenState extends State<AutoSetupScreen> 
    with TickerProviderStateMixin {
  final List<SetupStep> _steps = [
    SetupStep('Connecting to servers', [
      'Establishing secure connection...',
      'Authenticating credentials...',
      'Loading user profile...',
      'Syncing account data...',
      'Connection established ✓',
    ]),
    SetupStep('Setting up accounts', [
      'Creating checking account...',
      'Creating savings account...',
      'Setting up virtual cards...',
      'Configuring spending limits...',
      'Accounts ready ✓',
    ]),
    SetupStep('Configuring transfers', [
      'Enabling instant transfers...',
      'Setting up ACH routing...',
      'Configuring wire transfers...',
      'Adding Zelle integration...',
      'Transfers enabled ✓',
    ]),
    SetupStep('Enabling features', [
      'Activating spending insights...',
      'Setting up bill pay...',
      'Enabling mobile deposit...',
      'Configuring notifications...',
      'Features activated ✓',
    ]),
    SetupStep('Finalizing setup', [
      'Applying security settings...',
      'Enabling biometric login...',
      'Setting up 2FA...',
      'Creating backup codes...',
      'Setup complete ✓',
    ]),
  ];
  
  int _currentStepIndex = 0;
  int _currentLineIndex = 0;
  final List<AnimatedLine> _animatedLines = [];
  late Timer _autoPlayTimer;
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  bool _isComplete = false;
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _fadeController.forward();
    _startAutoPlay();
  }
  
  @override
  void dispose() {
    _autoPlayTimer.cancel();
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }
  
  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_currentStepIndex >= _steps.length) {
        timer.cancel();
        _completeSetup();
        return;
      }
      
      setState(() {
        final currentStep = _steps[_currentStepIndex];
        
        if (_currentLineIndex < currentStep.lines.length) {
          _animatedLines.add(AnimatedLine(
            text: currentStep.lines[_currentLineIndex],
            isComplete: _currentLineIndex == currentStep.lines.length - 1,
            stepTitle: _currentLineIndex == 0 ? currentStep.title : null,
          ));
          _currentLineIndex++;
        } else {
          _currentStepIndex++;
          _currentLineIndex = 0;
        }
        
        // Keep only last 15 lines visible
        if (_animatedLines.length > 15) {
          _animatedLines.removeAt(0);
        }
      });
    });
  }
  
  void _completeSetup() async {
    setState(() {
      _isComplete = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      await _fadeController.reverse();
      widget.onComplete();
    }
  }
  
  void _skip() async {
    _autoPlayTimer.cancel();
    await _fadeController.reverse();
    Navigator.of(context).pushReplacementNamed('/home');
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeController,
        child: Stack(
          children: [
            // Background gradient (same as splash)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.05),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
            ),
            
            // Content
            SafeArea(
              child: Column(
                children: [
                  // Skip button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextButton(
                        onPressed: _skip,
                        child: const Text('Skip'),
                      ),
                    ),
                  ),
                  
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(top: 40),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Animated lines
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ..._animatedLines.map((line) => _buildAnimatedLine(line)),
                            
                            if (_isComplete)
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 500),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.scale(
                                      scale: 0.8 + (0.2 * value),
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 40),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Welcome to your account!',
                                          style: TextStyle(
                                            color: theme.colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Progress bar
                  Container(
                    height: 4,
                    margin: const EdgeInsets.all(40),
                    child: LinearProgressIndicator(
                      value: (_currentStepIndex + (_currentLineIndex / 5)) / _steps.length,
                      backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
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
  
  Widget _buildAnimatedLine(AnimatedLine line) {
    final theme = Theme.of(context);
    
    return TweenAnimationBuilder<double>(
      key: ValueKey(line.text),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (line.stepTitle != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 16),
                      child: Text(
                        line.stepTitle!,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      if (!line.isComplete)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: line.isComplete
                                      ? [
                                          theme.colorScheme.onSurface,
                                          theme.colorScheme.onSurface,
                                        ]
                                      : [
                                          theme.colorScheme.onSurface,
                                          theme.colorScheme.primary,
                                          theme.colorScheme.onSurface,
                                        ],
                                  stops: line.isComplete
                                      ? [0, 1]
                                      : [
                                          0,
                                          _shimmerController.value,
                                          1,
                                        ],
                                ).createShader(bounds);
                              },
                              child: Text(
                                line.text,
                                style: TextStyle(
                                  color: line.isComplete
                                      ? theme.colorScheme.onSurface.withOpacity(0.6)
                                      : theme.colorScheme.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SetupStep {
  final String title;
  final List<String> lines;
  
  SetupStep(this.title, this.lines);
}

class AnimatedLine {
  final String text;
  final bool isComplete;
  final String? stepTitle;
  
  AnimatedLine({
    required this.text,
    required this.isComplete,
    this.stepTitle,
  });
}