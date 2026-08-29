/// 底部导航栏组件（胶囊高亮 + 动效标签）。
library;

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

/// 自绘胶囊底部导航。
class AppNavBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: context.surface,
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = currentIndex == index;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 18 : 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? context.onPrimary : context.textSecondary,
                      size: 22,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: SizedBox(
                      height: isSelected ? 20 : 0,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? context.primary
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surfaceSubtle,
        borderRadius: BorderRadius.circular(999),
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
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
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
