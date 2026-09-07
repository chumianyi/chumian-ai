import 'dart:math';
import 'package:flutter/material.dart';

/// ============================================================================
/// LoadingAnimations —— 加载动画集合
///
/// 提供粉色旋转花瓣、三点跳动、脉冲圈、进度条、骨架屏动画、
/// 无限滚动等多种加载风格。
/// ============================================================================

/// 粉色旋转花瓣加载动画
class PinkPetalLoading extends StatefulWidget {
  final double size;
  final Duration duration;
  final int petalCount;

  const PinkPetalLoading({
    super.key,
    this.size = 50,
    this.duration = const Duration(milliseconds: 1200),
    this.petalCount = 8,
  });

  @override
  State<PinkPetalLoading> createState() => _PinkPetalLoadingState();
}

class _PinkPetalLoadingState extends State<PinkPetalLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
        return Transform.rotate(
          angle: _controller.value * 2 * pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _PetalPainter(
              petalCount: widget.petalCount,
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

/// 花瓣绘制器
class _PetalPainter extends CustomPainter {
  final int petalCount;
  final double progress;

  _PetalPainter({required this.petalCount, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    for (int i = 0; i < petalCount; i++) {
      final angle = (i / petalCount) * 2 * pi;
      final petalProgress = ((progress + i / petalCount) % 1.0);
      final opacity = (1 - petalProgress).clamp(0.2, 1.0);
      final petalRadius = radius * (0.3 + petalProgress * 0.7);

      final paint = Paint()
        ..color = Color(0xFFFF69B4).withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;

      canvas.drawCircle(Offset(x, y), petalRadius * 0.3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// 三点跳动加载动画
class BouncingDotsLoading extends StatefulWidget {
  final double dotSize;
  final double spacing;
  final Duration duration;
  final Color color;

  const BouncingDotsLoading({
    super.key,
    this.dotSize = 12,
    this.spacing = 8,
    this.duration = const Duration(milliseconds: 1200),
    this.color = const Color(0xFFFF69B4),
  });

  @override
  State<BouncingDotsLoading> createState() => _BouncingDotsLoadingState();
}

class _BouncingDotsLoadingState extends State<BouncingDotsLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.15;
            final t = ((_controller.value + delay) % 1.0);
            final bounce = sin(t * pi) * widget.dotSize;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              child: Transform.translate(
                offset: Offset(0, -bounce),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// 脉冲圈加载动画
class PulseRingLoading extends StatefulWidget {
  final double size;
  final Duration duration;
  final Color color;
  final int ringCount;

  const PulseRingLoading({
    super.key,
    this.size = 60,
    this.duration = const Duration(milliseconds: 1500),
    this.color = const Color(0xFFFF69B4),
    this.ringCount = 3,
  });

  @override
  State<PulseRingLoading> createState() => _PulseRingLoadingState();
}

class _PulseRingLoadingState extends State<PulseRingLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PulseRingPainter(
            progress: _controller.value,
            color: widget.color,
            ringCount: widget.ringCount,
          ),
        );
      },
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int ringCount;

  _PulseRingPainter({
    required this.progress,
    required this.color,
    required this.ringCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < ringCount; i++) {
      final ringProgress = ((progress + i / ringCount) % 1.0);
      final radius = ringProgress * maxRadius;
      final opacity = (1 - ringProgress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }

    // 中心点
    final centerPaint = Paint()..color = color;
    canvas.drawCircle(center, maxRadius * 0.15, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// 渐变进度条
class GradientProgressBar extends StatefulWidget {
  final double value;
  final double height;
  final Duration animationDuration;
  final List<Color> colors;
  final bool showLabel;
  final String? label;

  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.animationDuration = const Duration(milliseconds: 500),
    this.colors = const [Color(0xFFFF69B4), Color(0xFFFFB6C1)],
    this.showLabel = false,
    this.label,
  });

  @override
  State<GradientProgressBar> createState() => _GradientProgressBarState();
}

class _GradientProgressBarState extends State<GradientProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() {
        setState(() => _currentValue = _animation.value);
      });
    _controller.forward();
  }

  @override
  void didUpdateWidget(GradientProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _currentValue,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      )..addListener(() {
          setState(() => _currentValue = _animation.value);
        });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              widget.label ?? '${(_currentValue * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth *
                      _currentValue.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: widget.colors),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 骨架屏动画
class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final Duration duration;
  final BorderRadius? borderRadius;
  final Color baseColor;
  final Color highlightColor;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.duration = const Duration(milliseconds: 1500),
    this.borderRadius,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// 骨架屏列表
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 70,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == itemCount - 1 ? 0 : spacing),
          child: Row(
            children: [
              SkeletonLoading(
                width: itemHeight,
                height: itemHeight,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoading(
                      width: double.infinity,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoading(
                      width: 150,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// 无限滚动加载条
class InfiniteScrollLoading extends StatefulWidget {
  final double height;
  final Duration duration;
  final Color color;

  const InfiniteScrollLoading({
    super.key,
    this.height = 4,
    this.duration = const Duration(milliseconds: 1000),
    this.color = const Color(0xFFFF69B4),
  });

  @override
  State<InfiniteScrollLoading> createState() => _InfiniteScrollLoadingState();
}

class _InfiniteScrollLoadingState extends State<InfiniteScrollLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
        return SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth * 0.3;
              final maxTranslate = constraints.maxWidth - barWidth;
              final position = _controller.value * maxTranslate * 2;
              final x = position < maxTranslate
                  ? position
                  : maxTranslate * 2 - position;
              return Stack(
                children: [
                  Container(
                    height: widget.height,
                    color: widget.color.withOpacity(0.2),
                  ),
                  Transform.translate(
                    offset: Offset(x, 0),
                    child: Container(
                      width: barWidth,
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(widget.height / 2),
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
}

/// 通用加载指示器（根据类型选择动画）
class AppLoadingIndicator extends StatelessWidget {
  final LoadingStyle style;
  final double size;
  final String? text;

  const AppLoadingIndicator({
    super.key,
    this.style = LoadingStyle.petal,
    this.size = 50,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    Widget indicator;
    switch (style) {
      case LoadingStyle.petal:
        indicator = PinkPetalLoading(size: size);
        break;
      case LoadingStyle.dots:
        indicator = BouncingDotsLoading(dotSize: size / 4);
        break;
      case LoadingStyle.pulse:
        indicator = PulseRingLoading(size: size);
        break;
      case LoadingStyle.circular:
        indicator = SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFFFF69B4)),
          ),
        );
        break;
      case LoadingStyle.infinite:
        indicator = InfiniteScrollLoading(height: size / 10);
        break;
    }

    if (text != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 12),
          Text(
            text!,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      );
    }
    return indicator;
  }
}

/// 加载风格枚举
enum LoadingStyle {
  petal,
  dots,
  pulse,
  circular,
  infinite,
}
