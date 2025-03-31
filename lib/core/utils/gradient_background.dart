import 'package:flutter/material.dart';
import 'package:loyalty_app/core/common/widgets/gradient_container.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final double? backgroundOpacity;

  const GradientBackground({
    super.key,
    required this.child,
    this.gradientColors,
    this.backgroundOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      gradientColors:
          gradientColors ??
          [
            const Color(0xFF121212),
            const Color(0xFF1E1E1E).withOpacity(0.8),
            const Color(0xFF292929).withOpacity(0.7),
          ],
      child: child,
    );
  }
}
