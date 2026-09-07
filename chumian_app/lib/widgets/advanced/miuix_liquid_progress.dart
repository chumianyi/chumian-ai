import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixLiquidProgress —— Miuix 风格液态进度
/// 波浪液面动画，粉色半透明液体，上升下降，气泡效果
/// ============================================================

/// Miuix 风格液态进度
///
/// 用法：
/// ```dart
/// MiuixLiquidProgress(
///   value: 0.65,
///   size: 160,
/// )
/// ```
class MiuixLiquidProgress extends StatefulWidget {
  const MiuixLiquidProgress({
    super.key,
    required this.value,
    this.size = 160,
    this.color,
    this.backgroundColor,
    this.showBubbles = true,
    this.showValue = true,
    this.borderWidth = 4,
    this.animate = true,
  });

  /// 进度值（0-1）
  final double value;

  /// 尺寸
  final double size;

  /// 液体颜色
  final Color? color;

  /// 背景色
  final Color? backgroundColor;

  /// 是否显示气泡
  final bool showBubbles;

  /// 是否显示中心数值
  final bool showValue;

  /// 边框宽度
  final double borderWidth;

  /// 是否启用动画
  final bool animate;

  @override
  State<MiuixLiquidProgress> createState() => _MiuixLiquidProgressState();
}

class _MiuixLiquidProgressState extends State<MiuixLiquidProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _riseController;
  late final Animation<double> _riseAnimation;
  double _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _riseAnimation = CurvedAnimation(
      parent: _riseController,
      curve: MiuixCurves.miuixSpring,
    );
    _displayValue = widget.animate ? 0 : widget.value;
    if (widget.animate) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _riseController.forward());
    }
  }

  @override
  void didUpdateWidget(MiuixLiquidProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _riseController.reset();
      _riseController.forward();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _riseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _riseAnimation]),
      builder: (context, child) {
        final animatedValue = widget.animate
            ? widget.value * _riseAnimation.value
            : widget.value;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _LiquidPainter(
            value: animatedValue,
            waveProgress: _waveController.value,
            color: widget.color ?? MiuixColors.primary,
            backgroundColor:
                widget.backgroundColor ?? MiuixColors.surfaceVariant,
            showBubbles: widget.showBubbles,
            borderWidth: widget.borderWidth,
          ),
          child: widget.showValue
              ? Center(
                  child: Text(
                    '${(animatedValue * 100).toInt()}%',
                    style: TextStyle(
                      color: animatedValue > 0.5
                          ? Colors.white
                          : MiuixColors.textPrimary,
                      fontSize: widget.size * 0.18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

/// 液态进度绘制器
class _LiquidPainter extends CustomPainter {
  _LiquidPainter({
    required this.value,
    required this.waveProgress,
    required this.color,
    required this.backgroundColor,
    required this.showBubbles,
    required this.borderWidth,
  });

  final double value;
  final double waveProgress;
  final Color color;
  final Color backgroundColor;
  final bool showBubbles;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - borderWidth;

    // 裁剪圆形区域
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    // 背景
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawCircle(center, radius, bgPaint);

    // 液体
    final liquidHeight = size.height * value;
    final liquidTop = size.height - liquidHeight;

    // 波浪路径
    final wavePath = Path();
    wavePath.moveTo(0, liquidTop);

    final waveAmplitude = 6.0;
    final waveFrequency = 2 * math.pi / size.width;
    final waveOffset = waveProgress * 2 * math.pi;

    for (double x = 0; x <= size.width; x += 2) {
      final y = liquidTop +
          math.sin(x * waveFrequency + waveOffset) * waveAmplitude +
          math.sin(x * waveFrequency * 2 + waveOffset * 1.5) *
              waveAmplitude *
              0.5;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    // 液体渐变
    final liquidPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.6),
          color.withOpacity(0.85),
        ],
      ).createShader(Rect.fromLTWH(0, liquidTop, size.width, liquidHeight));
    canvas.drawPath(wavePath, liquidPaint);

    // 第二层波浪（更浅）
    final wavePath2 = Path();
    wavePath2.moveTo(0, liquidTop + 4);
    for (double x = 0; x <= size.width; x += 2) {
      final y = liquidTop +
          4 +
          math.sin(x * waveFrequency * 1.5 + waveOffset + 1) *
              waveAmplitude *
              0.7;
      wavePath2.lineTo(x, y);
    }
    wavePath2.lineTo(size.width, size.height);
    wavePath2.lineTo(0, size.height);
    wavePath2.close();

    final liquidPaint2 = Paint()
      ..color = color.withOpacity(0.3);
    canvas.drawPath(wavePath2, liquidPaint2);

    // 气泡
    if (showBubbles && value > 0.1) {
      final random = math.Random(42);
      for (int i = 0; i < 8; i++) {
        final bubbleX =
            (random.nextDouble() * size.width);
        final bubbleBaseY =
            size.height - random.nextDouble() * liquidHeight * 0.8;
        final bubbleY = bubbleBaseY -
            (waveProgress * 50 % (liquidHeight * 0.8));
        final bubbleRadius = 2 + random.nextDouble() * 4;
        final bubbleOpacity =
            0.2 + random.nextDouble() * 0.3;

        final bubblePaint = Paint()
          ..color = Colors.white.withOpacity(bubbleOpacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(bubbleX, bubbleY),
          bubbleRadius,
          bubblePaint,
        );
      }
    }

    canvas.restore();

    // 外边框
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawCircle(center, radius + borderWidth / 2, borderPaint);

    // 边框光晕
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius + borderWidth / 2, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.waveProgress != waveProgress;
}

/// ============================================================
/// MiuixLiquidButton —— 液态填充按钮
/// 按下时液体从底部填充，粉色波浪效果
/// ============================================================
class MiuixLiquidButton extends StatefulWidget {
  const MiuixLiquidButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 200,
    this.height = 52,
    this.color = MiuixColors.primary,
  });

  final String label;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final Color color;

  @override
  State<MiuixLiquidButton> createState() => _MiuixLiquidButtonState();
}

