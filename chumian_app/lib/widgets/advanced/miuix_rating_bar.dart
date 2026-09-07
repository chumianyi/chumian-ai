import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixRatingBar —— Miuix 风格评分条
/// 星星/心形评分，半星支持，按压缩放，粉色渐变填充，动画入场
/// ============================================================

/// 评分图标类型
enum MiuixRatingIcon {
  /// 星星
  star,

  /// 心形
  heart,
}

/// Miuix 风格评分条
///
/// 用法：
/// ```dart
/// MiuixRatingBar(
///   initialRating: 3.5,
///   onRatingChanged: (rating) {},
/// )
/// ```
class MiuixRatingBar extends StatefulWidget {
  const MiuixRatingBar({
    super.key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.iconType = MiuixRatingIcon.star,
    this.iconSize = 32,
    this.spacing = 6,
    this.allowHalfRating = true,
    this.readOnly = false,
    this.onRatingChanged,
    this.animate = true,
  });

  /// 初始评分
  final double initialRating;

  /// 最大评分（图标数量）
  final int maxRating;

  /// 图标类型
  final MiuixRatingIcon iconType;

  /// 图标大小
  final double iconSize;

  /// 图标间距
  final double spacing;

  /// 是否允许半星
  final bool allowHalfRating;

  /// 是否只读
  final bool readOnly;

  /// 评分变化回调
  final ValueChanged<double>? onRatingChanged;

  /// 是否启用入场动画
  final bool animate;

  @override
  State<MiuixRatingBar> createState() => _MiuixRatingBarState();
}

class _MiuixRatingBarState extends State<MiuixRatingBar>
    with SingleTickerProviderStateMixin {
  late double _rating;
  double _hoverRating = 0;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: MiuixCurves.miuixSpring,
    );
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateRating(double rating) {
    setState(() => _rating = rating);
    widget.onRatingChanged?.call(rating);
  }

  @override
  Widget build(BuildContext context) {
    final displayRating = _hoverRating > 0 ? _hoverRating : _rating;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.maxRating, (index) {
            final iconValue = index + 1;
            final fillAmount =
                (displayRating - index).clamp(0.0, 1.0) * _animation.value;
            final scale = _hoverRating == iconValue.toDouble() ? 1.15 : 1.0;

            return Padding(
              padding: EdgeInsets.only(
                right: index < widget.maxRating - 1 ? widget.spacing : 0,
              ),
              child: GestureDetector(
                onTapDown: widget.readOnly
                    ? null
                    : (details) {
                        final renderBox =
                            context.findRenderObject() as RenderBox;
                        final localPos = details.globalPosition -
                            renderBox.localToGlobal(Offset.zero);
                        final iconWidth = widget.iconSize + widget.spacing;
                        final tappedIndex =
                            (localPos.dx / iconWidth).floor();
                        final inHalf = widget.allowHalfRating &&
                            (localPos.dx % iconWidth) < iconWidth / 2;
                        final rating =
                            tappedIndex + (inHalf ? 0.5 : 1.0);
                        _updateRating(rating.clamp(0.5, widget.maxRating.toDouble()));
                      },
                onHorizontalDragUpdate: widget.readOnly
                    ? null
                    : (details) {
                        final renderBox =
                            context.findRenderObject() as RenderBox;
                        final localPos = details.localPosition;
                        final iconWidth = widget.iconSize + widget.spacing;
                        final rawRating = localPos.dx / iconWidth;
                        if (widget.allowHalfRating) {
                          final rating =
                              (rawRating * 2).round() / 2;
                          _updateRating(
                              rating.clamp(0.5, widget.maxRating.toDouble()));
                        } else {
                          final rating = rawRating.ceil().toDouble();
                          _updateRating(
                              rating.clamp(1.0, widget.maxRating.toDouble()));
                        }
                      },
                child: AnimatedScale(
                  scale: scale,
                  duration: MiuixDuration.fast,
                  curve: MiuixCurves.miuixSpring,
                  child: _RatingIcon(
                    iconType: widget.iconType,
                    size: widget.iconSize,
                    fillAmount: fillAmount,
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

/// 评分图标（支持半填充）
class _RatingIcon extends StatelessWidget {
  const _RatingIcon({
    required this.iconType,
    required this.size,
    required this.fillAmount,
  });

  final MiuixRatingIcon iconType;
  final double size;
  final double fillAmount;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RatingIconPainter(
        iconType: iconType,
        fillAmount: fillAmount,
      ),
    );
  }
}

class _RatingIconPainter extends CustomPainter {
  _RatingIconPainter({
    required this.iconType,
    required this.fillAmount,
  });

  final MiuixRatingIcon iconType;
  final double fillAmount;

  @override
  void paint(Canvas canvas, Size size) {
    final path = iconType == MiuixRatingIcon.star
        ? _buildStarPath(size)
        : _buildHeartPath(size);

    // 背景（未填充）
    final bgPaint = Paint()
      ..color = MiuixColors.surfaceVariant
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    // 边框
    final borderPaint = Paint()
      ..color = MiuixColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);

    // 填充部分（裁剪）
    if (fillAmount > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(
        0,
        0,
        size.width * fillAmount,
        size.height,
      ));

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: MiuixColors.primaryGradient,
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // 高光
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      final highlightPath = Path()
        ..addOval(Rect.fromLTWH(
          size.width * 0.2,
          size.height * 0.15,
          size.width * 0.25,
          size.height * 0.15,
        ));
      canvas.drawPath(highlightPath, highlightPaint);

      canvas.restore();
    }
  }

  Path _buildStarPath(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.42;
    final path = Path();

    for (int i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
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
    return path;
  }

  Path _buildHeartPath(Size size) {
    final width = size.width;
    final height = size.height;
    final path = Path();

    path.moveTo(width * 0.5, height * 0.85);
    path.cubicTo(
      width * 0.1, height * 0.55,
      width * 0.0, height * 0.3,
      width * 0.25, height * 0.15,
    );
    path.cubicTo(
      width * 0.4, height * 0.05,
      width * 0.5, height * 0.2,
      width * 0.5, height * 0.3,
    );
    path.cubicTo(
      width * 0.5, height * 0.2,
      width * 0.6, height * 0.05,
      width * 0.75, height * 0.15,
    );
    path.cubicTo(
      width * 1.0, height * 0.3,
      width * 0.9, height * 0.55,
      width * 0.5, height * 0.85,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _RatingIconPainter oldDelegate) =>
      oldDelegate.fillAmount != fillAmount;
}
