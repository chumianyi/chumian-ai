import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixInput —— 扁平化单层边框输入框
/// 彻底消除内外双框，聚焦时粉色边框渐亮 + 柔和粉色光晕动画
/// 支持前缀/后缀图标、密码切换、错误状态、计数器、多行、搜索样式
/// ============================================================

/// 输入框类型
enum MiuixInputType {
  /// 普通文本
  text,

  /// 密码
  password,

  /// 邮箱
  email,

  /// 数字
  number,

  /// 搜索
  search,

  /// 多行
  multiline,
}

/// Miuix 风格输入框
///
/// 用法：
/// ```dart
/// MiuixInput(
///   hintText: '请输入用户名',
///   prefixIcon: Icons.person_outline,
///   controller: _controller,
/// )
/// ```
class MiuixInput extends StatefulWidget {
  const MiuixInput({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.type = MiuixInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.focusNode,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autoFocus = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.fillColor,
    this.borderRadius,
    this.height,
    this.contentPadding,
    this.showCounter = false,
    this.errorText,
    this.helperText,
    this.prefixText,
    this.suffixText,
    this.onClear,
    this.showClearButton = false,
    this.textAlign = TextAlign.start,
    this.textStyle,
    this.hintStyle,
    this.cursorColor,
  });

  /// 文本控制器
  final TextEditingController? controller;

  /// 占位文字
  final String? hintText;

  /// 标签文字
  final String? labelText;

  /// 输入类型
  final MiuixInputType type;

  /// 前缀图标
  final IconData? prefixIcon;

  /// 后缀图标
  final IconData? suffixIcon;

  /// 文本变化回调
  final ValueChanged<String>? onChanged;

  /// 提交回调
  final ValueChanged<String>? onSubmitted;

  /// 点击回调
  final VoidCallback? onTap;

  /// 验证器
  final FormFieldValidator<String>? validator;

  /// 焦点节点
  final FocusNode? focusNode;

  /// 最大长度
  final int? maxLength;

  /// 最大行数
  final int maxLines;

  /// 最小行数
  final int? minLines;

  /// 是否隐藏文字
  final bool obscureText;

  /// 是否启用
  final bool enabled;

  /// 是否只读
  final bool readOnly;

  /// 是否自动聚焦
  final bool autoFocus;

  /// 键盘类型
  final TextInputType? keyboardType;

  /// 键盘操作
  final TextInputAction? textInputAction;

  /// 输入格式化器
  final List<TextInputFormatter>? inputFormatters;

  /// 填充颜色
  final Color? fillColor;

  /// 圆角
  final double? borderRadius;

  /// 高度
  final double? height;

  /// 内容内边距
  final EdgeInsetsGeometry? contentPadding;

  /// 是否显示计数器
  final bool showCounter;

  /// 错误文字
  final String? errorText;

  /// 辅助文字
  final String? helperText;

  /// 前缀文字
  final String? prefixText;

  /// 后缀文字
  final String? suffixText;

  /// 清除回调
  final VoidCallback? onClear;

  /// 是否显示清除按钮
  final bool showClearButton;

  /// 文本对齐
  final TextAlign textAlign;

  /// 文本样式
  final TextStyle? textStyle;

  /// 占位文字样式
  final TextStyle? hintStyle;

  /// 光标颜色
  final Color? cursorColor;

  @override
  State<MiuixInput> createState() => _MiuixInputState();
}

