import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixSegmentControl —— 分段控制器
/// 粉色滑块在选项间滑动，弹簧动画
/// ============================================================

/// 分段选项
class MiuixSegmentItem {
  const MiuixSegmentItem({
    required this.label,
    this.icon,
    this.child,
  });

  final String label;
  final IconData? icon;
  final Widget? child;
}

/// Miuix 风格分段控制器
///
/// 用法：
/// ```dart
/// MiuixSegmentControl(
///   items: [
///     MiuixSegmentItem(label: '推荐'),
///     MiuixSegmentItem(label: '关注'),
///     MiuixSegmentItem(label: '热门'),
///   ],
///   selectedIndex: _index,
///   onChanged: (i) => setState(() => _index = i),
/// )
/// ```
class MiuixSegmentControl extends StatefulWidget {
  const MiuixSegmentControl({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 40.0,
    this.borderRadius,
    this.backgroundColor,
    this.activeColor,
    this.activeTextColor,
    this.inactiveTextColor,
    this.padding = 4.0,
    this.duration,
  });

  /// 选项列表
  final List<MiuixSegmentItem> items;

  /// 当前选中索引
  final int selectedIndex;

  /// 选中变化回调
  final ValueChanged<int> onChanged;

  /// 高度
  final double height;

  /// 圆角
  final double? borderRadius;

  /// 背景色
  final Color? backgroundColor;

  /// 激活滑块颜色
  final Color? activeColor;

  /// 激活文字颜色
  final Color? activeTextColor;

  /// 未激活文字颜色
  final Color? inactiveTextColor;

  /// 内边距
  final double padding;

  /// 动画时长
  final Duration? duration;

  @override
  State<MiuixSegmentControl> createState() => _MiuixSegmentControlState();
}

class _MiuixSegmentControlState extends State<MiuixSegmentControl> {
  @override
  Widget build(BuildContext context) {
    final double radius = widget.borderRadius ?? MiuixRadius.pill;

    return Container(
      height: widget.height,
      padding: EdgeInsets.all(widget.padding),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? MiuixColors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth =
              (constraints.maxWidth - widget.padding * 2) / widget.items.length;

          return Stack(
            children: [
              // 滑动的粉色滑块
              AnimatedPositioned(
                duration:
                    widget.duration ?? const Duration(milliseconds: 300),
                curve: MiuixCurves.miuixSpring,
                left: widget.selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.activeColor ?? MiuixColors.primaryLight,
                        widget.activeColor ?? MiuixColors.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(radius - widget.padding),
                    boxShadow: [
                      BoxShadow(
                        color: MiuixColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // 选项
              Row(
                children: List.generate(widget.items.length, (index) {
                  final bool isSelected = index == widget.selectedIndex;
                  final item = widget.items[index];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onChanged(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedDefaultTextStyle(
                        duration: MiuixDuration.fast,
                        style: TextStyle(
                          color: isSelected
                              ? (widget.activeTextColor ?? Colors.white)
                              : (widget.inactiveTextColor ??
                                  MiuixColors.textSecondary),
                          fontSize: MiuixFontSize.md,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: item.child ??
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (item.icon != null) ...[
                                    Icon(
                                      item.icon,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : MiuixColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(item.label),
                                ],
                              ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
