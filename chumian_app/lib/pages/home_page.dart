import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'creative_page.dart';
import 'explore_page.dart';
import 'activity_page.dart';
import 'points_page.dart';
import 'profile_page.dart';
import '../theme.dart';

class HomePage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const HomePage({super.key, required this.themeProvider});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: '对话'),
    _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: '创意'),
    _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: '探索'),
    _NavItem(icon: Icons.local_activity_outlined, activeIcon: Icons.local_activity, label: '活动'),
    _NavItem(icon: Icons.stars_outlined, activeIcon: Icons.stars, label: '积分'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final tp = widget.themeProvider;
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const ChatPage(),
          const CreativePage(),
          const ExplorePage(),
          const ActivityPage(),
          const PointsPage(),
          ProfilePage(themeProvider: tp),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: tp.surfaceColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _currentIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() => _currentIndex = index);
                  _pageController.jumpToPage(index);
                },
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: isSelected ? 18 : 12, vertical: 10),
                    decoration: BoxDecoration(color: isSelected ? tp.primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(30)),
                    child: Icon(isSelected ? item.activeIcon : item.icon, color: isSelected ? Colors.white : tp.textSecondary, size: 22),
                  ),
                  AnimatedSize(duration: const Duration(milliseconds: 200), child: SizedBox(height: isSelected ? 20 : 0, child: Center(child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(item.label, style: TextStyle(fontSize: 11, color: isSelected ? tp.primaryColor : Colors.transparent, fontWeight: FontWeight.w500)))))),
                ]),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  _NavItem({required this.icon, required this.activeIcon, required this.label});
}
