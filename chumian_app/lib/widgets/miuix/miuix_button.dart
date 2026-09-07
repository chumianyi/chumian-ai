import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// MiuixButton —— Miuix 风格按钮
/// 主按钮(粉渐变)、次按钮(白底粉边)、文字按钮、图标按钮、渐变按钮
/// 按压时弹簧式缩放回弹(scale 0.92→1.0)，粉色水晕涟漪
/// 连续曲率圆角，细腻阴影，加载状态，禁用状态
/// ============================================================

/// 按钮类型枚举
enum MiuixButtonType {
  /// 主按钮：粉色渐变背景 + 白色文字
  primary,

  /// 次按钮：白底 + 粉色边框 + 粉色文字
  secondary,

  /// 文字按钮：透明背景 + 粉色文字
  text,

  /// 渐变按钮：自定义粉色渐变
  gradient,

  /// 危险按钮：红色系
  danger,
}

/// 按钮尺寸
enum MiuixButtonSize {
  small,
  medium,
  large,
}

/// Miuix 风格按钮
///
/// 用法：
/// ```dart
/// MiuixButton(
///   label: '确认',
///   onPressed: () {},
///   type: MiuixButtonType.primary,
/// )
/// ```
class MiuixButton extends StatefulWidget {
  const MiuixButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = MiuixButtonType.primary,
    this.size = MiuixButtonSize.medium,
    this.icon,
    this.iconPosition = IconPosition.left,
    this.gradient,
    this.width,
    this.height,
    this.borderRadius,
    this.loading = false,
    this.disabled = false,
    this.padding,
    this.textStyle,
    this.leading,
    this.trailing,
  });

  /// 按钮文字
  final String label;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 按钮类型，默认 primary
  final MiuixButtonType type;

  /// 按钮尺寸，默认 medium
  final MiuixButtonSize size;

  /// 图标
  final IconData? icon;

  /// 图标位置
  final IconPosition iconPosition;

  /// 自定义渐变（仅 gradient 类型生效）
  final Gradient? gradient;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 圆角
  final double? borderRadius;

  /// 是否加载中
  final bool loading;

  /// 是否禁用
  final bool disabled;

  /// 自定义内边距
  final EdgeInsetsGeometry? padding;

  /// 自定义文字样式
  final TextStyle? textStyle;

  /// 前置自定义 Widget
  final Widget? leading;

  /// 后置自定义 Widget
  final Widget? trailing;

  @override
  State<MiuixButton> createState() => _MiuixButtonState();
}

enum IconPosition { left, right }

