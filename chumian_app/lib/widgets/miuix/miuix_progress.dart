import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixProgress —— 进度指示器
/// 线性进度条(粉色渐变+微光)、圆形进度(粉色旋转)、加载指示器(三点跳动/旋转花瓣)
/// ============================================================

/// 进度条类型
enum MiuixProgressType {
  /// 线性
  linear,

  /// 圆形
  circular,

  /// 不确定线性
  linearIndeterminate,

  /// 不确定圆形
  circularIndeterminate,
}

/// 加载指示器类型
enum MiuixLoadingType {
  /// 三点跳动
  dots,

  /// 旋转花瓣
  petals,

  /// 旋转圆环
  ring,

  /// 脉冲
  pulse,
}

/// Miuix 风格进度条
///
/// 用法：
/// ```dart
/// MiuixProgress(value: 0.6, type: MiuixProgressType.linear)
/// ```
class MiuixProgress extends StatefulWidget {
  const MiuixProgress({
    super.key,
    this.value,
    this.type = MiuixProgressType.linear,
    this.width,
    this.height = 6.0,
    this.size = 48.0,
    this.strokeWidth = 4.0,
    this.color,
    this.trackColor,
    this.gradient,
    this.showLabel = false,
    this.labelStyle,
    this.backgroundColor,
    this.borderRadius,
  });

  /// 进度值 0.0 - 1.0
  final double? value;

  /// 类型
  final MiuixProgressType type;

  /// 宽度（线性）
  final double? width;

  /// 高度（线性）
  final double height;

  /// 尺寸（圆形）
  final double size;

  /// 线宽（圆形）
  final double strokeWidth;

  /// 颜色
  final Color? color;

  /// 轨道颜色
  final Color? trackColor;

  /// 渐变
  final Gradient? gradient;

  /// 是否显示百分比文字
  final bool showLabel;

  /// 文字样式
  final TextStyle? labelStyle;

  /// 背景色
  final Color? backgroundColor;

  /// 圆角
  final double? borderRadius;

  @override
  State<MiuixProgress> createState() => _MiuixProgressState();
}

