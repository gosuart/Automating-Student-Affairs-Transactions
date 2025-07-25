import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/colors.dart';

class NeumorphismContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isPressed;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const NeumorphismContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.isPressed = false,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.cardBackground,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isPressed
              ? [
                  // Inner shadows when pressed
                  BoxShadow(
                    color: AppColors.darkShadow.withValues(alpha: 0.5),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: AppColors.lightShadow.withValues(alpha: 0.8),
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ]
              : [
                  // Outer shadows when not pressed
                  BoxShadow(
                    color: AppColors.darkShadow.withValues(alpha: 0.3),
                    offset: const Offset(8, 8),
                    blurRadius: 15,
                  ),
                  BoxShadow(
                    color: AppColors.lightShadow.withValues(alpha: 0.9),
                    offset: const Offset(-8, -8),
                    blurRadius: 15,
                  ),
                ]
        ),
        child: child,
      ),
    );
  }
}

// Glassmorphism Widgets
class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final double blur;
  final double opacity;

  const GlassmorphismContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.backgroundColor,
    this.blur = 10,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor?.withValues(alpha: opacity) ?? 
                     Colors.white.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: child
          ),
        ),
      ),
    );
  }
}

class GlassmorphismButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final double blur;
  final double opacity;

  const GlassmorphismButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = 12,
    this.backgroundColor,
    this.blur = 10,
    this.opacity = 0.15,
  });

  @override
  State<GlassmorphismButton> createState() => _GlassmorphismButtonState();
}

class _GlassmorphismButtonState extends State<GlassmorphismButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: widget.backgroundColor?.withValues(alpha: widget.opacity) ?? 
                         Colors.white.withValues(alpha: widget.opacity),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: widget.child
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NeumorphismButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;

  const NeumorphismButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = 16.0,
    this.backgroundColor,
  });

  @override
  State<NeumorphismButton> createState() => _NeumorphismButtonState();
}

class _NeumorphismButtonState extends State<NeumorphismButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: NeumorphismContainer(
        width: widget.width,
        height: widget.height,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        borderRadius: widget.borderRadius,
        isPressed: _isPressed,
        backgroundColor: widget.backgroundColor,
        child: _isPressed ? _buildPressedChild() : widget.child,
      ),
    );
  }

  Widget _buildPressedChild() {
    return _transformChild(widget.child, AppColors.accent);
  }

  Widget _transformChild(Widget child, Color pressedColor) {
    if (child is Icon) {
      return Icon(
        child.icon,
        size: child.size,
        color: pressedColor,
      );
    } else if (child is Text) {
      return Text(
        child.data ?? '',
        style: (child.style ?? const TextStyle()).copyWith(color: pressedColor),
        textAlign: child.textAlign,
        overflow: child.overflow,
        maxLines: child.maxLines,
      );
    } else if (child is Container) {
      return Container(
        width: child.constraints?.maxWidth,
        height: child.constraints?.maxHeight,
        padding: child.padding,
        margin: child.margin,
        decoration: child.decoration,
        child: child.child != null ? _transformChild(child.child!, pressedColor) : null,
      );
    } else if (child is Column) {
      return Column(
        mainAxisAlignment: child.mainAxisAlignment,
        crossAxisAlignment: child.crossAxisAlignment,
        mainAxisSize: child.mainAxisSize,
        children: child.children.map((c) => _transformChild(c, pressedColor)).toList(),
      );
    } else if (child is Row) {
      return Row(
        mainAxisAlignment: child.mainAxisAlignment,
        crossAxisAlignment: child.crossAxisAlignment,
        mainAxisSize: child.mainAxisSize,
        children: child.children.map((c) => _transformChild(c, pressedColor)).toList(),
      );
    } else if (child is SizedBox) {
      return SizedBox(
        width: child.width,
        height: child.height,
        child: child.child != null ? _transformChild(child.child!, pressedColor) : null,
      );
    }
    return child;
  }
}

class NeumorphismTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final Color? iconColor;
  final String? errorText;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  final int? maxLines;

  const NeumorphismTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.iconColor,
    this.errorText,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  State<NeumorphismTextField> createState() => _NeumorphismTextFieldState();
}

class _NeumorphismTextFieldState extends State<NeumorphismTextField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(() {
      setState(() {
        _isFocused = widget.focusNode?.hasFocus ?? false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isFocused ? [
              // Inner shadows when focused (pressed effect)
              BoxShadow(
                color: AppColors.darkShadow.withValues(alpha: 0.4),
                offset: const Offset(4, 4),
                blurRadius: 8,
                spreadRadius: -1,
              ),
              BoxShadow(
                color: AppColors.lightShadow.withValues(alpha: 0.9),
                offset: const Offset(-4, -4),
                blurRadius: 8,
                spreadRadius: -1,
              ),
              // Add a subtle glow effect when focused
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                offset: const Offset(0, 0),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ] : [
              // Outer shadows when not focused (raised effect)
              BoxShadow(
                color: AppColors.darkShadow.withValues(alpha: 0.3),
                offset: const Offset(8, 8),
                blurRadius: 15,
              ),
              BoxShadow(
                color: AppColors.lightShadow.withValues(alpha: 0.9),
                offset: const Offset(-8, -8),
                blurRadius: 15,
              )
            ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.obscureText,
            obscuringCharacter: '✱',
            onChanged: widget.onChanged,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontFamily: 'TheYearofHandicrafts',
            ),
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: widget.iconColor ?? AppColors.textSecondary)
                  : null,
              suffixIcon: widget.suffixIcon,
              labelStyle: TextStyle(
                color: _isFocused ? AppColors.primary : AppColors.textSecondary,
                fontFamily: 'TheYearofHandicrafts',
                fontWeight: FontWeight.w600,
              ),
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontFamily: 'TheYearofHandicrafts',
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontFamily: 'TheYearofHandicrafts',
              ),
            ),
          ),
        ]
      ],
    );
  }
}

class NeumorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const NeumorphismCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkShadow.withValues(alpha: 0.3),
            offset: const Offset(10, 10),
            blurRadius: 20,
          ),
          BoxShadow(
            color: AppColors.lightShadow.withValues(alpha: 0.9),
            offset: const Offset(-10, -10),
            blurRadius: 20,
          ),
        ]
      ),
      child: child,
    );
  }
}

class NeumorphicCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Color? activeColor;
  final Color? checkColor;
  final double size;
  final double borderRadius;

  const NeumorphicCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.checkColor,
    this.size = 24.0,
    this.borderRadius = 8.0,
  });

  @override
  State<NeumorphicCheckbox> createState() => _NeumorphicCheckboxState();
}

class _NeumorphicCheckboxState extends State<NeumorphicCheckbox> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onChanged != null
          ? () => widget.onChanged!(!widget.value)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: widget.value
              ? [
                  // Inner shadows when checked
                  BoxShadow(
                    color: AppColors.darkShadow.withValues(alpha: 0.4),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                    spreadRadius: -1,
                  ),
                  BoxShadow(
                    color: AppColors.lightShadow.withValues(alpha: 0.9),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                    spreadRadius: -1,
                  ),
                ]
              : [
                  // Outer shadows when unchecked
                  BoxShadow(
                    color: AppColors.darkShadow.withValues(alpha: 0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: AppColors.lightShadow.withValues(alpha: 0.9),
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: widget.value
            ? Icon(
                Icons.check,
                size: widget.size * 0.6,
                color: widget.checkColor ?? widget.activeColor ?? AppColors.primary,
              )
            : null,
      ),
    );
  }
}