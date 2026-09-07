import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';

/// ============================================================
/// MiuixAppBar —— Miuix 风格导航栏
/// 毛玻璃/透明背景，粉色标题，大标题折叠动画
/// 支持左侧返回/右侧操作按钮，水晕反馈
/// ============================================================

/// Miuix 风格顶部导航栏
///
/// 用法：
/// ```dart
/// MiuixAppBar(
///   title: '首页',
///   actions: [
///     MiuixIconButton(icon: Icons.search, onPressed: () {}),
///   ],
/// )
/// ```
class MiuixAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MiuixAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.elevation = 0,
    this.showBackButton = true,
    this.onBack,
    this.centerTitle = true,
    this.height = 56.0,
    this.largeTitle,
    this.expandedHeight,
    this.flexibleSpace,
    this.pinned = true,
    this.floating = false,
    this.transparent = false,
  });

  /// 标题文字
  final String? title;

  /// 自定义标题 Widget
  final Widget? titleWidget;

  /// 左侧组件
  final Widget? leading;

  /// 右侧操作按钮
  final List<Widget>? actions;

  /// 背景色
  final Color? backgroundColor;

  /// 阴影高度
  final double elevation;

  /// 是否显示返回按钮
  final bool showBackButton;

  /// 返回回调
  final VoidCallback? onBack;

  /// 标题是否居中
  final bool centerTitle;

  /// 高度
  final double height;

  /// 大标题（用于折叠效果）
  final String? largeTitle;

  /// 展开高度
  final double? expandedHeight;

  /// 灵活空间
  final Widget? flexibleSpace;

  /// 是否固定
  final bool pinned;

  /// 是否浮动
  final bool floating;

  /// 是否透明背景
  final bool transparent;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height + topInset,
          padding: EdgeInsets.only(top: topInset),
          decoration: BoxDecoration(
            color: transparent
                ? Colors.transparent
                : (backgroundColor ??
                    MiuixColors.surface.withValues(alpha: 0.85)),
            border: elevation > 0
                ? Border(
                    bottom: BorderSide(
                      color: MiuixColors.border.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  )
                : null,
            boxShadow: elevation > 0
                ? [
                    BoxShadow(
                      color: MiuixColors.primary.withValues(alpha: 0.06),
                      blurRadius: elevation * 2,
                      offset: Offset(0, elevation),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // 左侧
              if (leading != null)
                Positioned(
                  left: MiuixSpacing.sm,
                  top: 0,
                  bottom: 0,
                  child: Center(child: leading),
                )
              else if (showBackButton && Navigator.of(context).canPop())
                Positioned(
                  left: MiuixSpacing.sm,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: MiuixIconButton(
                      icon: Icons.arrow_back_ios_new,
                      style: MiuixIconButtonStyle.ghost,
                      size: 36,
                      onPressed: () {
                        if (onBack != null) {
                          onBack!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),
              // 标题
              if (titleWidget != null)
                Positioned.fill(child: Center(child: titleWidget!))
              else if (title != null)
                Positioned.fill(
                  child: Center(
                    child: Text(
                      title!,
                      style: TextStyle(
                        color: MiuixColors.textPrimary,
                        fontSize: MiuixFontSize.xl,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              // 右侧操作
              if (actions != null)
                Positioned(
                  right: MiuixSpacing.sm,
                  top: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// MiuixLargeTitleAppBar —— 带大标题折叠动画的导航栏
/// 滚动时大标题缩小为小标题
/// ============================================================

/// 带大标题折叠动画的 Sliver 导航栏
class MiuixLargeTitleAppBar extends StatelessWidget {
  const MiuixLargeTitleAppBar({
    super.key,
    required this.title,
    this.largeTitle,
    this.actions,
    this.expandedHeight = 120,
    this.collapsedHeight = 56,
    this.backgroundColor,
    this.showBackButton = true,
    this.onBack,
  });

  final String title;
  final String? largeTitle;
  final List<Widget>? actions;
  final double expandedHeight;
  final double collapsedHeight;
  final Color? backgroundColor;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight + MediaQuery.of(context).padding.top,
      toolbarHeight: collapsedHeight,
      pinned: true,
      floating: false,
      backgroundColor: backgroundColor ?? MiuixColors.surface,
      foregroundColor: MiuixColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: showBackButton && Navigator.of(context).canPop()
          ? MiuixIconButton(
              icon: Icons.arrow_back_ios_new,
              style: MiuixIconButtonStyle.ghost,
              size: 36,
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double top = constraints.biggest.height;
          final double ratio = ((top - collapsedHeight -
                  MediaQuery.of(context).padding.top) /
              (expandedHeight - collapsedHeight))
              .clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(
              left: MiuixSpacing.lg,
              bottom: MiuixSpacing.md + (1 - ratio) * 4,
            ),
            title: AnimatedDefaultTextStyle(
              duration: MiuixDuration.fast,
              style: TextStyle(
                color: Color.lerp(
                  MiuixColors.primary,
                  MiuixColors.textPrimary,
                  1 - ratio,
                ),
                fontSize: MiuixFontSize.xxxl * ratio +
                    MiuixFontSize.lg * (1 - ratio),
                fontWeight: FontWeight.w800,
              ),
              child: Text(largeTitle ?? title),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    MiuixColors.primaryLight.withValues(alpha: 0.08),
                    MiuixColors.background,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
