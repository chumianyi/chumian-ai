import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// MiuixIconButton —— 圆形图标按钮
/// 粉色背景，按压缩放回弹 + 水晕
/// ============================================================

/// 图标按钮样式
enum MiuixIconButtonStyle {
  /// 实心粉色背景 + 白色图标
  filled,

  /// 白色背景 + 粉色边框 + 粉色图标
  outlined,

  /// 透明背景 + 粉色图标
  ghost,

  /// 毛玻璃背景
  glass,
}

/// Miuix 风格圆形图标按钮
///
/// 用法：
/// ```dart
/// MiuixIconButton(
///   icon: Icons.favorite,
///   onPressed: () {},
/// )
/// ```
class MiuixIconButton extends StatefulWidget {
  const MiuixIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.style = MiuixIconButtonStyle.filled,
    this.size = 44.0,
    this.iconSize,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.disabled = false,
    this.tooltip,
    this.padding,
    this.child,
  });

  /// 图标
  final IconData icon;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 样式，默认 filled
  final MiuixIconButtonStyle style;

  /// 按钮尺寸，默认 44
  final double size;

  /// 图标尺寸，默认 size * 0.5
  final double? iconSize;

  /// 图标颜色
  final Color? color;

  /// 背景颜色
  final Color? backgroundColor;

  /// 边框颜色
  final Color? borderColor;

  /// 是否禁用
  final bool disabled;

  /// 长按提示
  final String? tooltip;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 自定义子组件（覆盖 icon）
  final Widget? child;

  @override
  State<MiuixIconButton> createState() => _MiuixIconButtonState();
}

class _MiuixIconButtonState extends State<MiuixIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
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
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.disabled) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.disabled) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  BoxDecoration _getDecoration() {
    switch (widget.style) {
      case MiuixIconButtonStyle.filled:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: MiuixColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: widget.disabled
              ? null
              : [
                  BoxShadow(
                    color: MiuixColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        );
      case MiuixIconButtonStyle.outlined:
        return BoxDecoration(
          color: widget.backgroundColor ?? MiuixColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.borderColor ?? MiuixColors.primary,
            width: 1.5,
          ),
        );
      case MiuixIconButtonStyle.ghost:
        return BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        );
      case MiuixIconButtonStyle.glass:
        return BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: MiuixColors.glassBorder,
            width: 1,
          ),
        );
    }
  }

  Color _getIconColor() {
    if (widget.disabled) return MiuixColors.textTertiary;
    if (widget.color != null) return widget.color!;
    switch (widget.style) {
      case MiuixIconButtonStyle.filled:
        return Colors.white;
      case MiuixIconButtonStyle.outlined:
      case MiuixIconButtonStyle.ghost:
      case MiuixIconButtonStyle.glass:
        return MiuixColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double iconSz = widget.iconSize ?? widget.size * 0.5;

    Widget button = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.disabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: MiuixRipple(
          borderRadius: BorderRadius.circular(widget.size / 2),
          color: widget.style == MiuixIconButtonStyle.filled
              ? Colors.white.withOpacity(0.3)
              : MiuixColors.primary.withOpacity(0.2),
          child: Opacity(
            opacity: widget.disabled ? 0.5 : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              padding: widget.padding,
              decoration: _getDecoration(),
              alignment: Alignment.center,
              child: widget.child ??
                  Icon(widget.icon, size: iconSz, color: _getIconColor()),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip, child: button);
    }

    return button;
  }
}
