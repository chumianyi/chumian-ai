import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// BadgeIcon —— 带角标的图标组件
///
/// 数字角标、红点提示，粉色主题，入场动画。
/// 用于消息通知、购物车、功能入口等需要角标提示的场景。
/// ============================================================================
class BadgeIcon extends StatefulWidget {
  /// 图标
  final IconData icon;

  /// 图标大小
  final double iconSize;

  /// 图标颜色
  final Color? iconColor;

  /// 角标数字（0 表示不显示数字角标）
  final int badgeCount;

  /// 是否显示红点（无数字）
  final bool showDot;

  /// 角标最大显示数字（超过显示 "99+"）
  final int maxCount;

  /// 角标背景色
  final Color? badgeColor;

  /// 角标文字颜色
  final Color badgeTextColor;

  /// 点击回调
  final VoidCallback? onTap;

  /// 角标位置偏移
  final Offset badgeOffset;

  /// 是否显示动画
  final bool animate;

  const BadgeIcon({
    super.key,
    required this.icon,
    this.iconSize = 24.0,
    this.iconColor,
    this.badgeCount = 0,
    this.showDot = false,
    this.maxCount = 99,
    this.badgeColor,
    this.badgeTextColor = Colors.white,
    this.onTap,
    this.badgeOffset = const Offset(8, -8),
    this.animate = true,
  });

  @override
  State<BadgeIcon> createState() => _BadgeIconState();
}

class _BadgeIconState extends State<BadgeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  int? _previousCount;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _previousCount = widget.badgeCount;
  }

  @override
  void didUpdateWidget(covariant BadgeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.badgeCount != widget.badgeCount &&
        widget.badgeCount > oldWidget.badgeCount &&
        widget.animate) {
      _bounceController.forward(from: 0);
    }
    _previousCount = widget.badgeCount;
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  bool get _showBadge => widget.badgeCount > 0 || widget.showDot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 主图标
          Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.iconColor ?? MiuixColors.textSecondary,
            ),
          ),
          // 角标
          if (_showBadge)
            Positioned(
              right: widget.badgeOffset.dx,
              top: widget.badgeOffset.dy,
              child: _buildBadge(),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    final color = widget.badgeColor ?? MiuixColors.error;

    if (widget.showDot && widget.badgeCount == 0) {
      // 红点
      return _BadgeAnimation(
        controller: _bounceController,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
      );
    }

    // 数字角标
    final displayText = widget.badgeCount > widget.maxCount
        ? '${widget.maxCount}+'
        : '${widget.badgeCount}';
    final isSingleDigit = widget.badgeCount <= 9;
    final badgeWidth = isSingleDigit ? 18.0 : 22.0;

    return _BadgeAnimation(
      controller: _bounceController,
      child: Container(
        width: badgeWidth,
        height: 18,
        padding: EdgeInsets.symmetric(horizontal: isSingleDigit ? 0 : 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            displayText,
            style: TextStyle(
              color: widget.badgeTextColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// 角标弹跳动画
class _BadgeAnimation extends StatelessWidget {
  final AnimationController controller;
  final Widget child;

  const _BadgeAnimation({
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final curve = Curves.elasticOut.transform(controller.value);
        final scale = 0.5 + curve * 0.7;
        return Transform.scale(scale: scale, child: child);
      },
      child: child,
    );
  }
}

/// ============================================================================
/// BadgeContainer —— 通用角标容器（可包裹任意子组件）
/// ============================================================================
class BadgeContainer extends StatelessWidget {
  final Widget child;
  final int badgeCount;
  final bool showDot;
  final int maxCount;
  final Color? badgeColor;
  final Offset badgeOffset;
  final double badgeSize;

  const BadgeContainer({
    super.key,
    required this.child,
    this.badgeCount = 0,
    this.showDot = false,
    this.maxCount = 99,
    this.badgeColor,
    this.badgeOffset = const Offset(10, -6),
    this.badgeSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = badgeCount > 0 || showDot;
    final color = badgeColor ?? MiuixColors.error;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (showBadge)
          Positioned(
            right: badgeOffset.dx,
            top: badgeOffset.dy,
            child: showDot && badgeCount == 0
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  )
                : Container(
                    height: badgeSize,
                    constraints: BoxConstraints(minWidth: badgeSize),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(badgeSize / 2),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > maxCount ? '$maxCount+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}
