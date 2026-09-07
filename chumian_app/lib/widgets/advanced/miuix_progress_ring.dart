import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixProgressRing —— Miuix 风格进度环
/// 多环叠加，渐变描边，旋转动画，中心数值，粉色系
/// ============================================================

/// 单个环数据
class MiuixProgressRingData {
  const MiuixProgressRingData({
    required this.value,
    this.color,
    this.label,
  });

  /// 进度值（0-1）
  final double value;

  /// 环颜色
  final Color? color;

  /// 标签
  final String? label;
}

/// Miuix 风格进度环
///
/// 用法：
/// ```dart
/// MiuixProgressRing(
///   rings: [
///     MiuixProgressRingData(value: 0.75, label: '完成率'),
///     MiuixProgressRingData(value: 0.5, color: Colors.orange),
///   ],
///   size: 180,
/// )
/// ```
class MiuixProgressRing extends StatefulWidget {
  const MiuixProgressRing({
    super.key,
    required this.rings,
    this.size = 180,
    this.strokeWidth = 12,
    this.gap = 6,
    this.showCenterValue = true,
    this.centerLabel,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.rotate = false,
  });

  /// 环数据列表
  final List<MiuixProgressRingData> rings;

  /// 整体尺寸
  final double size;

  /// 环宽度
  final double strokeWidth;

  /// 环间距
  final double gap;

  /// 是否显示中心数值
  final bool showCenterValue;

  /// 中心标签
  final String? centerLabel;

  /// 是否启用动画
  final bool animate;

  /// 动画时长
  final Duration animationDuration;

  /// 是否旋转动画
  final bool rotate;

  @override
  State<MiuixProgressRing> createState() => _MiuixProgressRingState();
}

class _MiuixProgressRingState extends State<MiuixProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _rotationController;
  late final Animation<double> _progressAnimation;

  static const List<Color> _defaultColors = [
    MiuixColors.primary,
    MiuixColors.primaryLight,
    Color(0xFFFF9EBB),
    MiuixColors.primaryDeep,
    Color(0xFFFFB3CC),
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: MiuixCurves.miuixSpring,
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.animate) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _progressController.forward());
    } else {
      _progressController.value = 1.0;
    }
    if (widget.rotate) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(MiuixProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rings != widget.rings) {
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_progressAnimation, _rotationController]),
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _ProgressRingPainter(
              rings: widget.rings,
              progress: _progressAnimation.value,
              strokeWidth: widget.strokeWidth,
              gap: widget.gap,
              rotation: widget.rotate ? _rotationController.value * math.pi * 2 : 0,
              colors: _defaultColors,
            ),
            child: widget.showCenterValue ? _buildCenter() : null,
          );
        },
      ),
    );
  }

  Widget _buildCenter() {
    final primaryRing = widget.rings.isNotEmpty ? widget.rings.first : null;
    final value = primaryRing != null
        ? (primaryRing.value * 100).toStringAsFixed(0)
        : '0';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value%',
            style: const TextStyle(
              color: MiuixColors.textPrimary,
              fontSize: MiuixFontSize.display,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (widget.centerLabel != null || primaryRing?.label != null)
            Text(
              widget.centerLabel ?? primaryRing?.label ?? '',
              style: const TextStyle(
                color: MiuixColors.textTertiary,
                fontSize: MiuixFontSize.sm,
              ),
            ),
        ],
      ),
    );
  }
}

