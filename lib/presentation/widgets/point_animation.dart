import 'package:flutter/material.dart';

class PointAnimation extends StatefulWidget {
  final Widget child;
  final bool showPointer;
  final double offsetY;
  final double pointerSize;

  const PointAnimation({
    super.key,
    required this.child,
    this.showPointer = false,
    this.offsetY = -30,
    this.pointerSize = 30,
  });

  @override
  State<PointAnimation> createState() => _PointAnimationState();
}

class _PointAnimationState extends State<PointAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: const Offset(0, 0.1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        if (widget.showPointer)
          Positioned(
            bottom: widget.offsetY,
            right: 0,
            child: SlideTransition(
              position: _animation,
              child: Text(
                '👆',
                style: TextStyle(fontSize: widget.pointerSize),
              ),
            ),
          ),
      ],
    );
  }
}
