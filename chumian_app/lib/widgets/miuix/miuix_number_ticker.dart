import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixNumberTicker —— 数字滚动动画
/// 积分/计数变化时数字逐位滚动
/// ============================================================

/// Miuix 数字滚动动画
///
/// 用法：
/// ```dart
/// MiuixNumberTicker(value: 12345)
/// ```
class MiuixNumberTicker extends StatefulWidget {
  const MiuixNumberTicker({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
    this.thousandsSeparator = true,
    this.color,
    this.fontSize,
    this.fontWeight,
  });

  /// 当前数值
  final num value;

  /// 动画时长
  final Duration duration;

  /// 动画曲线
  final Curve curve;

  /// 文字样式
  final TextStyle? textStyle;

  /// 对齐方式
  final TextAlign textAlign;

  /// 前缀
  final String? prefix;

  /// 后缀
  final String? suffix;

  /// 小数位数
  final int decimalPlaces;

  /// 是否千分位分隔
  final bool thousandsSeparator;

  /// 颜色
  final Color? color;

  /// 字体大小
  final double? fontSize;

  /// 字重
  final FontWeight? fontWeight;

  @override
  State<MiuixNumberTicker> createState() => _MiuixNumberTickerState();
}

class _MiuixNumberTickerState extends State<MiuixNumberTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late num _oldValue;
  late num _newValue;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    _newValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didUpdateWidget(covariant MiuixNumberTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _newValue = widget.value;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 格式化数字
  String _formatNumber(num value) {
    String formatted;
    if (widget.decimalPlaces > 0) {
      formatted = value.toStringAsFixed(widget.decimalPlaces);
    } else {
      formatted = value.toInt().toString();
    }

    if (widget.thousandsSeparator) {
      final parts = formatted.split('.');
      final integerPart = parts[0];
      final buffer = StringBuffer();
      for (int i = 0; i < integerPart.length; i++) {
        if (i > 0 && (integerPart.length - i) % 3 == 0) {
          buffer.write(',');
        }
        buffer.write(integerPart[i]);
      }
      if (parts.length > 1) {
        buffer.write('.${parts[1]}');
      }
      formatted = buffer.toString();
    }

    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = widget.textStyle ??
        TextStyle(
          color: widget.color ?? MiuixColors.primary,
          fontSize: widget.fontSize ?? MiuixFontSize.xxxl,
          fontWeight: widget.fontWeight ?? FontWeight.w800,
        );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = widget.curve.transform(_controller.value);
        final num currentValue = _oldValue + (_newValue - _oldValue) * t;
        final String display = _formatNumber(currentValue);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.prefix != null)
              Text(widget.prefix!, style: style),
            Text(
              display,
              style: style,
              textAlign: widget.textAlign,
            ),
            if (widget.suffix != null)
              Text(widget.suffix!, style: style),
          ],
        );
      },
    );
  }
}

/// ============================================================
/// MiuixDigitTicker —— 单数字位滚动（逐位滚动效果）
/// ============================================================

/// 单个数字位滚动
class MiuixDigitTicker extends StatefulWidget {
  const MiuixDigitTicker({
    super.key,
    required this.digit,
    this.duration = const Duration(milliseconds: 400),
    this.textStyle,
  });

  final int digit;
  final Duration duration;
  final TextStyle? textStyle;

  @override
  State<MiuixDigitTicker> createState() => _MiuixDigitTickerState();
}

class _MiuixDigitTickerState extends State<MiuixDigitTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _oldDigit;

  @override
  void initState() {
    super.initState();
    _oldDigit = widget.digit;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didUpdateWidget(covariant MiuixDigitTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit != widget.digit) {
      _oldDigit = oldWidget.digit;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = widget.textStyle ??
        TextStyle(
          color: MiuixColors.primary,
          fontSize: MiuixFontSize.xxxl,
          fontWeight: FontWeight.w800,
        );

    return ClipRect(
      child: SizedBox(
        height: style.fontSize ?? 28,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double t = Curves.easeOutCubic.transform(_controller.value);
            final double offset = -t * (style.fontSize ?? 28);
            return Transform.translate(
              offset: Offset(0, offset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$_oldDigit', style: style),
                  Text('${widget.digit}', style: style),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
