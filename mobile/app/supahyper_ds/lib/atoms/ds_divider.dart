import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

// Divider orientations
enum DSDividerOrientation {
  horizontal,
  vertical,
}

// Divider component for visual separation
class DSDivider extends StatelessWidget {
  final DSDividerOrientation orientation;
  final double? thickness;
  final double? indent;
  final double? endIndent;
  final Color? color;
  final double? height;
  final double? width;
  
  const DSDivider({
    super.key,
    this.orientation = DSDividerOrientation.horizontal,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
    this.height,
    this.width,
  });
  
  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? DSColors.border;
    final dividerThickness = thickness ?? 1.0;
    
    if (orientation == DSDividerOrientation.vertical) {
      return Container(
        width: dividerThickness,
        height: height,
        margin: EdgeInsets.symmetric(
          vertical: indent ?? 0,
        ),
        color: dividerColor,
      );
    }
    
    return Container(
      height: dividerThickness,
      width: width,
      margin: EdgeInsets.symmetric(
        horizontal: indent ?? 0,
      ),
      color: dividerColor,
    );
  }
  
  // Factory constructors for common use cases
  factory DSDivider.horizontal({
    Key? key,
    double? thickness,
    double? indent,
    double? endIndent,
    Color? color,
  }) => DSDivider(
    key: key,
    orientation: DSDividerOrientation.horizontal,
    thickness: thickness,
    indent: indent,
    endIndent: endIndent,
    color: color,
  );
  
  factory DSDivider.vertical({
    Key? key,
    double? thickness,
    double? indent,
    double? endIndent,
    Color? color,
    double? height,
  }) => DSDivider(
    key: key,
    orientation: DSDividerOrientation.vertical,
    thickness: thickness,
    indent: indent,
    endIndent: endIndent,
    color: color,
    height: height,
  );
  
  factory DSDivider.section({Key? key}) => DSDivider(
    key: key,
    thickness: 8.0,
    color: DSColors.surfaceVariant,
  );
}