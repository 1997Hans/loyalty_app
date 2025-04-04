import 'package:flutter/material.dart';

/// A widget that displays a list with staggered animation effects
class StaggeredList extends StatefulWidget {
  final List<Widget> children;
  final Duration itemDelay;
  final Duration itemDuration;
  final Curve curve;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool staggered;
  final Widget? emptyWidget;

  /// Creates a staggered list that animates children with a delayed effect
  const StaggeredList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 50),
    this.itemDuration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutQuad,
    this.physics,
    this.padding,
    this.staggered = true,
    this.emptyWidget,
  });

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds:
            widget.itemDuration.inMilliseconds +
            (widget.children.length * widget.itemDelay.inMilliseconds),
      ),
    );

    // Only play animation if the widget is staggered and has children
    if (widget.staggered && widget.children.isNotEmpty) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(StaggeredList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controller duration if the list changed size significantly
    if (oldWidget.children.length != widget.children.length) {
      _controller.duration = Duration(
        milliseconds:
            widget.itemDuration.inMilliseconds +
            (widget.children.length * widget.itemDelay.inMilliseconds),
      );

      // Restart animation if the list is staggered and now has items
      if (widget.staggered &&
          widget.children.isNotEmpty &&
          (oldWidget.children.isEmpty || !_controller.isAnimating)) {
        _controller.forward(from: 0.0);
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
    // Show empty widget if no children and one is provided
    if (widget.children.isEmpty && widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: widget.physics ?? const NeverScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        if (!widget.staggered) {
          return widget.children[index];
        }

        // Calculate the delay for this item
        final start =
            index *
            widget.itemDelay.inMilliseconds /
            _controller.duration!.inMilliseconds;
        final end =
            start +
            widget.itemDuration.inMilliseconds /
                _controller.duration!.inMilliseconds;

        // Create interval animation for this item
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              start.clamp(0.0, 1.0),
              end.clamp(0.0, 1.0),
              curve: widget.curve,
            ),
          ),
        );

        // Apply fade and slide effects
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(animation),
            child: widget.children[index],
          ),
        );
      },
    );
  }
}
