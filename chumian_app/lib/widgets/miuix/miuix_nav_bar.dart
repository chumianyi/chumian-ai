import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixNavBar —— 底部导航栏
/// 【核心动画】点击某项时：被点项先缩到 0.3 倍大小，然后快速弹性放大
/// (elasticOut) 到 1.15 再回弹到 1.0，同时页面内容缩放淡入
/// 未选中项灰色，选中项粉色渐变背景胶囊 + 白色图标 + 文字
/// 毛玻璃导航栏，粉色阴影
/// ============================================================

/// 底部导航项
class MiuixNavBarItem {
  const MiuixNavBarItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.badge,
  });

  /// 未选中图标
  final IconData icon;

  /// 选中图标
  final IconData? activeIcon;

  /// 文字
  final String label;

  /// 角标数量
  final int? badge;
}

/// Miuix 风格底部导航栏
///
/// 用法：
/// ```dart
/// MiuixNavBar(
///   items: [
///     MiuixNavBarItem(icon: Icons.home_outlined, label: '首页'),
///     MiuixNavBarItem(icon: Icons.explore_outlined, label: '发现'),
///     MiuixNavBarItem(icon: Icons.person_outlined, label: '我的'),
///   ],
///   currentIndex: _index,
///   onTap: (i) => setState(() => _index = i),
/// )
/// ```
class MiuixNavBar extends StatefulWidget {
  const MiuixNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.height = 68.0,
    this.backgroundColor,
    this.showLabels = true,
    this.elevation = true,
  });

  /// 导航项列表
  final List<MiuixNavBarItem> items;

  /// 当前索引
  final int currentIndex;

  /// 点击回调
  final ValueChanged<int> onTap;

  /// 高度
  final double height;

  /// 背景色
  final Color? backgroundColor;

  /// 是否显示文字
  final bool showLabels;

  /// 是否显示阴影
  final bool elevation;

  @override
  State<MiuixNavBar> createState() => _MiuixNavBarState();
}

class _MiuixNavBarState extends State<MiuixNavBar> {
  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: widget.height + bottomInset,
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: widget.backgroundColor ??
                MiuixColors.surface.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: MiuixColors.border.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            boxShadow: widget.elevation
                ? [
                    BoxShadow(
                      color: MiuixColors.primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(widget.items.length, (index) {
              return _NavBarItemWidget(
                item: widget.items[index],
                isSelected: index == widget.currentIndex,
                onTap: () => widget.onTap(index),
                showLabel: widget.showLabels,
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// 单个导航项 —— 包含核心弹性缩放动画
class _NavBarItemWidget extends StatefulWidget {
  const _NavBarItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.showLabel,
  });

  final MiuixNavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showLabel;

  @override
  State<_NavBarItemWidget> createState() => _NavBarItemWidgetState();
}

class _NavBarItemWidgetState extends State<_NavBarItemWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 核心动画：0.3 → 1.15 → 1.0 弹性回弹
    _scaleAnimation = TweenSequence<double>([
      // 第一阶段：快速缩到 0.3
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.3)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      // 第二阶段：弹性放大到 1.15 再回弹到 1.0
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 85,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _NavBarItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 从未选中变为选中时触发动画
    if (!oldWidget.isSelected && widget.isSelected) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isSelected ? _scaleAnimation.value : 1.0,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: MiuixDuration.normal,
          curve: MiuixCurves.miuixSpring,
          padding: EdgeInsets.symmetric(
            horizontal: widget.showLabel ? MiuixSpacing.md : MiuixSpacing.sm,
            vertical: MiuixSpacing.xs,
          ),
          decoration: BoxDecoration(
            // 选中项：粉色渐变胶囊
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: MiuixColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(MiuixRadius.pill),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: MiuixColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.isSelected && widget.item.activeIcon != null
                        ? widget.item.activeIcon
                        : widget.item.icon,
                    size: 24,
                    color: widget.isSelected
                        ? Colors.white
                        : MiuixColors.textTertiary,
                  ),
                  // 角标
                  if (widget.item.badge != null && widget.item.badge! > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        decoration: BoxDecoration(
                          color: MiuixColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.item.badge! > 99
                              ? '99+'
                              : '${widget.item.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              if (widget.showLabel) ...[
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: MiuixDuration.fast,
                  style: TextStyle(
                    color: widget.isSelected
                        ? Colors.white
                        : MiuixColors.textTertiary,
                    fontSize: MiuixFontSize.xs,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                  child: Text(widget.item.label),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// MiuixNavBarScaffold —— 带页面切换动画的导航脚手架
/// 页面内容缩放淡入切换
/// ============================================================

/// 带页面切换动画的导航脚手架
class MiuixNavBarScaffold extends StatefulWidget {
  const MiuixNavBarScaffold({
    super.key,
    required this.items,
    required this.pages,
    this.currentIndex = 0,
    this.onIndexChanged,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
    this.backgroundColor,
  });

  final List<MiuixNavBarItem> items;
  final List<Widget> pages;
  final int currentIndex;
  final ValueChanged<int>? onIndexChanged;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Color? backgroundColor;

  @override
  State<MiuixNavBarScaffold> createState() => _MiuixNavBarScaffoldState();
}

class _MiuixNavBarScaffoldState extends State<MiuixNavBarScaffold>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late final AnimationController _pageController;
  late final Animation<double> _pageScale;
  late final Animation<double> _pageFade;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _pageController = AnimationController(
      vsync: this,
      duration: MiuixDuration.normal,
    );
    _pageScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 100,
      ),
    ]).animate(_pageController);
    _pageFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOut),
    );
    _pageController.forward();
  }

  @override
  void didUpdateWidget(covariant MiuixNavBarScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _switchPage(widget.currentIndex);
    }
  }

  void _switchPage(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.forward(from: 0);
    widget.onIndexChanged?.call(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? MiuixColors.background,
      appBar: widget.appBar,
      drawer: widget.drawer,
      floatingActionButton: widget.floatingActionButton,
      body: AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          return Opacity(
            opacity: _pageFade.value,
            child: Transform.scale(
              scale: _pageScale.value,
              child: child,
            ),
          );
        },
        child: IndexedStack(
          index: _currentIndex,
          children: widget.pages,
        ),
      ),
      bottomNavigationBar: MiuixNavBar(
        items: widget.items,
        currentIndex: _currentIndex,
        onTap: _switchPage,
      ),
    );
  }
}
