/// 高级圆形底部导航栏：圆形按钮 + 360°旋转 + 滑动跟随变色 + 淡粉色波纹散开特效。
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'context_ext.dart';

/// 导航项配置。
class NavItemSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const NavItemSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// 波纹粒子数据。
class _Ripple {
  final Offset center;
  final double maxRadius;
  final int particleCount;
  final List<double> angles;
  final List<double> speeds;
  double progress = 0.0;

  _Ripple({required this.center, required this.maxRadius, this.particleCount = 8})
      : angles = List.generate(particleCount, (i) => (2 * pi * i) / particleCount + Random().nextDouble() * 0.5),
        speeds = List.generate(particleCount, (i) => 0.6 + Random().nextDouble() * 0.6);
}

/// 自绘圆形导航栏。
class AppNavBar extends StatefulWidget {
  final List<NavItemSpec> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const AppNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  State<AppNavBar> createState() => _AppNavBarState();
}

class _AppNavBarState extends State<AppNavBar> with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _rippleController;
  int _rotatingIndex = -1;
  int _hoverIndex = -1;
  final List<_Ripple> _ripples = [];
  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        for (final r in _ripples) {
          r.progress = _rippleController.value;
        }
        if (mounted) setState(() {});
      });
    for (var i = 0; i < widget.items.length; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index == widget.currentIndex && _rotatingIndex == -1) return;
    setState(() => _rotatingIndex = index);
    _rotationController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _rotatingIndex = -1);
      }
    });
    // 触发波纹特效
    final keyContext = _itemKeys[index].currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final center = box.localToGlobal(Offset.zero) +
          Offset(box.size.width / 2, box.size.height / 2);
      final navBox = context.findRenderObject() as RenderBox;
      final localCenter = navBox.globalToLocal(center);
      _ripples.add(_Ripple(center: localCenter, maxRadius: 60));
      _rippleController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() => _ripples.clear());
        }
      });
    }
    widget.onChanged(index);
  }

  int _findIndexAtPosition(Offset globalPosition) {
    for (var i = 0; i < _itemKeys.length; i++) {
      final ctx = _itemKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox;
      final local = box.globalToLocal(globalPosition);
      if (local.dx >= -10 &&
          local.dx <= box.size.width + 10 &&
          local.dy >= -10 &&
          local.dy <= box.size.height + 10) {
        return i;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final itemSize = 44.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (details) {
        final idx = _findIndexAtPosition(details.globalPosition);
        if (idx != -1 && idx != _hoverIndex) {
          setState(() => _hoverIndex = idx);
        }
      },
      onPanEnd: (_) {
        if (_hoverIndex != -1 && _hoverIndex != widget.currentIndex) {
          _handleTap(_hoverIndex);
        }
        setState(() => _hoverIndex = -1);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: const ColorFilter.matrix([
              1, 0, 0, 0, 0,
              0, 1, 0, 0, 0,
              0, 0, 1, 0, 0,
              0, 0, 0, 0.75, 0,
            ]),
            child: Container(
              decoration: BoxDecoration(
                color: context.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: context.divider.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: SafeArea(
                top: false,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 波纹特效层
                    if (_ripples.isNotEmpty)
                      CustomPaint(
                        size: Size.infinite,
                        painter: _RipplePainter(ripples: _ripples),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(widget.items.length, (index) {
                        final item = widget.items[index];
                        final isSelected = widget.currentIndex == index;
                        final isHover = _hoverIndex == index;
                        final isRotating = _rotatingIndex == index;
                        final showPink = isSelected || isHover || isRotating;

                        return GestureDetector(
                          key: _itemKeys[index],
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _handleTap(index),
                          child: SizedBox(
                            width: itemSize + 8,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedBuilder(
                                  animation: _rotationController,
                                  builder: (context, child) {
                                    final turns = isRotating
                                        ? _rotationController.value
                                        : 0.0;
                                    return Transform.rotate(
                                      angle: turns * 2 * pi,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        curve: Curves.easeOutCubic,
                                        width: itemSize,
                                        height: itemSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: showPink
                                              ? const Color(0xFFFF6B9D)
                                              : context.surfaceElevated,
                                          boxShadow: showPink
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(0xFFFF6B9D)
                                                        .withValues(alpha: 0.35),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Icon(
                                          showPink ? item.activeIcon : item.icon,
                                          color: showPink
                                              ? Colors.white
                                              : context.textSecondary,
                                          size: 20,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 200),
                                  child: SizedBox(
                                    height: isSelected ? 14 : 0,
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFFFF6B9D)
                                            : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 淡粉色波纹粒子绘制器。
class _RipplePainter extends CustomPainter {
  final List<_Ripple> ripples;
  _RipplePainter({required this.ripples});

  @override
  void paint(Canvas canvas, Size size) {
    for (final ripple in ripples) {
      final t = ripple.progress;
      final ease = 1 - pow(1 - t, 3).toDouble();
      // 中心扩散圆环
      final ringPaint = Paint()
        ..color = const Color(0xFFFF6B9D).withValues(alpha: 0.18 * (1 - t))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(
        ripple.center,
        10 + ease * (ripple.maxRadius - 10),
        ringPaint,
      );
      // 外围粒子
      for (var i = 0; i < ripple.particleCount; i++) {
        final angle = ripple.angles[i];
        final speed = ripple.speeds[i];
        final dist = 15 + ease * ripple.maxRadius * speed;
        final px = ripple.center.dx + cos(angle) * dist;
        final py = ripple.center.dy + sin(angle) * dist;
        final particlePaint = Paint()
          ..color = const Color(0xFFFFB3C6).withValues(alpha: 0.35 * (1 - t))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(px, py), 2.5 * (1 - t * 0.5), particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => true;
}

/// 胶囊分段控制器（TDesign 风格）。
class PillSegment extends StatelessWidget {
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;
  const PillSegment({
    super.key,
    required this.options,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final selected = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? context.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  options[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? context.primary : context.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
