import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/providers/theme_provider.dart';
import 'package:chumian_ai/utils/app_icons.dart';
import 'package:chumian_ai/pages/chat_page.dart';
import 'package:chumian_ai/pages/creative_page.dart';
import 'package:chumian_ai/pages/explore_page.dart';
import 'package:chumian_ai/pages/activity_page.dart';
import 'package:chumian_ai/pages/points_page.dart';
import 'package:chumian_ai/pages/profile_page.dart';

/// ============================================================
/// HomePage —— 主框架，6 个 Tab
/// 对话 / 创意 / 探索 / 活动 / 积分 / 我的
/// MiuixNavBar + PageView，点击导航项弹性动画
/// ============================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _navAnimController;
  late Animation<double> _navScaleAnim;
  int _animatingIndex = -1;

  static const List<_NavItem> _navItems = [
    _NavItem(iconPath: AppIcons.chat, label: '对话'),
    _NavItem(iconPath: AppIcons.creative, label: '创意'),
    _NavItem(iconPath: AppIcons.explore, label: '探索'),
    _NavItem(iconPath: AppIcons.activity, label: '活动'),
    _NavItem(iconPath: AppIcons.points, label: '积分'),
    _NavItem(iconPath: AppIcons.profile, label: '我的'),
  ];

  static const List<String> _appBarTitles = [
    '初眠AI',
    '创意工坊',
    '探索发现',
    '活动中心',
    '积分中心',
    '个人中心',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _navAnimController = AnimationController(
      vsync: this,
      duration: MiuixDuration.elastic,
    );
    _navScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _navAnimController,
      curve: MiuixCurves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navAnimController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _animatingIndex = index;
    });
    _navAnimController.reset();
    _navAnimController.forward().then((_) {
      if (mounted) {
        setState(() {
          _animatingIndex = -1;
        });
      }
    });
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: MiuixDuration.page,
      curve: MiuixCurves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? MiuixColors.darkBackground : MiuixColors.background;

    return MiuixRipple(
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(isDark),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            ChatPage(),
            CreativePage(),
            ExplorePage(),
            ActivityPage(),
            PointsPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(isDark),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final bgColor = isDark ? MiuixColors.darkSurface : MiuixColors.surface;
    final textColor = isDark ? MiuixColors.darkTextPrimary : MiuixColors.textPrimary;

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: AnimatedSwitcher(
        duration: MiuixDuration.normal,
        transitionBuilder: (child, anim) {
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: anim, child: child),
          );
        },
        child: Text(
          _appBarTitles[_currentIndex],
          key: ValueKey<int>(_currentIndex),
          style: TextStyle(
            color: textColor,
            fontSize: MiuixFontSize.xl,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MiuixColors.primary.withValues(alpha: 0.04),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    final bgColor = isDark
        ? MiuixColors.darkSurface.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.92);
    final borderColor = isDark ? MiuixColors.darkBorder : MiuixColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: MiuixColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              return _buildNavItem(index, isDark);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;
    final isAnimating = _animatingIndex == index;

    final activeColor = MiuixColors.primary;
    final inactiveColor = isDark
        ? MiuixColors.darkTextSecondary
        : MiuixColors.textTertiary;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(index),
        behavior: HitTestBehavior.opaque,
        child: MiuixRipple(
          borderRadius: MiuixRadius.md,
          child: AnimatedBuilder(
            animation: _navAnimController,
            builder: (context, child) {
              final s = isAnimating ? _navScaleAnim.value : 1.0;
              return Transform.scale(
                scale: s,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: MiuixDuration.fast,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? MiuixColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: MiuixRadius.pillRadius,
                      ),
                      child: SvgPicture.asset(
                        item.iconPath,
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(
                          isSelected ? activeColor : inactiveColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: MiuixDuration.fast,
                      style: TextStyle(
                        color: isSelected ? activeColor : inactiveColor,
                        fontSize: MiuixFontSize.xs,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      child: Text(item.label),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.iconPath,
    required this.label,
  });

  final String iconPath;
  final String label;
}
