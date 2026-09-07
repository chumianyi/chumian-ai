import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixAnimatedBackground —— Miuix 风格动态背景
/// 浮动粉色气泡/渐变流动/粒子漂浮，不干扰前景交互
/// ============================================================

/// 背景动画类型
enum MiuixBackgroundType {
  /// 浮动气泡
  bubbles,

  /// 渐变流动
  gradientFlow,

  /// 粒子漂浮
  particles,
}

/// Miuix 风格动态背景
///
/// 用法：
/// ```dart
/// MiuixAnimatedBackground(
///   type: MiuixBackgroundType.bubbles,
///   child: Center(child: Text('内容')),
/// )
/// ```
class MiuixAnimatedBackground extends StatefulWidget {
  const MiuixAnimatedBackground({
    super.key,
    required this.child,
    this.type = MiuixBackgroundType.bubbles,
    this.bubbleCount = 15,
    this.particleCount = 30,
    this.baseColor,
  });

  /// 前景内容
  final Widget child;

  /// 动画类型
  final MiuixBackgroundType type;

  /// 气泡数量
  final int bubbleCount;

  /// 粒子数量
  final int particleCount;

  /// 基础颜色
  final Color? baseColor;

  @override
  State<MiuixAnimatedBackground> createState() =>
      _MiuixAnimatedBackgroundState();
}

class _MiuixAnimatedBackgroundState extends State<MiuixAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random();
  late final List<_Bubble> _bubbles;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _bubbles = List.generate(widget.bubbleCount, (i) {
      return _Bubble(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: 15 + _random.nextDouble() * 40,
        speed: 0.3 + _random.nextDouble() * 0.7,
        phase: _random.nextDouble() * math.pi * 2,
        opacity: 0.05 + _random.nextDouble() * 0.1,
      );
    });

    _particles = List.generate(widget.particleCount, (i) {
      return _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: 1 + _random.nextDouble() * 3,
        speed: 0.2 + _random.nextDouble() * 0.5,
        phase: _random.nextDouble() * math.pi * 2,
        opacity: 0.2 + _random.nextDouble() * 0.4,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 基础背景
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.baseColor ?? MiuixColors.background,
                  (widget.baseColor ?? MiuixColors.background)
                      .withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),
        // 动画层
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BackgroundPainter(
                    type: widget.type,
                    progress: _controller.value,
                    bubbles: _bubbles,
                    particles: _particles,
                    baseColor: widget.baseColor ?? MiuixColors.primary,
                  ),
                );
              },
            ),
          ),
        ),
        // 前景
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

/// 气泡数据
class _Bubble {
  _Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.opacity,
  });

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double phase;
  final double opacity;
}

/// 粒子数据
class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.opacity,
  });

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double phase;
  final double opacity;
}