class _MiuixInputState extends State<MiuixInput>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  bool _obscureText = false;
  bool _hasFocus = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();
    _obscureText = widget.obscureText || widget.type == MiuixInputType.password;

    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);

    // 光晕动画：聚焦时渐亮
    _glowController = AnimationController(
      vsync: this,
      duration: MiuixDuration.normal,
    );
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOutCubic,
    );

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChange);
    if (widget.focusNode == null) _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
    if (_hasFocus) {
      _glowController.forward();
    } else {
      _glowController.reverse();
    }
  }

  void _onTextChange() {
    final bool hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  /// 切换密码可见性
  void _toggleObscure() {
    setState(() => _obscureText = !_obscureText);
  }

  /// 清除文本
  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  /// 获取边框颜色
  Color _getBorderColor() {
    if (widget.errorText != null) return MiuixColors.error;
    if (_hasFocus) return MiuixColors.primary;
    return MiuixColors.border;
  }

  /// 获取边框宽度
  double _getBorderWidth() {
    if (_hasFocus || widget.errorText != null) return 1.5;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final double radius = widget.borderRadius ?? MiuixRadius.md;
    final bool isError = widget.errorText != null;
    final bool isSearch = widget.type == MiuixInputType.search;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标签
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: MiuixSpacing.sm),
            child: Text(
              widget.labelText!,
              style: TextStyle(
                color: MiuixColors.textSecondary,
                fontSize: MiuixFontSize.sm,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        // 输入框主体
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.fillColor ??
                    (widget.enabled
                        ? MiuixColors.surface
                        : MiuixColors.surfaceVariant),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: _getBorderColor(),
                  width: _getBorderWidth(),
                ),
                // 聚焦时粉色光晕
                boxShadow: _hasFocus && !isError
                    ? [
                        BoxShadow(
                          color: MiuixColors.primary
                              .withOpacity(0.15 * _glowAnimation.value),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : isError
                        ? [
                            BoxShadow(
                              color: MiuixColors.error.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
              ),
              child: child,
            );
          },
          child: Row(
            children: [
              // 前缀图标
              if (widget.prefixIcon != null || isSearch)
                Padding(
                  padding: const EdgeInsets.only(left: MiuixSpacing.md),
                  child: Icon(
                    isSearch ? Icons.search : widget.prefixIcon,
                    size: 20,
                    color: _hasFocus
                        ? MiuixColors.primary
                        : MiuixColors.textTertiary,
                  ),
                ),
              // 前缀文字
              if (widget.prefixText != null)
                Padding(
                  padding: const EdgeInsets.only(left: MiuixSpacing.sm),
                  child: Text(
                    widget.prefixText!,
                    style: TextStyle(
                      color: MiuixColors.textSecondary,
                      fontSize: MiuixFontSize.md,
                    ),
                  ),
                ),
              // 文本输入
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  obscureText: _obscureText,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  autofocus: widget.autoFocus,
                  maxLength: widget.maxLength,
                  maxLines: widget.type == MiuixInputType.multiline
                      ? null
                      : widget.maxLines,
                  minLines: widget.minLines,
                  keyboardType: widget.keyboardType ?? _getKeyboardType(),
                  textInputAction:
                      widget.textInputAction ?? TextInputAction.done,
                  inputFormatters: widget.inputFormatters,
                  textAlign: widget.textAlign,
                  cursorColor: widget.cursorColor ?? MiuixColors.primary,
                  cursorWidth: 2,
                  cursorRadius: const Radius.circular(2),
                  style: widget.textStyle ??
                      TextStyle(
                        color: MiuixColors.textPrimary,
                        fontSize: MiuixFontSize.md,
                      ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: widget.hintStyle ??
                        TextStyle(
                          color: MiuixColors.textTertiary,
                          fontSize: MiuixFontSize.md,
                        ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    contentPadding: widget.contentPadding ??
                        const EdgeInsets.symmetric(
                          horizontal: MiuixSpacing.md,
                          vertical: MiuixSpacing.md,
                        ),
                    counterText: widget.showCounter ? null : '',
                  ),
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  onTap: widget.onTap,
                ),
              ),
              // 清除按钮
              if (widget.showClearButton && _hasText && widget.enabled)
                GestureDetector(
                  onTap: _clearText,
                  child: Padding(
                    padding: const EdgeInsets.only(right: MiuixSpacing.sm),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: MiuixColors.textTertiary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: MiuixColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              // 密码切换
              if (widget.type == MiuixInputType.password)
                GestureDetector(
                  onTap: _toggleObscure,
                  child: Padding(
                    padding: const EdgeInsets.only(right: MiuixSpacing.md),
                    child: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: MiuixColors.textTertiary,
                    ),
                  ),
                ),
              // 后缀图标
              if (widget.suffixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: MiuixSpacing.md),
                  child: Icon(
                    widget.suffixIcon,
                    size: 20,
                    color: MiuixColors.textTertiary,
                  ),
                ),
              // 后缀文字
              if (widget.suffixText != null)
                Padding(
                  padding: const EdgeInsets.only(right: MiuixSpacing.md),
                  child: Text(
                    widget.suffixText!,
                    style: TextStyle(
                      color: MiuixColors.textSecondary,
                      fontSize: MiuixFontSize.md,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // 错误/辅助文字 + 计数器
        if (isError || widget.helperText != null || widget.showCounter)
          Padding(
            padding: const EdgeInsets.only(top: MiuixSpacing.xs, left: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isError)
                  Text(
                    widget.errorText!,
                    style: TextStyle(
                      color: MiuixColors.error,
                      fontSize: MiuixFontSize.xs,
                    ),
                  )
                else if (widget.helperText != null)
                  Text(
                    widget.helperText!,
                    style: TextStyle(
                      color: MiuixColors.textTertiary,
                      fontSize: MiuixFontSize.xs,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (widget.showCounter && widget.maxLength != null)
                  Text(
                    '${_controller.text.length}/${widget.maxLength}',
                    style: TextStyle(
                      color: MiuixColors.textTertiary,
                      fontSize: MiuixFontSize.xs,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case MiuixInputType.email:
        return TextInputType.emailAddress;
      case MiuixInputType.number:
        return TextInputType.number;
      case MiuixInputType.search:
        return TextInputType.text;
      case MiuixInputType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }
}
