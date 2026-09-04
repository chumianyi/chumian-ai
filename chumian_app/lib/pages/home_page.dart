import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'creative_page.dart';
import 'explore_page.dart';
import 'activity_page.dart';
import 'points_page.dart';
import 'profile_page.dart';
import '../theme.dart';
import '../widgets/nav_bar.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  final ThemeProvider themeProvider;
  final VoidCallback? onLogout;
  const HomePage({super.key, required this.themeProvider, this.onLogout});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? _nickname;
  String? _avatar;

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
      ProfilePage(themeProvider: widget.themeProvider, onLogout: widget.onLogout),
    ];
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final info = await ApiService.getUserInfo();
      setState(() {
        _nickname = info['nickname'];
        _avatar = info['avatar'];
      });
    } catch (_) {}
  }

  bool _pageLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        child: _pageLoading
            ? _buildLoadingView(key: const ValueKey('loading'))
            : IndexedStack(
                key: ValueKey<int>(_currentIndex),
                index: _currentIndex,
                children: _pages,
              ),
      ),
      bottomNavigationBar: AppNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onChanged: (index) {
          if (index == _currentIndex) return;
          setState(() {
            _pageLoading = true;
            _currentIndex = index;
          });
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) setState(() => _pageLoading = false);
          });
        },
      ),
    );
  }

  Widget _buildLoadingView({Key? key}) {
    return Container(
      key: key,
      color: const Color(0xFFE8ECF0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECF0),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 10, offset: const Offset(-3, -3)),
                  BoxShadow(color: const Color(0xFFA3B1C6).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(3, 3)),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Color(0xFFFF6B9D)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '加载中...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
