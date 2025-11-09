import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/borders.dart';
import '../tokens/motion.dart';

// Input field component with validation
class DSInput extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefix;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  
  const DSInput({
    super.key,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.prefix,
    this.suffix,
    this.inputFormatters,
    this.focusNode,
  });
  
  @override
  State<DSInput> createState() => _DSInputState();
}

class _DSInputState extends State<DSInput> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = false;
  
  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    
    _animationController = AnimationController(
      duration: DSMotion.microInteraction,
      vsync: this,
    );
    
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DSMotion.smooth,
    ));
  }
  
  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusNode.removeListener(_handleFocusChange);
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: DSTypography.labelMedium.copyWith(
              color: hasError ? DSColors.error : DSColors.textSecondary,
              fontWeight: DSTypography.weightMedium,
            ),
          ),
          const SizedBox(height: DSSpacing.space1),
        ],
        AnimatedBuilder(
          animation: _focusAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: DSBorders.borderRadiusMd,
                border: Border.all(
                  color: hasError
                      ? DSColors.error
                      : _isFocused
                          ? DSColors.primary
                          : DSColors.border,
                  width: _isFocused ? 2.0 : 1.0,
                ),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                onEditingComplete: widget.onEditingComplete,
                onSubmitted: widget.onSubmitted,
                keyboardType: widget.keyboardType,
                obscureText: _obscureText,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                maxLines: widget.obscureText ? 1 : widget.maxLines,
                maxLength: widget.maxLength,
                inputFormatters: widget.inputFormatters,
                style: DSTypography.bodyMedium.copyWith(
                  color: widget.enabled ? DSColors.textPrimary : DSColors.textDisabled,
                ),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: DSTypography.bodyMedium.copyWith(
                    color: DSColors.textTertiary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.space4,
                    vertical: DSSpacing.space3,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                  prefixIcon: widget.prefix,
                  suffixIcon: widget.suffix ?? (widget.obscureText
                      ? IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility : Icons.visibility_off,
                            color: DSColors.textTertiary,
                          ),
                          onPressed: _toggleObscureText,
                        )
                      : null),
                ),
              ),
            );
          },
        ),
        if (widget.helperText != null || widget.errorText != null) ...[
          const SizedBox(height: DSSpacing.space1),
          Text(
            widget.errorText ?? widget.helperText!,
            style: DSTypography.bodySmall.copyWith(
              color: hasError ? DSColors.error : DSColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}