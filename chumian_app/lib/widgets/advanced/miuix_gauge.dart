import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixGauge —— Miuix 风格仪表盘
/// 支持半圆形/圆形仪表盘，指针弹簧动画，刻度绘制，粉色渐变，数值显示
/// ============================================================

/// 仪表盘样式
enum MiuixGaugeStyle {
  /// 半圆形仪表盘（180度）
  semicircle,

  /// 圆形仪表盘（270度）
  circular,
}

/// Miuix 风格仪表盘组件
///
/// 用法：
/// ```dart
/// MiuixGauge(
///   value: 75,
///   minValue: 0,
///   maxValue: 100,
///   style: MiuixGaugeStyle.semicircle,
/// )
/// ```
class MiuixGauge extends StatefulWidget {
  const MiuixGauge({
    super.key,
    required this.value,
    this.minValue = 0,
    this.maxValue = 100,
    this.style = MiuixGaugeStyle.semicircle,
    this.size = 200,
    this.title,
    this.unit = '',
    this.showTicks = true,
    this.showPointer = true,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.onValueChanged,
  });

  /// 当前值
  final double value;

  /// 最小值
  final double minValue;

  /// 最大值
  final double maxValue;

  /// 仪表盘样式
  final MiuixGaugeStyle style;

  /// 尺寸（直径）
  final double size;

  /// 标题
  final String? title;

  /// 单位
  final String unit;

  /// 是否显示刻度
  final bool showTicks;

  /// 是否显示指针
  final bool showPointer;

  /// 是否启用动画
  final bool animate;

  /// 动画时长
  final Duration animationDuration;

  /// 值变化回调（用于交互式仪表盘）
  final ValueChanged<double>? onValueChanged;

  @override
  State<MiuixGauge> createState() => _MiuixGaugeState();
}

class _MiuixGaugeState extends State<MiuixGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  double _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: MiuixCurves.miuixSpring,
    );
    _displayValue = widget.animate ? widget.minValue : widget.value;
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
    }
  }

  @override
  void didUpdateWidget(MiuixGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _currentValue {
    if (!widget.animate) return widget.value;
    return widget.minValue +
        (widget.value - widget.minValue) * _animation.value;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.style == MiuixGaugeStyle.semicircle
          ? widget.size / 2 + 40
          : widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _GaugePainter(
              value: _currentValue,
              minValue: widget.minValue,
              maxValue: widget.maxValue,
              style: widget.style,
              showTicks: widget.showTicks,
              showPointer: widget.showPointer,
              title: widget.title,
              unit: widget.unit,
            ),
          );
        },
      ),
    );
  }
}

