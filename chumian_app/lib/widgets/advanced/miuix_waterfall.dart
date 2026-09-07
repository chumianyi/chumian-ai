import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixWaterfall —— Miuix 风格瀑布流
/// 双列瀑布流布局，卡片错落入场，粉色卡片，加载更多
/// ============================================================

/// 瀑布流项数据
class MiuixWaterfallItem {
  const MiuixWaterfallItem({
    required this.id,
    required this.height,
    this.title,
    this.subtitle,
    this.color,
    this.imageUrl,
    this.onTap,
  });

  /// 唯一标识
  final String id;

  /// 卡片高度
  final double height;

  /// 标题
  final String? title;

  /// 副标题
  final String? subtitle;

  /// 卡片背景色
  final Color? color;

  /// 图片URL
  final String? imageUrl;

  /// 点击回调
  final VoidCallback? onTap;
}

/// Miuix 风格瀑布流
///
/// 用法：
/// ```dart
/// MiuixWaterfall(
///   items: [
///     MiuixWaterfallItem(id: '1', height: 180, title: '卡片1'),
///     MiuixWaterfallItem(id: '2', height: 220, title: '卡片2'),
///   ],
/// )
/// ```
class MiuixWaterfall extends StatefulWidget {
  const MiuixWaterfall({
    super.key,
    required this.items,
    this.columns = 2,
    this.spacing = 12,
    this.onLoadMore,
    this.hasMore = false,
    this.animate = true,
  });

  /// 瀑布流项列表
  final List<MiuixWaterfallItem> items;

  /// 列数
  final int columns;

  /// 间距
  final double spacing;

  /// 加载更多回调
  final VoidCallback? onLoadMore;

  /// 是否还有更多
  final bool hasMore;

  /// 是否启用错落入场
  final bool animate;

  @override
  State<MiuixWaterfall> createState() => _MiuixWaterfallState();
}

class _MiuixWaterfallState extends State<MiuixWaterfall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scrollController.addListener(_onScroll);
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        widget.hasMore &&
        !_loadingMore) {
      _loadingMore = true;
      widget.onLoadMore?.call();
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomScrollView(
          controller: _scrollController,
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
                  final itemProgress = _getItemProgress(index);
                  return _WaterfallCard(
                    item: item,
                    progress: itemProgress,
                  );
                },
              ),
            ),
            if (widget.hasMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(MiuixSpacing.lg),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          MiuixColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _getItemProgress(int index) {
    final start = (index * 0.05).clamp(0.0, 0.8);
    final end = (start + 0.2).clamp(0.0, 1.0);
    if (_controller.value <= start) return 0;
    if (_controller.value >= end) return 1;
    return (_controller.value - start) / (end - start);
  }
}

/// 瀑布流卡片
class _WaterfallCard extends StatefulWidget {
  const _WaterfallCard({
    required this.item,
    required this.progress,
  });

  final MiuixWaterfallItem item;
  final double progress;

  @override
  State<_WaterfallCard> createState() => _WaterfallCardState();
}

class _WaterfallCardState extends State<_WaterfallCard>
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
    final slideY = (1 - curveValue) * 30;

    return Transform.translate(
      offset: Offset(0, slideY),
      child: Opacity(
        opacity: curveValue,
        child: GestureDetector(
          onTapDown: (_) => _scaleController.forward(),
          onTapUp: (_) => _scaleController.reverse(),
          onTapCancel: () => _scaleController.reverse(),
          onTap: widget.item.onTap,
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
                        .withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(MiuixRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: (widget.item.color ?? MiuixColors.primary)
                        .withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 高光装饰
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // 内容
                  if (widget.item.title != null ||
                      widget.item.subtitle != null)
                    Positioned(
                      left: MiuixSpacing.md,
                      right: MiuixSpacing.md,
                      bottom: MiuixSpacing.md,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                color: Colors.white.withValues(alpha: 0.85),
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
