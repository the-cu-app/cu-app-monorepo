import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'dart:async';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _displayedText = "";
  final String _fullText = "CU.APP";
  Timer? _timer;
  bool _navigated = false;
  
  @override
  void initState() {
    super.initState();
    _startAnimation();
  }
  
  void _startAnimation() async {
    // Wait a bit
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Type out text
    for (int i = 0; i < _fullText.length; i++) {
      if (!mounted) return;
      setState(() {
        _displayedText += _fullText[i];
      });
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    // Wait then navigate
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted && !_navigated) {
      _navigated = true;
      Navigator.of(context).pushReplacementNamed('/');
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _displayedText,
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                fontFamily: 'Geist',
                color: Colors.white,
                letterSpacing: 8,
              ),
            ),
            if (_displayedText == _fullText) ...[
              const SizedBox(height: 20),
              Text(
                'CREDIT UNION APP',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Geist',
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}