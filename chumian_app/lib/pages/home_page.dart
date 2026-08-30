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
  const HomePage({super.key, required this.themeProvider});

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
      ProfilePage(themeProvider: widget.themeProvider),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