class _MiuixLiquidButtonState extends State<MiuixLiquidButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fillController;
  late final AnimationController _waveController;
  double _fillLevel = 0;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _fillController.addListener(() {
      setState(() => _fillLevel = _fillController.value);
    });
  }

  @override
  void dispose() {
    _fillController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _fillController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _fillController.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _fillController.reverse();
      },
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: MiuixColors.surface,
              borderRadius: BorderRadius.circular(MiuixRadius.pill),
              border: Border.all(color: widget.color, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MiuixRadius.pill),
              child: Stack(
                children: [
                  // 液体填充
                  CustomPaint(
                    size: Size(widget.width, widget.height),
                    painter: _LiquidFillPainter(
                      fillLevel: _fillLevel,
                      waveProgress: _waveController.value,
                      color: widget.color,
                    ),
                  ),
                  // 文字
                  Center(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: _fillLevel > 0.5 ? Colors.white : widget.color,
                        fontSize: MiuixFontSize.md,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 液态填充绘制器
class _LiquidFillPainter extends CustomPainter {
  _LiquidFillPainter({
    required this.fillLevel,
    required this.waveProgress,
    required this.color,
  });

  final double fillLevel;
  final double waveProgress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (fillLevel <= 0) return;
    final liquidHeight = size.height * fillLevel;
    final liquidTop = size.height - liquidHeight;

    final path = Path();
    path.moveTo(0, liquidTop);
    for (double x = 0; x <= size.width; x += 2) {
      final y = liquidTop +
          math.sin(x * 0.05 + waveProgress * math.pi * 2) * 3;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.7), color],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidFillPainter oldDelegate) =>
      oldDelegate.fillLevel != fillLevel ||
      oldDelegate.waveProgress != waveProgress;
}

/// ============================================================
/// MiuixWaveLoading —— 波浪加载动画
/// 三个粉色波浪依次起伏
/// ============================================================
class MiuixWaveLoading extends StatefulWidget {
  const MiuixWaveLoading({
    super.key,
    this.size = 40,
    this.color = MiuixColors.primary,
  });

  final double size;
  final Color color;

  @override
  State<MiuixWaveLoading> createState() => _MiuixWaveLoadingState();
}

class _MiuixWaveLoadingState extends State<MiuixWaveLoading>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size * 0.6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              final delay = index * 0.15;
              final wave = math.sin(
                    (_controller.value + delay) * math.pi * 2,
                  ) *
                  0.5 +
                  0.5;
              final barHeight = widget.size * 0.2 + wave * widget.size * 0.4;
              return Container(
                width: widget.size * 0.15,
                height: barHeight,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.size * 0.08),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
