import 'dart:math';
import 'package:flutter/material.dart';

/// ============================================================================
/// ParticleAnimation —— 粒子动画
///
/// 提供粒子系统，支持粉色粒子、爆炸/漂浮/下雪/烟花效果，
/// 使用 CustomPainter 绘制，包含性能优化。
/// ============================================================================

/// 粒子类型
enum ParticleType {
  /// 爆炸效果
  explosion,

  /// 漂浮效果
  float,

  /// 下雪效果
  snow,

  /// 烟花效果
  fireworks,

  /// 心形漂浮
  hearts,
}

/// 单个粒子
class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double life;
  double maxLife;
  double rotation;
  double rotationSpeed;
  ParticleShape shape;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.life,
    required this.maxLife,
    this.rotation = 0,
    this.rotationSpeed = 0,
    this.shape = ParticleShape.circle,
  });

  bool get isDead => life <= 0;

  double get opacity => (life / maxLife).clamp(0.0, 1.0);

  void update(double gravity, double drag) {
    vy += gravity;
    vx *= drag;
    vy *= drag;
    x += vx;
    y += vy;
    life -= 1;
    rotation += rotationSpeed;
  }
}

/// 粒子形状
enum ParticleShape { circle, square, star, heart }

/// 粒子动画 Widget
class ParticleAnimation extends StatefulWidget {
  final ParticleType type;
  final int particleCount;
  final List<Color>? colors;
  final double minSize;
  final double maxSize;
  final Duration duration;
  final bool repeat;
  final Widget? child;

  const ParticleAnimation({
    super.key,
    this.type = ParticleType.float,
    this.particleCount = 30,
    this.colors,
    this.minSize = 2,
    this.maxSize = 8,
    this.duration = const Duration(seconds: 5),
    this.repeat = true,
    this.child,
  });

  @override
  State<ParticleAnimation> createState() => _ParticleAnimationState();
}

class _ParticleAnimationState extends State<ParticleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();
  Size _canvasSize = Size.zero;

  /// 默认粉色系颜色
  List<Color> get _defaultColors => [
        const Color(0xFFFF69B4),
        const Color(0xFFFFB6C1),
        const Color(0xFFFFC0CB),
        const Color(0xFFFF1493),
        const Color(0xFFFFB6C1),
      ];

  List<Color> get _colors => widget.colors ?? _defaultColors;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(_updateParticles);
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateParticles() {
    setState(() {
      final gravity = _getGravity();
      final drag = _getDrag();
      for (final particle in _particles) {
        particle.update(gravity, drag);
      }
      _particles.removeWhere((p) => p.isDead);

      // 补充粒子
      if (widget.repeat && _particles.length < widget.particleCount) {
        _spawnParticles(widget.particleCount - _particles.length);
      }
    });
  }

  double _getGravity() {
    switch (widget.type) {
      case ParticleType.explosion:
        return 0.1;
      case ParticleType.float:
        return -0.02;
      case ParticleType.snow:
        return 0.05;
      case ParticleType.fireworks:
        return 0.08;
      case ParticleType.hearts:
        return -0.03;
    }
  }

  double _getDrag() {
    switch (widget.type) {
      case ParticleType.explosion:
        return 0.98;
      case ParticleType.float:
        return 0.99;
      case ParticleType.snow:
        return 0.995;
      case ParticleType.fireworks:
        return 0.97;
      case ParticleType.hearts:
        return 0.99;
    }
  }

  void _spawnParticles(int count) {
    for (int i = 0; i < count; i++) {
      _particles.add(_createParticle());
    }
  }

  _Particle _createParticle() {
    final size = widget.minSize +
        _random.nextDouble() * (widget.maxSize - widget.minSize);
    final color = _colors[_random.nextInt(_colors.length)];
    final maxLife = 60 + _random.nextInt(120).toDouble();

    switch (widget.type) {
      case ParticleType.explosion:
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 2 + _random.nextDouble() * 5;
        return _Particle(
          x: _canvasSize.width / 2,
          y: _canvasSize.height / 2,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: size,
          color: color,
          life: maxLife,
          maxLife: maxLife,
          shape: ParticleShape.circle,
        );

      case ParticleType.float:
        return _Particle(
          x: _random.nextDouble() * _canvasSize.width,
          y: _canvasSize.height + size,
          vx: (_random.nextDouble() - 0.5) * 0.5,
          vy: -0.5 - _random.nextDouble(),
          size: size,
          color: color,
          life: maxLife,
          maxLife: maxLife,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.05,
          shape: ParticleShape.circle,
        );

      case ParticleType.snow:
        return _Particle(
          x: _random.nextDouble() * _canvasSize.width,
          y: -size,
          vx: (_random.nextDouble() - 0.5) * 1,
          vy: 0.5 + _random.nextDouble() * 1.5,
          size: size,
          color: Colors.white,
          life: maxLife,
          maxLife: maxLife,
          shape: ParticleShape.circle,
        );

      case ParticleType.fireworks:
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 1 + _random.nextDouble() * 4;
        return _Particle(
          x: _canvasSize.width / 2 + (_random.nextDouble() - 0.5) * 100,
          y: _canvasSize.height / 3,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: size,
          color: color,
          life: maxLife,
          maxLife: maxLife,
          shape: ParticleShape.star,
        );

      case ParticleType.hearts:
        return _Particle(
          x: _random.nextDouble() * _canvasSize.width,
          y: _canvasSize.height + size,
          vx: (_random.nextDouble() - 0.5) * 0.3,
          vy: -0.3 - _random.nextDouble() * 0.8,
          size: size * 1.5,
          color: color,
          life: maxLife,
          maxLife: maxLife,
          shape: ParticleShape.heart,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (_particles.isEmpty) {
          _spawnParticles(widget.particleCount);
        }
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
          ),
          size: _canvasSize,
          child: widget.child,
        );
      },
    );
  }
}

