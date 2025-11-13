import 'package:flutter/material.dart';

class PointingHandAnimation extends StatefulWidget {
  const PointingHandAnimation({super.key});

  @override
  State<PointingHandAnimation> createState() => _PointingHandAnimationState();
}

class _PointingHandAnimationState extends State<PointingHandAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _animation = Tween<Offset>(
      begin: const Offset(0, -0.1),
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
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
              child: const Text('Click Me'),
            ),
            Positioned(
              bottom: 60,
              child: SlideTransition(
                position: _animation,
                child: const Text(
                  '👆',
                  style: TextStyle(fontSize: 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
