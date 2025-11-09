import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Colors;

class RollerDeckLoader extends StatefulWidget {
  final List<String> messages;
  final Duration duration;
  final double height;
  final TextStyle? textStyle;

  const RollerDeckLoader({
    super.key,
    required this.messages,
    this.duration = const Duration(milliseconds: 2000),
    this.height = 24,
    this.textStyle,
  });

  @override
  State<RollerDeckLoader> createState() => _RollerDeckLoaderState();
}

class _RollerDeckLoaderState extends State<RollerDeckLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.messages.length;
        });
        _controller.reset();
        _controller.forward();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final nextIndex = (_currentIndex + 1) % widget.messages.length;
            final offset = -_animation.value * widget.height;

            return Stack(
              children: [
                // Current message sliding out
                Transform.translate(
                  offset: Offset(0, offset),
                  child: Opacity(
                    opacity: 1.0 - _animation.value,
                    child: Text(
                      widget.messages[_currentIndex],
                      style: widget.textStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Next message sliding in
                Transform.translate(
                  offset: Offset(0, widget.height + offset),
                  child: Opacity(
                    opacity: _animation.value,
                    child: Text(
                      widget.messages[nextIndex],
                      style: widget.textStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
