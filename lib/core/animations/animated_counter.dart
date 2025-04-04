import 'package:flutter/material.dart';

/// A widget that animates number changes with a smooth counting effect
class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String? prefix;
  final String? suffix;
  final int decimalPlaces;

  /// Creates an animated counter that smoothly transitions between number values
  const AnimatedCounter({
    Key? key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
  }) : super(key: key);

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _oldValue;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _oldValue = widget.value;
    _setupAnimation();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only animate if the value has changed
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _setupAnimation();
      _controller.forward(from: 0.0);
    }
  }

  void _setupAnimation() {
    _animation = Tween<double>(
      begin: _oldValue.toDouble(),
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Format based on decimal places
        String valueText;
        if (widget.decimalPlaces > 0) {
          valueText = _animation.value.toStringAsFixed(widget.decimalPlaces);
        } else {
          valueText = _animation.value.round().toString();
        }

        // Add prefix/suffix if provided
        if (widget.prefix != null) {
          valueText = "${widget.prefix}$valueText";
        }
        if (widget.suffix != null) {
          valueText = "$valueText${widget.suffix}";
        }

        return Text(valueText, style: widget.style);
      },
    );
  }
}