class _MiuixButtonState extends State<MiuixButton>
    with SingleTickerProviderStateMixin {
  /// 缩放动画控制器
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  /// 是否按下
  bool _isPressed = false;

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
        tween: Tween(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
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

  /// 处理按下
  void _onTapDown(TapDownDetails details) {
    if (_isDisabled) return;
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  /// 处理抬起
  void _onTapUp(TapUpDetails details) {
    if (_isDisabled) return;
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  /// 处理取消
  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  bool get _isDisabled => widget.disabled || widget.loading;

  /// 根据类型获取背景装饰
  BoxDecoration _getDecoration() {
    final double radius = widget.borderRadius ?? MiuixRadius.pill;
    switch (widget.type) {
      case MiuixButtonType.primary:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: MiuixColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: _isDisabled
              ? null
              : [
                  BoxShadow(
                    color: MiuixColors.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        );
      case MiuixButtonType.secondary:
        return BoxDecoration(
          color: MiuixColors.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: MiuixColors.primary, width: 1.5),
          boxShadow: _isDisabled ? null : MiuixShadows.xs,
        );
      case MiuixButtonType.text:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
        );
      case MiuixButtonType.gradient:
        return BoxDecoration(
          gradient: widget.gradient ??
              LinearGradient(
                colors: [
                  MiuixColors.primaryLight,
                  MiuixColors.primaryDeep,
                ],
              ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: _isDisabled
              ? null
              : [
                  BoxShadow(
                    color: MiuixColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        );
      case MiuixButtonType.danger:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              MiuixColors.error.withOpacity(0.9),
              MiuixColors.error,
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: _isDisabled
              ? null
              : [
                  BoxShadow(
                    color: MiuixColors.error.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        );
    }
  }

  /// 根据类型获取文字颜色
  Color _getTextColor() {
    if (_isDisabled) return MiuixColors.textTertiary;
    switch (widget.type) {
      case MiuixButtonType.primary:
      case MiuixButtonType.gradient:
      case MiuixButtonType.danger:
        return Colors.white;
      case MiuixButtonType.secondary:
      case MiuixButtonType.text:
        return MiuixColors.primary;
    }
  }

  /// 根据尺寸获取高度
  double _getHeight() {
    if (widget.height != null) return widget.height!;
    switch (widget.size) {
      case MiuixButtonSize.small:
        return 32;
      case MiuixButtonSize.medium:
        return 44;
      case MiuixButtonSize.large:
        return 52;
    }
  }

  /// 根据尺寸获取字体大小
  double _getFontSize() {
    switch (widget.size) {
      case MiuixButtonSize.small:
        return MiuixFontSize.sm;
      case MiuixButtonSize.medium:
        return MiuixFontSize.md;
      case MiuixButtonSize.large:
        return MiuixFontSize.lg;
    }
  }

  /// 根据尺寸获取水平内边距
  double _getHorizontalPadding() {
    switch (widget.size) {
      case MiuixButtonSize.small:
        return MiuixSpacing.md;
      case MiuixButtonSize.medium:
        return MiuixSpacing.xl;
      case MiuixButtonSize.large:
        return MiuixSpacing.xxl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = _getHeight();
    final double radius = widget.borderRadius ?? MiuixRadius.pill;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _isDisabled
          ? null
          : () {
              widget.onPressed?.call();
            },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: MiuixRipple(
          borderRadius: BorderRadius.circular(radius),
          color: widget.type == MiuixButtonType.primary ||
                  widget.type == MiuixButtonType.gradient ||
                  widget.type == MiuixButtonType.danger
              ? Colors.white.withOpacity(0.3)
              : MiuixColors.primary.withOpacity(0.2),
          child: Opacity(
            opacity: _isDisabled ? 0.5 : 1.0,
            child: Container(
              width: widget.width,
              height: height,
              padding: widget.padding ??
                  EdgeInsets.symmetric(horizontal: _getHorizontalPadding()),
              decoration: _getDecoration(),
              alignment: Alignment.center,
              child: widget.loading
                  ? SizedBox(
                      width: height * 0.45,
                      height: height * 0.45,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getTextColor(),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildChildren(),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建按钮内容（图标 + 文字）
  List<Widget> _buildChildren() {
    final List<Widget> children = [];
    final Color textColor = _getTextColor();
    final TextStyle style = widget.textStyle ??
        TextStyle(
          color: textColor,
          fontSize: _getFontSize(),
          fontWeight: FontWeight.w600,
        );

    final Widget textWidget = Text(
      widget.label,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final Widget? iconWidget = widget.icon != null
        ? Padding(
            padding: EdgeInsets.only(
              left: widget.iconPosition == IconPosition.left ? 0 : 6,
              right: widget.iconPosition == IconPosition.left ? 6 : 0,
            ),
            child: Icon(widget.icon, size: _getFontSize() + 2, color: textColor),
          )
        : null;

    if (widget.leading != null) {
      children.add(Padding(
        padding: const EdgeInsets.only(right: MiuixSpacing.sm),
        child: widget.leading,
      ));
    }

    if (widget.iconPosition == IconPosition.left && iconWidget != null) {
      children.add(iconWidget);
    }

    children.add(textWidget);

    if (widget.iconPosition == IconPosition.right && iconWidget != null) {
      children.add(iconWidget);
    }

    if (widget.trailing != null) {
      children.add(Padding(
        padding: const EdgeInsets.only(left: MiuixSpacing.sm),
        child: widget.trailing,
      ));
    }

    return children;
  }
}
