import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// MiuixChip / MiuixPill —— 胶囊标签
/// 粉色渐变选中态，未选中白底粉边，按压回弹，支持图标+文字，删除按钮
/// ============================================================

/// 胶囊标签样式
enum MiuixChipStyle {
  /// 普通：白底粉边
  normal,

  /// 选中：粉色渐变
  selected,

  /// 毛玻璃
  glass,
}

/// Miuix 风格胶囊标签
///
/// 用法：
/// ```dart
/// MiuixChip(
///   label: '标签',
///   onTap: () {},
///   isSelected: true,
/// )
/// ```
class MiuixChip extends StatefulWidget {
  const MiuixChip({
    super.key,
    required this.label,
    this.onTap,
    this.isSelected = false,
    this.icon,
    this.onDeleted,
    this.avatar,
    this.style = MiuixChipStyle.normal,
    this.padding,
    this.textStyle,
    this.height = 32.0,
    this.borderRadius,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.disabled = false,
  });

  /// 标签文字
  final String label;

  /// 点击回调
  final VoidCallback? onTap;

  /// 是否选中
  final bool isSelected;

  /// 前置图标
  final IconData? icon;

  /// 删除回调（非 null 时显示删除按钮）
  final VoidCallback? onDeleted;

  /// 前置头像 Widget
  final Widget? avatar;

  /// 样式
  final MiuixChipStyle style;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 文字样式
  final TextStyle? textStyle;

  /// 高度
  final double height;

  /// 圆角
  final double? borderRadius;

  /// 背景色
  final Color? backgroundColor;

  /// 选中背景色
  final Color? selectedBackgroundColor;

  /// 是否禁用
  final bool disabled;

  @override
  State<MiuixChip> createState() => _MiuixChipState();
}

class _MiuixChipState extends State<MiuixChip>
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
        tween: Tween(begin: 1.0, end: 0.92),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
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
    final double radius = widget.borderRadius ?? MiuixRadius.pill;
    final bool selected = widget.isSelected ||
        widget.style == MiuixChipStyle.selected;

    if (widget.style == MiuixChipStyle.glass) {
      return BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: MiuixColors.glassBorder),
      );
    }

    if (selected) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: widget.selectedBackgroundColor != null
              ? [widget.selectedBackgroundColor!, widget.selectedBackgroundColor!]
              : MiuixColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: MiuixColors.primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }

    return BoxDecoration(
      color: widget.backgroundColor ?? MiuixColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: MiuixColors.border, width: 1),
    );
  }

  Color _getTextColor() {
    if (widget.disabled) return MiuixColors.textTertiary;
    final bool selected = widget.isSelected ||
        widget.style == MiuixChipStyle.selected;
    return selected ? Colors.white : MiuixColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final double radius = widget.borderRadius ?? MiuixRadius.pill;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.disabled ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: MiuixRipple(
          borderRadius: BorderRadius.circular(radius),
          color: widget.isSelected
              ? Colors.white.withValues(alpha: 0.3)
              : MiuixColors.primary.withValues(alpha: 0.15),
          child: Opacity(
            opacity: widget.disabled ? 0.5 : 1.0,
            child: Container(
              height: widget.height,
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: MiuixSpacing.md),
              decoration: _getDecoration(),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.avatar != null) ...[
                    widget.avatar!,
                    const SizedBox(width: 6),
                  ],
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 14,
                      color: _getTextColor(),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    widget.label,
                    style: widget.textStyle ??
                        TextStyle(
                          color: _getTextColor(),
                          fontSize: MiuixFontSize.sm,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (widget.onDeleted != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onDeleted,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getTextColor().withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 10,
                          color: _getTextColor(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// MiuixPill —— 大胶囊按钮（Chip 的大号变体）
/// ============================================================

/// 大胶囊标签
class MiuixPill extends StatelessWidget {
  const MiuixPill({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.isSelected = false,
    this.height = 40.0,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    return MiuixChip(
      label: label,
      onTap: onTap,
      icon: icon,
      isSelected: isSelected,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.lg),
      textStyle: TextStyle(
        color: isSelected ? Colors.white : MiuixColors.primary,
        fontSize: MiuixFontSize.md,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
