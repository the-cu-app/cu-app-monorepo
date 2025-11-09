import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/feature_service.dart';
import '../onboarding/auto_setup_screen.dart';
import '../../widgets/consistent_list_tile.dart';

class LoginScreenRiverpod extends ConsumerStatefulWidget {
  final bool isAddAccount;
  
  const LoginScreenRiverpod({
    super.key,
    this.isAddAccount = false,
  });

  @override
  ConsumerState<LoginScreenRiverpod> createState() => _LoginScreenRiverpodState();
}

class _LoginScreenRiverpodState extends ConsumerState<LoginScreenRiverpod>
    with TickerProviderStateMixin {
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _rememberMe = false;
  bool _showTestAccounts = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Animations
  late AnimationController _animationController;
  late AnimationController _testAccountsController;
  late AnimationController _fieldAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _field1Animation;
  late Animation<double> _field2Animation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _testAccountsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fieldAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Staggered field animations
    _field1Animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fieldAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    _field2Animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fieldAnimationController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    ));
    
    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fieldAnimationController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
    _fieldAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _testAccountsController.dispose();
    _fieldAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Try test accounts first
      ref.read(profileProvider.notifier).loginWithTestAccount(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // Check if login was successful
      await Future.delayed(const Duration(milliseconds: 500));
      final profile = ref.read(activeProfileProvider);
      
      if (profile != null) {
        HapticFeedback.lightImpact();
        
        // Check if this is the first login (show auto setup)
        final profiles = ref.read(profilesListProvider);
        if (!widget.isAddAccount && profiles.length == 1) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => 
                  AutoSetupScreen(
                    onComplete: () {
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                  ),
                transitionDuration: const Duration(milliseconds: 600),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
          }
        } else {
          // Go directly to home if adding account or not first login
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        throw Exception('Invalid credentials');
      }
    } catch (error) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showErrorDialog('Invalid email or password. Try one of the test accounts.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectTestAccount(String email) {
    _emailController.text = email;
    _passwordController.text = TestCredentials.password;
    setState(() {
      _showTestAccounts = false;
    });
    _testAccountsController.reverse();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Error'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    bool isLoading = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(fontSize: 14, fontFamily: 'Geist'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading ? null : () async {
                final email = resetEmailController.text.trim();
                
                if (email.isEmpty) {
                  CUSnackBar.show(
                    context,
                    message: 'Please enter your email address',
                    backgroundColor: const Color(0xFFFF0000),
                  );
                  return;
                }
                
                setState(() {
                  isLoading = true;
                });
                
                try {
                  // Call Supabase auth to send password reset email
                  await Supabase.instance.client.auth.resetPasswordForEmail(
                    email,
                    redirectTo: 'supahyper://reset-password', // Deep link for mobile app
                  );
                  
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    CUSnackBar.show(
                      context,
                      message: 'Password reset link sent to $email',
                      backgroundColor: const Color(0xFF00FF00),
                      duration: const Duration(seconds: 5),
                    );
                  }
                } catch (e) {
                  setState(() {
                    isLoading = false;
                  });
                  
                  if (context.mounted) {
                    CUSnackBar.show(
                      context,
                      message: 'Error: ${e.toString()}',
                      backgroundColor: const Color(0xFFFF0000),
                    );
                  }
                }
              },
              child: isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: widget.isAddAccount ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ) : null,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 40 : 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 450 : double.infinity,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo and title
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance,
                            size: 40,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.isAddAccount ? 'Add Account' : 'Welcome Back',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isAddAccount 
                              ? 'Sign in with another profile'
                              : 'Sign in to your account',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email field
                              AnimatedBuilder(
                                animation: _field1Animation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - _field1Animation.value)),
                                    child: Opacity(
                                      opacity: _field1Animation.value,
                                      child: TextFormField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: const Icon(Icons.email_outlined),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: theme.colorScheme.surface,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Password field
                              AnimatedBuilder(
                                animation: _field2Animation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - _field2Animation.value)),
                                    child: Opacity(
                                      opacity: _field2Animation.value,
                                      child: TextFormField(
                                        controller: _passwordController,
                                        obscureText: !_showPassword,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) => _signIn(),
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _showPassword 
                                                  ? Icons.visibility_off 
                                                  : Icons.visibility,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _showPassword = !_showPassword;
                                              });
                                            },
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: theme.colorScheme.surface,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Remember me
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                  ),
                                  const Text('Remember me'),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      _showForgotPasswordDialog();
                                    },
                                    child: const Text('Forgot password?'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              // Sign in button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: FilledButton(
                                  onPressed: _isLoading ? null : _signIn,
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Test accounts toggle
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showTestAccounts = !_showTestAccounts;
                                  });
                                  if (_showTestAccounts) {
                                    _testAccountsController.forward();
                                  } else {
                                    _testAccountsController.reverse();
                                  }
                                },
                                icon: Icon(
                                  _showTestAccounts 
                                      ? Icons.expand_less 
                                      : Icons.expand_more,
                                ),
                                label: const Text('Use Test Account'),
                              ),
                              
                              // Test accounts list
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                child: _showTestAccounts
                                    ? Container(
                                        margin: const EdgeInsets.only(top: 16),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceVariant
                                              .withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: theme.colorScheme.outline
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Test Accounts',
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Password: ${TestCredentials.password}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontFamily: 'monospace',
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            ...TestCredentials.testProfiles.map((profile) {
                                              return ConsistentListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                leading: ConsistentListTileLeading(
                                                  backgroundColor: _getMembershipColor(
                                                    profile.membershipType
                                                  ).withOpacity(0.2),
                                                  child: Text(
                                                    profile.membershipIcon,
                                                    style: const TextStyle(fontSize: 16),
                                                  ),
                                                ),
                                                title: ConsistentListTileTitle(
                                                  text: profile.membershipName,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                subtitle: Text(
                                                  profile.email,
                                                  style: const TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                onTap: () => _selectTestAccount(profile.email),
                                              );
                                            }),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              
                              // Error message
                              if (profileState.error != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    profileState.error!,
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getMembershipColor(MembershipType type) {
    switch (type) {
      case MembershipType.general:
        return const Color(0xFF4ECDC4);
      case MembershipType.business:
        return const Color(0xFF6B5B95);
      case MembershipType.youth:
        return const Color(0xFFFF6B6B);
      case MembershipType.fiduciary:
        return const Color(0xFF1DB954);
      case MembershipType.premium:
        return const Color(0xFFF7B731);
      case MembershipType.student:
        return const Color(0xFF9B59B6);
    }
  }
}