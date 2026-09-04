/// 全局点击水面荡漾特效：多层圆环向外扩散，模拟水面涟漪。
library;

import 'dart:math';
import 'package:flutter/material.dart';

class _RippleData {
  final Offset position;
  final double startTime;
  _RippleData({required this.position, required this.startTime});
}

class GlobalRipple extends StatefulWidget {
  final Widget child;
  const GlobalRipple({super.key, required this.child});

  @override
  State<GlobalRipple> createState() => _GlobalRippleState();
}

class _GlobalRippleState extends State<GlobalRipple> with SingleTickerProviderStateMixin {
  final List<_RippleData> _ripples = [];
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(() {
        final now = DateTime.now().millisecondsSinceEpoch.toDouble();
        _ripples.removeWhere((r) => now - r.startTime > 750);
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addRipple(Offset position) {
    _ripples.add(_RippleData(
      position: position,
      startTime: DateTime.now().millisecondsSinceEpoch.toDouble(),
    ));
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _addRipple(event.localPosition),
      child: Stack(
        children: [
          widget.child,
          if (_ripples.isNotEmpty)
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: _WaterRipplePainter(ripples: _ripples),
              ),
            ),
        ],
      ),
    );
  }
}

class _WaterRipplePainter extends CustomPainter {
  final List<_RippleData> ripples;
  _WaterRipplePainter({required this.ripples});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    for (final ripple in ripples) {
      final elapsed = (now - ripple.startTime) / 700.0;
      if (elapsed > 1.0) continue;
      // 多层圆环模拟水面涟漪（3层，不同延迟）
      for (int layer = 0; layer < 3; layer++) {
        final layerDelay = layer * 0.12;
        final t = (elapsed - layerDelay) / (1.0 - layerDelay);
        if (t <= 0 || t > 1) continue;
        final ease = Curves.easeOutCubic.transform(t);
        final radius = 8.0 + ease * 70.0;
        final alpha = 0.12 * (1 - t) * (1 - layer * 0.25);
        final paint = Paint()
          ..color = const Color(0xFFFF6B9D).withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 - layer * 0.3;
        canvas.drawCircle(ripple.position, radius, paint);
      }
      // 中心点微光
      final centerAlpha = 0.08 * (1 - elapsed);
      if (centerAlpha > 0) {
        final centerPaint = Paint()
          ..color = const Color(0xFFFFB3C6).withValues(alpha: centerAlpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(ripple.position, 4 + elapsed * 15, centerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaterRipplePainter oldDelegate) => true;
}
