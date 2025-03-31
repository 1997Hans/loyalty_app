import 'package:flutter/material.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';

class GradientContainer extends StatelessWidget {
  final Widget child;
  final double height;
  final double width;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradientColors;

  const GradientContainer({
    super.key,
    required this.child,
    this.height = double.infinity,
    this.width = double.infinity,
    this.padding = EdgeInsets.zero,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              gradientColors ??
              [
                AppTheme.backgroundDarkColor,
                const Color(0xFF1A1A1A),
                const Color(0xFF292929),
              ],
        ),
      ),
      child: child,
    );
  }
}
