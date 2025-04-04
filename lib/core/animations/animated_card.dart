import 'package:flutter/material.dart';

/// A widget that animates a card with scale and opacity effects
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onTap;
  final bool animate;
  final double beginScale;
  final double beginOpacity;

  /// Creates an animated card with scale and opacity transitions
  const AnimatedCard({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.onTap,
    this.animate = true,
    this.beginScale = 0.95,
    this.beginOpacity = 0.0,
  }) : super(key: key);

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _setupAnimations();

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  void _setupAnimations() {
    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _opacityAnimation = Tween<double>(
      begin: widget.beginOpacity,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void didUpdateWidget(AnimatedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _controller.forward();
      } else {
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If there's no onTap handler, just build the animated card
    if (widget.onTap == null) {
      return _buildAnimatedCard();
    }

    // Add hover effect if onTap is provided
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovering ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: _buildAnimatedCard(),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
