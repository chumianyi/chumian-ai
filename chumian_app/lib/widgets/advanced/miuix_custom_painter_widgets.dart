import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixCustomPainterWidgets —— Miuix 风格自定义绘制组件集合
/// 粉色波浪、云朵、星星、心形、花朵等装饰性 CustomPainter，带动画
/// ============================================================

/// 装饰类型
enum MiuixDecorationType {
  /// 波浪
  wave,

  /// 云朵
  cloud,

  /// 星星
  star,

  /// 心形
  heart,

  /// 花朵
  flower,
}

/// Miuix 风格装饰性绘制组件
///
/// 用法：
/// ```dart
/// MiuixDecoration(
///   type: MiuixDecorationType.heart,
///   size: 80,
///   color: MiuixColors.primary,
/// )
/// ```
class MiuixDecoration extends StatefulWidget {
  const MiuixDecoration({
    super.key,
    required this.type,
    this.size = 60,
    this.color,
    this.animate = true,
    this.animationDuration = const Duration(seconds: 3),
  });

  /// 装饰类型
  final MiuixDecorationType type;

  /// 尺寸
  final double size;

  /// 颜色
  final Color? color;

  /// 是否启用动画
  final bool animate;

  /// 动画时长
  final Duration animationDuration;

  @override
  State<MiuixDecoration> createState() => _MiuixDecorationState();
}