/// 仪表盘绘制器
class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.style,
    required this.showTicks,
    required this.showPointer,
    this.title,
    this.unit = '',
  });

  final double value;
  final double minValue;
  final double maxValue;
  final MiuixGaugeStyle style;
  final bool showTicks;
  final bool showPointer;
  final String? title;
  final String unit;

  /// 起始角度（从左侧开始）
  double get _startAngle {
    switch (style) {
      case MiuixGaugeStyle.semicircle:
        return math.pi; // 180度
      case MiuixGaugeStyle.circular:
        return math.pi * 0.75; // 135度
    }
  }

  /// 扫描角度
  double get _sweepAngle {
    switch (style) {
      case MiuixGaugeStyle.semicircle:
        return math.pi; // 180度
      case MiuixGaugeStyle.circular:
        return math.pi * 1.5; // 270度
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.82;
    final normalized = ((value - minValue) / (maxValue - minValue))
        .clamp(0.0, 1.0);

    // 绘制背景弧
    _drawBackgroundArc(canvas, center, radius);

    // 绘制渐变进度弧
    _drawProgressArc(canvas, center, radius, normalized);

    // 绘制刻度
    if (showTicks) {
      _drawTicks(canvas, center, radius);
    }

    // 绘制指针
    if (showPointer) {
      _drawPointer(canvas, center, radius, normalized);
    }

    // 绘制中心数值
    _drawCenterValue(canvas, center, size);
  }

  void _drawBackgroundArc(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = MiuixColors.surfaceVariant
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepAngle,
      false,
      paint,
    );
  }

  void _drawProgressArc(
      Canvas canvas, Offset center, double radius, double normalized) {
    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: _startAngle,
        endAngle: _startAngle + _sweepAngle,
        colors: [
          MiuixColors.primaryLight,
          MiuixColors.primary,
          MiuixColors.primaryDeep,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(_startAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepAngle * normalized,
      false,
      paint,
    );

    // 进度末端光晕
    if (normalized > 0) {
      final endAngle = _startAngle + _sweepAngle * normalized;
      final endPoint = center +
          Offset(math.cos(endAngle) * radius, math.sin(endAngle) * radius);
      final glowPaint = Paint()
        ..color = MiuixColors.primary.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(endPoint, 10, glowPaint);
    }
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    const tickCount = 11;
    for (int i = 0; i <= tickCount; i++) {
      final angle = _startAngle + _sweepAngle * i / tickCount;
      final isMajor = i % 2 == 0;
      final innerRadius = radius - (isMajor ? 22 : 16);
      final outerRadius = radius - 8;

      final p1 = center +
          Offset(math.cos(angle) * innerRadius, math.sin(angle) * innerRadius);
      final p2 = center +
          Offset(math.cos(angle) * outerRadius, math.sin(angle) * outerRadius);

      final tickPaint = Paint()
        ..color = isMajor
            ? MiuixColors.textTertiary
            : MiuixColors.border
        ..strokeWidth = isMajor ? 2 : 1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, tickPaint);

      // 刻度数值
      if (isMajor) {
        final labelRadius = radius - 34;
        final labelPos = center +
            Offset(math.cos(angle) * labelRadius,
                math.sin(angle) * labelRadius);
        final labelValue =
            (minValue + (maxValue - minValue) * i / tickCount).toInt();
        final tp = TextPainter(
          text: TextSpan(
            text: '$labelValue',
            style: const TextStyle(
              color: MiuixColors.textTertiary,
              fontSize: MiuixFontSize.xs,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2),
        );
      }
    }
  }

  void _drawPointer(
      Canvas canvas, Offset center, double radius, double normalized) {
    final angle = _startAngle + _sweepAngle * normalized;
    final pointerLength = radius * 0.65;
    final pointerEnd = center +
        Offset(math.cos(angle) * pointerLength, math.sin(angle) * pointerLength);

    // 指针阴影
    final shadowPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(pointerEnd.dx, pointerEnd.dy);
    final shadowPaint = Paint()
      ..color = MiuixColors.primary.withValues(alpha: 0.3)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(shadowPath, shadowPaint);

    // 指针主体（三角形）
    final pointerWidth = 6.0;
    final perpAngle = angle + math.pi / 2;
    final baseLeft = center +
        Offset(math.cos(perpAngle) * pointerWidth,
            math.sin(perpAngle) * pointerWidth);
    final baseRight = center -
        Offset(math.cos(perpAngle) * pointerWidth,
            math.sin(perpAngle) * pointerWidth);

    final pointerPath = Path()
      ..moveTo(pointerEnd.dx, pointerEnd.dy)
      ..lineTo(baseLeft.dx, baseLeft.dy)
      ..lineTo(baseRight.dx, baseRight.dy)
      ..close();

    final pointerPaint = Paint()
      ..shader = LinearGradient(
        colors: [MiuixColors.primaryDeep, MiuixColors.primaryLight],
      ).createShader(Rect.fromPoints(center, pointerEnd));
    canvas.drawPath(pointerPath, pointerPaint);

    // 中心圆
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, centerPaint);

    final centerBorderPaint = Paint()
      ..color = MiuixColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 12, centerBorderPaint);

    final innerDotPaint = Paint()
      ..color = MiuixColors.primaryDeep
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, innerDotPaint);
  }

  void _drawCenterValue(Canvas canvas, Offset center, Size size) {
    final valueText = value.toStringAsFixed(value % 1 == 0 ? 0 : 1);

    final valueTp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: valueText,
            style: const TextStyle(
              color: MiuixColors.textPrimary,
              fontSize: MiuixFontSize.display,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (unit.isNotEmpty)
            TextSpan(
              text: ' $unit',
              style: const TextStyle(
                color: MiuixColors.textTertiary,
                fontSize: MiuixFontSize.md,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final valueY = style == MiuixGaugeStyle.semicircle
        ? center.dy - 10
        : center.dy + size.height * 0.18;
    valueTp.paint(
      canvas,
      Offset(center.dx - valueTp.width / 2, valueY - valueTp.height / 2),
    );

    if (title != null) {
      final titleTp = TextPainter(
        text: TextSpan(
          text: title,
          style: const TextStyle(
            color: MiuixColors.textSecondary,
            fontSize: MiuixFontSize.sm,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      titleTp.paint(
        canvas,
        Offset(
          center.dx - titleTp.width / 2,
          valueY + valueTp.height / 2 + 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value;
}
