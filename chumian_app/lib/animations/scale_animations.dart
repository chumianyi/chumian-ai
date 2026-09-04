import 'package:flutter/material.dart';
import 'animation_constants.dart';

/// 缩放进入动画 - 从极小放大到正常
class ScaleInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double beginScale;
  final double endScale;
  final Offset? beginOffset;
  final bool autoPlay;
  final VoidCallback? onComplete;

  const ScaleInAnimation({
    super.key,
    required this.child,
    this.duration = AppDurations.navSwitch,
    this.curve = AppCurves.elasticOut,
    this.beginScale = 0.1,
    this.endScale = 1.0,
    this.beginOffset,
    this.autoPlay = true,
    this.onComplete,
  });

  @override
  State<ScaleInAnimation> createState() => _ScaleInAnimationState();
}

class _ScaleInAnimationState extends State<ScaleInAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scale = Tween<double>(
      begin: widget.beginScale,
      end: widget.endScale,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _slide = Tween<Offset>(
      begin: widget.beginOffset ?? const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.smooth));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
    if (widget.autoPlay) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void forward() => _controller.forward();
  void reverse() => _controller.reverse();
  void reset() => _controller.reset();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: _slide.value * 50,
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 缩放退出动画
class ScaleOutAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double endScale;
  final bool autoPlay;

  const ScaleOutAnimation({
    super.key,
    required this.child,
    this.duration = AppDurations.fast,
    this.curve = AppCurves.accelerate,
    this.endScale = 0.8,
    this.autoPlay = false,
  });

  @override
  State<ScaleOutAnimation> createState() => _ScaleOutAnimationState();
}

class _ScaleOutAnimationState extends State<ScaleOutAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: 1.0, end: widget.endScale)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _fade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    if (widget.autoPlay) _controller.forward();
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
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}

/// 弹性缩放动画 - 用于按钮点击反馈
class ElasticScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double pressScale;
  final VoidCallback? onTap;
  final bool enabled;

  const ElasticScaleAnimation({
    super.key,
    required this.child,
    this.duration = AppDurations.buttonPress,
    this.pressScale = 0.95,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<ElasticScaleAnimation> createState() => _ElasticScaleAnimationState();
}

class _ElasticScaleAnimationState extends State<ElasticScaleAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// 脉冲缩放动画
class PulseScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool repeat;

  const PulseScaleAnimation({
    super.key,
    required this.child,
    this.duration = AppDurations.pulse,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.repeat = true,
  });

  @override
  State<PulseScaleAnimation> createState() => _PulseScaleAnimationState();
}

class _PulseScaleAnimationState extends State<PulseScaleAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: widget.minScale, end: widget.maxScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.repeat) {
      _controller.repeat(reverse: true);
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
      animation: _controller,
      builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}

/// 呼吸缩放动画
class BreatheScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scaleRange;

  const BreatheScaleAnimation({
    super.key,
    required this.child,
    this.duration = AppDurations.breathe,
    this.scaleRange = 0.03,
  });

  @override
  State<BreatheScaleAnimation> createState() => _BreatheScaleAnimationState();
}

class _BreatheScaleAnimationState extends State<BreatheScaleAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(
      begin: 1.0 - widget.scaleRange,
      end: 1.0 + widget.scaleRange,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine));
    _controller.repeat(reverse: true);
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
      builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}
