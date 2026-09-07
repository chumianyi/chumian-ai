import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixChart —— Miuix 风格图表组件
/// 支持：折线图(渐变填充+动画绘制)、柱状图(弹簧入场)、饼图(旋转动画)、环形进度图
/// 全部使用 CustomPainter 手绘，粉色系，支持数据点标签、交互动画
/// ============================================================

/// 图表类型枚举
enum MiuixChartType {
  /// 折线图
  line,

  /// 柱状图
  bar,

  /// 饼图
  pie,

  /// 环形进度图
  ring,
}

/// 单个数据点
class MiuixChartData {
  const MiuixChartData({
    required this.label,
    required this.value,
    this.color,
  });

  /// 数据标签
  final String label;

  /// 数据值
  final double value;

  /// 自定义颜色（饼图/柱状图可用）
  final Color? color;
}

/// Miuix 风格图表组件
///
/// 用法：
/// ```dart
/// MiuixChart(
///   type: MiuixChartType.line,
///   data: [MiuixChartData(label: '周一', value: 30), ...],
///   height: 200,
/// )
/// ```
class MiuixChart extends StatefulWidget {
  const MiuixChart({
    super.key,
    required this.type,
    required this.data,
    this.height = 200,
    this.width,
    this.title,
    this.showLabels = true,
    this.showValues = true,
    this.animate = true,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
    this.onDataTap,
  });

  /// 图表类型
  final MiuixChartType type;

  /// 数据列表
  final List<MiuixChartData> data;

  /// 图表高度
  final double height;

  /// 图表宽度（默认撑满父容器）
  final double? width;

  /// 图表标题
  final String? title;

  /// 是否显示标签
  final bool showLabels;

  /// 是否显示数值
  final bool showValues;

  /// 是否启用入场动画
  final bool animate;

  /// 背景色
  final Color? backgroundColor;

  /// 内边距
  final EdgeInsets padding;

  /// 数据点点击回调
  final void Function(MiuixChartData data, int index)? onDataTap;

  @override
  State<MiuixChart> createState() => _MiuixChartState();
}

class _MiuixChartState extends State<MiuixChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: MiuixCurves.miuixSpring,
    );
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MiuixChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? MiuixColors.surface,
        borderRadius: BorderRadius.circular(MiuixRadius.lg),
        boxShadow: MiuixShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: const TextStyle(
                color: MiuixColors.textPrimary,
                fontSize: MiuixFontSize.lg,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: MiuixSpacing.sm),
          ],
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return GestureDetector(
                  onTapDown: (details) => _handleTap(details.localPosition),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _buildPainter(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  CustomPainter _buildPainter() {
    switch (widget.type) {
      case MiuixChartType.line:
        return _LineChartPainter(
          data: widget.data,
          animation: _animation.value,
          showLabels: widget.showLabels,
          showValues: widget.showValues,
          touchedIndex: _touchedIndex,
        );
      case MiuixChartType.bar:
        return _BarChartPainter(
          data: widget.data,
          animation: _animation.value,
          showLabels: widget.showLabels,
          showValues: widget.showValues,
          touchedIndex: _touchedIndex,
        );
      case MiuixChartType.pie:
        return _PieChartPainter(
          data: widget.data,
          animation: _animation.value,
          showLabels: widget.showLabels,
          showValues: widget.showValues,
          touchedIndex: _touchedIndex,
        );
      case MiuixChartType.ring:
        return _RingChartPainter(
          data: widget.data,
          animation: _animation.value,
          showLabels: widget.showLabels,
          showValues: widget.showValues,
        );
    }
  }

  void _handleTap(Offset position) {
    // 简化的点击检测：根据类型粗略定位
    final count = widget.data.length;
    if (count == 0) return;
    // 这里只做简单的索引估算，实际项目中可结合 painter 的坐标映射
    int index = 0;
    switch (widget.type) {
      case MiuixChartType.line:
      case MiuixChartType.bar:
        index = (position.dx / (context.size?.width ?? 1) * count).floor();
        break;
      case MiuixChartType.pie:
      case MiuixChartType.ring:
        index = 0;
        break;
    }
    index = index.clamp(0, count - 1);
    setState(() => _touchedIndex = index);
    widget.onDataTap?.call(widget.data[index], index);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _touchedIndex = null);
    });
  }
}

