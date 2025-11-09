import 'package:flutter/material.dart';
import 'dart:async';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration typingSpeed;
  final bool loop;
  
  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 50),
    this.loop = true,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;
  bool _isDeleting = false;
  
  @override
  void initState() {
    super.initState();
    _startTyping();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTyping() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.typingSpeed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (!_isDeleting) {
          // Typing forward
          if (_currentIndex < widget.text.length) {
            _displayedText = widget.text.substring(0, _currentIndex + 1);
            _currentIndex++;
          } else {
            // Finished typing
            if (widget.loop) {
              // Wait a bit then start deleting
              timer.cancel();
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  _isDeleting = true;
                  _startTyping();
                }
              });
            } else {
              timer.cancel();
            }
          }
        } else {
          // Deleting
          if (_currentIndex > 0) {
            _currentIndex--;
            _displayedText = widget.text.substring(0, _currentIndex);
          } else {
            // Finished deleting, start typing again
            _isDeleting = false;
            timer.cancel();
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _startTyping();
              }
            });
          }
        }
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: _displayedText,
            style: widget.style ?? const TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: _currentIndex < widget.text.length && !_isDeleting ? '|' : '',
            style: (widget.style ?? const TextStyle(color: Colors.white)).copyWith(
              color: (widget.style?.color ?? Colors.white).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}