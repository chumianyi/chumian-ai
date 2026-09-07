import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixMasonryGrid —— Miuix 风格石砌网格
/// 不等高网格布局，粉色卡片，错落入场，点击缩放
/// ============================================================

/// 石砌网格项数据
class MiuixMasonryItem {
  const MiuixMasonryItem({
    required this.id,
    required this.height,
    this.title,
    this.subtitle,
    this.color,
    this.child,
    this.onTap,
  });

  /// 唯一标识
  final String id;

  /// 高度
  final double height;

  /// 标题
  final String? title;

  /// 副标题
  final String? subtitle;

  /// 背景色
  final Color? color;

  /// 自定义内容
  final Widget? child;

  /// 点击回调
  final VoidCallback? onTap;
}

/// Miuix 风格石砌网格
///
/// 用法：
/// ```dart
/// MiuixMasonryGrid(
///   items: [
///     MiuixMasonryItem(id: '1', height: 180, title: '卡片1'),
///     MiuixMasonryItem(id: '2', height: 240, title: '卡片2'),
///   ],
/// )
/// ```
class MiuixMasonryGrid extends StatefulWidget {
  const MiuixMasonryGrid({
    super.key,
    required this.items,
    this.columns = 2,
    this.spacing = 12,
    this.animate = true,
    this.physics,
    this.shrinkWrap = false,
  });

  /// 网格项列表
  final List<MiuixMasonryItem> items;

  /// 列数
  final int columns;

  /// 间距
  final double spacing;

  /// 是否启用错落入场
  final bool animate;

  /// 滚动物理
  final ScrollPhysics? physics;

  /// 是否紧凑
  final bool shrinkWrap;

  @override
  State<MiuixMasonryGrid> createState() => _MiuixMasonryGridState();
}

class _MiuixMasonryGridState extends State<MiuixMasonryGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.animate) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _controller.forward());
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getItemProgress(int index) {
    final start = (index * 0.06).clamp(0.0, 0.7);
    final end = (start + 0.25).clamp(0.0, 1.0);
    if (_controller.value <= start) return 0;
    if (_controller.value >= end) return 1;
    return (_controller.value - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomScrollView(
          physics: widget.physics,
          shrinkWrap: widget.shrinkWrap,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(widget.spacing),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: widget.columns,
                mainAxisSpacing: widget.spacing,
                crossAxisSpacing: widget.spacing,
                childCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final progress = _getItemProgress(index);
                  return _MasonryCard(
                    item: item,
                    progress: progress,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 石砌卡片
class _MasonryCard extends StatefulWidget {
  const _MasonryCard({
    required this.item,
    required this.progress,
  });

  final MiuixMasonryItem item;
  final double progress;

  @override
  State<_MasonryCard> createState() => _MasonryCardState();
}

class _MasonryCardState extends State<_MasonryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: MiuixDuration.fast,
      reverseDuration: MiuixDuration.elastic,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.95)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: MiuixCurves.miuixSpring)),
        weight: 70,
      ),
    ]).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curveValue = Curves.easeOutCubic.transform(widget.progress);
    final slideY = (1 - curveValue) * 40;

    return Transform.translate(
      offset: Offset(0, slideY),
      child: Opacity(
        opacity: curveValue,
        child: GestureDetector(
          onTapDown: (_) => _scaleController.forward(),
          onTapUp: (_) {
            _scaleController.reverse();
            widget.item.onTap?.call();
          },
          onTapCancel: () => _scaleController.reverse(),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: Container(
              height: widget.item.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.item.color ?? MiuixColors.primaryLight,
                    (widget.item.color ?? MiuixColors.primary)
                        .withOpacity(0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(MiuixRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: (widget.item.color ?? MiuixColors.primary)
                        .withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.item.child ??
                  Stack(
                    children: [
                      // 装饰圆
                      Positioned(
                        top: -15,
                        right: -15,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -10,
                        left: -10,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // 内容
                      Padding(
                        padding: const EdgeInsets.all(MiuixSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (widget.item.title != null)
                              Text(
                                widget.item.title!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: MiuixFontSize.md,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (widget.item.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.item.subtitle!,
                                style: TextStyle(
                                  color:
                                      Colors.white.withOpacity(0.85),
                                  fontSize: MiuixFontSize.sm,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
