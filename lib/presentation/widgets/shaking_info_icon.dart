import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';


class ShakingInfoIcon extends StatefulWidget {
  final VoidCallback? onWatched; // Callback when video is watched
  const ShakingInfoIcon({super.key,this.onWatched});

  @override
  _ShakingInfoIconState createState() => _ShakingInfoIconState();
}

class _ShakingInfoIconState extends State<ShakingInfoIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;
  bool _shouldShake = false;

  @override
  void initState() {
    super.initState();
    _initPreferences();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _offsetAnimation = Tween(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );
  }

  Future<void> _initPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";

    final lastWatched = prefs.getString('videoWatchedDate');

    if (lastWatched != todayStr) {
      setState(() {
        _shouldShake = true;
      });
    } else {
      _controller.stop(); // Stop shaking if watched
    }
  }

  void _onTap() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";

    // Simulate "video watched"
    await prefs.setString('videoWatchedDate', todayStr);

    setState(() {
      _shouldShake = false;
    });
    _controller.stop();
    widget.onWatched?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: _shouldShake
          ? AnimatedBuilder(
        animation: _offsetAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_offsetAnimation.value, 0),
            child: child,
          );
        },
        child: Icon(Icons.info_outline, size: 28),
      )
          : Icon(Icons.info_outline, size: 28),
    );
  }
}
