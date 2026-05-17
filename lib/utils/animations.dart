import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Wraps child in staggered FadeTransition + SlideTransition.
class StaggeredItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final AnimationController? controller;
  final Duration duration;

  const StaggeredItem({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.controller,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        AnimationController(duration: widget.duration, vsync: this);

    if (_ownsController) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (widget.delay > Duration.zero) {
          await Future<void>.delayed(widget.delay);
        }
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(animation),
        child: widget.child,
      ),
    );
  }
}

/// Animated counter that counts from 0 to target value
class AnimatedCounter extends StatelessWidget {
  final int target;
  final Duration duration;
  final Curve curve;
  final TextStyle? textStyle;

  const AnimatedCounter({
    super.key,
    required this.target,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Text(value.toInt().toString(), style: textStyle);
      },
    );
  }
}

/// Shimmer loading placeholder.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final sweep = (_controller.value * 2) - 1;
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.0 + sweep, -0.15),
                end: Alignment(1.0 + sweep, 0.15),
                colors: const [
                  Color(0xFFE0E0E0),
                  Color(0xFFF7F7F7),
                  Color(0xFFE0E0E0),
                ],
                stops: const [0.2, 0.5, 0.8],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pulsing dot for notification badges.
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulseDot({super.key, this.color = Colors.red, this.size = 12});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 1.0 - (_controller.value * 0.7);
        final scale = 1.0 + (_controller.value * 0.4);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// Pressable widget with scale animation on tap.
class PressableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;

  const PressableWidget({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<PressableWidget> createState() => _PressableWidgetState();
}

class _PressableWidgetState extends State<PressableWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: widget.duration,
        curve: Curves.bounceOut,
        child: widget.child,
      ),
    );
  }
}

/// Shake animation for alerts
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final int shakeCount;

  const ShakeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.shakeCount = 3,
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset =
            math.sin(_controller.value * widget.shakeCount * 2 * math.pi) * 5;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Helper to show a staggered list of items
class StaggeredListAnimationController {
  late AnimationController _controller;
  final TickerProvider vsync;
  final Duration itemDelay;

  StaggeredListAnimationController({
    required this.vsync,
    this.itemDelay = const Duration(milliseconds: 80),
  }) {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: vsync,
    );
  }

  AnimationController get controller => _controller;

  Duration getDelay(int index) => itemDelay * index;

  void forward() => _controller.forward();
  void dispose() => _controller.dispose();
}
