import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// GradientButton —— 渐变按钮组件
///
/// 粉色渐变，按压缩放，水晕效果，加载态，图标+文字。
/// 用于主要操作按钮，如确认、提交、登录等。
/// ============================================================================
class GradientButton extends StatefulWidget {
  /// 按钮文字
  final String text;

  /// 左侧图标
  final IconData? icon;

  /// 右侧图标
  final IconData? trailingIcon;

  /// 点击回调
  final VoidCallback? onTap;

  /// 是否加载中
  final bool isLoading;

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

  /// 渐变色
  final List<Color>? gradientColors;

  /// 圆角
  final double borderRadius;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 加载指示器颜色
  final Color? loadingColor;

  const GradientButton({
    super.key,
    required this.text,
    this.icon,
    this.trailingIcon,
    this.onTap,
    this.isLoading = false,
    this.disabled = false,
    this.width,
    this.height = 48.0,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.w600,
    this.gradientColors,
    this.borderRadius = 24.0,
    this.padding,
    this.loadingColor,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isPressed = false;

  bool get _isEnabled => !widget.disabled && !widget.isLoading;

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
    final colors = widget.gradientColors ?? MiuixColors.primaryGradient;

    return Opacity(
      opacity: widget.disabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _isEnabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: _isEnabled
                  ? [
                      BoxShadow(
                        color: colors.first.withOpacity(0.4),
                        blurRadius: _isPressed ? 6 : 12,
                        offset: Offset(0, _isPressed ? 2 : 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                onTap: _isEnabled ? widget.onTap : null,
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Center(
                  child: widget.isLoading
                      ? _buildLoading()
                      : _buildContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.loadingColor ?? Colors.white,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: Colors.white, size: widget.fontSize + 2),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            letterSpacing: 0.5,
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon,
              color: Colors.white, size: widget.fontSize + 2),
        ],
      ],
    );
  }
}
