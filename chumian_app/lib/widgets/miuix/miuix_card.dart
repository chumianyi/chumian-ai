import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// MiuixCard —— 毛玻璃/半透明卡片
/// 悬浮上移动画，按压回弹，粉色柔和阴影
/// 可选渐变背景，圆角，onTap 回调带水晕
/// ============================================================

/// 卡片样式
enum MiuixCardStyle {
  /// 白色表面
  surface,

  /// 毛玻璃
  glass,

  /// 粉色渐变
  gradient,

  ///  outlined 描边
  outlined,
}

/// Miuix 风格卡片
///
/// 用法：
/// ```dart
/// MiuixCard(
///   onTap: () {},
///   child: Text('卡片内容'),
/// )
/// ```
class MiuixCard extends StatefulWidget {
  const MiuixCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.style = MiuixCardStyle.surface,
    this.padding = const EdgeInsets.all(MiuixSpacing.lg),
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.gradient,
    this.backgroundColor,
    this.elevation = 0,
    this.hoverElevation = 4,
    this.showRipple = true,
    this.borderColor,
  });

  /// 子组件
  final Widget child;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 样式
  final MiuixCardStyle style;

  /// 内边距
  final EdgeInsetsGeometry padding;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 圆角
  final double? borderRadius;

  /// 自定义渐变
  final Gradient? gradient;

  /// 背景色
  final Color? backgroundColor;

  /// 阴影高度
  final double elevation;

  /// 悬浮时阴影高度
  final double hoverElevation;

  /// 是否显示水晕
  final bool showRipple;

  /// 边框颜色
  final Color? borderColor;

  @override
  State<MiuixCard> createState() => _MiuixCardState();
}

class _MiuixCardState extends State<MiuixCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _liftAnimation;
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
        tween: Tween(begin: 1.0, end: 0.97),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.97, end: 1.0)
            .chain(CurveTween(curve: MiuixCurves.miuixSpring)),
        weight: 70,
      ),
    ]).animate(_controller);
    _liftAnimation = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  BoxDecoration _getDecoration() {
    final double radius = widget.borderRadius ?? MiuixRadius.lg;
    final double currentElevation =
        _isPressed ? widget.elevation : widget.hoverElevation;

    switch (widget.style) {
      case MiuixCardStyle.surface:
        return BoxDecoration(
          color: widget.backgroundColor ?? MiuixColors.surface,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: MiuixColors.primary.withOpacity(0.08),
              blurRadius: 12 + currentElevation * 2,
              offset: Offset(0, 2 + currentElevation),
            ),
          ],
        );
      case MiuixCardStyle.glass:
        return BoxDecoration(
          color: widget.backgroundColor ??
              Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: widget.borderColor ?? MiuixColors.glassBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: MiuixColors.primary.withOpacity(0.06),
              blurRadius: 16,
              offset: Offset(0, 2 + currentElevation),
            ),
          ],
        );
      case MiuixCardStyle.gradient:
        return BoxDecoration(
          gradient: widget.gradient ??
              LinearGradient(
                colors: [
                  MiuixColors.primaryLight.withOpacity(0.9),
                  MiuixColors.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: MiuixColors.primary.withOpacity(0.25),
              blurRadius: 16 + currentElevation * 2,
              offset: Offset(0, 4 + currentElevation),
            ),
          ],
        );
      case MiuixCardStyle.outlined:
        return BoxDecoration(
          color: widget.backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: widget.borderColor ?? MiuixColors.border,
            width: 1,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double radius = widget.borderRadius ?? MiuixRadius.lg;
    final bool interactive =
        widget.onTap != null || widget.onLongPress != null;

    Widget content = Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      decoration: _getDecoration(),
      child: widget.style == MiuixCardStyle.glass
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: widget.child,
              ),
            )
          : widget.child,
    );

    if (widget.showRipple && interactive) {
      content = MiuixRipple(
        borderRadius: BorderRadius.circular(radius),
        color: widget.style == MiuixCardStyle.gradient
            ? Colors.white.withOpacity(0.2)
            : MiuixColors.primary.withOpacity(0.1),
        child: content,
      );
    }

    if (interactive) {
      content = GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _liftAnimation.value),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: content,
        ),
      );
    }

    if (widget.margin != null) {
      content = Padding(padding: widget.margin!, child: content);
    }

    return content;
  }
}
