import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';

// Text style variants
enum DSTextVariant {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
  monoLarge,
  monoMedium,
  monoSmall,
}

// Text component with semantic styling
class DSText extends StatelessWidget {
  final String text;
  final DSTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;
  final FontWeight? fontWeight;
  
  const DSText(
    this.text, {
    super.key,
    this.variant = DSTextVariant.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
    this.fontWeight,
  });
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _getTextStyle().copyWith(
        color: color ?? DSColors.textPrimary,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
  
  TextStyle _getTextStyle() {
    switch (variant) {
      case DSTextVariant.displayLarge:
        return DSTypography.displayLarge;
      case DSTextVariant.displayMedium:
        return DSTypography.displayMedium;
      case DSTextVariant.displaySmall:
        return DSTypography.displaySmall;
      case DSTextVariant.headlineLarge:
        return DSTypography.headlineLarge;
      case DSTextVariant.headlineMedium:
        return DSTypography.headlineMedium;
      case DSTextVariant.headlineSmall:
        return DSTypography.headlineSmall;
      case DSTextVariant.titleLarge:
        return DSTypography.titleLarge;
      case DSTextVariant.titleMedium:
        return DSTypography.titleMedium;
      case DSTextVariant.titleSmall:
        return DSTypography.titleSmall;
      case DSTextVariant.bodyLarge:
        return DSTypography.bodyLarge;
      case DSTextVariant.bodyMedium:
        return DSTypography.bodyMedium;
      case DSTextVariant.bodySmall:
        return DSTypography.bodySmall;
      case DSTextVariant.labelLarge:
        return DSTypography.labelLarge;
      case DSTextVariant.labelMedium:
        return DSTypography.labelMedium;
      case DSTextVariant.labelSmall:
        return DSTypography.labelSmall;
      case DSTextVariant.monoLarge:
        return DSTypography.monoLarge;
      case DSTextVariant.monoMedium:
        return DSTypography.monoMedium;
      case DSTextVariant.monoSmall:
        return DSTypography.monoSmall;
    }
  }
  
  // Factory constructors for common use cases
  factory DSText.display(String text, {Key? key, Color? color}) => DSText(
    text,
    key: key,
    variant: DSTextVariant.displayMedium,
    color: color,
  );
  
  factory DSText.headline(String text, {Key? key, Color? color}) => DSText(
    text,
    key: key,
    variant: DSTextVariant.headlineMedium,
    color: color,
  );
  
  factory DSText.title(String text, {Key? key, Color? color}) => DSText(
    text,
    key: key,
    variant: DSTextVariant.titleMedium,
    color: color,
  );
  
  factory DSText.body(String text, {Key? key, Color? color}) => DSText(
    text,
    key: key,
    variant: DSTextVariant.bodyMedium,
    color: color,
  );
  
  factory DSText.label(String text, {Key? key, Color? color}) => DSText(
    text,
    key: key,
    variant: DSTextVariant.labelMedium,
    color: color,
  );
  
  factory DSText.mono(String text, {Key? key, Color? color}) => DSText(
    text,
    key: key,
    variant: DSTextVariant.monoMedium,
    color: color,
  );
  
  factory DSText.error(String text, {Key? key}) => DSText(
    text,
    key: key,
    variant: DSTextVariant.bodyMedium,
    color: DSColors.error,
  );
  
  factory DSText.success(String text, {Key? key}) => DSText(
    text,
    key: key,
    variant: DSTextVariant.bodyMedium,
    color: DSColors.success,
  );
}