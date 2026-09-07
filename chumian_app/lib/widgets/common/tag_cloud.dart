import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// TagCloud —— 标签云组件
///
/// 不同大小/颜色的标签，可点击，粉色系，动画入场，流式布局。
/// 用于热门标签、兴趣选择、搜索推荐等场景。
/// ============================================================================

/// 标签云数据项
class TagItem {
  /// 标签文字
  final String label;

  /// 权重（决定大小，1-5）
  final int weight;

  /// 自定义颜色
  final Color? color;

  /// 自定义背景色
  final Color? backgroundColor;

  /// 关联数据
  final dynamic data;

  const TagItem({
    required this.label,
    this.weight = 3,
    this.color,
    this.backgroundColor,
    this.data,
  });
}

class TagCloud extends StatefulWidget {
  /// 标签列表
  final List<TagItem> tags;

  /// 标签点击回调
  final ValueChanged<TagItem>? onTagTap;

  /// 标签长按回调
  final ValueChanged<TagItem>? onTagLongPress;

  /// 选中的标签（高亮显示）
  final Set<String> selectedTags;

  /// 是否可多选
  final bool multiSelect;

  /// 最大行数（null 表示不限制）
  final int? maxRows;

  /// 标签间距
  final double spacing;

  /// 行间距
  final double runSpacing;

  /// 入场动画延迟（每个标签递增）
  final Duration itemDelay;

  /// 内边距
  final EdgeInsetsGeometry padding;

  const TagCloud({
    super.key,
    required this.tags,
    this.onTagTap,
    this.onTagLongPress,
    this.selectedTags = const {},
    this.multiSelect = false,
    this.maxRows,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.itemDelay = const Duration(milliseconds: 40),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  State<TagCloud> createState() => _TagCloudState();
}

class _TagCloudState extends State<TagCloud> {
  /// 粉色系标签颜色池
  static final List<Color> _tagColors = [
    MiuixColors.primary,
    MiuixColors.primaryLight,
    MiuixColors.primaryDark,
    const Color(0xFFFF85A2),
    const Color(0xFFFF6B9D),
    const Color(0xFFE8558A),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Wrap(
        spacing: widget.spacing,
        runSpacing: widget.runSpacing,
        children: List.generate(widget.tags.length, (index) {
          return _buildTag(widget.tags[index], index);
        }),
      ),
    );
  }

  Widget _buildTag(TagItem tag, int index) {
    final isSelected = widget.selectedTags.contains(tag.label);
    final colorIndex = index % _tagColors.length;
    final baseColor = tag.color ?? _tagColors[colorIndex];
    final bgColor = tag.backgroundColor ??
        baseColor.withValues(alpha: isSelected ? 1.0 : 0.1);

    // 根据权重决定字体大小
    final fontSize = 12.0 + (tag.weight.clamp(1, 5) - 1) * 2.0;
    final horizontalPadding = 12.0 + (tag.weight.clamp(1, 5) - 1) * 2.0;
    final verticalPadding = 6.0 + (tag.weight.clamp(1, 5) - 1) * 1.0;

    return _TagAnimation(
      delay: widget.itemDelay * index,
      child: GestureDetector(
        onTap: () => widget.onTagTap?.call(tag),
        onLongPress: () => widget.onTagLongPress?.call(tag),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(MiuixRadius.pill),
            border: isSelected
                ? Border.all(color: baseColor, width: 1.5)
                : Border.all(color: baseColor.withValues(alpha: 0.3), width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(
                  Icons.check,
                  color: isSelected ? Colors.white : baseColor,
                  size: fontSize,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                tag.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : baseColor,
                  fontSize: fontSize,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 标签入场动画
class _TagAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _TagAnimation({
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<_TagAnimation> createState() => _TagAnimationState();
}

class _TagAnimationState extends State<_TagAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(curve);

    Future.delayed(widget.delay, () {
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
