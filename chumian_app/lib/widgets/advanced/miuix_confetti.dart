import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixConfetti —— Miuix 风格彩带庆祝
/// 粒子爆炸动画，粉色/金色/白色彩带粒子，重力下落，可触发
/// ============================================================

/// 彩带控制器
class MiuixConfettiController {
  MiuixConfettiController();
  _MiuixConfettiState? _state;

  void _attach(_MiuixConfettiState state) => _state = state;

  /// 触发彩带爆炸
  void burst({int count = 50, Offset? origin}) {
    _state?._burst(count: count, origin: origin);
  }

  void dispose() {
    _state = null;
  }
}

/// 单个彩带粒子
class _ConfettiParticle {
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
  });

  double x;
  double y;
  double vx;
  double vy;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;
  final int shape; // 0: 矩形, 1: 圆形, 2: 三角形
}

/// Miuix 风格彩带庆祝组件
///
/// 用法：
/// ```dart
/// final controller = MiuixConfettiController();
/// MiuixConfetti(controller: controller);
/// // 触发：controller.burst();
/// ```
class MiuixConfetti extends StatefulWidget {
  const MiuixConfetti({
    super.key,
    this.controller,
    this.autoPlay = false,
    this.colors = const [
      MiuixColors.primary,
      MiuixColors.primaryLight,
      Color(0xFFFFD700),
      Colors.white,
      Color(0xFFFF9EBB),
    ],
    this.gravity = 0.15,
    this.friction = 0.98,
    this.child,
  });

  /// 控制器
  final MiuixConfettiController? controller;

  /// 是否自动播放
  final bool autoPlay;

  /// 彩带颜色
  final List<Color> colors;

  /// 重力加速度
  final double gravity;

  /// 空气阻力
  final double friction;

  /// 子组件（彩带覆盖在其上）
  final Widget? child;

  @override
  State<MiuixConfetti> createState() => _MiuixConfettiState();
}

class _MiuixConfettiState extends State<MiuixConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(_updateParticles);
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _burst());
    }
  }

  @override
  void dispose() {
    widget.controller?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _burst({int count = 50, Offset? origin}) {
    final size = context.size ?? Size.zero;
    final startX = origin?.dx ?? size.width / 2;
    final startY = origin?.dy ?? size.height / 3;

    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 3 + _random.nextDouble() * 8;
      _particles.add(_ConfettiParticle(
        x: startX,
        y: startY,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 5,
        color: widget.colors[_random.nextInt(widget.colors.length)],
        size: 4 + _random.nextDouble() * 8,
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.3,
        shape: _random.nextInt(3),
      ));
    }
    if (!_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  void _updateParticles() {
    setState(() {
      for (final p in _particles) {
        p.vy += widget.gravity;
        p.vx *= widget.friction;
        p.vy *= widget.friction;
        p.x += p.vx;
        p.y += p.vy;
        p.rotation += p.rotationSpeed;
      }
      _particles.removeWhere((p) => p.y > (context.size?.height ?? 800) + 50);
    });
    if (_particles.isEmpty && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(particles: _particles),
              ),
            ),
          ),
      ],
    );
  }
}

/// 彩带绘制器
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles});

  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;

      switch (p.shape) {
        case 0: // 矩形彩带
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.4,
            ),
            paint,
          );
          break;
        case 1: // 圆形
          canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
          break;
        case 2: // 三角形
          final path = Path()
            ..moveTo(0, -p.size * 0.5)
            ..lineTo(p.size * 0.5, p.size * 0.4)
            ..lineTo(-p.size * 0.5, p.size * 0.4)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

/// ============================================================
/// MiuixConfettiRain —— 持续彩带雨效果
/// 从顶部持续飘落彩带，可设置持续时间和密度
/// ============================================================
class MiuixConfettiRain extends StatefulWidget {
  const MiuixConfettiRain({
    super.key,
    this.duration = const Duration(seconds: 5),
    this.particlesPerSecond = 20,
    this.colors = const [
      MiuixColors.primary,
      MiuixColors.primaryLight,
      Color(0xFFFFD700),
      Colors.white,
      Color(0xFFFF9EBB),
    ],
    this.child,
    this.onComplete,
  });

  /// 持续时间
  final Duration duration;

  /// 每秒生成粒子数
  final int particlesPerSecond;

  /// 颜色列表
  final List<Color> colors;

  /// 子组件
  final Widget? child;

  /// 完成回调
  final VoidCallback? onComplete;

  @override
  State<MiuixConfettiRain> createState() => _MiuixConfettiRainState();
}

class _MiuixConfettiRainState extends State<MiuixConfettiRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();
  Timer? _spawnTimer;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_updateParticles);
    _controller.repeat();

    _spawnTimer = Timer.periodic(
      Duration(milliseconds: 1000 ~/ widget.particlesPerSecond),
      (_) => _spawnParticle(),
    );

    // 自动停止
    Future.delayed(widget.duration, () {
      if (mounted) {
        _active = false;
        _spawnTimer?.cancel();
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _controller.stop();
            widget.onComplete?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _spawnParticle() {
    if (!_active || !mounted) return;
    final size = context.size ?? Size.zero;
    _particles.add(_ConfettiParticle(
      x: _random.nextDouble() * size.width,
      y: -20,
      vx: (_random.nextDouble() - 0.5) * 2,
      vy: 1 + _random.nextDouble() * 2,
      color: widget.colors[_random.nextInt(widget.colors.length)],
      size: 4 + _random.nextDouble() * 8,
      rotation: _random.nextDouble() * math.pi * 2,
      rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
      shape: _random.nextInt(3),
    ));
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      for (final p in _particles) {
        p.vy += 0.05;
        p.x += p.vx;
        p.y += p.vy;
        p.rotation += p.rotationSpeed;
      }
      _particles.removeWhere((p) => p.y > 1000);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(particles: _particles),
              ),
            ),
          ),
      ],
    );
  }
}

/// ============================================================
/// MiuixCelebrationOverlay —— 庆祝覆盖层
/// 全屏彩带 + 中心文字，用于任务完成等场景
/// ============================================================
class MiuixCelebrationOverlay extends StatelessWidget {
  const MiuixCelebrationOverlay({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.celebration,
    this.onDismiss,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onDismiss,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: MiuixColors.primaryGradient,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: MiuixColors.primary.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 40),
              ),
              const SizedBox(height: MiuixSpacing.xl),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: MiuixFontSize.xxl,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: MiuixSpacing.sm),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: MiuixFontSize.md,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