/// 粒子绘制器
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      switch (particle.shape) {
        case ParticleShape.circle:
          canvas.drawCircle(
            Offset(particle.x, particle.y),
            particle.size,
            paint,
          );
          break;

        case ParticleShape.square:
          canvas.save();
          canvas.translate(particle.x, particle.y);
          canvas.rotate(particle.rotation);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size * 2,
              height: particle.size * 2,
            ),
            paint,
          );
          canvas.restore();
          break;

        case ParticleShape.star:
          _drawStar(canvas, particle, paint);
          break;

        case ParticleShape.heart:
          _drawHeart(canvas, particle, paint);
          break;
      }
    }
  }

  void _drawStar(Canvas canvas, _Particle particle, Paint paint) {
    final path = Path();
    final r = particle.size;
    final innerR = r * 0.4;
    for (int i = 0; i < 10; i++) {
      final angle = (i * pi / 5) - pi / 2;
      final radius = i % 2 == 0 ? r : innerR;
      final x = particle.x + cos(angle) * radius;
      final y = particle.y + sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, _Particle particle, Paint paint) {
    final path = Path();
    final s = particle.size;
    final x = particle.x;
    final y = particle.y;
    path.moveTo(x, y + s * 0.3);
    path.cubicTo(x, y, x - s, y, x - s, y + s * 0.3);
    path.cubicTo(x - s, y + s * 0.6, x, y + s, x, y + s * 1.2);
    path.cubicTo(x, y + s, x + s, y + s * 0.6, x + s, y + s * 0.3);
    path.cubicTo(x + s, y, x, y, x, y + s * 0.3);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return particles != oldDelegate.particles;
  }
}

/// 爆炸粒子效果（一次性）
class ExplosionBurst extends StatefulWidget {
  final Offset position;
  final int particleCount;
  final List<Color>? colors;
  final Duration duration;
  final VoidCallback? onComplete;

  const ExplosionBurst({
    super.key,
    required this.position,
    this.particleCount = 50,
    this.colors,
    this.duration = const Duration(milliseconds: 800),
    this.onComplete,
  });

  @override
  State<ExplosionBurst> createState() => _ExplosionBurstState();
}

class _ExplosionBurstState extends State<ExplosionBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )
      ..addListener(() {
        setState(() {
          for (final p in _particles) {
            p.update(0.15, 0.96);
          }
          _particles.removeWhere((p) => p.isDead);
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });

    // 创建爆炸粒子
    final colors = widget.colors ??
        [
          const Color(0xFFFF69B4),
          const Color(0xFFFFB6C1),
          Colors.white,
          const Color(0xFFFF1493),
        ];
    for (int i = 0; i < widget.particleCount; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 2 + _random.nextDouble() * 6;
      _particles.add(_Particle(
        x: widget.position.dx,
        y: widget.position.dy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 2 + _random.nextDouble() * 4,
        color: colors[_random.nextInt(colors.length)],
        life: 40 + _random.nextInt(40).toDouble(),
        maxLife: 80,
      ));
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(particles: _particles),
      size: Size.infinite,
    );
  }
}
