import 'package:flutter/material.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';

class DinarysLogo extends StatelessWidget {
  final double width;
  final double height;

  const DinarysLogo({
    super.key,
    this.width = 120,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.centerLeft,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            colors: [
              AppTheme.redGradientStart,
              AppTheme.redGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds);
        },
        child: const Text(
          'dinarys',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
} 