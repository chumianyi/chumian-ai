import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// AttentionAnimations —— 注意力动画集合
///
/// 提供多种用于吸引用户注意力的动画：抖动、闪烁、脉冲、心跳、摇晃等。
/// 适用于新消息提示、错误提醒、重要操作引导等场景，粉色主题。
/// ============================================================================

/// 抖动画（左右快速抖动，用于错误提示）
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;
  final int shakeCount;
  final bool autoPlay;
  final VoidCallback? onComplete;

  const ShakeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 8.0,
    this.shakeCount = 4,
    this.autoPlay = false,
    this.onComplete,
  });

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
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

  /// 触发抖动
  void shake() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        // 正弦波抖动：多次来回
        final shake =
            sin(progress * widget.shakeCount * pi * 2) * widget.offset;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 闪烁动画（透明度交替，用于提示）
class BlinkAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minOpacity;
  final bool repeat;
  final int? repeatCount;
  final VoidCallback? onComplete;

  const BlinkAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.minOpacity = 0.3,
    this.repeat = true,
    this.repeatCount,
    this.onComplete,
  });

  @override
  State<BlinkAnimation> createState() => _BlinkAnimationState();
}

class _BlinkAnimationState extends State<BlinkAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _currentCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentCount++;
        if (widget.repeat &&
            (widget.repeatCount == null ||
                _currentCount < widget.repeatCount!)) {
          _controller.reverse();
        } else if (!widget.repeat) {
          widget.onComplete?.call();
        } else {
          widget.onComplete?.call();
        }
      } else if (status == AnimationStatus.dismissed) {
        if (widget.repeat &&
            (widget.repeatCount == null ||
                _currentCount < widget.repeatCount!)) {
          _controller.forward();
        }
      }
    });
    _controller.forward();
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
        final opacity = widget.minOpacity +
            (1.0 - widget.minOpacity) * _controller.value;
        return Opacity(opacity: opacity, child: child);
      },
      child: widget.child,
    );
  }
}

/// 脉冲动画（缩放呼吸，用于强调）
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool repeat;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.repeat = true,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
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
      builder: (context, child) {
        final scale = widget.minScale +
            (widget.maxScale - widget.minScale) * _controller.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}

/// 心跳动画（模拟心跳节奏，两连跳）
class HeartbeatAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scale;
  final bool repeat;

  const HeartbeatAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
    this.scale = 1.15,
    this.repeat = true,
  });

  @override
  State<HeartbeatAnimation> createState() => _HeartbeatAnimationState();
}

class _HeartbeatAnimationState extends State<HeartbeatAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
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
      builder: (context, child) {
        final t = _controller.value;
        // 心跳曲线：0-0.1 快速放大，0.1-0.2 回缩，0.2-0.3 再放大，0.3-1.0 保持
        double scale;
        if (t < 0.1) {
          scale = 1.0 + (widget.scale - 1.0) * (t / 0.1);
        } else if (t < 0.2) {
          scale = widget.scale - (widget.scale - 1.0) * ((t - 0.1) / 0.1);
        } else if (t < 0.3) {
          scale = 1.0 + (widget.scale - 1.0) * 0.7 * ((t - 0.2) / 0.1);
        } else if (t < 0.4) {
          scale = 1.0 + (widget.scale - 1.0) * 0.7 * (1 - (t - 0.3) / 0.1);
        } else {
          scale = 1.0;
        }
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}

/// 摇晃动画（旋转摇晃，用于提醒）
class WobbleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double angle;
  final bool repeat;

  const WobbleAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.angle = 0.05,
    this.repeat = true,
  });

  @override
  State<WobbleAnimation> createState() => _WobbleAnimationState();
}

class _WobbleAnimationState extends State<WobbleAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
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
      builder: (context, child) {
        final rotation = sin(_controller.value * pi * 2) * widget.angle;
        return Transform.rotate(angle: rotation, child: child);
      },
      child: widget.child,
    );
  }
}

/// 呼吸光晕动画（粉色光圈脉冲，用于重要元素）
class GlowPulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color glowColor;
  final double maxBlur;
  final double maxSpread;
  final bool repeat;

  const GlowPulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.glowColor = MiuixColors.primary,
    this.maxBlur = 30.0,
    this.maxSpread = 5.0,
    this.repeat = true,
  });

  @override
  State<GlowPulseAnimation> createState() => _GlowPulseAnimationState();
}

class _GlowPulseAnimationState extends State<GlowPulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
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
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.4 * t),
                blurRadius: widget.maxBlur * t,
                spreadRadius: widget.maxSpread * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
