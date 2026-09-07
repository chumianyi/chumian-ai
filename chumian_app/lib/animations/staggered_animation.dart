import 'package:flutter/material.dart';

/// ============================================================================
/// StaggeredAnimation —— 列表项错落入场动画
///
/// 为列表中的每个子项添加依次延迟的入场动画，
/// 实现"错落有致"的视觉效果。支持淡入、上移、缩放组合动画。
///
/// 用法：
///   ListView.builder(
///     itemCount: items.length,
///     itemBuilder: (context, index) {
///       return StaggeredAnimation(
///         index: index,
///         child: YourListItem(),
///       );
///     },
///   )
/// ============================================================================
class StaggeredAnimation extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 列表项索引（决定动画延迟）
  final int index;

  /// 动画总时长
  final Duration duration;

  /// 每项之间的延迟间隔
  final Duration staggerDelay;

  /// 入场起始偏移（相对于自身高度的比例）
  final double beginOffset;

  /// 入场起始缩放
  final double beginScale;

  /// 动画曲线
  final Curve curve;

  /// 是否启用动画（可用于首屏之外的项跳过动画）
  final bool enabled;

  const StaggeredAnimation({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 500),
    this.staggerDelay = const Duration(milliseconds: 60),
    this.beginOffset = 0.15,
    this.beginScale = 0.95,
    this.curve = Curves.easeOutCubic,
    this.enabled = true,
  });

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curve = CurvedAnimation(parent: _controller, curve: widget.curve);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.beginOffset),
      end: Offset.zero,
    ).animate(curve);
    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: 1.0,
    ).animate(curve);

    if (widget.enabled) {
      // 延迟启动动画，实现错落效果
      Future.delayed(widget.staggerDelay * widget.index, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

/// ============================================================================
/// StaggeredAnimationBuilder —— 错落动画构建器
///
/// 更灵活的错落动画实现，通过 builder 回调获取动画值，
/// 可自定义动画效果。适用于需要精确控制动画参数的场景。
/// ============================================================================
class StaggeredAnimationBuilder extends StatefulWidget {
  /// 构建回调，接收动画值（0.0 - 1.0）并返回子组件
  final Widget Function(BuildContext context, double value) builder;

  /// 列表项索引
  final int index;

  /// 动画总时长
  final Duration duration;

  /// 每项延迟间隔
  final Duration staggerDelay;

  /// 动画曲线
  final Curve curve;

  const StaggeredAnimationBuilder({
    super.key,
    required this.builder,
    required this.index,
    this.duration = const Duration(milliseconds: 500),
    this.staggerDelay = const Duration(milliseconds: 60),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<StaggeredAnimationBuilder> createState() =>
      _StaggeredAnimationBuilderState();
}

class _StaggeredAnimationBuilderState
    extends State<StaggeredAnimationBuilder>
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
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    Future.delayed(widget.staggerDelay * widget.index, () {
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
      animation: _animation,
      builder: (context, child) =>
          widget.builder(context, _animation.value),
    );
  }
}

/// ============================================================================
/// StaggeredList —— 错落动画列表封装
///
/// 封装了 ListView + StaggeredAnimation 的便捷组件，
/// 直接传入 itemBuilder 即可获得错落入场效果。
/// ============================================================================
class StaggeredList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Duration duration;
  final Duration staggerDelay;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const StaggeredList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.duration = const Duration(milliseconds: 500),
    this.staggerDelay = const Duration(milliseconds: 60),
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return StaggeredAnimation(
          index: index,
          duration: duration,
          staggerDelay: staggerDelay,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}
