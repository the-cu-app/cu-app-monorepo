import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/motion.dart';

// Loader sizes
enum DSLoaderSize {
  small,
  medium,
  large,
}

// Loader types
enum DSLoaderType {
  circular,
  linear,
  dots,
}

// Loader component for loading states
class DSLoader extends StatefulWidget {
  final DSLoaderSize size;
  final DSLoaderType type;
  final Color? color;
  final double? value;
  final String? label;
  
  const DSLoader({
    super.key,
    this.size = DSLoaderSize.medium,
    this.type = DSLoaderType.circular,
    this.color,
    this.value,
    this.label,
  });
  
  @override
  State<DSLoader> createState() => _DSLoaderState();
}

class _DSLoaderState extends State<DSLoader> with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late List<Animation<double>> _dotAnimations;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.type == DSLoaderType.dots) {
      _dotsController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      )..repeat();
      
      _dotAnimations = List.generate(3, (index) {
        return Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _dotsController,
            curve: Interval(
              index * 0.2,
              0.6 + index * 0.2,
              curve: Curves.easeInOut,
            ),
          ),
        );
      });
    }
  }
  
  @override
  void dispose() {
    if (widget.type == DSLoaderType.dots) {
      _dotsController.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final loaderColor = widget.color ?? DSColors.primary;
    
    Widget loader;
    
    switch (widget.type) {
      case DSLoaderType.circular:
        loader = SizedBox(
          width: _getSize(),
          height: _getSize(),
          child: CircularProgressIndicator(
            value: widget.value,
            strokeWidth: _getStrokeWidth(),
            valueColor: AlwaysStoppedAnimation<Color>(loaderColor),
          ),
        );
        break;
        
      case DSLoaderType.linear:
        loader = SizedBox(
          width: _getLinearWidth(),
          height: _getLinearHeight(),
          child: LinearProgressIndicator(
            value: widget.value,
            minHeight: _getLinearHeight(),
            valueColor: AlwaysStoppedAnimation<Color>(loaderColor),
            backgroundColor: DSColors.surfaceContainer,
          ),
        );
        break;
        
      case DSLoaderType.dots:
        loader = AnimatedBuilder(
          animation: _dotsController,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: _getDotSpacing()),
                  child: Transform.scale(
                    scale: 0.5 + (_dotAnimations[index].value * 0.5),
                    child: Container(
                      width: _getDotSize(),
                      height: _getDotSize(),
                      decoration: BoxDecoration(
                        color: loaderColor.withOpacity(
                          0.3 + (_dotAnimations[index].value * 0.7),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
        break;
    }
    
    if (widget.label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: DSSpacing.space2),
          Text(
            widget.label!,
            style: TextStyle(
              color: DSColors.textSecondary,
              fontSize: _getLabelSize(),
            ),
          ),
        ],
      );
    }
    
    return loader;
  }
  
  double _getSize() {
    switch (widget.size) {
      case DSLoaderSize.small:
        return 16.0;
      case DSLoaderSize.medium:
        return 32.0;
      case DSLoaderSize.large:
        return 48.0;
    }
  }
  
  double _getStrokeWidth() {
    switch (widget.size) {
      case DSLoaderSize.small:
        return 2.0;
      case DSLoaderSize.medium:
        return 3.0;
      case DSLoaderSize.large:
        return 4.0;
    }
  }
  
  double _getLinearWidth() {
    switch (widget.size) {
      case DSLoaderSize.small:
        return 100.0;
      case DSLoaderSize.medium:
        return 200.0;
      case DSLoaderSize.large:
        return 300.0;
    }
  }
  
  double _getLinearHeight() {
    switch (widget.size) {
      case DSLoaderSize.small:
        return 2.0;
      case DSLoaderSize.medium:
        return 4.0;
      case DSLoaderSize.large:
        return 6.0;
    }
  }
  
  double _getDotSize() {
    switch (widget.size) {
      case DSLoaderSize.small:
        return 6.0;
      case DSLoaderSize.medium:
        return 10.0;
      case DSLoaderSize.large:
        return 14.0;
    }
  }
  
  double _getDotSpacing() {
    switch (widget.size) {
      case DSLoaderSize.small:
        return 2.0;
      case DSLoaderSize.medium:
        return 3.0;
      case DSLoaderSize.large:
        return 4.0;
    }
  }
  
  double _getLabelSize() {
    switch (widget.size) {
      case DSLoaderSize.small:
        return 12.0;
      case DSLoaderSize.medium:
        return 14.0;
      case DSLoaderSize.large:
        return 16.0;
    }
  }
}