// ============================================================
// 折线图绘制器
// ============================================================
class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.animation,
    required this.showLabels,
    required this.showValues,
    this.touchedIndex,
  });

  final List<MiuixChartData> data;
  final double animation;
  final bool showLabels;
  final bool showValues;
  final int? touchedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.map((e) => e.value).reduce(math.max);
    final minValue = data.map((e) => e.value).reduce(math.min);
    final range = (maxValue - minValue).abs() < 0.01 ? 1.0 : maxValue - minValue;

    final chartRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height - (showLabels ? 24 : 0),
    );

    // 绘制网格线
    _drawGrid(canvas, chartRect);

    // 计算数据点坐标
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = chartRect.left +
          (chartRect.width / (data.length > 1 ? data.length - 1 : 1)) * i;
      final normalized = (data[i].value - minValue) / range;
      final y = chartRect.bottom - normalized * chartRect.height * 0.85 -
          chartRect.height * 0.075;
      points.add(Offset(x, y));
    }

    // 绘制渐变填充区域
    if (points.length > 1) {
      final fillPath = Path()..moveTo(points.first.dx, chartRect.bottom);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(points.last.dx, chartRect.bottom);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MiuixColors.primary.withValues(alpha: 0.35 * animation),
            MiuixColors.primary.withValues(alpha: 0.02),
          ],
        ).createShader(chartRect);
      canvas.drawPath(fillPath, fillPaint);
    }

    // 绘制折线（贝塞尔平滑）
    if (points.length > 1) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final midX = (p0.dx + p1.dx) / 2;
        linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      }

      final linePaint = Paint()
        ..color = MiuixColors.primary
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // 动画：路径长度裁剪
      final pathMetrics = linePath.computeMetrics().toList();
      if (pathMetrics.isNotEmpty) {
        final totalLength =
            pathMetrics.fold<double>(0, (sum, m) => sum + m.length);
        final extractPath = Path();
        double extracted = 0;
        for (final metric in pathMetrics) {
          final needed = (totalLength * animation - extracted).clamp(0.0, metric.length);
          extractPath.addPath(metric.extractPath(0, needed), Offset.zero);
          extracted += metric.length;
          if (extracted >= totalLength * animation) break;
        }
        canvas.drawPath(extractPath, linePaint);
      }
    }

    // 绘制数据点
    for (int i = 0; i < points.length; i++) {
      final isTouched = touchedIndex == i;
      final pointProgress =
          ((i / data.length) <= animation ? 1.0 : 0.0).clamp(0.0, 1.0);
      final radius = (isTouched ? 7.0 : 4.5) * pointProgress;

      // 外圈光晕
      final glowPaint = Paint()
        ..color = MiuixColors.primary.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], radius + 4, glowPaint);

      // 数据点
      final pointPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], radius, pointPaint);

      final borderPaint = Paint()
        ..color = MiuixColors.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(points[i], radius, borderPaint);

      // 数值标签
      if (showValues && pointProgress > 0.5) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: data[i].value.toStringAsFixed(0),
            style: TextStyle(
              color: isTouched
                  ? MiuixColors.primaryDeep
                  : MiuixColors.textSecondary,
              fontSize: MiuixFontSize.xs,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(
            points[i].dx - textPainter.width / 2,
            points[i].dy - textPainter.height - 10,
          ),
        );
      }
    }

    // 绘制底部标签
    if (showLabels) {
      for (int i = 0; i < data.length; i++) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: data[i].label,
            style: const TextStyle(
              color: MiuixColors.textTertiary,
              fontSize: MiuixFontSize.xs,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        labelPainter.paint(
          canvas,
          Offset(
            points[i].dx - labelPainter.width / 2,
            size.height - 20,
          ),
        );
      }
    }
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final gridPaint = Paint()
      ..color = MiuixColors.divider
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = rect.top + rect.height * i / 4;
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.touchedIndex != touchedIndex;
}