/// 进度环绘制器
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.rings,
    required this.progress,
    required this.strokeWidth,
    required this.gap,
    required this.rotation,
    required this.colors,
  });

  final List<MiuixProgressRingData> rings;
  final double progress;
  final double strokeWidth;
  final double gap;
  final double rotation;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - strokeWidth / 2 - 4;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < rings.length; i++) {
      final ring = rings[i];
      final radius = maxRadius - i * (strokeWidth + gap);
      if (radius <= 0) break;

      // 背景环
      final bgPaint = Paint()
        ..color = MiuixColors.surfaceVariant
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, bgPaint);

      // 进度环
      final ringColor = ring.color ?? colors[i % colors.length];
      final sweepAngle = 2 * math.pi * ring.value * progress;

      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweepAngle,
          colors: [
            ringColor.withOpacity(0.6),
            ringColor,
            ringColor.withOpacity(0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );

      // 末端圆点光晕
      if (progress > 0 && ring.value > 0) {
        final endAngle = -math.pi / 2 + sweepAngle;
        final endPoint = center +
            Offset(
              math.cos(endAngle) * radius,
              math.sin(endAngle) * radius,
            );
        final glowPaint = Paint()
          ..color = ringColor.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(endPoint, strokeWidth * 0.6, glowPaint);

        final dotPaint = Paint()..color = Colors.white;
        canvas.drawCircle(endPoint, strokeWidth * 0.25, dotPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.rotation != rotation;
}

/// ============================================================
/// MiuixCircularProgress —— 圆形进度指示器
/// 单环进度，粉色渐变，中心显示百分比
/// ============================================================
class MiuixCircularProgress extends StatefulWidget {
  const MiuixCircularProgress({
    super.key,
    required this.value,
    this.size = 100,
    this.strokeWidth = 8,
    this.color,
    this.trackColor,
    this.showPercentage = true,
    this.animate = true,
  });

  /// 进度值（0-1）
  final double value;

  /// 尺寸
  final double size;

  /// 线宽
  final double strokeWidth;

  /// 进度颜色
  final Color? color;

  /// 轨道颜色
  final Color? trackColor;

  /// 是否显示百分比
  final bool showPercentage;

  /// 是否启用动画
  final bool animate;

  @override
  State<MiuixCircularProgress> createState() => _MiuixCircularProgressState();
}

class _MiuixCircularProgressState extends State<MiuixCircularProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: MiuixCurves.miuixSpring,
    );
    if (widget.animate) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _controller.forward());
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MiuixCircularProgress oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final progressColor = widget.color ?? MiuixColors.primary;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedValue = widget.value * _animation.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircularProgressPainter(
                  value: animatedValue,
                  strokeWidth: widget.strokeWidth,
                  color: progressColor,
                  trackColor:
                      widget.trackColor ?? MiuixColors.surfaceVariant,
                ),
              ),
              if (widget.showPercentage)
                Text(
                  '${(animatedValue * 100).toInt()}%',
                  style: TextStyle(
                    color: progressColor,
                    fontSize: widget.size * 0.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // 背景轨道
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // 进度弧
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi * value,
        colors: [color.withOpacity(0.6), color],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) =>
      oldDelegate.value != value;
}

/// ============================================================
/// MiuixLinearProgress —— 线性进度条
/// 粉色渐变进度条，带圆角和动画
/// ============================================================
class MiuixLinearProgress extends StatefulWidget {
  const MiuixLinearProgress({
    super.key,
    required this.value,
    this.height = 8,
    this.width,
    this.color,
    this.trackColor,
    this.showLabel = false,
    this.animate = true,
  });

  final double value;
  final double height;
  final double? width;
  final Color? color;
  final Color? trackColor;
  final bool showLabel;
  final bool animate;

  @override
  State<MiuixLinearProgress> createState() => _MiuixLinearProgressState();
}

class _MiuixLinearProgressState extends State<MiuixLinearProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: MiuixCurves.easeOut,
    );
    if (widget.animate) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _controller.forward());
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MiuixLinearProgress oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final progressColor = widget.color ?? MiuixColors.primary;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedValue = widget.value * _animation.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showLabel) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '进度',
                    style: TextStyle(
                      color: progressColor,
                      fontSize: MiuixFontSize.sm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(animatedValue * 100).toInt()}%',
                    style: TextStyle(
                      color: progressColor,
                      fontSize: MiuixFontSize.sm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MiuixSpacing.xs),
            ],
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.trackColor ?? MiuixColors.surfaceVariant,
                borderRadius: BorderRadius.circular(widget.height),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: constraints.maxWidth * animatedValue,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            progressColor.withOpacity(0.7),
                            progressColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(widget.height),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
