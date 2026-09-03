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
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        final now = DateTime.now().millisecondsSinceEpoch;
        _ripples.removeWhere((r) => now - r.startTime > 450);
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
      startTime: DateTime.now().millisecondsSinceEpoch,
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
                painter: _GlobalRipplePainter(ripples: _ripples),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlobalRipplePainter extends CustomPainter {
  final List<_RippleData> ripples;
  _GlobalRipplePainter({required this.ripples});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final ripple in ripples) {
      final elapsed = (now - ripple.startTime) / 450.0;
      if (elapsed > 1.0) continue;
      final ease = 1 - pow(1 - elapsed, 3).toDouble();
      // Outer ring
      final ringPaint = Paint()
        ..color = const Color(0xFFFF6B9D).withValues(alpha: 0.18 * (1 - elapsed))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(ripple.position, 6 + ease * 55, ringPaint);
      // Inner fill
      final fillPaint = Paint()
        ..color = const Color(0xFFFFB3C6).withValues(alpha: 0.08 * (1 - elapsed))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(ripple.position, 3 + ease * 35, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlobalRipplePainter oldDelegate) => true;
}