// ============================================================
// 柱状图绘制器
// ============================================================
class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.data,
    required this.animation,
    required this.showLabels,
    required this.showValues,
    this.touchedIndex,
  });

  final List<MiuixChartData> data;
  final double animation;
  final bool showLabels;
  final bool showValues;
  final int? touchedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.map((e) => e.value).reduce(math.max);
    final chartRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height - (showLabels ? 24 : 0),
    );

    _drawGrid(canvas, chartRect);

    final barWidth = chartRect.width / data.length * 0.55;
    final gap = chartRect.width / data.length;

    for (int i = 0; i < data.length; i++) {
      // 弹簧入场：每个柱子延迟出现
      final delay = i / data.length * 0.3;
      final barAnim =
          ((animation - delay) / (1 - delay)).clamp(0.0, 1.0);
      final springValue = _spring(barAnim);

      final barHeight = (data[i].value / maxValue) *
          chartRect.height *
          0.85 *
          springValue;
      final x = chartRect.left + gap * i + (gap - barWidth) / 2;
      final y = chartRect.bottom - barHeight;
      final isTouched = touchedIndex == i;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(MiuixRadius.sm),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isTouched
              ? [MiuixColors.primaryDeep, MiuixColors.primary]
              : [MiuixColors.primaryLight, MiuixColors.primary],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));
      canvas.drawRRect(barRect, barPaint);

      // 顶部高光
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 2, y + 2, barWidth - 4, 4),
          const Radius.circular(2),
        ),
        highlightPaint,
      );

      // 数值
      if (showValues && springValue > 0.3) {
        final tp = TextPainter(
          text: TextSpan(
            text: data[i].value.toStringAsFixed(0),
            style: TextStyle(
              color: isTouched
                  ? MiuixColors.primaryDeep
                  : MiuixColors.textSecondary,
              fontSize: MiuixFontSize.xs,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + barWidth / 2 - tp.width / 2, y - 16));
      }

      // 标签
      if (showLabels) {
        final lp = TextPainter(
          text: TextSpan(
            text: data[i].label,
            style: const TextStyle(
              color: MiuixColors.textTertiary,
              fontSize: MiuixFontSize.xs,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        lp.paint(
          canvas,
          Offset(x + barWidth / 2 - lp.width / 2, size.height - 20),
        );
      }
    }
  }

  double _spring(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    const overshoot = 1.12;
    final s = 1.0 - overshoot;
    return 1.0 + s * (1 - (1 - t) * (1 - t));
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final gridPaint = Paint()
      ..color = MiuixColors.divider
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = rect.top + rect.height * i / 4;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.touchedIndex != touchedIndex;
}

// ============================================================
// 饼图绘制器
// ============================================================
class _PieChartPainter extends CustomPainter {
  _PieChartPainter({
    required this.data,
    required this.animation,
    required this.showLabels,
    required this.showValues,
    this.touchedIndex,
  });

  final List<MiuixChartData> data;
  final double animation;
  final bool showLabels;
  final bool showValues;
  final int? touchedIndex;

  static const List<Color> _palette = [
    MiuixColors.primary,
    MiuixColors.primaryLight,
    MiuixColors.primaryDeep,
    Color(0xFFFF9EBB),
    Color(0xFFFFB3CC),
    Color(0xFFE878A0),
    Color(0xFFFFC8DD),
    Color(0xFFD46088),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final total = data.fold<double>(0, (sum, e) => sum + e.value);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.7;
    final startAngle = -math.pi / 2;

    double currentAngle = startAngle;
    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * math.pi * animation;
      final isTouched = touchedIndex == i;
      final offset = isTouched ? 8.0 : 0.0;
      final midAngle = currentAngle + sweepAngle / 2;
      final sliceCenter = center +
          Offset(math.cos(midAngle) * offset, math.sin(midAngle) * offset);

      final paint = Paint()
        ..color = data[i].color ?? _palette[i % _palette.length]
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(sliceCenter.dx, sliceCenter.dy)
        ..arcTo(
          Rect.fromCircle(center: sliceCenter, radius: radius),
          currentAngle,
          sweepAngle,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);

      // 扇区间隔白线
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, borderPaint);

      // 标签
      if (showLabels && animation > 0.8) {
        final labelRadius = radius * 0.65;
        final labelPos = sliceCenter +
            Offset(
              math.cos(midAngle) * labelRadius,
              math.sin(midAngle) * labelRadius,
            );
        final percentage = (data[i].value / total * 100).toStringAsFixed(0);
        final tp = TextPainter(
          text: TextSpan(
            text: showValues ? '$percentage%' : data[i].label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: MiuixFontSize.sm,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2),
        );
      }

      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.touchedIndex != touchedIndex;
}

// ============================================================
// 环形进度图绘制器
// ============================================================
class _RingChartPainter extends CustomPainter {
  _RingChartPainter({
    required this.data,
    required this.animation,
    required this.showLabels,
    required this.showValues,
  });

  final List<MiuixChartData> data;
  final double animation;
  final bool showLabels;
  final bool showValues;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final total = data.fold<double>(0, (sum, e) => sum + e.value);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.7;
    const strokeWidth = 18.0;
    final startAngle = -math.pi / 2;

    // 背景环
    final bgPaint = Paint()
      ..color = MiuixColors.surfaceVariant
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // 数据环
    double currentAngle = startAngle;
    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * math.pi * animation;
      final ringPaint = Paint()
        ..color = data[i].color ?? MiuixColors.primary
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle - (i < data.length - 1 ? 0.04 : 0),
        false,
        ringPaint,
      );
      currentAngle += sweepAngle;
    }

    // 中心数值
    if (showValues) {
      final primaryValue = data.first.value;
      final tp = TextPainter(
        text: TextSpan(
          text: primaryValue.toStringAsFixed(0),
          style: const TextStyle(
            color: MiuixColors.textPrimary,
            fontSize: MiuixFontSize.xxl,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2 - 8),
      );

      if (showLabels) {
        final lp = TextPainter(
          text: TextSpan(
            text: data.first.label,
            style: const TextStyle(
              color: MiuixColors.textTertiary,
              fontSize: MiuixFontSize.sm,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        lp.paint(
          canvas,
          Offset(center.dx - lp.width / 2, center.dy + tp.height / 2 + 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingChartPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
