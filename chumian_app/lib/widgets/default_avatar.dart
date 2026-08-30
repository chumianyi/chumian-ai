import 'package:flutter/material.dart';

/// 默认头像：圆形头 + 半圆身体的人物剪影，类似抖音初始头像
class DefaultAvatar extends StatelessWidget {
  final double size;
  final Color? color;
  const DefaultAvatar({super.key, this.size = 64, this.color});

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15);
    final fg = color ?? Theme.of(context).colorScheme.primary;
    return CustomPaint(
      size: Size(size, size),
      painter: _DefaultAvatarPainter(bgColor: bg, fgColor: fg),
    );
  }
}

class _DefaultAvatarPainter extends CustomPainter {
  final Color bgColor;
  final Color fgColor;
  _DefaultAvatarPainter({required this.bgColor, required this.fgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 背景圆
    final bgPaint = Paint()..color = bgColor;
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, bgPaint);

    // 头（圆形）
    final headRadius = w * 0.18;
    final headCenter = Offset(w / 2, h * 0.38);
    final fgPaint = Paint()..color = fgColor;
    canvas.drawCircle(headCenter, headRadius, fgPaint);

    // 身体（半圆/弧形，从底部向上的圆弧）
    final bodyRect = Rect.fromLTWH(
      w * 0.22,
      h * 0.55,
      w * 0.56,
      h * 0.5,
    );
    canvas.drawArc(
      bodyRect,
      3.14159, // 从左侧开始（180度）
      3.14159, // 画180度（半圆）
      true,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
