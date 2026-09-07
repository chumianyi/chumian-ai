import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixFabMenu —— Miuix 风格浮动操作按钮菜单
/// 展开/收起扇形菜单，粉色渐变 FAB，子项弹簧入场，水晕
/// ============================================================

/// FAB 菜单项
class MiuixFabMenuItem {
  const MiuixFabMenuItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  /// 图标
  final IconData icon;

  /// 标签
  final String label;

  /// 点击回调
  final VoidCallback onPressed;

  /// 自定义颜色
  final Color? color;
}

/// Miuix 风格浮动操作按钮菜单
///
/// 用法：
/// ```dart
/// MiuixFabMenu(
///   items: [
///     MiuixFabMenuItem(icon: Icons.add, label: '新建', onPressed: () {}),
///     MiuixFabMenuItem(icon: Icons.share, label: '分享', onPressed: () {}),
///   ],
/// )
/// ```
class MiuixFabMenu extends StatefulWidget {
  const MiuixFabMenu({
    super.key,
    required this.items,
    this.mainIcon = Icons.add,
    this.closeIcon = Icons.close,
    this.fabSize = 56,
    this.itemSize = 48,
    this.spreadAngle = 90,
    this.spreadRadius = 120,
  });

  /// 菜单项
  final List<MiuixFabMenuItem> items;

  /// 主按钮图标
  final IconData mainIcon;

  /// 关闭图标
  final IconData closeIcon;

  /// 主按钮大小
  final double fabSize;

  /// 子项大小
  final double itemSize;

  /// 扇形展开角度（度）
  final double spreadAngle;

  /// 展开半径
  final double spreadRadius;

  @override
  State<MiuixFabMenu> createState() => _MiuixFabMenuState();
}

class _MiuixFabMenuState extends State<MiuixFabMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MiuixDuration.elastic,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: MiuixCurves.miuixSpring,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.spreadRadius * 2 + widget.fabSize,
      height: widget.spreadRadius * 2 + widget.fabSize,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // 背景遮罩
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggle,
                child: AnimatedOpacity(
                  opacity: _isOpen ? 0.3 : 0,
                  duration: MiuixDuration.fast,
                  child: Container(color: Colors.black),
                ),
              ),
            ),
          // 子菜单项
          ..._buildMenuItems(),
          // 主按钮
          _buildMainButton(),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    final items = <Widget>[];
    final startAngle = -math.pi / 2 -
        (widget.spreadAngle * math.pi / 180) / 2;
    final angleStep = widget.items.length > 1
        ? (widget.spreadAngle * math.pi / 180) / (widget.items.length - 1)
        : 0;

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final angle = startAngle + angleStep * i;
      final delay = i * 0.08;
      final itemAnimation = CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, 1.0, curve: MiuixCurves.miuixSpring),
      );

      items.add(
        AnimatedBuilder(
          animation: itemAnimation,
          builder: (context, child) {
            final progress = itemAnimation.value;
            final dx = math.cos(angle) * widget.spreadRadius * progress;
            final dy = math.sin(angle) * widget.spreadRadius * progress;

            return Positioned(
              bottom: widget.fabSize / 2 - widget.itemSize / 2 + dy,
              right: widget.fabSize / 2 - widget.itemSize / 2 + dx,
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.5 + progress * 0.5,
                  child: child,
                ),
              ),
            );
          },
          child: _buildMenuItem(item),
        ),
      );
    }
    return items;
  }

  Widget _buildMenuItem(MiuixFabMenuItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.label.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MiuixSpacing.sm,
              vertical: MiuixSpacing.xs,
            ),
            margin: const EdgeInsets.only(right: MiuixSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MiuixRadius.sm),
              boxShadow: MiuixShadows.xs,
            ),
            child: Text(
              item.label,
              style: const TextStyle(
                color: MiuixColors.textPrimary,
                fontSize: MiuixFontSize.sm,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        GestureDetector(
          onTap: () {
            item.onPressed();
            _toggle();
          },
          child: Container(
            width: widget.itemSize,
            height: widget.itemSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item.color ?? MiuixColors.primaryLight,
                  item.color ?? MiuixColors.primary,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (item.color ?? MiuixColors.primary)
                      .withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(item.icon, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton() {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animation.value * math.pi / 4,
            child: child,
          );
        },
        child: Container(
          width: widget.fabSize,
          height: widget.fabSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: MiuixColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: MiuixColors.primary.withOpacity(0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            _isOpen ? widget.closeIcon : widget.mainIcon,
            color: Colors.white,
            size: widget.fabSize * 0.45,
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// MiuixFAB —— 单个浮动操作按钮
/// 粉色渐变，按压缩放，水晕效果
/// ============================================================
class MiuixFAB extends StatefulWidget {
  const MiuixFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.heroTag,
    this.mini = false,
    this.gradient,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final Object? heroTag;
  final bool mini;
  final Gradient? gradient;

  @override
  State<MiuixFAB> createState() => _MiuixFABState();
}

class _MiuixFABState extends State<MiuixFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: MiuixDuration.fast,
      reverseDuration: MiuixDuration.elastic,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.0)
            .chain(CurveTween(curve: MiuixCurves.miuixSpring)),
        weight: 70,
      ),
    ]).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.mini ? 40.0 : 56.0;
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.heroTag != null
            ? Hero(
                tag: widget.heroTag!,
                child: _buildFAB(size),
              )
            : _buildFAB(size),
      ),
    );
  }

  Widget _buildFAB(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: widget.gradient ??
            const LinearGradient(
              colors: MiuixColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: MiuixColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        widget.icon,
        color: Colors.white,
        size: size * 0.45,
      ),
    );
  }
}

/// ============================================================
/// MiuixFABExtended —— 扩展型 FAB
/// 带文字标签的浮动按钮
/// ============================================================
class MiuixFABExtended extends StatelessWidget {
  const MiuixFABExtended({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: MiuixColors.primary,
    );
  }
}
