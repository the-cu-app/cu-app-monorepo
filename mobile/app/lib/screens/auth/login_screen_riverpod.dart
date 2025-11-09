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
import '../../widgets/saber_glow_traced_logo.dart';

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
  late AnimationController _logoAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _field1Animation;
  late Animation<double> _field2Animation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<Offset> _formSlideAnimation;
  bool _logoAnimationComplete = false;

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
    
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
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
    
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeIn,
    ));
    
    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
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
    
    // Start logo animation first
    _logoAnimationController.forward().then((_) {
      if (mounted) {
        setState(() {
          _logoAnimationComplete = true;
        });
        _animationController.forward();
        _fieldAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _testAccountsController.dispose();
    _fieldAnimationController.dispose();
    _logoAnimationController.dispose();
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
                  // CUSnackBar.show(
                  //   context,
                  //   message: 'Please enter your email address',
                  //   backgroundColor: const Color(0xFFFF0000),
                  // );
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
                    // CUSnackBar.show(
                    //   context,
                    //   message: 'Password reset link sent to $email',
                    //   backgroundColor: const Color(0xFF00FF00),
                    //   duration: const Duration(seconds: 5),
                    // );
                  }
                } catch (e) {
                  setState(() {
                    isLoading = false;
                  });
                  
                  if (context.mounted) {
                    // CUSnackBar.show(
                    //   context,
                    //   message: 'Error: ${e.toString()}',
                    //   backgroundColor: const Color(0xFFFF0000),
                    // );
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
                        // Finux.dev logo with tracing animation
                        AnimatedBuilder(
                          animation: _logoOpacityAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _logoOpacityAnimation.value,
                              child: SizedBox(
                                width: 200,
                                height: 44,
                                child: SaberGlowTracedLogo(
                                        svgPath: 'M28.0913 2.82622C28.0913 4.3871 26.8259 5.65244 25.2651 5.65244H16.2439C14.7938 5.65244 13.4209 5.92593 12.1251 6.47294C10.8601 7.01994 9.74941 7.76449 8.79298 8.70656C7.83656 9.61824 7.08066 10.7122 6.52531 11.9886C6.00082 13.2346 5.73859 14.5717 5.73859 16V29.1307C5.73859 30.7154 4.45397 32 2.8693 32C1.28463 32 0 30.7154 0 29.1307V16C5.46235e-07 13.7816 0.416524 11.6999 1.24954 9.755C2.11341 7.81008 3.2858 6.12346 4.76672 4.69516C6.24764 3.23647 7.97538 2.09686 9.94995 1.27634C11.9554 0.425442 14.0996 2.46384e-07 16.3827 0H25.2651C26.8259 0 28.0913 1.26534 28.0913 2.82622ZM38.4592 29.1307C38.4592 30.7154 37.1746 32 35.5899 32C34.0052 32 32.7206 30.7154 32.7206 29.1307V2.91489C32.7206 1.33022 34.0052 0.0455938 35.5899 0.0455938C37.1746 0.0455938 38.4592 1.33022 38.4592 2.91489V29.1307ZM79.2138 0C81.065 0 82.5613 0.212738 83.7029 0.638188C84.8444 1.06364 85.7238 1.62583 86.3408 2.32478C86.9887 2.99335 87.4052 3.78348 87.5903 4.69516C87.8063 5.57644 87.9143 6.48812 87.9143 7.43019V19.1453C87.9143 19.161 87.9143 19.1766 87.9144 19.1923C87.9206 20.1776 88.1211 21.104 88.5159 21.9715C88.8861 22.8224 89.4106 23.5822 90.0894 24.2507C90.7373 24.8889 91.5086 25.4055 92.4033 25.8006C93.2606 26.1625 94.1939 26.3448 95.2032 26.3475C96.2124 26.3448 97.1457 26.1625 98.0031 25.8006C98.8978 25.4055 99.6691 24.8889 100.317 24.2507C100.996 23.5822 101.52 22.8224 101.89 21.9715C102.292 21.0902 102.492 20.1482 102.492 19.1453V6.74644H102.511C102.551 6.0453 102.653 5.36154 102.816 4.69516C103.001 3.78348 103.418 2.99335 104.066 2.32478C104.683 1.62583 105.562 1.06364 106.703 0.638188C107.845 0.212738 109.341 0 111.193 0H112.118C113.445 1.98961e-06 114.652 0.249573 115.867 0.774938C116.99 1.24879 118.011 1.92973 118.875 2.78063C119.543 3.43866 120.1 4.18759 120.547 5.02738C121.122 5.90835 121.742 7.00704 122.408 8.38747C122.865 9.33721 123.271 10.0285 123.703 10.7578C124.166 11.4568 124.629 12.0494 125.092 12.5356C125.555 12.9915 126.017 13.2194 126.48 13.2194C127.622 13.2194 128.486 13.2042 129.072 13.1738C129.658 13.1434 130.167 12.9307 130.599 12.5356C130.96 12.2036 131.34 11.7051 131.739 11.04C131.761 11.0035 131.782 10.9671 131.803 10.9306C131.895 10.7752 131.987 10.6113 132.08 10.4388C132.134 10.3407 132.188 10.2452 132.242 10.1523C134.966 5.04328 134.875 0 142.614 0H166.84C169.077 1.24859e-06 171.175 0.422429 173.136 1.26731C175.096 2.08202 176.796 3.21357 178.236 4.66194C179.707 6.08014 180.855 7.75484 181.683 9.686C182.54 11.6172 182.969 13.6841 182.969 15.8868C182.969 18.0594 182.54 20.1113 181.683 22.0424C180.855 23.9736 179.722 25.6634 178.282 27.1118C176.842 28.5299 175.142 29.6615 173.181 30.5064C171.252 31.3211 169.184 31.7435 166.978 31.7737H155.214V26.1613H166.84C168.28 26.1612 169.628 25.8897 170.884 25.3465C172.171 24.8034 173.273 24.0792 174.192 23.174C175.142 22.2386 175.893 21.1523 176.444 19.9151C176.995 18.6478 177.271 17.305 177.271 15.8868C177.271 14.4686 176.995 13.141 176.444 11.9038C175.893 10.6365 175.142 9.5502 174.192 8.64497C173.273 7.70957 172.171 6.97029 170.884 6.42716C169.628 5.88402 168.28 5.61244 166.84 5.61244H146.065V5.63031H143.536C140.071 5.63031 139.584 8.048 139.584 8.048C139.584 8.048 138.966 9.856 138.463 10.848C138.463 10.848 138.189 11.4568 137.818 12.1254C137.448 12.7635 137.032 13.4321 136.569 14.1311C136.137 14.7996 135.643 15.4378 135.088 16.0456C135.643 16.6534 136.137 17.2916 136.569 17.9601C137.032 18.6287 137.448 19.2973 137.818 19.9658C138.189 20.6344 138.513 21.2726 138.79 21.8803C139.099 22.4577 139.376 22.9592 139.623 23.3846L142.003 27.859C143.004 29.7423 141.617 32 139.459 32C138.393 32 137.415 31.4185 136.918 30.4896L134.533 26.0285C134.101 25.2992 133.669 24.509 133.237 23.6581C132.805 22.8072 132.358 22.0323 131.895 21.3333C131.463 20.6344 131.015 20.057 130.553 19.6012C130.09 19.1149 129.627 18.8718 129.164 18.8718H127.267C126.773 18.8718 126.341 18.9326 125.971 19.0541C125.632 19.1453 125.323 19.3277 125.045 19.6012C124.768 19.8443 124.444 20.2393 124.074 20.7863C123.734 21.303 123.333 21.9867 122.87 22.8376C122.408 23.6885 121.821 24.7522 121.112 26.0285L118.726 30.4896C118.229 31.4185 117.251 32 116.185 32C114.027 32 112.64 29.7423 113.642 27.859L116.021 23.3846C116.268 22.9592 116.53 22.4577 116.808 21.8803C117.116 21.2726 117.456 20.6344 117.826 19.9658C118.196 19.2972 118.597 18.6287 119.029 17.9601C119.492 17.2916 120.001 16.6534 120.556 16.0456C120.001 15.4378 119.492 14.7996 119.029 14.1311C118.597 13.4321 118.196 12.7635 117.826 12.1254C117.456 11.4568 117.116 10.8186 116.808 10.2108C116.548 9.64104 116.301 9.15136 116.068 8.74181L116.021 8.66097L115.999 8.60863C115.897 8.37181 115.45 7.38462 114.802 6.74644C114.062 6.0171 113.167 5.65244 112.118 5.65244C110.606 5.65244 109.588 5.97151 109.064 6.60969C108.508 7.21747 108.231 8.32668 108.231 9.93731V19.1453C108.231 20.9383 107.891 22.6097 107.213 24.1596C107.202 24.1838 107.191 24.2079 107.181 24.2321C106.505 25.7521 105.59 27.0955 104.436 28.2621C103.233 29.4169 101.844 30.3286 100.271 30.9972C98.6972 31.6657 97.0158 32 95.2263 32C95.2186 32 95.2109 31.9999 95.2032 31.9999C95.1955 31.9999 95.1878 32 95.18 32C93.3906 32 91.7091 31.6657 90.1357 30.9972C88.5622 30.3286 87.1738 29.4169 85.9706 28.2621C84.7982 27.0769 83.8726 25.7094 83.1938 24.1596C82.5151 22.6097 82.1757 20.9383 82.1757 19.1453V9.93731C82.1757 8.32668 81.898 7.21747 81.3427 6.60969C80.8182 5.97151 79.8 5.65244 78.2883 5.65244C77.2393 5.65244 76.3446 6.0171 75.6041 6.74644C74.8636 7.47578 74.4934 8.37228 74.4934 9.43591V22.5641C74.4934 24.3267 74.2929 25.8158 73.8918 27.0313C73.4907 28.2165 72.9971 29.189 72.4109 29.9487C71.8555 30.6781 71.2385 31.2099 70.5597 31.5442C69.881 31.848 69.2639 32 68.7086 32C67.567 32 66.5797 31.8633 65.7467 31.5898C64.9137 31.3162 64.127 30.8148 63.3865 30.0855C62.646 29.3561 61.8901 28.3533 61.1188 27.0769C60.3784 25.7702 59.5145 24.0836 58.5272 22.0171L53.8993 12.3989L52.9737 10.5755C52.6343 9.84616 52.2641 9.13201 51.863 8.43306C51.4928 7.70372 51.1072 7.08071 50.7061 6.56409C50.3359 6.0171 49.9965 5.71322 49.688 5.65244C49.4103 5.59166 49.1789 5.83477 48.9938 6.38178C48.8395 6.92879 48.7778 7.93164 48.8086 9.39031V29.1307C48.8086 30.7154 47.524 32 45.9394 32C44.3547 32 43.0701 30.7154 43.0701 29.1307V9.39031C43.0701 7.62773 43.2706 6.15384 43.6717 4.96866C44.0728 3.75309 44.5664 2.78062 45.1526 2.05128C45.7388 1.32194 46.3559 0.80533 47.0038 0.501438C47.6825 0.167158 48.2996 0 48.8549 0C49.9965 0 50.9837 0.136747 51.8168 0.41025C52.6498 0.683754 53.4365 1.18519 54.177 1.91453C54.9174 2.64387 55.6733 3.66192 56.4446 4.96866C57.216 6.24501 58.0953 7.91643 59.0825 9.98291L63.8493 19.9202C64.1269 20.528 64.4509 21.2118 64.8211 21.9715C65.1914 22.7008 65.5616 23.3998 65.9318 24.0684C66.3021 24.7066 66.6568 25.2536 66.9962 25.7094C67.3665 26.1349 67.6904 26.3476 67.9681 26.3476C68.2458 26.3172 68.4463 26.0285 68.5697 25.4815C68.724 24.9041 68.7857 23.9316 68.7548 22.5641V9.43591C68.7548 8.12916 69.0017 6.91359 69.4953 5.78919C69.9889 4.63439 70.6677 3.63153 71.5316 2.78063C72.3954 1.92973 73.3982 1.26117 74.5397 0.774938C75.7121 0.258321 76.9616 0 78.2883 0H79.2138ZM219.648 22.4951C219.648 23.702 219.77 24.6525 220.015 25.3465C220.261 26.0405 220.781 26.3876 221.578 26.3876C222.221 26.3876 222.849 26.1763 223.462 25.7539C224.075 25.3315 224.641 24.8185 225.162 24.215C225.683 23.6115 226.142 22.9929 226.541 22.3593C226.969 21.6954 227.322 21.1523 227.597 20.7298L240.358 1.36745C240.883 0.570308 241.774 0.0905313 242.728 0.0905313C244.989 0.0905313 246.343 2.6044 245.099 4.49223L234.398 20.7298C233.234 22.5101 232.131 24.1094 231.09 25.5276C230.079 26.9156 229.037 28.0924 227.965 29.058C226.924 30.0236 225.79 30.7628 224.565 31.2758C223.37 31.7586 221.991 32 220.429 32C218.499 32 216.937 31.1702 215.742 29.5106C214.547 27.851 213.95 25.5125 213.95 22.4951V2.93952C213.95 1.36607 215.225 0.0905313 216.799 0.0905313C218.372 0.0905313 219.648 1.36607 219.648 2.93952V22.4951ZM148.908 26.176C150.478 26.176 151.75 27.4296 151.75 28.976C151.75 30.5224 150.478 31.776 148.908 31.776C147.338 31.776 146.065 30.5224 146.065 28.976C146.065 27.4296 147.338 26.176 148.908 26.176ZM212.107 2.80622C212.107 4.35605 210.851 5.61244 209.301 5.61244H200.481C199.042 5.61244 197.678 5.88402 196.392 6.42716C195.136 6.97029 194.033 7.70956 193.083 8.64497C192.164 9.5502 191.429 10.6365 190.878 11.9038C190.326 13.141 190.05 14.4686 190.05 15.8868C190.05 17.305 190.326 18.6478 190.878 19.9151C191.429 21.1523 192.164 22.2386 193.083 23.174C194.033 24.0792 195.136 24.8034 196.392 25.3465C197.678 25.8897 199.042 26.1613 200.481 26.1613H209.301C210.851 26.1613 212.107 27.4176 212.107 28.9675C212.107 30.5173 210.851 31.7737 209.301 31.7737H200.389C198.184 31.7435 196.101 31.3211 194.14 30.5064C192.179 29.6615 190.479 28.5299 189.039 27.1118C187.6 25.6634 186.451 23.9736 185.593 22.0424C184.766 20.1113 184.352 18.0594 184.352 15.8868C184.352 13.6841 184.766 11.6172 185.593 9.686C186.451 7.75484 187.6 6.08014 189.039 4.66194C190.51 3.21357 192.225 2.08202 194.186 1.26731C196.147 0.422431 198.245 1.00489e-07 200.481 0H209.301C210.851 0 212.107 1.25639 212.107 2.80622ZM23.6485 18.8262H15.6917C14.1309 18.8262 12.8655 17.5609 12.8655 16C12.8655 14.4391 14.1309 13.1738 15.6917 13.1738H23.6485V18.8262ZM207.696 15.8868C207.696 17.4367 206.439 18.6931 204.89 18.6931H196.989V13.0806H204.89C206.439 13.0806 207.696 14.337 207.696 15.8868Z',
                                        width: 200,
                                        height: 44,
                                        glowColor: theme.colorScheme.primary,
                                        duration: const Duration(milliseconds: 2000),
                                        onComplete: () {
                                          if (mounted) {
                                            setState(() {
                                              _logoAnimationComplete = true;
                                            });
                                          }
                                        },
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Sign In title
                        AnimatedBuilder(
                          animation: _formSlideAnimation,
                          builder: (context, child) {
                            return SlideTransition(
                              position: _formSlideAnimation,
                              child: FadeTransition(
                                opacity: _logoOpacityAnimation,
                                child: Text(
                                  'Sign In',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _formSlideAnimation,
                          builder: (context, child) {
                            return SlideTransition(
                              position: _formSlideAnimation,
                              child: FadeTransition(
                                opacity: _logoOpacityAnimation,
                                child: Text(
                                  widget.isAddAccount 
                                      ? 'Sign in with another profile'
                                      : 'Sign in to your account',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        
                        // Form - floats in after logo
                        AnimatedBuilder(
                          animation: _formSlideAnimation,
                          builder: (context, child) {
                            return SlideTransition(
                              position: _formSlideAnimation,
                              child: FadeTransition(
                                opacity: _logoOpacityAnimation,
                                child: Form(
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
                              ),
                            );
                          },
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