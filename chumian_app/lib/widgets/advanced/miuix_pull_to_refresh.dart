import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixPullToRefresh —— Miuix 风格下拉刷新
/// 粉色弹性头部，旋转花瓣加载，释放刷新动画，回弹
/// ============================================================

/// 刷新状态
enum _RefreshState { idle, dragging, armed, refreshing, done }

/// Miuix 风格下拉刷新组件
///
/// 用法：
/// ```dart
/// MiuixPullToRefresh(
///   onRefresh: () async { await Future.delayed(Duration(seconds: 2)); },
///   child: ListView(...),
/// )
/// ```
class MiuixPullToRefresh extends StatefulWidget {
  const MiuixPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshTriggerDistance = 80,
    this.headerHeight = 60,
    this.indicatorColor = MiuixColors.primary,
  });

  /// 子组件（通常是可滚动列表）
  final Widget child;

  /// 刷新回调
  final Future<void> Function() onRefresh;

  /// 触发刷新的下拉距离
  final double refreshTriggerDistance;

  /// 头部高度
  final double headerHeight;

  /// 指示器颜色
  final Color indicatorColor;

  @override
  State<MiuixPullToRefresh> createState() => _MiuixPullToRefreshState();
}

class _MiuixPullToRefreshState extends State<MiuixPullToRefresh>
    with SingleTickerProviderStateMixin {
  _RefreshState _state = _RefreshState.idle;
  double _dragOffset = 0;
  late final AnimationController _rotationController;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _bounceController = AnimationController(
      vsync: this,
      duration: MiuixDuration.elastic,
    );
    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: MiuixCurves.miuixSpring,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  bool get _canScroll =>
      PrimaryScrollController.of(context)?.positions.isNotEmpty ?? false;

  double get _headerVisible => _state == _RefreshState.refreshing
      ? widget.headerHeight
      : _dragOffset.clamp(0.0, widget.refreshTriggerDistance * 1.5);

  void _handleScrollUpdate(ScrollUpdateNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return;
    if (_state == _RefreshState.refreshing) return;

    final scrollDelta = notification.scrollDelta ?? 0;
    if (notification.metrics.pixels <= 0 && scrollDelta < 0) {
      setState(() {
        _dragOffset -= scrollDelta * 0.5; // 阻尼效果
        if (_dragOffset >= widget.refreshTriggerDistance) {
          _state = _RefreshState.armed;
        } else {
          _state = _RefreshState.dragging;
        }
      });
    }
  }

  void _handleScrollEnd(ScrollEndNotification notification) {
    if (_state == _RefreshState.armed) {
      _startRefresh();
    } else if (_state == _RefreshState.dragging) {
      _bounceBack();
    }
  }

  void _startRefresh() async {
    setState(() {
      _state = _RefreshState.refreshing;
      _dragOffset = widget.headerHeight;
    });
    await widget.onRefresh();
    if (mounted) {
      setState(() => _state = _RefreshState.done);
      _bounceController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _state = _RefreshState.idle;
            _dragOffset = 0;
          });
        }
      });
    }
  }

  void _bounceBack() {
    _bounceController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _state = _RefreshState.idle;
          _dragOffset = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _handleScrollUpdate(notification);
        } else if (notification is ScrollEndNotification) {
          _handleScrollEnd(notification);
        }
        return false;
      },
      child: Stack(
        children: [
          // 粉色弹性头部背景
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _headerVisible + MediaQuery.of(context).padding.top,
            child: _buildHeader(),
          ),
          // 内容
          Positioned.fill(
            top: _headerVisible,
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final progress = (_dragOffset / widget.refreshTriggerDistance)
        .clamp(0.0, 1.0);
    final isRefreshing = _state == _RefreshState.refreshing;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE8F0), MiuixColors.background],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: isRefreshing
                    ? _rotationController.value * math.pi * 2
                    : progress * math.pi,
                child: CustomPaint(
                  size: Size(36, 36),
                  painter: _PetalPainter(
                    color: widget.indicatorColor,
                    progress: isRefreshing ? 1.0 : progress,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 花瓣加载指示器绘制器
class _PetalPainter extends CustomPainter {
  _PetalPainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petalCount = 6;

    for (int i = 0; i < petalCount; i++) {
      final angle = i * math.pi * 2 / petalCount;
      final petalProgress =
          ((progress * petalCount - i) / 1).clamp(0.0, 1.0);
      if (petalProgress <= 0) continue;

      final petalCenter = center +
          Offset(
            math.cos(angle) * size.width * 0.25,
            math.sin(angle) * size.width * 0.25,
          );

      final petalPaint = Paint()
        ..color = color.withValues(alpha: 0.4 + petalProgress * 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        petalCenter,
        size.width * 0.12 * petalProgress,
        petalPaint,
      );
    }

    // 中心圆
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.1 * progress, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _PetalPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// ============================================================
/// MiuixRefreshIndicator —— 标准 RefreshIndicator 风格封装
/// 可包裹任意可滚动组件，粉色加载动画
/// ============================================================
class MiuixRefreshIndicator extends StatelessWidget {
  const MiuixRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40,
    this.strokeWidth = 2.5,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final double displacement;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: displacement,
      strokeWidth: strokeWidth,
      color: MiuixColors.primary,
      backgroundColor: MiuixColors.surface,
      child: child,
    );
  }
}

/// ============================================================
/// MiuixLoadingMore —— 上拉加载更多指示器
/// 粉色旋转加载动画
/// ============================================================
class MiuixLoadingMore extends StatefulWidget {
  const MiuixLoadingMore({
    super.key,
    this.status = MiuixLoadMoreStatus.idle,
    this.onLoadMore,
  });

  final MiuixLoadMoreStatus status;
  final VoidCallback? onLoadMore;

  @override
  State<MiuixLoadingMore> createState() => _MiuixLoadingMoreState();
}

enum MiuixLoadMoreStatus { idle, loading, noMore, error }

class _MiuixLoadingMoreState extends State<MiuixLoadingMore> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.lg),
      child: Center(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.status) {
      case MiuixLoadMoreStatus.loading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(MiuixColors.primary),
              ),
            ),
            const SizedBox(width: MiuixSpacing.sm),
            const Text(
              '加载中...',
              style: TextStyle(
                color: MiuixColors.textSecondary,
                fontSize: MiuixFontSize.sm,
              ),
            ),
          ],
        );
      case MiuixLoadMoreStatus.noMore:
        return const Text(
          '没有更多了',
          style: TextStyle(
            color: MiuixColors.textTertiary,
            fontSize: MiuixFontSize.sm,
          ),
        );
      case MiuixLoadMoreStatus.error:
        return GestureDetector(
          onTap: widget.onLoadMore,
          child: const Text(
            '加载失败，点击重试',
            style: TextStyle(
              color: MiuixColors.error,
              fontSize: MiuixFontSize.sm,
            ),
          ),
        );
      case MiuixLoadMoreStatus.idle:
        return const SizedBox.shrink();
    }
  }
}
