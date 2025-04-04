import 'package:flutter/material.dart';

/// A widget that combines fade and slide transitions for a smoother animation effect
class FadeSlideTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final Offset beginOffset;
  final Curve curve;
  final Duration duration;

  /// Creates a fade-slide transition with the given parameters
  const FadeSlideTransition({
    super.key,
    required this.child,
    required this.animation,
    this.beginOffset = const Offset(0, 0.25),
    this.curve = Curves.easeOutCubic,
    this.duration = const Duration(milliseconds: 500),
  });

  /// Creates a fade-slide transition from a controller
  factory FadeSlideTransition.fromController({
    Key? key,
    required AnimationController controller,
    required Widget child,
    Offset beginOffset = const Offset(0, 0.25),
    Curve curve = Curves.easeOutCubic,
  }) {
    final animation = CurvedAnimation(parent: controller, curve: curve);

    return FadeSlideTransition(
      key: key,
      animation: animation,
      beginOffset: beginOffset,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
