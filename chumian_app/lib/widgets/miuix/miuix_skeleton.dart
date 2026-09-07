import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixSkeleton + MiuixShimmer —— 骨架屏
/// 粉色微光扫过动画，支持文本/卡片/列表/头像骨架
/// ============================================================

/// 骨架屏类型
enum MiuixSkeletonType {
  /// 文本行
  text,

  /// 圆形
  circle,

  /// 矩形
  rect,

  /// 圆角矩形
  rounded,

  /// 卡片
  card,

  /// 列表项
  listItem,

  /// 头像 + 文本
  avatarText,
}

/// Miuix 风格骨架屏
///
/// 用法：
/// ```dart
/// MiuixSkeleton(type: MiuixSkeletonType.listItem)
/// ```
class MiuixSkeleton extends StatelessWidget {
  const MiuixSkeleton({
    super.key,
    this.type = MiuixSkeletonType.rounded,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
    this.highlightColor,
    this.padding,
    this.lines = 3,
    this.lineHeight = 12.0,
    this.lineSpacing = 8.0,
    this.avatarSize = 48.0,
    this.showShimmer = true,
  });

  /// 骨架类型
  final MiuixSkeletonType type;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 圆角
  final double? borderRadius;

  /// 基础颜色
  final Color? color;

  /// 高光颜色
  final Color? highlightColor;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 文本行数
  final int lines;

  /// 行高
  final double lineHeight;

  /// 行间距
  final double lineSpacing;

  /// 头像大小
  final double avatarSize;

  /// 是否显示微光动画
  final bool showShimmer;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case MiuixSkeletonType.text:
        return _buildTextSkeleton();
      case MiuixSkeletonType.circle:
        return _buildCircleSkeleton();
      case MiuixSkeletonType.rect:
        return _buildRectSkeleton();
      case MiuixSkeletonType.rounded:
        return _buildRoundedSkeleton();
      case MiuixSkeletonType.card:
        return _buildCardSkeleton();
      case MiuixSkeletonType.listItem:
        return _buildListItemSkeleton();
      case MiuixSkeletonType.avatarText:
        return _buildAvatarTextSkeleton();
    }
  }

  Widget _shimmer(Widget child) {
    if (!showShimmer) return child;
    return MiuixShimmer(child: child);
  }

  Widget _buildBase({
    double? w,
    double? h,
    double? radius,
  }) {
    return _shimmer(
      Container(
        width: w ?? width,
        height: h ?? height,
        decoration: BoxDecoration(
          color: color ?? MiuixColors.surfaceVariant,
          borderRadius: BorderRadius.circular(
            radius ?? borderRadius ?? MiuixRadius.sm,
          ),
        ),
      ),
    );
  }

  Widget _buildTextSkeleton() {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lines, (index) {
          final bool isLast = index == lines - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : lineSpacing),
            child: _buildBase(
              w: isLast ? (width ?? 120) : (width ?? double.infinity),
              h: lineHeight,
              radius: lineHeight / 2,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCircleSkeleton() {
    return _shimmer(
      Container(
        width: width ?? avatarSize,
        height: height ?? avatarSize,
        decoration: BoxDecoration(
          color: color ?? MiuixColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildRectSkeleton() {
    return _buildBase(radius: 0);
  }

  Widget _buildRoundedSkeleton() {
    return _buildBase();
  }

  Widget _buildCardSkeleton() {
    return _shimmer(
      Container(
        width: width ?? double.infinity,
        height: height ?? 160,
        padding: padding ?? const EdgeInsets.all(MiuixSpacing.lg),
        decoration: BoxDecoration(
          color: color ?? MiuixColors.surface,
          borderRadius: BorderRadius.circular(
            borderRadius ?? MiuixRadius.lg,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBase(w: 120, h: 16, radius: 8),
            const SizedBox(height: MiuixSpacing.md),
            _buildBase(w: double.infinity, h: 12, radius: 6),
            const SizedBox(height: 6),
            _buildBase(w: double.infinity, h: 12, radius: 6),
            const SizedBox(height: 6),
            _buildBase(w: 150, h: 12, radius: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildListItemSkeleton() {
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: MiuixSpacing.lg,
            vertical: MiuixSpacing.md,
          ),
      child: Row(
        children: [
          _buildCircleSkeleton(),
          const SizedBox(width: MiuixSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBase(w: 120, h: 14, radius: 7),
                const SizedBox(height: 6),
                _buildBase(w: double.infinity, h: 12, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarTextSkeleton() {
    return Row(
      children: [
        _buildCircleSkeleton(),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(child: _buildTextSkeleton()),
      ],
    );
  }
}

/// ============================================================
/// MiuixShimmer —— 粉色微光扫过动画
/// ============================================================

/// 粉色微光动画
class MiuixShimmer extends StatefulWidget {
  const MiuixShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.direction = Axis.horizontal,
    this.period = const Duration(milliseconds: 1500),
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Axis direction;
  final Duration period;

  @override
  State<MiuixShimmer> createState() => _MiuixShimmerState();
}

class _MiuixShimmerState extends State<MiuixShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    )..repeat();
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
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            return LinearGradient(
              begin: widget.direction == Axis.horizontal
                  ? Alignment.centerLeft
                  : Alignment.topCenter,
              end: widget.direction == Axis.horizontal
                  ? Alignment.centerRight
                  : Alignment.bottomCenter,
              colors: [
                widget.baseColor ?? MiuixColors.surfaceVariant,
                widget.highlightColor ??
                    MiuixColors.primaryLight.withValues(alpha: 0.3),
                widget.baseColor ?? MiuixColors.surfaceVariant,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(rect);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// ============================================================
/// MiuixSkeletonList —— 骨架屏列表
/// ============================================================

/// 骨架屏列表
class MiuixSkeletonList extends StatelessWidget {
  const MiuixSkeletonList({
    super.key,
    this.count = 5,
    this.itemBuilder,
    this.physics,
    this.padding,
  });

  final int count;
  final Widget Function(int index)? itemBuilder;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: physics ?? const NeverScrollableScrollPhysics(),
      padding: padding ?? EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (context, index) {
        return itemBuilder?.call(index) ??
            const MiuixSkeleton(type: MiuixSkeletonType.listItem);
      },
    );
  }
}
