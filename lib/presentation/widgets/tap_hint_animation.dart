import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TapHintAnimation extends StatefulWidget {
  final Widget child;
  final double circleSize;
  final double fingerSize;
  final Color circleColor;
  final Duration duration;
  final bool showFinger;
  final bool showPulse;
  final String hintKey;
  final VoidCallback? onDismiss; // ✅ new

  const TapHintAnimation({
    super.key,
    required this.child,
    required this.hintKey,
    this.circleSize = 120,
    this.fingerSize = 30,
    this.circleColor = Colors.blue,
    this.duration = const Duration(seconds: 2),
    this.showFinger = true,
    this.showPulse = true,
    this.onDismiss,
  });

  @override
  State<TapHintAnimation> createState() => _TapHintAnimationState();
}

class _TapHintAnimationState extends State<TapHintAnimation>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _fingerController;
  late Animation<double> _circleScale;
  late Animation<double> _circleOpacity;
  late Animation<Offset> _fingerSlide;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _checkIfSeen();

    _circleController =
        AnimationController(vsync: this, duration: widget.duration);
    _fingerController =
        AnimationController(vsync: this, duration: widget.duration);

    _circleScale = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOut),
    );
    _circleOpacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOut),
    );
    _fingerSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fingerController, curve: Curves.easeOutBack));
  }

  Future<void> _checkIfSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(widget.hintKey) ?? false;
    if (!seen) {
      setState(() => _visible = true);
      _startAnimations();
    }
  }

  void _startAnimations() {
    _circleController.repeat();
    _fingerController.repeat();
  }

  Future<void> _markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.hintKey, true);
    setState(() => _visible = false);
    widget.onDismiss?.call(); // ✅ trigger next hint
  }

  @override
  void dispose() {
    _circleController.dispose();
    _fingerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return widget.child;

    return GestureDetector(
      onTap: _markAsSeen,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (widget.showPulse)
            AnimatedBuilder(
              animation: _circleController,
              builder: (_, __) => Transform.scale(
                scale: _circleScale.value,
                child: Opacity(
                  opacity: _circleOpacity.value,
                  child: Container(
                    width: widget.circleSize,
                    height: widget.circleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.circleColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          if (widget.showFinger)
            Positioned(
              bottom: widget.fingerSize * 1.5,
              child: SlideTransition(
                position: _fingerSlide,
                child: Text('👆', style: TextStyle(fontSize: widget.fingerSize)),
              ),
            ),
        ],
      ),
    );
  }
}