class _MiuixProgressState extends State<MiuixProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _indeterminateController;

  @override
  void initState() {
    super.initState();
    _indeterminateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _indeterminateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case MiuixProgressType.linear:
        return _buildLinear();
      case MiuixProgressType.circular:
        return _buildCircular();
      case MiuixProgressType.linearIndeterminate:
        return _buildLinearIndeterminate();
      case MiuixProgressType.circularIndeterminate:
        return _buildCircularIndeterminate();
    }
  }

  Widget _buildLinear() {
    final double radius = widget.borderRadius ?? widget.height / 2;
    final double progress = (widget.value ?? 0).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.trackColor ?? MiuixColors.border.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Stack(
            children: [
              // 进度填充
              AnimatedContainer(
                duration: MiuixDuration.normal,
                curve: Curves.easeOutCubic,
                width: (widget.width ?? 100) * progress,
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: widget.gradient ??
                      LinearGradient(
                        colors: [
                          widget.color ?? MiuixColors.primaryLight,
                          widget.color ?? MiuixColors.primary,
                        ],
                      ),
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.color ?? MiuixColors.primary)
                          .withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // 微光
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}%',
            style: widget.labelStyle ??
                TextStyle(
                  color: MiuixColors.textSecondary,
                  fontSize: MiuixFontSize.xs,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildCircular() {
    final double progress = (widget.value ?? 0).clamp(0.0, 1.0);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _CircularProgressPainter(
          progress: progress,
          color: widget.color ?? MiuixColors.primary,
          trackColor: widget.trackColor ??
              MiuixColors.border.withValues(alpha: 0.5),
          strokeWidth: widget.strokeWidth,
        ),
        child: Center(
          child: widget.showLabel
              ? Text(
                  '${(progress * 100).toInt()}%',
                  style: widget.labelStyle ??
                      TextStyle(
                        color: MiuixColors.primary,
                        fontSize: widget.size * 0.25,
                        fontWeight: FontWeight.w700,
                      ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildLinearIndeterminate() {
    final double radius = widget.borderRadius ?? widget.height / 2;

    return AnimatedBuilder(
      animation: _indeterminateController,
      builder: (context, child) {
        final double t = _indeterminateController.value;
        final double start = (t * 1.5 - 0.5).clamp(0.0, 1.0);
        final double end = (t * 1.5).clamp(0.0, 1.0);

        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.trackColor ?? MiuixColors.border.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              return Stack(
                children: [
                  Positioned(
                    left: start * totalWidth,
                    width: (end - start) * totalWidth,
                    child: Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        gradient: widget.gradient ??
                            LinearGradient(
                              colors: [
                                widget.color ?? MiuixColors.primaryLight,
                                widget.color ?? MiuixColors.primary,
                              ],
                            ),
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCircularIndeterminate() {
    return RotationTransition(
      turns: _indeterminateController,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _CircularProgressPainter(
            progress: 0.75,
            color: widget.color ?? MiuixColors.primary,
            trackColor: Colors.transparent,
            strokeWidth: widget.strokeWidth,
          ),
        ),
      ),
    );
  }
}

/// 圆形进度绘制器
class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    // 轨道
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // 进度弧
    final Paint progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.3), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// ============================================================
/// MiuixLoadingIndicator —— 加载指示器
/// ============================================================

/// Miuix 加载指示器
class MiuixLoadingIndicator extends StatefulWidget {
  const MiuixLoadingIndicator({
    super.key,
    this.type = MiuixLoadingType.dots,
    this.size = 40.0,
    this.color,
    this.dotCount = 3,
  });

  final MiuixLoadingType type;
  final double size;
  final Color? color;
  final int dotCount;

  @override
  State<MiuixLoadingIndicator> createState() => _MiuixLoadingIndicatorState();
}

class _MiuixLoadingIndicatorState extends State<MiuixLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case MiuixLoadingType.dots:
        return _buildDots();
      case MiuixLoadingType.petals:
        return _buildPetals();
      case MiuixLoadingType.ring:
        return _buildRing();
      case MiuixLoadingType.pulse:
        return _buildPulse();
    }
  }

  Widget _buildDots() {
    final Color c = widget.color ?? MiuixColors.primary;
    final double dotSize = widget.size / 4;

    return SizedBox(
      width: widget.size,
      height: widget.size / 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.dotCount, (index) {
          final double delay = index * 0.15;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double t =
                  ((_controller.value + delay) % 1.0);
              final double scale = 0.5 +
                  0.5 * math.sin(t * math.pi * 2).clamp(0.0, 1.0);
              return Transform.scale(
                scale: 0.6 + scale * 0.4,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.5 + scale * 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPetals() {
    final Color c = widget.color ?? MiuixColors.primary;
    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(6, (index) {
            final double angle = index * math.pi / 3;
            return Transform.rotate(
              angle: angle,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: widget.size * 0.15,
                  height: widget.size * 0.4,
                  margin: EdgeInsets.only(top: widget.size * 0.05),
                  decoration: BoxDecoration(
                    color: c.withValues(
                      alpha: 0.3 + 0.7 * (index / 6),
                    ),
                    borderRadius: BorderRadius.circular(widget.size * 0.075),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRing() {
    return MiuixProgress(
      type: MiuixProgressType.circularIndeterminate,
      size: widget.size,
      color: widget.color,
      strokeWidth: widget.size * 0.08,
    );
  }

  Widget _buildPulse() {
    final Color c = widget.color ?? MiuixColors.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value;
        final double scale = 0.8 + 0.2 * math.sin(t * math.pi * 2);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.3 + 0.3 * scale),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: widget.size * 0.5 * scale,
              height: widget.size * 0.5 * scale,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
