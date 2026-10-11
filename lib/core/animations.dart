import 'dart:async';

import 'package:flutter/material.dart';

/// Fades and slides its child up a few pixels, optionally after [delay].
/// Plays once when the widget is first inserted.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    child: widget.child,
    builder: (_, child) => Opacity(
      opacity: _curve.value,
      child: Transform.translate(
        offset: Offset(0, (1 - _curve.value) * widget.offset),
        child: child,
      ),
    ),
  );
}

/// Smoothly animated number (used for countdowns / progress texts).
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({super.key, required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.toDouble()),
    duration: const Duration(milliseconds: 300),
    builder: (_, v, _) => Text('${v.round()}', style: style),
  );
}

/// A tappable wrapper that gently scales down while pressed.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => _down = true),
    onTapCancel: () => setState(() => _down = false),
    onTapUp: (_) => setState(() => _down = false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: _down ? 0.95 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}
