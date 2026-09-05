import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'chat_page.dart';
import 'creative_page.dart';
import 'explore_page.dart';
import 'activity_page.dart';
import 'profile_page.dart';
import 'model_store_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _navCtrl;

  final List<Widget> _pages = const [
    ChatPage(),
    CreativePage(),
    ExplorePage(),
    ModelStorePage(),
    ActivityPage(),
    ProfilePage(),
  ];

  final List<IconData> _icons = [
    Icons.chat_bubble_outline,
    Icons.auto_awesome,
    Icons.explore_outlined,
    Icons.store_outlined,
    Icons.sports_esports_outlined,
    Icons.person_outline,
  ];

  final List<String> _labels = ['对话', '创作', '发现', '模型商店', '活动', '我的'];

  @override
  void initState() {
    super.initState();
    _navCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _navCtrl.forward();
  }

  @override
  void dispose() {
    _navCtrl.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _navCtrl.reset();
    _navCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, anim) {
            final scaleAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.elasticOut),
            );
            final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: const Interval(0.0, 0.5)),
            );
            return FadeTransition(
              opacity: fadeAnim,
              child: ScaleTransition(scale: scaleAnim, child: child),
            );
          },
          child: KeyedSubtree(key: ValueKey<int>(_currentIndex), child: _pages[_currentIndex]),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, -4))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_icons.length, (i) => _buildNavItem(i)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              child: Icon(_icons[index], color: isSelected ? AppColors.primary : AppColors.textTertiary, size: 24),
            ),
            const SizedBox(height: 2),
            Text(_labels[index], style: TextStyle(fontSize: 11, color: isSelected ? AppColors.primary : AppColors.textTertiary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontFamily: 'LXGW WenKai')),
          ],
        ),
      ),
    );
  }
}
