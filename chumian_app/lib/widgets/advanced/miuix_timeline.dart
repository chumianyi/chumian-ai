import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixTimeline —— Miuix 风格时间线
/// 左右交替时间线节点，粉色圆点，连接线，卡片内容，错落入场
/// ============================================================

/// 时间线节点数据
class MiuixTimelineItem {
  const MiuixTimelineItem({
    required this.title,
    required this.time,
    this.description,
    this.icon,
    this.content,
    this.color,
  });

  /// 标题
  final String title;

  /// 时间
  final String time;

  /// 描述
  final String? description;

  /// 图标
  final IconData? icon;

  /// 自定义内容
  final Widget? content;

  /// 自定义颜色
  final Color? color;
}

/// Miuix 风格时间线
///
/// 用法：
/// ```dart
/// MiuixTimeline(
///   items: [
///     MiuixTimelineItem(title: '订单创建', time: '10:00', description: '用户下单'),
///     MiuixTimelineItem(title: '支付完成', time: '10:05', description: '已付款'),
///   ],
/// )
/// ```
class MiuixTimeline extends StatefulWidget {
  const MiuixTimeline({
    super.key,
    required this.items,
    this.alternate = true,
    this.animate = true,
    this.animationDelay = 100,
  });

  /// 时间线节点列表
  final List<MiuixTimelineItem> items;

  /// 是否左右交替
  final bool alternate;

  /// 是否启用错落入场动画
  final bool animate;

  /// 每个节点的动画延迟（毫秒）
  final int animationDelay;

  @override
  State<MiuixTimeline> createState() => _MiuixTimelineState();
}

class _MiuixTimelineState extends State<MiuixTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 600 + widget.items.length * widget.animationDelay,
      ),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: MiuixCurves.easeOut,
    );
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            final isLeft = widget.alternate ? index.isEven : true;
            final itemProgress = _getItemProgress(index);

            return _TimelineNode(
              item: item,
              isLeft: isLeft,
              isLast: index == widget.items.length - 1,
              progress: itemProgress,
            );
          }),
        );
      },
    );
  }

  double _getItemProgress(int index) {
    final start = index * widget.animationDelay /
        (600 + widget.items.length * widget.animationDelay);
    final end = (index * widget.animationDelay + 500) /
        (600 + widget.items.length * widget.animationDelay);
    if (_animation.value <= start) return 0;
    if (_animation.value >= end) return 1;
    return (_animation.value - start) / (end - start);
  }
}

/// 时间线节点
class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.item,
    required this.isLeft,
    required this.isLast,
    required this.progress,
  });

  final MiuixTimelineItem item;
  final bool isLeft;
  final bool isLast;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final curveValue = Curves.easeOutCubic.transform(progress);
    final slideOffset = (1 - curveValue) * 40;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧内容
          if (isLeft)
            Expanded(
              child: Transform.translate(
                offset: Offset(-slideOffset, 0),
                child: Opacity(
                  opacity: curveValue,
                  child: _buildContentCard(alignment: Alignment.centerRight),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox.shrink()),

          // 中心时间线
          _buildTimelineLine(),

          // 右侧内容
          if (!isLeft)
            Expanded(
              child: Transform.translate(
                offset: Offset(slideOffset, 0),
                child: Opacity(
                  opacity: curveValue,
                  child: _buildContentCard(alignment: Alignment.centerLeft),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildTimelineLine() {
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          // 节点圆点
          Transform.scale(
            scale: 0.5 + progress * 0.5,
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    item.color ?? MiuixColors.primaryLight,
                    item.color ?? MiuixColors.primary,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: (item.color ?? MiuixColors.primary)
                        .withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: item.icon != null
                  ? Icon(item.icon, size: 10, color: Colors.white)
                  : null,
            ),
          ),
          // 连接线
          if (!isLast)
            Expanded(
              child: Container(
                width: 2.5,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      item.color ?? MiuixColors.primary,
                      (item.color ?? MiuixColors.primary)
                          .withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentCard({required Alignment alignment}) {
    return Padding(
      padding: EdgeInsets.only(
        left: isLeft ? 0 : MiuixSpacing.sm,
        right: isLeft ? MiuixSpacing.sm : 0,
        bottom: MiuixSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment:
            isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            item.time,
            style: TextStyle(
              color: item.color ?? MiuixColors.primary,
              fontSize: MiuixFontSize.sm,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(MiuixSpacing.md),
            decoration: BoxDecoration(
              color: MiuixColors.surface,
              borderRadius: BorderRadius.circular(MiuixRadius.md),
              border: Border.all(color: MiuixColors.borderLight, width: 1),
              boxShadow: MiuixShadows.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: MiuixColors.textPrimary,
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: const TextStyle(
                      color: MiuixColors.textSecondary,
                      fontSize: MiuixFontSize.sm,
                    ),
                  ),
                ],
                if (item.content != null) ...[
                  const SizedBox(height: MiuixSpacing.sm),
                  item.content!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
