import 'dart:math';
import 'package:flutter/material.dart';

/// ============================================================================
/// RotateAnimations —— 旋转动画集合
///
/// 提供 Spin / Pendulum / Flip / 3DRotate 等旋转动画，
/// 支持无限旋转、翻转动画、3D 透视旋转。
/// ============================================================================

/// 无限旋转动画
class Spin extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final int turns;
  final Curve curve;

  const Spin({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 1),
    this.turns = 1,
    this.curve = Curves.linear,
  });

  @override
  State<Spin> createState() => _SpinState();
}

class _SpinState extends State<Spin> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _rotation = Tween<double>(begin: 0, end: widget.turns * 2 * pi)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotation,
      builder: (context, child) {
        return Transform.rotate(angle: _rotation.value, child: child);
      },
      child: widget.child,
    );
  }
}

/// 钟摆动画（左右摆动）
class Pendulum extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double angle;
  final Curve curve;

  const Pendulum({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.angle = 0.3,
    this.curve = Curves.easeInOut,
  });

  @override
  State<Pendulum> createState() => _PendulumState();
}

class _PendulumState extends State<Pendulum>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    _rotation = Tween<double>(begin: -widget.angle, end: widget.angle)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotation.value,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 翻转动画（Y 轴翻转，类似卡片翻转）
class Flip extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;
  final bool isFlipped;
  final Curve curve;

  const Flip({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 600),
    this.isFlipped = false,
    this.curve = Curves.easeInOut,
  });

  @override
  State<Flip> createState() => _FlipState();
}

class _FlipState extends State<Flip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _rotation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    if (widget.isFlipped) _controller.value = 1;
  }

  @override
  void didUpdateWidget(Flip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
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
    return AnimatedBuilder(
      animation: _rotation,
      builder: (context, child) {
        final angle = _rotation.value;
        final isBack = angle > pi / 2;
        final displayAngle = isBack ? angle - pi : angle;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(displayAngle),
          child: isBack ? widget.back : widget.front,
        );
      },
    );
  }
}

/// 3D 透视旋转动画
class ThreeDRotate extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double rotateX;
  final double rotateY;
  final double perspective;
  final Curve curve;

  const ThreeDRotate({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.rotateX = 0.3,
    this.rotateY = 0.5,
    this.perspective = 0.002,
    this.curve = Curves.easeInOut,
  });

  @override
  State<ThreeDRotate> createState() => _ThreeDRotateState();
}

class _ThreeDRotateState extends State<ThreeDRotate>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
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
        final t = _animation.value;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, widget.perspective)
            ..rotateX(widget.rotateX * sin(t * 2 * pi))
            ..rotateY(widget.rotateY * cos(t * 2 * pi)),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 3D 倾斜跟随（根据鼠标/触摸位置倾斜）
class TiltFollow extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final Duration duration;

  const TiltFollow({
    super.key,
    required this.child,
    this.maxTilt = 0.1,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<TiltFollow> createState() => _TiltFollowState();
}

class _TiltFollowState extends State<TiltFollow> {
  double _tiltX = 0;
  double _tiltY = 0;

  void _onPointerMove(PointerMoveEvent event) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final position = box.globalToLocal(event.position);
    final center = box.size.center(Offset.zero);
    final dx = (position.dx - center.dx) / center.dx;
    final dy = (position.dy - center.dy) / center.dy;
    setState(() {
      _tiltX = (-dy * widget.maxTilt).clamp(-widget.maxTilt, widget.maxTilt);
      _tiltY = (dx * widget.maxTilt).clamp(-widget.maxTilt, widget.maxTilt);
    });
  }

  void _onPointerExit(PointerExitEvent event) {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: _onPointerMove,
      onPointerExit: _onPointerExit,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateX(_tiltX)
          ..rotateY(_tiltY),
        child: widget.child,
      ),
    );
  }
}

/// 旋转入场动画
class RotateIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double beginAngle;
  final Curve curve;

  const RotateIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.beginAngle = -0.5,
    this.curve = Curves.elasticOut,
  });

  @override
  State<RotateIn> createState() => _RotateInState();
}

class _RotateInState extends State<RotateIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final curve = CurvedAnimation(parent: _controller, curve: widget.curve);
    _rotation =
        Tween<double>(begin: widget.beginAngle, end: 0).animate(curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _scale = Tween<double>(begin: 0.5, end: 1).animate(curve);
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
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
        return Opacity(
          opacity: _opacity.value,
          child: Transform.rotate(
            angle: _rotation.value,
            child: Transform.scale(scale: _scale.value, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
