import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'creative_page.dart';
import 'explore_page.dart';
import 'activity_page.dart';
import 'points_page.dart';
import 'profile_page.dart';
import '../theme.dart';
import '../widgets/nav_bar.dart';

class HomePage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const HomePage({super.key, required this.themeProvider});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const List<NavItemSpec> _navItems = [
    NavItemSpec(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: '对话'),
    NavItemSpec(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: '创意'),
    NavItemSpec(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: '探索'),
    NavItemSpec(icon: Icons.local_activity_outlined, activeIcon: Icons.local_activity, label: '活动'),
    NavItemSpec(icon: Icons.stars_outlined, activeIcon: Icons.stars, label: '积分'),
    NavItemSpec(icon: Icons.person_outline, activeIcon: Icons.person, label: '我的'),
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const ChatPage(),
      const CreativePage(),
      const ExplorePage(),
      const ActivityPage(),
      const PointsPage(),
      ProfilePage(themeProvider: widget.themeProvider),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeProvider,
      builder: (context, _) {
        if (widget.themeProvider.fullscreenLayout) {
          return _buildFullscreenLayout();
        }
        return _buildDefaultLayout();
      },
    );
  }

  Widget _buildDefaultLayout() {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onChanged: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  Widget _buildFullscreenLayout() {
    final drawerItems = [
      _DrawerItem(icon: Icons.chat_bubble_outline, label: '对话', index: 0),
      _DrawerItem(icon: Icons.auto_awesome_outlined, label: '创意', index: 1),
      _DrawerItem(icon: Icons.explore_outlined, label: '探索', index: 2),
      _DrawerItem(icon: Icons.local_activity_outlined, label: '活动', index: 3),
      _DrawerItem(icon: Icons.stars_outlined, label: '积分', index: 4),
    ];

    return Scaffold(
      drawer: Drawer(
        width: 240,
        child: Container(
          decoration: BoxDecoration(
            color: widget.themeProvider.surfaceColor,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: widget.themeProvider.primaryGradient,
                    borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
                        child: const Icon(Icons.smart_toy, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text('初眠AI', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('全屏主题模式', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: drawerItems.length,
                    itemBuilder: (_, i) {
                      final item = drawerItems[i];
                      final selected = _currentIndex == item.index;
                      return ListTile(
                        leading: Icon(item.icon, color: selected ? widget.themeProvider.primaryColor : widget.themeProvider.textSecondary),
                        title: Text(item.label, style: TextStyle(color: selected ? widget.themeProvider.primaryColor : widget.themeProvider.textPrimary, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                        selected: selected,
                        selectedTileColor: widget.themeProvider.primaryColor.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          setState(() => _currentIndex = item.index);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.person_outline, color: widget.themeProvider.textSecondary),
                  title: Text('我的', style: TextStyle(color: widget.themeProvider.textPrimary)),
                  onTap: () {
                    setState(() => _currentIndex = 5);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          // FAB for 我的
          Positioned(
            right: 16,
            bottom: 20,
            child: GestureDetector(
              onTap: () => setState(() => _currentIndex = 5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: widget.themeProvider.primaryVibrantGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: widget.themeProvider.primaryColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_currentIndex == 5 ? Icons.person : Icons.person_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    const Text('我的', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final int index;
  const _DrawerItem({required this.icon, required this.label, required this.index});
}
