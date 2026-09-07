import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixBounceIndicator —— Miuix 风格弹跳指示器
/// 页面指示器，当前页弹跳放大，粉色渐变，平滑滑动
/// 支持圆点/数字/进度条三种样式，带入场动画
/// ============================================================

/// 指示器样式
enum MiuixIndicatorStyle {
  /// 圆点
  dot,

  /// 数字（1/5）
  number,

  /// 进度条
  progress,
}

/// Miuix 风格弹跳指示器
///
/// 用法：
/// ```dart
/// MiuixBounceIndicator(
///   count: 5,
///   currentIndex: 2,
///   style: MiuixIndicatorStyle.dot,
/// )
/// ```
class MiuixBounceIndicator extends StatefulWidget {
  const MiuixBounceIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
    this.style = MiuixIndicatorStyle.dot,
    this.spacing = 8,
    this.dotSize = 10,
    this.activeSize = 28,
    this.activeColor,
    this.inactiveColor,
    this.onDotTap,
    this.showLabels = false,
    this.labels = const [],
    this.animateEntry = true,
  });

  /// 总页数
  final int count;

  /// 当前页索引
  final int currentIndex;

  /// 指示器样式
  final MiuixIndicatorStyle style;

  /// 点间距
  final double spacing;

  /// 普通点大小
  final double dotSize;

  /// 当前点宽度
  final double activeSize;

  /// 激活颜色
  final Color? activeColor;

  /// 未激活颜色
  final Color? inactiveColor;

  /// 点点击回调
  final ValueChanged<int>? onDotTap;

  /// 是否显示文字标签
  final bool showLabels;

  /// 标签列表
  final List<String> labels;

  /// 是否启用入场动画
  final bool animateEntry;

  @override
  State<MiuixBounceIndicator> createState() => _MiuixBounceIndicatorState();
}

class _MiuixBounceIndicatorState extends State<MiuixBounceIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _entryController;
  late final Animation<double> _entryAnimation;
  int _bounceIndex = -1;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: MiuixCurves.miuixSpring,
    );
    if (widget.animateEntry) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _entryController.forward());
    } else {
      _entryController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MiuixBounceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _triggerBounce(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _triggerBounce(int index) {
    setState(() => _bounceIndex = index);
    _bounceController.forward(from: 0).then((_) {
      if (mounted) setState(() => _bounceIndex = -1);
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case MiuixIndicatorStyle.dot:
        return _buildDotIndicator();
      case MiuixIndicatorStyle.number:
        return _buildNumberIndicator();
      case MiuixIndicatorStyle.progress:
        return _buildProgressIndicator();
    }
  }

  Widget _buildDotIndicator() {
    final activeColor = widget.activeColor ?? MiuixColors.primary;
    final inactiveColor = widget.inactiveColor ?? MiuixColors.border;

    return AnimatedBuilder(
      animation: Listenable.merge([_bounceController, _entryAnimation]),
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.count, (index) {
            final isActive = index == widget.currentIndex;
            final isBouncing = index == _bounceIndex;
            final bounceScale = isBouncing
                ? 1.0 + math.sin(_bounceController.value * math.pi) * 0.4
                : 1.0;
            final entryScale = 0.5 + _entryAnimation.value * 0.5;
            final entryDelay =
                (1 - index / widget.count * 0.5).clamp(0.0, 1.0);
            final finalScale = bounceScale *
                (index / widget.count < _entryAnimation.value
                    ? entryScale
                    : 0.0);

            return GestureDetector(
              onTap: () => widget.onDotTap?.call(index),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: MiuixDuration.normal,
                      curve: MiuixCurves.miuixSpring,
                      width: isActive ? widget.activeSize : widget.dotSize,
                      height: widget.dotSize,
                      transform: Matrix4.identity()..scale(finalScale),
                      transformAlignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [
                                  activeColor.withOpacity(0.8),
                                  activeColor,
                                ],
                              )
                            : null,
                        color: isActive ? null : inactiveColor,
                        borderRadius: BorderRadius.circular(widget.dotSize),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: activeColor.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (widget.showLabels &&
                        widget.labels.length > index) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.labels[index],
                        style: TextStyle(
                          color: isActive
                              ? activeColor
                              : MiuixColors.textTertiary,
                          fontSize: MiuixFontSize.xs,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildNumberIndicator() {
    final activeColor = widget.activeColor ?? MiuixColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MiuixSpacing.md,
        vertical: MiuixSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: BorderRadius.circular(MiuixRadius.pill),
        border: Border.all(color: activeColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: activeColor.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _bounceController,
        builder: (context, child) {
          final bounce = _bounceIndex == widget.currentIndex
              ? 1.0 + math.sin(_bounceController.value * math.pi) * 0.15
              : 1.0;
          return Transform.scale(
            scale: bounce,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${widget.currentIndex + 1}',
                    style: TextStyle(
                      color: activeColor,
                      fontSize: MiuixFontSize.lg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${widget.count}',
                    style: const TextStyle(
                      color: MiuixColors.textTertiary,
                      fontSize: MiuixFontSize.md,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final activeColor = widget.activeColor ?? MiuixColors.primary;
    final progress = (widget.currentIndex + 1) / widget.count;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MiuixRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: MiuixColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          ),
        ),
        const SizedBox(height: MiuixSpacing.sm),
        Text(
          '${widget.currentIndex + 1} / ${widget.count}',
          style: TextStyle(
            color: activeColor,
            fontSize: MiuixFontSize.sm,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// ============================================================
/// MiuixPageIndicator —— 带页面标题的横向指示器
/// 可用于引导页、介绍页等场景
/// ============================================================
class MiuixPageIndicator extends StatelessWidget {
  const MiuixPageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
    this.titles = const [],
    this.onPageSelected,
  });

  final int count;
  final int currentIndex;
  final List<String> titles;
  final ValueChanged<int>? onPageSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        final title = titles.length > index ? titles[index] : '';
        return GestureDetector(
          onTap: () => onPageSelected?.call(index),
          child: AnimatedContainer(
            duration: MiuixDuration.normal,
            curve: MiuixCurves.miuixSpring,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? MiuixSpacing.md : MiuixSpacing.sm,
              vertical: MiuixSpacing.xs,
            ),
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(colors: MiuixColors.primaryGradient)
                  : null,
              color: isActive ? null : MiuixColors.surfaceVariant,
              borderRadius: BorderRadius.circular(MiuixRadius.pill),
            ),
            child: Text(
              title.isEmpty ? '${index + 1}' : title,
              style: TextStyle(
                color: isActive ? Colors.white : MiuixColors.textSecondary,
                fontSize: MiuixFontSize.sm,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }),
    );
  }
}
