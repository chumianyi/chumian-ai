import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixAnimatedList / StaggeredList —— 列表项错落入场动画
/// 淡入 + 上移 + 缩放，每项延迟 50ms
/// 删除/插入动画
/// ============================================================

/// 错落入场动画列表
///
/// 用法：
/// ```dart
/// MiuixAnimatedList(
///   itemCount: items.length,
///   itemBuilder: (context, index, animation) => ListTile(title: Text(items[index])),
/// )
/// ```
class MiuixAnimatedList extends StatefulWidget {
  const MiuixAnimatedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 500),
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.clipBehavior = Clip.hardEdge,
    this.startDelay = Duration.zero,
  });

  /// 列表项数量
  final int itemCount;

  /// 列表项构建器（带动画参数）
  final Widget Function(
    BuildContext context,
    int index,
    Animation<double> animation,
  ) itemBuilder;

  /// 每项延迟
  final Duration staggerDelay;

  /// 动画时长
  final Duration animationDuration;

  /// 滚动方向
  final Axis scrollDirection;

  /// 滚动控制器
  final ScrollController? controller;

  /// 滚动物理
  final ScrollPhysics? physics;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 是否紧凑
  final bool shrinkWrap;

  /// 裁剪行为
  final Clip clipBehavior;

  /// 起始延迟
  final Duration startDelay;

  @override
  State<MiuixAnimatedList> createState() => _MiuixAnimatedListState();
}

class _MiuixAnimatedListState extends State<MiuixAnimatedList>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // 延迟启动错落动画
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
    });
  }

  void _initAnimations() {
    for (int i = 0; i < widget.itemCount; i++) {
      final AnimationController controller = AnimationController(
        vsync: this,
        duration: widget.animationDuration,
      );
      final Animation<double> animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      );
      _controllers.add(controller);
      _animations.add(animation);
    }
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(
        widget.startDelay + widget.staggerDelay * i,
        () {
          if (mounted) _controllers[i].forward();
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant MiuixAnimatedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      // 清理多余的控制器
      while (_controllers.length > widget.itemCount) {
        _controllers.removeLast().dispose();
        _animations.removeLast();
      }
      // 添加新的控制器
      while (_controllers.length < widget.itemCount) {
        final int index = _controllers.length;
        final AnimationController controller = AnimationController(
          vsync: this,
          duration: widget.animationDuration,
        );
        final Animation<double> animation = CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        );
        _controllers.add(controller);
        _animations.add(animation);
        Future.delayed(widget.staggerDelay * index, () {
          if (mounted) controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: widget.scrollDirection,
      controller: widget.controller,
      physics: widget.physics,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      clipBehavior: widget.clipBehavior,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        if (index >= _animations.length) {
          return widget.itemBuilder(
            context,
            index,
            const AlwaysStoppedAnimation(1.0),
          );
        }
        return _AnimatedListItem(
          animation: _animations[index],
          child: widget.itemBuilder(context, index, _animations[index]),
        );
      },
    );
  }
}

/// 单个动画列表项
class _AnimatedListItem extends StatelessWidget {
  const _AnimatedListItem({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 30),
            child: Transform.scale(
              scale: 0.95 + t * 0.05,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// ============================================================
/// StaggeredList —— 错落列表（Sliver 版本）
/// ============================================================

/// 错落 Sliver 列表
class StaggeredList extends StatefulWidget {
  const StaggeredList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 500),
  });

  final int itemCount;
  final Widget Function(BuildContext, int, Animation<double>) itemBuilder;
  final Duration staggerDelay;
  final Duration animationDuration;

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.itemCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: widget.animationDuration,
      );
      _controllers.add(controller);
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _controllers.length) {
            return widget.itemBuilder(
              context,
              index,
              const AlwaysStoppedAnimation(1.0),
            );
          }
          final animation = CurvedAnimation(
            parent: _controllers[index],
            curve: Curves.easeOutCubic,
          );
          return _AnimatedListItem(
            animation: animation,
            child: widget.itemBuilder(context, index, animation),
          );
        },
        childCount: widget.itemCount,
      ),
    );
  }
}

/// ============================================================
/// MiuixAnimatedListController —— 支持插入/删除动画的列表控制器
/// ============================================================

/// 动画列表控制器
class MiuixAnimatedListController {
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  void insertItem(int index) {
    listKey.currentState?.insertItem(index);
  }

  void removeItem(int index, Widget item) {
    listKey.currentState?.removeItem(
      index,
      (context, animation) => _AnimatedListItem(
        animation: animation,
        child: item,
      ),
    );
  }
}
