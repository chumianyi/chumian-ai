import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'creative_page.dart';
import 'explore_page.dart';
import 'activity_page.dart';
import 'points_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import '../theme.dart';
import '../widgets/nav_bar.dart';
import '../widgets/chumian_drawer.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const HomePage({super.key, required this.themeProvider});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final GlobalKey<ChatPageState> _chatKey = GlobalKey<ChatPageState>();
  int _currentIndex = 0;
  String? _nickname;
  String? _avatar;

  // Drawer animation
  late final AnimationController _drawerCtrl;
  bool _drawerOpen = false;
  static const double _drawerWidth = 280;
  double _dragStartX = 0;
  double _dragCurrentX = 0;
  bool _dragging = false;

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
    _drawerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pages = [
      ChatPage(key: _chatKey),
      const CreativePage(),
      const ExplorePage(),
      const ActivityPage(),
      const PointsPage(),
      ProfilePage(themeProvider: widget.themeProvider),
    ];
    _loadUserInfo();
  }

  @override
  void dispose() {
    _drawerCtrl.dispose();
    super.dispose();
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

  void _openDrawer() {
    setState(() => _drawerOpen = true);
    _drawerCtrl.forward();
  }

  void _closeDrawer() {
    _drawerCtrl.reverse().then((_) {
      if (mounted) setState(() => _drawerOpen = false);
    });
  }

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
    _closeDrawer();
  }

  void _openConversation(String convId, String title) {
    setState(() => _currentIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatKey.currentState?.openConversationById(convId, title);
    });
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
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildFullscreenLayout() {
    final anim = _drawerCtrl.view;
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragStart: (details) {
          if (details.globalPosition.dx < 30) {
            _dragging = true;
            _dragStartX = details.globalPosition.dx;
            _dragCurrentX = 0;
          }
        },
        onHorizontalDragUpdate: (details) {
          if (!_dragging) return;
          _dragCurrentX = details.globalPosition.dx - _dragStartX;
          if (_dragCurrentX < 0) _dragCurrentX = 0;
          if (_dragCurrentX > _drawerWidth) _dragCurrentX = _drawerWidth;
          _drawerCtrl.value = _dragCurrentX / _drawerWidth;
          if (!_drawerOpen && _dragCurrentX > 5) {
            setState(() => _drawerOpen = true);
          }
        },
        onHorizontalDragEnd: (details) {
          if (!_dragging) return;
          _dragging = false;
          if (_drawerCtrl.value > 0.5) {
            _openDrawer();
          } else {
            _closeDrawer();
          }
        },
        child: Stack(
          children: [
            // 内容区
            IndexedStack(index: _currentIndex, children: _pages),

            // 左上角菜单按钮（全屏模式）
            Positioned(
              left: 0,
              top: MediaQuery.of(context).padding.top + 8,
              child: GestureDetector(
                onTap: _openDrawer,
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.menu, size: 22, color: Color(0xFF333333)),
                ),
              ),
            ),

            // 遮罩
            if (_drawerOpen)
              AnimatedBuilder(
                animation: _drawerCtrl,
                builder: (context, _) {
                  return Positioned.fill(
                    child: GestureDetector(
                      onTap: _closeDrawer,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4 * _drawerCtrl.value),
                      ),
                    ),
                  );
                },
              ),

            // 侧边栏
            if (_drawerOpen)
              AnimatedBuilder(
                animation: _drawerCtrl,
                builder: (context, _) {
                  return Positioned(
                    left: -_drawerWidth + (_drawerWidth * _drawerCtrl.value),
                    top: 0,
                    bottom: 0,
                    width: _drawerWidth,
                    child: ChumianDrawer(
                      nickname: _nickname,
                      avatar: _avatar,
                      currentPageIndex: _currentIndex,
                      onNavigate: _navigateTo,
                      onOpenConversation: _openConversation,
                      onClose: _closeDrawer,
                      onOpenSettings: () {
                        _closeDrawer();
                        _navigateTo(5);
                      },
                      onOpenNotifications: () {
                        _closeDrawer();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
