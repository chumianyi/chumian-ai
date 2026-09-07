import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// OutlineButton —— 描边按钮组件
///
/// 粉色边框，白底，按压缩放，水晕效果，图标+文字。
/// 用于次要操作按钮，如取消、返回、查看详情等。
/// ============================================================================
class OutlineButton extends StatefulWidget {
  /// 按钮文字
  final String text;

  /// 左侧图标
  final IconData? icon;

  /// 右侧图标
  final IconData? trailingIcon;

  /// 点击回调
  final VoidCallback? onTap;

  /// 是否禁用
  final bool disabled;

  /// 按钮宽度
  final double? width;

  /// 按钮高度
  final double height;

  /// 文字大小
  final double fontSize;

  /// 文字字重
  final FontWeight fontWeight;

  /// 边框颜色
  final Color? borderColor;

  /// 文字颜色
  final Color? textColor;

  /// 背景色
  final Color? backgroundColor;

  /// 边框宽度
  final double borderWidth;

  /// 圆角
  final double borderRadius;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  const OutlineButton({
    super.key,
    required this.text,
    this.icon,
    this.trailingIcon,
    this.onTap,
    this.disabled = false,
    this.width,
    this.height = 44.0,
    this.fontSize = 15.0,
    this.fontWeight = FontWeight.w500,
    this.borderColor,
    this.textColor,
    this.backgroundColor,
    this.borderWidth = 1.5,
    this.borderRadius = 22.0,
    this.padding,
  });

  @override
  State<OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<OutlineButton> {
  bool _isPressed = false;
  bool _isHovering = false;

  bool get _isEnabled => !widget.disabled;

  void _handleTapDown(TapDownDetails details) {
    if (_isEnabled) setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.borderColor ?? MiuixColors.primary;
    final text = widget.textColor ?? MiuixColors.primary;
    final bg = widget.backgroundColor ?? Colors.white;

    return Opacity(
      opacity: widget.disabled ? 0.5 : 1.0,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: _isEnabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _isEnabled ? widget.onTap : null,
          child: AnimatedScale(
            scale: _isPressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.width,
              height: widget.height,
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _isHovering && _isEnabled
                    ? border.withValues(alpha: 0.06)
                    : bg,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: _isHovering && _isEnabled
                      ? border.withValues(alpha: 0.8)
                      : border,
                  width: widget.borderWidth,
                ),
                boxShadow: _isPressed && _isEnabled
                    ? [
                        BoxShadow(
                          color: border.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  onTap: _isEnabled ? widget.onTap : null,
                  splashColor: border.withValues(alpha: 0.1),
                  highlightColor: border.withValues(alpha: 0.05),
                  child: Center(
                    child: _buildContent(text),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: textColor, size: widget.fontSize + 2),
          const SizedBox(width: 6),
        ],
        Text(
          widget.text,
          style: TextStyle(
            color: textColor,
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 6),
          Icon(widget.trailingIcon,
              color: textColor, size: widget.fontSize + 2),
        ],
      ],
    );
  }
}
