import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter/services.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:local_auth/local_auth.dart';
import '../services/plaid_service.dart';
import '../services/banking_service.dart';

class PlaidLinkScreen extends StatefulWidget {
  const PlaidLinkScreen({super.key});

  @override
  State<PlaidLinkScreen> createState() => _PlaidLinkScreenState();
}

class _PlaidLinkScreenState extends State<PlaidLinkScreen>
    with TickerProviderStateMixin {
  final PlaidService _plaidService = PlaidService();
  final BankingService _bankingService = BankingService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late AnimationController _successController;
  late Animation<double> _successAnimation;

  bool _isLoading = true;
  String _status = 'Initializing Plaid Link...';
  double _progress = 0.0;
  bool _isAuthenticated = false;
  List<Map<String, dynamic>> _connectedAccounts = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    _authenticateAndConnect();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _authenticateAndConnect() async {
    try {
      setState(() {
        _status = 'Authenticating...';
        _progress = 0.1;
      });

      // Check if biometric authentication is available
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        final List<BiometricType> availableBiometrics =
            await _localAuth.getAvailableBiometrics();

        if (availableBiometrics.isNotEmpty) {
          // Attempt biometric authentication
          final bool authenticated = await _localAuth.authenticate(
            localizedReason: 'Authenticate to connect your bank account',
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: true,
            ),
          );

          if (!authenticated) {
            setState(() {
              _isLoading = false;
              _status = 'Authentication cancelled';
            });
            return;
          }

          setState(() {
            _isAuthenticated = true;
            _progress = 0.2;
          });
        }
      }

      // Proceed with Plaid Link
      await _initializePlaidLink();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Authentication error: $e';
      });
    }
  }

  Future<void> _initializePlaidLink() async {
    try {
      setState(() {
        _status = 'Creating secure connection...';
        _progress = 0.3;
      });
      _animationController.forward();

      // Create a sandbox public token for immediate testing
      final publicToken = await _plaidService.createSandboxPublicToken();

      if (!mounted) return;

      setState(() {
        _status = 'Securing your connection...';
        _progress = 0.6;
      });

      // Exchange public token for access token
      await _plaidService.exchangePublicToken(publicToken);

      // Fetch accounts with enhanced data
      setState(() {
        _status = 'Retrieving account information...';
        _progress = 0.8;
      });
      
      final accounts = await _plaidService.getAccounts();
      
      // Fetch additional account details
      final balances = await _plaidService.getAccountBalances();
      
      setState(() {
        _status = 'Successfully connected ${accounts.length} accounts';
        _progress = 1.0;
        _connectedAccounts = accounts;
        _isLoading = false;
      });
      
      // Trigger success animation
      await _successController.forward();
      
      // Create test transactions for demo
      await _plaidService.createTestTransactions();

      // Wait a moment to show success state
      await Future.delayed(const Duration(seconds: 2));
      
      // Navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Connection failed. Please try again.';
        _progress = 0.0;
      });
      debugPrint('Plaid Link error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Connect Your Bank'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              // Progress indicator or success animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _progress >= 1.0
                    ? _buildSuccessAnimation()
                    : _buildProgressIndicator(),
              ),
              const SizedBox(height: 48),
              
              // Status text
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: _progress >= 1.0 ? 24 : 20,
                  fontWeight: _progress >= 1.0 ? FontWeight.w600 : FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                  fontFamily: 'Geist',
                ),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Show connected accounts if available
              if (_connectedAccounts.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildConnectedAccountsList(),
              ],
              
              const Spacer(),
              
              // Action buttons
              if (!_isLoading && _progress < 1.0)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _authenticateAndConnect,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              
              // Security badges
              if (_isLoading) ...[
                const SizedBox(height: 48),
                _buildSecurityBadges(),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Container(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
          ),
          // Progress circle
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(120, 120),
                painter: CircularProgressPainter(
                  progress: _progressAnimation.value * _progress,
                  backgroundColor: Colors.grey.shade300,
                  progressColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
          // Icon in center
          Icon(
            _isAuthenticated ? Icons.lock_open : Icons.account_balance,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: _successAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.shade500,
        ),
        child: const Icon(
          Icons.check,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildConnectedAccountsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _connectedAccounts.length,
        itemBuilder: (context, index) {
          final account = _connectedAccounts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                Icons.account_balance,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                account['name'] ?? 'Account',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(account['subtype'] ?? 'Account'),
              trailing: Icon(
                Icons.check_circle,
                color: Colors.green.shade500,
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSecurityBadges() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.security,
          size: 20,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          'Bank-level encryption',
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.verified_user,
          size: 20,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          'Plaid secured',
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// Custom painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    
    canvas.drawCircle(center, radius - 4, backgroundPaint);
    
    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -1.57, // Start from top
      progress * 2 * 3.14159, // Progress in radians
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
