import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'dart:async';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class CodeDemoScreen extends StatefulWidget {
  const CodeDemoScreen({super.key});

  @override
  State<CodeDemoScreen> createState() => _CodeDemoScreenState();
}

class _CodeDemoScreenState extends State<CodeDemoScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late AnimationController _terminalController;
  late Animation<double> _terminalAnimation;
  
  final List<String> _terminalCommands = [];
  int _currentCommandIndex = 0;
  Timer? _commandTimer;
  
  final List<AcquisitionSlide> _slides = [
    AcquisitionSlide(
      title: "Hey there,",
      subtitle: "I Got a Strategy For You",
      description: "A complete digital transformation roadmap that will revolutionize credit union banking",
      code: """
\$ flutter create cu_banking_app
Creating project cu_banking_app...
Running "flutter pub get" in cu_banking_app...
Resolving dependencies...
✓ Project created successfully!""",
      gradient: [Colors.blue.shade800, Colors.blue.shade600],
    ),
    AcquisitionSlide(
      title: "Full Acquisition Plan",
      subtitle: "Modern Banking Technology Stack",
      description: "Flutter + Supabase + AI = The future of credit union member experience",
      code: """
\$ flutter pub add supabase_flutter
\$ flutter pub add flutter_riverpod
\$ flutter pub add go_router
✓ Dependencies installed
✓ Building next-gen banking app...""",
      gradient: [Colors.purple.shade800, Colors.purple.shade600],
    ),
    AcquisitionSlide(
      title: "Digital-First Banking",
      subtitle: "Member-Centric Experience",
      description: "Real-time transactions, AI assistance, and seamless integration with modern fintech",
      code: """
class BankingService {
  Future<Account> getBalance() async {
    final response = await supabase
      .from('accounts')
      .select('*')
      .single();
    return Account.fromJson(response);
  }
}""",
      gradient: [Colors.green.shade800, Colors.green.shade600],
    ),
    AcquisitionSlide(
      title: "AI-Powered Features",
      subtitle: "CU.APPGPT Intelligence",
      description: "Personalized financial insights, automated assistance, and predictive analytics",
      code: """
\$ flutter build ios --release
Building com.cu.app for device (ios-release)...
Running Xcode build...
✓ Built build/ios/iphoneos/Runner.app
✓ App ready for deployment!""",
      gradient: [Colors.orange.shade800, Colors.orange.shade600],
    ),
    AcquisitionSlide(
      title: "The Future is Now",
      subtitle: "Join the Revolution",
      description: "Transform your credit union with cutting-edge technology built by industry experts",
      code: """
\$ git push origin main
Enumerating objects: 1337, done.
Counting objects: 100% (1337/1337), done.
Writing objects: 100% (1337/1337), 2.1 MiB
✓ Successfully deployed to production
🚀 App is live!""",
      gradient: [Colors.red.shade800, Colors.pink.shade600],
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _terminalController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _terminalAnimation = CurvedAnimation(
      parent: _terminalController,
      curve: Curves.easeInOut,
    );
    _terminalController.forward();
    _startTerminalAnimation();
  }
  
  @override
  void dispose() {
    _terminalController.dispose();
    _commandTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
  
  void _startTerminalAnimation() {
    final commands = [
      "\$ cd /Users/developer/projects",
      "\$ flutter doctor",
      "✓ Flutter: Channel stable, 3.24.0",
      "✓ Xcode: version 15.0",
      "\$ flutter create cu_banking_platform",
      "Creating project cu_banking_platform...",
      "\$ cd cu_banking_platform",
      "\$ code .",
      "Opening VS Code...",
      "\$ flutter run",
      "Launching lib/main.dart on iPhone...",
      "✓ App running successfully!",
    ];
    
    _commandTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_currentCommandIndex < commands.length) {
        setState(() {
          _terminalCommands.add(commands[_currentCommandIndex]);
          _currentCommandIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Text(
                    'Build Strategy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Share functionality
                    },
                    child: const Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.green,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: List.generate(
                  _slides.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? Colors.green
                            : Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Carousel Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index]);
                },
              ),
            ),
            
            // Terminal Window
            FadeTransition(
              opacity: _terminalAnimation,
              child: Container(
                height: 200,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Terminal header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Terminal - flutter',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Terminal content
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _terminalCommands.length,
                        itemBuilder: (context, index) {
                          final command = _terminalCommands[index];
                          final isCommand = command.startsWith('\$');
                          final isSuccess = command.startsWith('✓');
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              command,
                              style: TextStyle(
                                color: isCommand 
                                  ? Colors.green.shade400 
                                  : isSuccess 
                                    ? Colors.green.shade300
                                    : Colors.white70,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.green.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Previous',
                          style: TextStyle(
                            color: Colors.green,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Ready to build the future!)),

          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1 ? 'Let\'s Build' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Geist',
                        ),
                      ),
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
  
  Widget _buildSlide(AcquisitionSlide slide) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          
          // Gradient title background
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slide.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  slide.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            slide.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontFamily: 'Geist',
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Code preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Text(
              slide.code,
              style: TextStyle(
                color: Colors.green.shade400,
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }
}

class AcquisitionSlide {
  final String title;
  final String subtitle;
  final String description;
  final String code;
  final List<Color> gradient;
  
  AcquisitionSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.code,
    required this.gradient,
  });
}