class _MiuixDecorationState extends State<MiuixDecoration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _DecorationPainter(
            type: widget.type,
            color: widget.color ?? MiuixColors.primary,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

/// 装饰绘制器
class _DecorationPainter extends CustomPainter {
  _DecorationPainter({
    required this.type,
    required this.color,
    required this.progress,
  });

  final MiuixDecorationType type;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case MiuixDecorationType.wave:
        _paintWave(canvas, size);
        break;
      case MiuixDecorationType.cloud:
        _paintCloud(canvas, size);
        break;
      case MiuixDecorationType.star:
        _paintStar(canvas, size);
        break;
      case MiuixDecorationType.heart:
        _paintHeart(canvas, size);
        break;
      case MiuixDecorationType.flower:
        _paintFlower(canvas, size);
        break;
    }
  }

  void _paintWave(Canvas canvas, Size size) {
    final waveHeight = size.height * 0.3;
    final baseY = size.height * 0.6;
    final path = Path();
    path.moveTo(0, baseY);

    for (double x = 0; x <= size.width; x += 2) {
      final y = baseY +
          math.sin(x * 0.05 + progress * math.pi * 2) * waveHeight * 0.5 +
          math.sin(x * 0.08 + progress * math.pi * 3) * waveHeight * 0.3;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.6),
          color.withValues(alpha: 0.2),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);

    // 第二层波浪
    final path2 = Path();
    path2.moveTo(0, baseY + 10);
    for (double x = 0; x <= size.width; x += 2) {
      final y = baseY +
          10 +
          math.sin(x * 0.06 + progress * math.pi * 2 + 1) * waveHeight * 0.4;
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    final paint2 = Paint()
      ..color = color.withValues(alpha: 0.3);
    canvas.drawPath(path2, paint2);
  }

  void _paintCloud(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final floatOffset = math.sin(progress * math.pi * 2) * 3;

    final cloudPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // 云朵由多个圆组成
    final circles = [
      Offset(center.dx - size.width * 0.2, center.dy + floatOffset),
      Offset(center.dx, center.dy - size.height * 0.1 + floatOffset),
      Offset(center.dx + size.width * 0.2, center.dy + floatOffset),
      Offset(center.dx - size.width * 0.1, center.dy + size.height * 0.1 + floatOffset),
      Offset(center.dx + size.width * 0.1, center.dy + size.height * 0.1 + floatOffset),
    ];

    for (final c in circles) {
      canvas.drawCircle(c, size.width * 0.18, cloudPaint);
    }

    // 底部椭圆
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + size.height * 0.1 + floatOffset),
        width: size.width * 0.6,
        height: size.height * 0.25,
      ),
      cloudPaint,
    );
  }

  void _paintStar(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 * 0.8;
    final innerRadius = outerRadius * 0.42;
    final rotation = progress * math.pi * 0.5;
    const points = 5;

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = -math.pi / 2 + rotation + i * math.pi / points;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.8), color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // 闪烁光晕
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3 + math.sin(progress * math.pi * 2) * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);
  }

  void _paintHeart(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = 1 + math.sin(progress * math.pi * 2) * 0.08;
    final width = size.width * 0.8 * scale;
    final height = size.height * 0.75 * scale;

    final path = Path();
    path.moveTo(center.dx, center.dy + height * 0.35);
    path.cubicTo(
      center.dx - width * 0.5, center.dy,
      center.dx - width * 0.5, center.dy - height * 0.4,
      center.dx - width * 0.2, center.dy - height * 0.4,
    );
    path.cubicTo(
      center.dx - width * 0.05, center.dy - height * 0.4,
      center.dx, center.dy - height * 0.25,
      center.dx, center.dy - height * 0.15,
    );
    path.cubicTo(
      center.dx, center.dy - height * 0.25,
      center.dx + width * 0.05, center.dy - height * 0.4,
      center.dx + width * 0.2, center.dy - height * 0.4,
    );
    path.cubicTo(
      center.dx + width * 0.5, center.dy - height * 0.4,
      center.dx + width * 0.5, center.dy,
      center.dx, center.dy + height * 0.35,
    );
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.7), color],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // 高光
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(
        center.dx - width * 0.25,
        center.dy - height * 0.3,
        width * 0.15,
        height * 0.1,
      ),
      highlightPaint,
    );
  }

  void _paintFlower(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petalCount = 6;
    final petalRadius = size.width * 0.22;
    final centerRadius = size.width * 0.12;
    final rotation = progress * math.pi * 0.3;

    // 花瓣
    for (int i = 0; i < petalCount; i++) {
      final angle = rotation + i * 2 * math.pi / petalCount;
      final petalCenter = center +
          Offset(
            math.cos(angle) * petalRadius * 0.8,
            math.sin(angle) * petalRadius * 0.8,
          );

      final petalPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.9),
            color.withValues(alpha: 0.5),
          ],
        ).createShader(Rect.fromCircle(
          center: petalCenter,
          radius: petalRadius,
        ));
      canvas.drawCircle(petalCenter, petalRadius, petalPaint);
    }

    // 花心
    final centerPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, centerRadius, centerPaint);

    // 花心纹理
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final angle = progress * math.pi + i * 2 * math.pi / 5;
      final dotPos = center +
          Offset(
            math.cos(angle) * centerRadius * 0.5,
            math.sin(angle) * centerRadius * 0.5,
          );
      canvas.drawCircle(dotPos, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DecorationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// ============================================================
/// MiuixWaveDivider —— 粉色波浪分割线
/// ============================================================
class MiuixWaveDivider extends StatelessWidget {
  const MiuixWaveDivider({
    super.key,
    this.height = 30,
    this.color = MiuixColors.primary,
    this.waveCount = 5,
  });

  final double height;
  final Color color;
  final int waveCount;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _WaveDividerPainter(
        color: color,
        waveCount: waveCount,
      ),
    );
  }
}

class _WaveDividerPainter extends CustomPainter {
  _WaveDividerPainter({required this.color, required this.waveCount});

  final Color color;
  final int waveCount;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final amplitude = size.height * 0.3;
    final wavelength = size.width / waveCount;

    path.moveTo(0, size.height / 2);
    for (int i = 0; i < waveCount; i++) {
      final x1 = i * wavelength + wavelength / 4;
      final x2 = i * wavelength + wavelength * 3 / 4;
      final xEnd = (i + 1) * wavelength;
      path.cubicTo(
        x1, size.height / 2 - amplitude,
        x2, size.height / 2 + amplitude,
        xEnd, size.height / 2,
      );
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveDividerPainter oldDelegate) => false;
}