/// 背景绘制器
class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({
    required this.type,
    required this.progress,
    required this.bubbles,
    required this.particles,
    required this.baseColor,
  });

  final MiuixBackgroundType type;
  final double progress;
  final List<_Bubble> bubbles;
  final List<_Particle> particles;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case MiuixBackgroundType.bubbles:
        _paintBubbles(canvas, size);
        break;
      case MiuixBackgroundType.gradientFlow:
        _paintGradientFlow(canvas, size);
        break;
      case MiuixBackgroundType.particles:
        _paintParticles(canvas, size);
        break;
    }
  }

  void _paintBubbles(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      final y = ((bubble.y - progress * bubble.speed) % 1.0 + 1.0) % 1.0;
      final x = bubble.x +
          math.sin(progress * math.pi * 2 + bubble.phase) * 0.03;
      final center = Offset(x * size.width, y * size.height);

      final paint = Paint()
        ..color = baseColor.withValues(alpha: bubble.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, bubble.radius, paint);

      // 气泡高光
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: bubble.opacity * 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        center + Offset(-bubble.radius * 0.3, -bubble.radius * 0.3),
        bubble.radius * 0.25,
        highlightPaint,
      );
    }
  }

  void _paintGradientFlow(Canvas canvas, Size size) {
    // 流动的渐变光斑
    for (int i = 0; i < 3; i++) {
      final angle = progress * math.pi * 2 + i * math.pi * 2 / 3;
      final center = Offset(
        size.width * 0.5 + math.cos(angle) * size.width * 0.3,
        size.height * 0.5 + math.sin(angle) * size.height * 0.3,
      );
      final radius = size.width * 0.4;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            baseColor.withValues(alpha: 0.12),
            baseColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _paintParticles(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y =
          ((particle.y - progress * particle.speed) % 1.0 + 1.0) % 1.0;
      final x = particle.x +
          math.sin(progress * math.pi * 4 + particle.phase) * 0.05;
      final center = Offset(x * size.width, y * size.height);

      final paint = Paint()
        ..color = baseColor.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, particle.radius, paint);

      // 粒子拖尾
      final trailPaint = Paint()
        ..color = baseColor.withValues(alpha: particle.opacity * 0.3)
        ..strokeWidth = particle.radius * 0.5
        ..strokeCap = StrokeCap.round;
      final trailEnd = center + const Offset(0, 8);
      canvas.drawLine(center, trailEnd, trailPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// ============================================================
/// MiuixGradientBackground —— 渐变流动背景
/// 多色渐变缓慢流动
/// ============================================================
class MiuixGradientBackground extends StatefulWidget {
  const MiuixGradientBackground({
    super.key,
    this.colors = const [
      Color(0xFFFFE8F0),
      Color(0xFFFFD6E4),
      Color(0xFFFFF5F8),
      Color(0xFFFFEEF3),
    ],
    this.duration = const Duration(seconds: 8),
    this.child,
  });

  final List<Color> colors;
  final Duration duration;
  final Widget? child;

  @override
  State<MiuixGradientBackground> createState() =>
      _MiuixGradientBackgroundState();
}

class _MiuixGradientBackgroundState extends State<MiuixGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
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
        final t = _controller.value;
        final colors = widget.colors;
        final shifted = [
          colors[(t * colors.length).floor() % colors.length],
          colors[((t * colors.length) + 1).floor() % colors.length],
          colors[((t * colors.length) + 2).floor() % colors.length],
        ];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(t * math.pi * 2),
                math.sin(t * math.pi * 2),
              ),
              end: Alignment(
                -math.cos(t * math.pi * 2),
                -math.sin(t * math.pi * 2),
              ),
              colors: shifted,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// ============================================================
/// MiuixFloatingOrbs —— 浮动光球背景
/// 多个粉色光球缓慢浮动
/// ============================================================
class MiuixFloatingOrbs extends StatefulWidget {
  const MiuixFloatingOrbs({
    super.key,
    this.orbCount = 5,
    this.colors = const [
      MiuixColors.primaryLight,
      MiuixColors.primary,
      Color(0xFFFF9EBB),
    ],
    this.child,
  });

  final int orbCount;
  final List<Color> colors;
  final Widget? child;

  @override
  State<MiuixFloatingOrbs> createState() => _MiuixFloatingOrbsState();
}

class _MiuixFloatingOrbsState extends State<MiuixFloatingOrbs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random();
  late final List<_OrbData> _orbs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _orbs = List.generate(widget.orbCount, (i) {
      return _OrbData(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: 40 + _random.nextDouble() * 80,
        speed: 0.2 + _random.nextDouble() * 0.5,
        phase: _random.nextDouble() * math.pi * 2,
        color: widget.colors[i % widget.colors.length],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _OrbsPainter(
                orbs: _orbs,
                progress: _controller.value,
              ),
            );
          },
        ),
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _OrbData {
  _OrbData({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.color,
  });

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double phase;
  final Color color;
}

class _OrbsPainter extends CustomPainter {
  _OrbsPainter({required this.orbs, required this.progress});

  final List<_OrbData> orbs;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final orb in orbs) {
      final x = (orb.x + math.sin(progress * math.pi * 2 * orb.speed + orb.phase) * 0.1) *
          size.width;
      final y = (orb.y + math.cos(progress * math.pi * 2 * orb.speed + orb.phase) * 0.1) *
          size.height;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withValues(alpha: 0.3),
            orb.color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(x, y),
          radius: orb.radius,
        ));
      canvas.drawCircle(Offset(x, y), orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
