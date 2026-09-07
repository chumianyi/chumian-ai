import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// Miuix3DCard —— Miuix 风格 3D 卡片
/// 倾斜手势检测，3D 透视变换，高光跟随，粉色阴影，按压缩放
/// ============================================================

/// Miuix 风格 3D 卡片
///
/// 用法：
/// ```dart
/// Miuix3DCard(
///   child: Container(width: 200, height: 280, color: Colors.pink),
/// )
/// ```
class Miuix3DCard extends StatefulWidget {
  const Miuix3DCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.maxTilt = 0.3,
    this.perspective = 0.002,
    this.enableGlare = true,
    this.onTap,
  });

  /// 卡片内容
  final Widget child;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 最大倾斜角度（弧度）
  final double maxTilt;

  /// 透视强度
  final double perspective;

  /// 是否启用高光跟随
  final bool enableGlare;

  /// 点击回调
  final VoidCallback? onTap;

  @override
  State<Miuix3DCard> createState() => _Miuix3DCardState();
}

class _Miuix3DCardState extends State<Miuix3DCard>
    with SingleTickerProviderStateMixin {
  Offset _tilt = Offset.zero;
  Offset _glarePosition = Offset.zero;
  bool _isPressed = false;
  late final AnimationController _pressController;
  late final Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: MiuixDuration.fast,
      reverseDuration: MiuixDuration.elastic,
    );
    _pressAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.94)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.0)
            .chain(CurveTween(curve: MiuixCurves.miuixSpring)),
        weight: 70,
      ),
    ]).animate(_pressController);
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = (details.localPosition.dx - center.dx) / (size.width / 2);
    final dy = (details.localPosition.dy - center.dy) / (size.height / 2);
    setState(() {
      _tilt = Offset(
        dx.clamp(-1.0, 1.0) * widget.maxTilt,
        (-dy).clamp(-1.0, 1.0) * widget.maxTilt,
      );
      _glarePosition = Offset(
        (details.localPosition.dx / size.width).clamp(0.0, 1.0),
        (details.localPosition.dy / size.height).clamp(0.0, 1.0),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _tilt = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _pressController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _pressController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _pressController.reverse();
      },
      onPanUpdate: (details) {
        final size = context.size ?? Size.zero;
        _onPanUpdate(details, size);
      },
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, widget.perspective)
              ..rotateX(_tilt.dy)
              ..rotateY(_tilt.dx)
              ..scale(_pressAnimation.value),
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: MiuixDuration.fast,
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MiuixRadius.xl),
            boxShadow: [
              BoxShadow(
                color: MiuixColors.primary.withOpacity(0.3),
                blurRadius: _isPressed ? 12 : 24,
                offset: Offset(
                  -_tilt.dx * 20,
                  -_tilt.dy * 20 + 8,
                ),
                spreadRadius: _isPressed ? 0 : 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MiuixRadius.xl),
            child: Stack(
              children: [
                widget.child,
                // 高光跟随
                if (widget.enableGlare)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: MiuixDuration.fast,
                        opacity: _isPressed ? 0.6 : 0.35,
                        child: CustomPaint(
                          painter: _GlarePainter(
                            position: _glarePosition,
                          ),
                        ),
                      ),
                    ),
                  ),
                // 边框高光
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(MiuixRadius.xl),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 高光绘制器
class _GlarePainter extends CustomPainter {
  _GlarePainter({required this.position});

  final Offset position;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      position.dx * size.width,
      position.dy * size.height,
    );
    final radius = math.max(size.width, size.height) * 0.6;

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (position.dx - 0.5) * 2,
          (position.dy - 0.5) * 2,
        ),
        radius: 0.6,
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GlarePainter oldDelegate) =>
      oldDelegate.position != position;
}

/// ============================================================
/// Miuix3DCarousel —— 3D 卡片轮播
/// 多张 3D 卡片横向排列，中间卡片最大，两侧缩小
/// ============================================================
class Miuix3DCarousel extends StatefulWidget {
  const Miuix3DCarousel({
    super.key,
    required this.children,
    this.cardWidth = 240,
    this.cardHeight = 320,
    this.viewportFraction = 0.7,
    this.onPageChanged,
  });

  final List<Widget> children;
  final double cardWidth;
  final double cardHeight;
  final double viewportFraction;
  final ValueChanged<int>? onPageChanged;

  @override
  State<Miuix3DCarousel> createState() => _Miuix3DCarouselState();
}

class _Miuix3DCarouselState extends State<Miuix3DCarousel> {
  late final PageController _controller;
  int _currentPage = 0;
  double _pageOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: widget.viewportFraction,
    );
    _controller.addListener(() {
      setState(() => _pageOffset = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.cardHeight,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.children.length,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
          widget.onPageChanged?.call(index);
        },
        itemBuilder: (context, index) {
          final diff = _pageOffset - index;
          final scale = (1 - diff.abs() * 0.15).clamp(0.7, 1.0);
          final rotateY = diff * 0.3;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(rotateY)
              ..scale(scale),
            child: Container(
              width: widget.cardWidth,
              margin: const EdgeInsets.symmetric(horizontal: MiuixSpacing.sm),
              child: widget.children[index],
            ),
          );
        },
      ),
    );
  }
}

/// ============================================================
/// MiuixTiltDetector —— 倾斜检测包装器
/// 检测手指位置并提供倾斜角度，可用于任意组件
/// ============================================================
class MiuixTiltDetector extends StatefulWidget {
  const MiuixTiltDetector({
    super.key,
    required this.child,
    this.maxTilt = 0.2,
    this.onTiltChanged,
  });

  final Widget child;
  final double maxTilt;
  final ValueChanged<Offset>? onTiltChanged;

  @override
  State<MiuixTiltDetector> createState() => _MiuixTiltDetectorState();
}

class _MiuixTiltDetectorState extends State<MiuixTiltDetector> {
  Offset _tilt = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final size = context.size ?? Size.zero;
        final center = Offset(size.width / 2, size.height / 2);
        final dx = (details.localPosition.dx - center.dx) /
            (size.width / 2);
        final dy = (details.localPosition.dy - center.dy) /
            (size.height / 2);
        setState(() {
          _tilt = Offset(
            dx.clamp(-1.0, 1.0) * widget.maxTilt,
            (-dy).clamp(-1.0, 1.0) * widget.maxTilt,
          );
        });
        widget.onTiltChanged?.call(_tilt);
      },
      onPanEnd: (_) => setState(() => _tilt = Offset.zero),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateX(_tilt.dy)
          ..rotateY(_tilt.dx),
        child: widget.child,
      ),
    );
  }
}
