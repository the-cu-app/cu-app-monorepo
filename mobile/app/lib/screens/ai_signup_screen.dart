import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/plaid_service.dart';
import '../services/sound_service.dart';
import '../l10n/app_localizations.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class AISignupScreen extends StatefulWidget {
  const AISignupScreen({super.key});

  @override
  State<AISignupScreen> createState() => _AISignupScreenState();
}

class _AISignupScreenState extends State<AISignupScreen> 
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final AuthService _authService = AuthService();
  final PlaidService _plaidService = PlaidService();
  
  // Animation controllers
  late AnimationController _typingAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _typingAnimation;
  late Animation<double> _fadeAnimation;
  
  // Chat state
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isProcessing = false;
  
  // Onboarding state
  OnboardingStep _currentStep = OnboardingStep.greeting;
  Map<String, dynamic> _userData = {};
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  List<String> _availableProducts = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkBiometricAvailability();
    _startOnboarding();
  }
  
  void _initializeAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeOut,
    ));
  }
  
  Future<void> _checkBiometricAvailability() async {
    final available = await _authService.isBiometricAvailable;
    setState(() {
      _biometricAvailable = available;
    });
  }
  
  void _startOnboarding() {
    _addAIMessage(
      "👋 Hi there! I'm CUGPT, your personal banking assistant. I'm here to help you create your SUPAHYPER account in just a few minutes.",
      delay: 1000,
    );
    
    Timer(const Duration(milliseconds: 2000), () {
      _addAIMessage(
        "I'll guide you through a quick setup process to get your account ready. We'll gather some basic information, set up security features, and connect your existing accounts if you'd like.",
        delay: 500,
      );
    });
    
    Timer(const Duration(milliseconds: 3500), () {
      _addAIMessage(
        "Let's start with your name. What should I call you?",
        showInputField: true,
        delay: 500,
      );
    });
  }
  
  void _addAIMessage(String text, {int delay = 0, bool showInputField = false}) {
    if (delay > 0) {
      Timer(Duration(milliseconds: delay), () {
        _showTypingIndicator();
        Timer(Duration(milliseconds: _calculateTypingDuration(text)), () {
          _hideTypingIndicator();
          _addMessageToChat(ChatMessage(
            text: text,
            isUser: false,
            timestamp: DateTime.now(),
            showInputField: showInputField,
          ));
        });
      });
    } else {
      _addMessageToChat(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
        showInputField: showInputField,
      ));
    }
  }
  
  void _addUserMessage(String text) {
    _addMessageToChat(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _messageController.clear();
  }
  
  void _addMessageToChat(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }
  
  void _showTypingIndicator() {
    setState(() {
      _isTyping = true;
    });
    _scrollToBottom();
  }
  
  void _hideTypingIndicator() {
    setState(() {
      _isTyping = false;
    });
  }
  
  int _calculateTypingDuration(String text) {
    // Simulate realistic typing speed
    return (text.length * 30).clamp(800, 3000);
  }
  
  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _processUserInput(String input) async {
    if (input.trim().isEmpty) return;
    
    SoundService().playButtonTap();
    _addUserMessage(input);
    
    setState(() {
      _isProcessing = true;
    });
    
    // Process based on current step
    switch (_currentStep) {
      case OnboardingStep.greeting:
        await _handleNameInput(input);
        break;
      case OnboardingStep.collectingName:
        await _handleNameInput(input);
        break;
      case OnboardingStep.collectingEmail:
        await _handleEmailInput(input);
        break;
      case OnboardingStep.collectingPhone:
        await _handlePhoneInput(input);
        break;
      case OnboardingStep.collectingPassword:
        await _handlePasswordInput(input);
        break;
      case OnboardingStep.biometricSetup:
        await _handleBiometricChoice(input);
        break;
      case OnboardingStep.plaidIntegration:
        await _handlePlaidChoice(input);
        break;
      case OnboardingStep.accountCreation:
        await _createAccount();
        break;
      case OnboardingStep.completed:
        // Already completed, do nothing
        break;
    }
    
    setState(() {
      _isProcessing = false;
    });
  }
  
  Future<void> _handleNameInput(String input) async {
    final names = input.split(' ');
    final firstName = names.first;
    final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
    
    _userData['firstName'] = firstName;
    _userData['lastName'] = lastName;
    
    _addAIMessage(
      "Nice to meet you, $firstName! Now I'll need your email address to create your account.",
      delay: 800,
    );
    
    Timer(const Duration(milliseconds: 1500), () {
      _addAIMessage(
        "What's your email address?",
        showInputField: true,
        delay: 300,
      );
    });
    
    setState(() {
      _currentStep = OnboardingStep.collectingEmail;
    });
  }
  
  Future<void> _handleEmailInput(String input) async {
    if (!_isValidEmail(input)) {
      _addAIMessage(
        "That doesn't look like a valid email address. Could you please enter a valid email? (e.g., john@example.com)",
        showInputField: true,
        delay: 800,
      );
      return;
    }
    
    _userData['email'] = input.trim().toLowerCase();
    
    _addAIMessage(
      "Perfect! I'll use ${_userData['email']} for your account.",
      delay: 800,
    );
    
    Timer(const Duration(milliseconds: 1500), () {
      _addAIMessage(
        "Now I need your phone number for security verification. What's your mobile number?",
        showInputField: true,
        delay: 300,
      );
    });
    
    setState(() {
      _currentStep = OnboardingStep.collectingPhone;
    });
  }
  
  Future<void> _handlePhoneInput(String input) async {
    final cleanPhone = input.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length != 10 && cleanPhone.length != 11) {
      _addAIMessage(
        "Please enter a valid phone number (10 digits). You can include or omit the area code.",
        showInputField: true,
        delay: 800,
      );
      return;
    }
    
    _userData['phoneNumber'] = cleanPhone.length == 10 ? '+1$cleanPhone' : '+$cleanPhone';
    
    _addAIMessage(
      "Great! Your phone number has been saved.",
      delay: 800,
    );
    
    Timer(const Duration(milliseconds: 1500), () {
      _addAIMessage(
        "Now let's create a secure password for your account. Your password should be at least 8 characters long and include a mix of letters, numbers, and symbols.",
        delay: 300,
      );
    });
    
    Timer(const Duration(milliseconds: 2800), () {
      _addAIMessage(
        "What would you like your password to be? (Don't worry, I can't see what you type)",
        showInputField: true,
        delay: 300,
      );
    });
    
    setState(() {
      _currentStep = OnboardingStep.collectingPassword;
    });
  }
  
  Future<void> _handlePasswordInput(String input) async {
    if (input.length < 8) {
      _addAIMessage(
        "Your password needs to be at least 8 characters long. Please try again.",
        showInputField: true,
        delay: 800,
      );
      return;
    }
    
    if (!_isStrongPassword(input)) {
      _addAIMessage(
        "Let's make your password stronger! Please include at least one uppercase letter, one lowercase letter, one number, and one special character.",
        showInputField: true,
        delay: 800,
      );
      return;
    }
    
    _userData['password'] = input;
    
    _addAIMessage(
      "Excellent! Your password is strong and secure. ",
      delay: 800,
    );
    
    if (_biometricAvailable) {
      Timer(const Duration(milliseconds: 1500), () {
        _addAIMessage(
          "I notice your device supports biometric authentication (Face ID/Touch ID). Would you like to enable this for faster, more secure sign-ins?",
          delay: 300,
        );
      });
      
      Timer(const Duration(milliseconds: 2500), () {
        _addAIMessage(
          "Type 'yes' to enable biometric authentication, or 'no' to skip for now.",
          showInputField: true,
          delay: 300,
        );
      });
      
      setState(() {
        _currentStep = OnboardingStep.biometricSetup;
      });
    } else {
      _proceedToPlaidIntegration();
    }
  }
  
  Future<void> _handleBiometricChoice(String input) async {
    final choice = input.toLowerCase().trim();
    
    if (choice == 'yes' || choice == 'y') {
      _addAIMessage(
        "Perfect! Let me set up biometric authentication for you...",
        delay: 800,
      );
      
      try {
        final enabled = await _authService.enableBiometric(
          _userData['email'],
          _userData['password'],
        );
        
        if (enabled) {
          _biometricEnabled = true;
          _addAIMessage(
            " Biometric authentication enabled! You'll be able to sign in with your fingerprint or face.",
            delay: 1200,
          );
        } else {
          _addAIMessage(
            " Biometric setup failed. Don't worry, you can enable it later in settings.",
            delay: 1200,
          );
        }
      } catch (e) {
        _addAIMessage(
          "There was an issue setting up biometrics, but you can enable it later in your account settings.",
          delay: 1200,
        );
      }
    } else {
      _addAIMessage(
        "No problem! You can always enable biometric authentication later in your settings.",
        delay: 800,
      );
    }
    
    Timer(const Duration(milliseconds: 2000), () {
      _proceedToPlaidIntegration();
    });
  }
  
  void _proceedToPlaidIntegration() {
    _addAIMessage(
      "Now let's connect your existing bank accounts to give you a complete financial picture. This is powered by Plaid, a secure banking technology trusted by millions.",
      delay: 300,
    );
    
    Timer(const Duration(milliseconds: 2500), () {
      _addAIMessage(
        "Would you like to connect your bank accounts now? This will let you:\n• View all accounts in one place\n• Track spending across institutions\n• Get better insights\n• Make transfers easily",
        delay: 300,
      );
    });
    
    Timer(const Duration(milliseconds: 3500), () {
      _addAIMessage(
        "Type 'connect' to link your accounts, or 'skip' to do this later.",
        showInputField: true,
        delay: 300,
      );
    });
    
    setState(() {
      _currentStep = OnboardingStep.plaidIntegration;
    });
  }
  
  Future<void> _handlePlaidChoice(String input) async {
    final choice = input.toLowerCase().trim();
    
    if (choice == 'connect' || choice == 'yes' || choice == 'y') {
      _addAIMessage(
        "Excellent! Let me prepare the secure connection to your bank...",
        delay: 800,
      );
      
      try {
        // Create link token for Plaid Link
        await _plaidService.createLinkToken();
        
        _addAIMessage(
          " I've prepared a secure connection. In a real app, this would launch Plaid Link to connect your accounts safely.",
          delay: 1500,
        );
        
        Timer(const Duration(milliseconds: 2500), () {
          _addAIMessage(
            "For this demo, I'll simulate connecting to a few popular financial products. This gives you access to checking, savings, credit cards, and investment accounts.",
            delay: 300,
          );
        });
        
        // Simulate adding Plaid products
        _availableProducts = [
          'Chase Total Checking',
          'Chase Savings Plus', 
          'American Express Gold Card',
          'Fidelity Investment Account',
          'Wells Fargo Checking'
        ];
        
      } catch (e) {
        _addAIMessage(
          "There was an issue connecting to the banking service. Don't worry - you can connect your accounts later in the app.",
          delay: 1500,
        );
      }
    } else {
      _addAIMessage(
        "No problem! You can connect your accounts anytime from the app's main menu.",
        delay: 800,
      );
    }
    
    Timer(const Duration(milliseconds: 2000), () {
      _addAIMessage(
        "Perfect! I have everything I need to create your account. Let me set that up for you now... ",
        delay: 300,
      );
    });
    
    Timer(const Duration(milliseconds: 3000), () {
      setState(() {
        _currentStep = OnboardingStep.accountCreation;
      });
      _createAccount();
    });
  }
  
  Future<void> _createAccount() async {
    try {
      _addAIMessage(
        "Creating your SUPAHYPER account... ",
        delay: 500,
      );
      
      // Create the account using AuthService
      final response = await _authService.signUp(
        email: _userData['email'],
        password: _userData['password'],
        firstName: _userData['firstName'],
        lastName: _userData['lastName'],
        phoneNumber: _userData['phoneNumber'],
      );
      
      if (response.user != null) {
        _addAIMessage(
          " Success! Your SUPAHYPER account has been created.",
          delay: 1500,
        );
        
        Timer(const Duration(milliseconds: 2500), () {
          _addAIMessage(
            "Here's what I've set up for you:",
            delay: 300,
          );
        });
        
        Timer(const Duration(milliseconds: 3000), () {
          final setupSummary = _generateSetupSummary();
          _addAIMessage(
            setupSummary,
            delay: 300,
          );
        });
        
        Timer(const Duration(milliseconds: 4500), () {
          _addAIMessage(
            "You're all set! Tap 'Get Started' to explore your new SUPAHYPER account.",
            delay: 300,
          );
        });
        
        Timer(const Duration(milliseconds: 5500), () {
          _showGetStartedButton();
        });
        
      } else {
        throw Exception('Account creation failed');
      }
    } catch (e) {
      _addAIMessage(
        " There was an issue creating your account: ${e.toString()}",
        delay: 1000,
      );
      
      Timer(const Duration(milliseconds: 1800), () {
        _addAIMessage(
          "Please check your information and try again, or contact support if the issue persists.",
          delay: 300,
        );
      });
    }
  }
  
  String _generateSetupSummary() {
    final summary = StringBuffer();
    summary.writeln(" Account: ${_userData['firstName']} ${_userData['lastName']}");
    summary.writeln(" Email: ${_userData['email']}");
    summary.writeln(" Phone: ${_userData['phoneNumber']}");
    summary.writeln(" Security: Strong password");
    
    if (_biometricEnabled) {
      summary.writeln(" Biometric: Face/Touch ID enabled");
    }
    
    if (_availableProducts.isNotEmpty) {
      summary.writeln(" Connected: ${_availableProducts.length} financial accounts");
    }
    
    summary.writeln(" Protection: Bank-level encryption");
    
    return summary.toString();
  }
  
  void _showGetStartedButton() {
    setState(() {
      // Add a special message type that shows the button
      _messages.add(ChatMessage(
        text: "",
        isUser: false,
        timestamp: DateTime.now(),
        showButton: true,
        buttonText: "Get Started ",
        buttonAction: () {
          Navigator.of(context).pushReplacementNamed('/home');
        },
      ));
    });
    _scrollToBottom();
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }
  
  bool _isStrongPassword(String password) {
    return password.length >= 8 &&
           RegExp(r'[A-Z]').hasMatch(password) &&
           RegExp(r'[a-z]').hasMatch(password) &&
           RegExp(r'[0-9]').hasMatch(password) &&
           RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }
  
  @override
  void dispose() {
    _typingAnimationController.dispose();
    _fadeAnimationController.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.purple.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'CUGPT Setup',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(theme);
                }
                
                return _buildChatMessage(_messages[index], theme);
              },
            ),
          ),
          if (_messages.isNotEmpty && 
              _messages.last.showInputField && 
              !_isProcessing)
            _buildInputField(theme),
        ],
      ),
    );
  }
  
  Widget _buildChatMessage(ChatMessage message, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.purple.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                if (message.showButton && message.buttonAction != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: FilledButton.icon(
                      onPressed: message.buttonAction,
                      icon: const Icon(Icons.rocket_launch),
                      label: Text(message.buttonText ?? 'Get Started'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24, 
                          vertical: 16,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'Geist',
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 12,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                _userData['firstName']?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTypingIndicator(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.purple.shade400,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(0),
                    const SizedBox(width: 4),
                    _buildDot(1),
                    const SizedBox(width: 4),
                    _buildDot(2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDot(int index) {
    final delay = index * 0.3;
    final value = (_typingAnimation.value - delay).clamp(0.0, 1.0);
    final opacity = (value * 2).clamp(0.0, 1.0);
    
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
  
  Widget _buildInputField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _getInputHint(),
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontFamily: 'Geist',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              obscureText: _currentStep == OnboardingStep.collectingPassword,
              onSubmitted: _processUserInput,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _isProcessing 
                ? null 
                : () => _processUserInput(_messageController.text),
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, size: 20),
          ),
        ],
      ),
    );
  }
  
  String _getInputHint() {
    switch (_currentStep) {
      case OnboardingStep.greeting:
      case OnboardingStep.collectingName:
        return "Enter your full name...";
      case OnboardingStep.collectingEmail:
        return "Enter your email address...";
      case OnboardingStep.collectingPhone:
        return "Enter your phone number...";
      case OnboardingStep.collectingPassword:
        return "Create a secure password...";
      case OnboardingStep.biometricSetup:
        return "Type 'yes' or 'no'...";
      case OnboardingStep.plaidIntegration:
        return "Type 'connect' or 'skip'...";
      default:
        return "Type your message...";
    }
  }
}

enum OnboardingStep {
  greeting,
  collectingName,
  collectingEmail,
  collectingPhone,
  collectingPassword,
  biometricSetup,
  plaidIntegration,
  accountCreation,
  completed,
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool showInputField;
  final bool showButton;
  final String? buttonText;
  final VoidCallback? buttonAction;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.showInputField = false,
    this.showButton = false,
    this.buttonText,
    this.buttonAction,
  });
}