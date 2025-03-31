import 'package:flutter/material.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';

/// A simplified version of GlassCard that doesn't use BackdropFilter
/// to avoid rendering issues on some devices
class SimpleGlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final LinearGradient? gradient;
  final Color? borderColor;
  final BorderRadius? borderRadius;

  const SimpleGlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.gradient,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        color: Colors.black.withOpacity(0.3),
      ),
      child: child,
    );
  }
}
