/// 底部导航栏（Neumorphism 圆形按钮 + 滑动跟随高亮 + 固定底部）。
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

class _AppNavBarState extends State<AppNavBar> {
  int _hoverIndex = -1;
  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.items.length; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  void _checkHover(Offset globalPosition) {
    final navBox = context.findRenderObject() as RenderBox;
    final local = navBox.globalToLocal(globalPosition);
    for (int i = 0; i < _itemKeys.length; i++) {
      final keyContext = _itemKeys[i].currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox;
        final itemPos = box.localToGlobal(Offset.zero);
        final itemLocal = navBox.globalToLocal(itemPos);
        final itemRect = Rect.fromLTWH(
          itemLocal.dx, itemLocal.dy, box.size.width, box.size.height,
        );
        if (itemRect.contains(local)) {
          if (_hoverIndex != i) {
            setState(() => _hoverIndex = i);
          }
          return;
        }
      }
    }
  }

  void _handlePanEnd() {
    if (_hoverIndex >= 0 && _hoverIndex != widget.currentIndex) {
      widget.onChanged(_hoverIndex);
    }
    setState(() => _hoverIndex = -1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2E35) : const Color(0xFFE8ECF0);

    return Container(
      decoration: BoxDecoration(
        color: baseColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _checkHover(details.globalPosition),
          onPanUpdate: (details) => _checkHover(details.globalPosition),
          onPanEnd: (_) => _handlePanEnd(),
          onPanCancel: () => setState(() => _hoverIndex = -1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(widget.items.length, (index) {
                final item = widget.items[index];
                final isSelected = widget.currentIndex == index;
                final isHovered = _hoverIndex == index;
                final showHighlight = isSelected || isHovered;

                return Expanded(
                  key: _itemKeys[index],
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (index != widget.currentIndex) {
                        widget.onChanged(index);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: baseColor,
                            shape: BoxShape.circle,
                            boxShadow: showHighlight
                                ? (isDark
                                    ? [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(2, 2)),
                                        BoxShadow(color: Colors.white.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(-2, -2)),
                                      ]
                                    : [
                                        BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 6, offset: const Offset(-2, -2)),
                                        BoxShadow(color: const Color(0xFFA3B1C6).withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(2, 2)),
                                      ])
                                : (isDark
                                    ? [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(1, 1)),
                                        BoxShadow(color: Colors.white.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(-1, -1)),
                                      ]
                                    : [
                                        BoxShadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: 4, offset: const Offset(-1, -1)),
                                        BoxShadow(color: const Color(0xFFA3B1C6).withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(1, 1)),
                                      ]),
                          ),
                          child: Icon(
                            showHighlight ? item.activeIcon : item.icon,
                            color: showHighlight ? const Color(0xFFFF6B9D) : context.textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: showHighlight ? FontWeight.w700 : FontWeight.w500,
                            color: showHighlight ? const Color(0xFFFF6B9D) : context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// 胶囊分段控制器。
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
        borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(14),
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
