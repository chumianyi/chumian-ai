import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// SpringAnimationBuilder —— 弹簧动画封装
///
/// 基于 Flutter 的 SpringSimulation 实现物理弹簧动画，
/// 提供 Miuix 标志性的"按压回弹"效果。封装了常用的弹簧参数预设，
/// 可用于按钮按压、卡片展开、数值变化等场景。
///
/// 用法：
///   SpringAnimationBuilder(
///     builder: (context, value, child) {
///       return Transform.scale(scale: value, child: child);
///     },
///     child: MyButton(),
///   )
/// ============================================================================
class SpringAnimationBuilder extends StatefulWidget {
  /// 构建回调，接收动画值（0.0 - 1.0）和子组件
  final Widget Function(BuildContext context, double value, Widget? child)
      builder;

  /// 子组件（可选，用于优化性能）
  final Widget? child;

  /// 动画起始值
  final double begin;

  /// 动画结束值
  final double end;

  /// 弹簧刚度（越大回弹越快）
  final double stiffness;

  /// 弹簧阻尼（越大震荡越少）
  final double damping;

  /// 质量
  final double mass;

  /// 动画持续时间上限
  final Duration duration;

  /// 是否在构建时自动启动动画
  final bool autoStart;

  /// 动画曲线（用于非弹簧模式的回退）
  final Curve curve;

  const SpringAnimationBuilder({
    super.key,
    required this.builder,
    this.child,
    this.begin = 0.0,
    this.end = 1.0,
    this.stiffness = 180.0,
    this.damping = 12.0,
    this.mass = 1.0,
    this.duration = const Duration(milliseconds: 600),
    this.autoStart = true,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SpringAnimationBuilder> createState() =>
      _SpringAnimationBuilderState();

  /// 预设：Miuix 标准弹簧（柔和回弹）
  factory SpringAnimationBuilder.miuix({
    Key? key,
    required Widget Function(BuildContext, double, Widget?) builder,
    Widget? child,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return SpringAnimationBuilder(
      key: key,
      builder: builder,
      child: child,
      begin: begin,
      end: end,
      stiffness: 200.0,
      damping: 14.0,
      mass: 1.0,
    );
  }

  /// 预设：轻快弹簧（快速回弹，轻微过冲）
  factory SpringAnimationBuilder.bounce({
    Key? key,
    required Widget Function(BuildContext, double, Widget?) builder,
    Widget? child,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return SpringAnimationBuilder(
      key: key,
      builder: builder,
      child: child,
      begin: begin,
      end: end,
      stiffness: 300.0,
      damping: 8.0,
      mass: 1.0,
    );
  }

  /// 预设：柔和弹簧（无过冲，平滑过渡）
  factory SpringAnimationBuilder.soft({
    Key? key,
    required Widget Function(BuildContext, double, Widget?) builder,
    Widget? child,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return SpringAnimationBuilder(
      key: key,
      builder: builder,
      child: child,
      begin: begin,
      end: end,
      stiffness: 120.0,
      damping: 18.0,
      mass: 1.0,
    );
  }
}

class _SpringAnimationBuilderState extends State<SpringAnimationBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // 控制器值通过弹簧模拟从 0 运动到 1，
    // Tween 将 0-1 映射到 begin-end 范围
    _animation = Tween<double>(
      begin: widget.begin,
      end: widget.end,
    ).animate(_controller);

    // 使用弹簧描述创建物理模拟
    final springDescription = SpringDescription(
      mass: widget.mass,
      stiffness: widget.stiffness,
      damping: widget.damping,
    );

    if (widget.autoStart) {
      // 以弹簧物理驱动控制器从 0 运动到 1
      _controller.animateWith(SpringSimulation(
        springDescription,
        0.0, // 起始位置
        0.0, // 初始速度
        1.0, // 目标位置
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 重新播放动画
  void replay() {
    _controller.reset();
    final springDescription = SpringDescription(
      mass: widget.mass,
      stiffness: widget.stiffness,
      damping: widget.damping,
    );
    _controller.animateWith(SpringSimulation(
      springDescription,
      0.0,
      0.0,
      1.0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) =>
          widget.builder(context, _animation.value, child),
      child: widget.child,
    );
  }
}

/// ============================================================================
/// SpringScale —— 弹簧缩放组件
///
/// 封装了弹簧动画 + 缩放变换的便捷组件，
/// 适用于按钮按压、卡片出现等需要缩放动画的场景。
/// ============================================================================
class SpringScale extends StatefulWidget {
  final Widget child;
  final double beginScale;
  final double endScale;
  final Duration delay;
  final double stiffness;
  final double damping;

  const SpringScale({
    super.key,
    required this.child,
    this.beginScale = 0.8,
    this.endScale = 1.0,
    this.delay = Duration.zero,
    this.stiffness = 200.0,
    this.damping = 14.0,
  });

  @override
  State<SpringScale> createState() => _SpringScaleState();
}

class _SpringScaleState extends State<SpringScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 控制器 0-1 映射到 beginScale-endScale
    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: widget.endScale,
    ).animate(_controller);

    final spring = SpringDescription(
      mass: 1.0,
      stiffness: widget.stiffness,
      damping: widget.damping,
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.animateWith(SpringSimulation(spring, 0.0, 0.0, 1.0));
      }
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
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// ============================================================================
/// Pressable —— 可按压弹簧组件
///
/// 按下时缩小，松开时弹簧回弹，模拟物理按钮的按压感。
/// 适用于自定义按钮、卡片点击等交互场景。
/// ============================================================================
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double pressScale;
  final Duration animationDuration;

  const Pressable({
    super.key,
    required this.child,
    this.onPressed,
    this.pressScale = 0.95,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: MiuixCurves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
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
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
