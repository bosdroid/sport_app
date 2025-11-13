import 'package:flutter/material.dart';

class ClickAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const ClickAnimation({super.key, required this.child, required this.onTap});

  @override
  State<ClickAnimation> createState() => _ClickAnimationState();
}

class _ClickAnimationState extends State<ClickAnimation> {
  double _scale = 1.0;
  bool _clicked = false;

  void _handleTap() async {
    if (_clicked) return;
    _clicked = true;

    setState(() => _scale = 0.92);
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() => _scale = 1.0);
    await Future.delayed(const Duration(milliseconds: 100));

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: _scale,
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: _handleTap,
        child: widget.child,
      ),
    );
  }
}
