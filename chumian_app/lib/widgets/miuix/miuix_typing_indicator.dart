import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixTypingIndicator —— AI 输入中动画
/// 三个粉色点依次跳动 + 缩放
/// ============================================================

/// Miuix AI 输入中动画
///
/// 用法：
/// ```dart
/// MiuixTypingIndicator()
/// ```
class MiuixTypingIndicator extends StatefulWidget {
  const MiuixTypingIndicator({
    super.key,
    this.dotCount = 3,
    this.dotSize = 10.0,
    this.dotSpacing = 6.0,
    this.color,
    this.gradient,
    this.bubble = true,
    this.bubbleColor,
    this.duration = const Duration(milliseconds: 1200),
    this.flashText,
  });

  /// 点数量
  final int dotCount;

  /// 点大小
  final double dotSize;

  /// 点间距
  final double dotSpacing;

  /// 颜色
  final Color? color;

  /// 渐变
  final Gradient? gradient;

  /// 是否显示气泡背景
  final bool bubble;

  /// 气泡颜色
  final Color? bubbleColor;

  /// 动画周期
  final Duration duration;

  /// 闪烁文字（如"正在输入..."）
  final String? flashText;

  @override
  State<MiuixTypingIndicator> createState() => _MiuixTypingIndicatorState();
}

class _MiuixTypingIndicatorState extends State<MiuixTypingIndicator>
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
    final Color dotColor = widget.color ?? MiuixColors.primary;

    Widget dots = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.dotCount, (index) {
            // 每个点有不同的相位延迟
            final double phase = index / widget.dotCount;
            final double t =
                ((_controller.value + phase) % 1.0);
            // 正弦跳动
            final double bounce = math.sin(t * math.pi * 2);
            final double translateY = -bounce * widget.dotSize * 0.6;
            final double scale = 0.7 + (bounce + 1) / 2 * 0.5;
            final double opacity = 0.4 + (bounce + 1) / 2 * 0.6;

            return Padding(
              padding: EdgeInsets.only(
                right: index < widget.dotCount - 1
                    ? widget.dotSpacing
                    : 0,
              ),
              child: Transform.translate(
                offset: Offset(0, translateY),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: widget.dotSize,
                      height: widget.dotSize,
                      decoration: BoxDecoration(
                        gradient: widget.gradient ??
                            RadialGradient(
                              colors: [
                                dotColor.withOpacity(0.8),
                                dotColor,
                              ],
                            ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: dotColor.withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );

    if (widget.flashText != null) {
      dots = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dots,
          const SizedBox(width: MiuixSpacing.sm),
          _FlashingText(
            text: widget.flashText!,
            controller: _controller,
            color: dotColor,
          ),
        ],
      );
    }

    if (widget.bubble) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MiuixSpacing.lg,
          vertical: MiuixSpacing.md,
        ),
        decoration: BoxDecoration(
          color: widget.bubbleColor ??
              MiuixColors.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(MiuixRadius.lg),
          border: Border.all(
            color: MiuixColors.primary.withOpacity(0.2),
          ),
        ),
        child: dots,
      );
    }

    return dots;
  }
}

/// 闪烁文字
class _FlashingText extends StatelessWidget {
  const _FlashingText({
    required this.text,
    required this.controller,
    required this.color,
  });

  final String text;
  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double opacity = 0.5 + 0.5 * math.sin(controller.value * 2 * math.pi);
        return Opacity(
          opacity: opacity,
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: MiuixFontSize.sm,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}

/// ============================================================
/// MiuixThinkingIndicator —— AI 思考中动画（旋转花瓣 + 文字）
/// ============================================================

/// AI 思考中指示器
class MiuixThinkingIndicator extends StatefulWidget {
  const MiuixThinkingIndicator({
    super.key,
    this.text = '正在思考...',
    this.size = 32.0,
    this.color,
  });

  final String text;
  final double size;
  final Color? color;

  @override
  State<MiuixThinkingIndicator> createState() => _MiuixThinkingIndicatorState();
}

class _MiuixThinkingIndicatorState extends State<MiuixThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color c = widget.color ?? MiuixColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RotationTransition(
          turns: _controller,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _ThinkingPainter(color: c),
            ),
          ),
        ),
        const SizedBox(width: MiuixSpacing.sm),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final int dots =
                ((_controller.value * 3).floor() % 3) + 1;
            return Text(
              '${widget.text}${'.' * dots}',
              style: TextStyle(
                color: c,
                fontSize: MiuixFontSize.md,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 思考动画绘制器
class _ThinkingPainter extends CustomPainter {
  _ThinkingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width * 0.35;

    for (int i = 0; i < 3; i++) {
      final double angle = i * 2 * math.pi / 3;
      final Offset dotCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final Paint paint = Paint()
        ..color = color.withOpacity(0.4 + 0.6 * (i / 3))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotCenter, size.width * 0.1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThinkingPainter oldDelegate) => false;
}
