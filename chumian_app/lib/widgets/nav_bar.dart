/// 底部导航栏（默认样式：图标+文字，选中粉色高亮，毛玻璃背景，点击波纹特效）。
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'context_ext.dart';

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

class _Ripple {
  final Offset center;
  double progress = 0.0;
  _Ripple({required this.center});
}

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
  late final AnimationController _rippleController;
  final List<_Ripple> _ripples = [];
  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
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
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    final keyContext = _itemKeys[index].currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final center = box.localToGlobal(Offset.zero) +
          Offset(box.size.width / 2, box.size.height / 2);
      final navBox = context.findRenderObject() as RenderBox;
      final localCenter = navBox.globalToLocal(center);
      _ripples.add(_Ripple(center: localCenter));
      _rippleController.forward(from: 0).then((_) {
        if (mounted) setState(() => _ripples.clear());
      });
    }
    widget.onChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: const ColorFilter.matrix([
            1, 0, 0, 0, 0,
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            0, 0, 0, 0.8, 0,
          ]),
          child: Container(
            decoration: BoxDecoration(
              color: context.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.divider.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: SafeArea(
              top: false,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
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
                      return Expanded(
                        child: GestureDetector(
                          key: _itemKeys[index],
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _handleTap(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFF6B9D).withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    color: isSelected
                                        ? const Color(0xFFFF6B9D)
                                        : context.textSecondary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFFFF6B9D)
                                        : context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }
}

class _RipplePainter extends CustomPainter {
  final List<_Ripple> ripples;
  _RipplePainter({required this.ripples});

  @override
  void paint(Canvas canvas, Size size) {
    for (final ripple in ripples) {
      final t = ripple.progress;
      final ease = 1 - pow(1 - t, 3).toDouble();
      final paint = Paint()
        ..color = const Color(0xFFFF6B9D).withValues(alpha: 0.2 * (1 - t))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(ripple.center, 8 + ease * 50, paint);
      final fillPaint = Paint()
        ..color = const Color(0xFFFFB3C6).withValues(alpha: 0.1 * (1 - t))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(ripple.center, 4 + ease * 30, fillPaint);
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
