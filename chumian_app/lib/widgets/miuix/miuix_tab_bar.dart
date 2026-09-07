import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixTabBar —— 粉色下划线 Tab
/// 滑动指示器，弹簧动画
/// ============================================================

/// Tab 项
class MiuixTabItem {
  const MiuixTabItem({
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;
}

/// Miuix 风格 Tab 栏
///
/// 用法：
/// ```dart
/// MiuixTabBar(
///   items: [
///     MiuixTabItem(label: '推荐'),
///     MiuixTabItem(label: '热门'),
///     MiuixTabItem(label: '关注'),
///   ],
///   controller: _tabController,
/// )
/// ```
class MiuixTabBar extends StatefulWidget {
  const MiuixTabBar({
    super.key,
    required this.items,
    this.controller,
    this.onTap,
    this.height = 44.0,
    this.indicatorHeight = 3.0,
    this.indicatorWidth,
    this.backgroundColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.isScrollable = false,
    this.padding,
    this.indicatorPadding = 0,
  });

  /// Tab 项
  final List<MiuixTabItem> items;

  /// Tab 控制器
  final TabController? controller;

  /// 点击回调
  final ValueChanged<int>? onTap;

  /// 高度
  final double height;

  /// 指示器高度
  final double indicatorHeight;

  /// 指示器宽度（null 时自适应文字宽度）
  final double? indicatorWidth;

  /// 背景色
  final Color? backgroundColor;

  /// 选中文字颜色
  final Color? labelColor;

  /// 未选中文字颜色
  final Color? unselectedLabelColor;

  /// 选中文字样式
  final TextStyle? labelStyle;

  /// 未选中文字样式
  final TextStyle? unselectedLabelStyle;

  /// 是否可滚动
  final bool isScrollable;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 指示器左右内边距
  final double indicatorPadding;

  @override
  State<MiuixTabBar> createState() => _MiuixTabBarState();
}

class _MiuixTabBarState extends State<MiuixTabBar>
    with SingleTickerProviderStateMixin {
  TabController? _internalController;
  TabController get _controller =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TabController(
        length: widget.items.length,
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      color: widget.backgroundColor ?? Colors.transparent,
      padding: widget.padding,
      child: widget.isScrollable
          ? ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.items.length,
              itemBuilder: (context, index) => _buildTabItem(index),
            )
          : Row(
              children: List.generate(
                widget.items.length,
                (index) => Expanded(child: _buildTabItem(index)),
              ),
            ),
    );
  }

  Widget _buildTabItem(int index) {
    final MiuixTabItem item = widget.items[index];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bool isSelected = _controller.index == index;
        // 计算指示器位置（用于滑动动画）
        final double animationValue = _controller.animation?.value ?? index.toDouble();
        final double indicatorProgress =
            (animationValue - index).abs() < 0.5 ? 1.0 : 0.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _controller.animateTo(index);
            widget.onTap?.call(index);
          },
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 图标 + 文字
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 16,
                        color: isSelected
                            ? (widget.labelColor ?? MiuixColors.primary)
                            : (widget.unselectedLabelColor ??
                                MiuixColors.textTertiary),
                      ),
                      const SizedBox(width: 4),
                    ],
                    AnimatedDefaultTextStyle(
                      duration: MiuixDuration.fast,
                      style: widget.labelStyle ??
                          TextStyle(
                            color: isSelected
                                ? (widget.labelColor ?? MiuixColors.primary)
                                : (widget.unselectedLabelColor ??
                                    MiuixColors.textTertiary),
                            fontSize: MiuixFontSize.md,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                      child: Text(item.label),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 粉色下划线指示器
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: MiuixCurves.miuixSpring,
                  width: isSelected
                      ? (widget.indicatorWidth ?? 24)
                      : 0,
                  height: widget.indicatorHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MiuixColors.primaryLight,
                        MiuixColors.primary,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(widget.indicatorHeight / 2),
                    boxShadow: [
                      BoxShadow(
                        color: MiuixColors.primary.withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ============================================================
/// MiuixTabBarView —— 配合 MiuixTabBar 使用的页面视图
/// ============================================================

/// Tab 页面视图
class MiuixTabBarView extends StatelessWidget {
  const MiuixTabBarView({
    super.key,
    required this.children,
    this.controller,
    this.physics,
  });

  final List<Widget> children;
  final TabController? controller;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: controller,
      physics: physics ?? const BouncingScrollPhysics(),
      children: children,
    );
  }
}
