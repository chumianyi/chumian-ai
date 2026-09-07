import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/providers/user_provider.dart';
import 'package:chumian_ai/providers/theme_provider.dart';
import 'package:chumian_ai/pages/settings/settings_page.dart';
import 'package:chumian_ai/pages/settings/privacy_policy_page.dart';
import 'package:chumian_ai/pages/settings/user_agreement_page.dart';
import 'package:chumian_ai/pages/settings/about_page.dart';
import 'package:chumian_ai/pages/notifications_page.dart';
import 'package:chumian_ai/pages/agent_leaderboard_page.dart';

/// ============================================================
/// ProfilePage —— 我的页面
/// 用户头像+昵称+积分 + 功能列表，错落入场动画
/// ============================================================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<_ProfileMenuItem> _menuItems = [
    _ProfileMenuItem(icon: Icons.edit_note, label: '我的帖子', color: Color(0xFFFF8FB5)),
    _ProfileMenuItem(icon: Icons.smart_toy, label: '我的Agent', color: Color(0xFFFF6B9D)),
    _ProfileMenuItem(icon: Icons.people_outline, label: '关注 / 粉丝', color: Color(0xFFFFB3C9)),
    _ProfileMenuItem(icon: Icons.notifications_none, label: '消息通知', color: Color(0xFFFF9DBB)),
    _ProfileMenuItem(icon: Icons.emoji_events_outlined, label: 'Agent排行榜', color: Color(0xFFFFC0D6)),
    _ProfileMenuItem(icon: Icons.settings_outlined, label: '设置', color: Color(0xFFFF8FB5)),
    _ProfileMenuItem(icon: Icons.privacy_tip_outlined, label: '隐私政策', color: Color(0xFFFF6B9D)),
    _ProfileMenuItem(icon: Icons.description_outlined, label: '用户协议', color: Color(0xFFFFB3C9)),
    _ProfileMenuItem(icon: Icons.info_outline, label: '关于初眠', color: Color(0xFFFF9DBB)),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onMenuItemTap(int index) {
    switch (index) {
      case 0:
        ScaffoldMessenger.of(context).showSnackBar(_buildSnack('我的帖子'));
        break;
      case 1:
        ScaffoldMessenger.of(context).showSnackBar(_buildSnack('我的Agent'));
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(_buildSnack('关注 / 粉丝'));
        break;
      case 3:
        Navigator.of(context).push(_buildRoute(const NotificationsPage()));
        break;
      case 4:
        Navigator.of(context).push(_buildRoute(const AgentLeaderboardPage()));
        break;
      case 5:
        Navigator.of(context).push(_buildRoute(const SettingsPage()));
        break;
      case 6:
        Navigator.of(context).push(_buildRoute(const PrivacyPolicyPage()));
        break;
      case 7:
        Navigator.of(context).push(_buildRoute(const UserAgreementPage()));
        break;
      case 8:
        Navigator.of(context).push(_buildRoute(const AboutPage()));
        break;
    }
  }

  PageRouteBuilder _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: page),
      transitionDuration: MiuixDuration.page,
    );
  }

  SnackBar _buildSnack(String text) {
    return SnackBar(
      content: Text(text),
      backgroundColor: MiuixColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? MiuixColors.darkBackground : MiuixColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(userProvider, isDark),
            const SizedBox(height: 16),
            _buildPointsCard(userProvider, isDark),
            const SizedBox(height: 16),
            _buildMenuList(isDark),
            const SizedBox(height: 24),
            _buildLogoutButton(userProvider),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserProvider userProvider, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8FB5), Color(0xFFFF6B9D), Color(0xFFFF5588)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(MiuixRadius.xxl),
          bottomRight: Radius.circular(MiuixRadius.xxl),
        ),
      ),
      child: FadeTransition(
        opacity: _controller,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero)
              .animate(CurvedAnimation(parent: _controller, curve: MiuixCurves.easeOut)),
          child: Row(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12)],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/mascot/mascot_full.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, color: Colors.white, size: 36),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProvider.nickname ?? '初眠用户',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: MiuixFontSize.xl,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userProvider.email ?? 'ID: ${userProvider.userId ?? '------'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: MiuixFontSize.sm,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: MiuixRadius.pillRadius,
                      ),
                      child: const Text(
                        'SVIP 会员',
                        style: TextStyle(color: Colors.white, fontSize: MiuixFontSize.xs, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              MiuixRipple(
                borderRadius: MiuixRadius.pill,
                child: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard(UserProvider userProvider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MiuixGlassCard(
        borderRadius: MiuixRadius.lg,
        child: Row(
          children: [
            _buildStatItem('积分', '${userProvider.dailyPoints}', Icons.stars),
            _buildVerticalDivider(),
            _buildStatItem('关注', '128', Icons.people),
            _buildVerticalDivider(),
            _buildStatItem('粉丝', '2.3k', Icons.favorite),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: MiuixColors.primary, size: 20),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0),
            duration: MiuixDuration.elastic,
            builder: (context, val, _) {
              return Text(
                value.contains('k') ? '${(val / 1000).toStringAsFixed(1)}k' : val.toInt().toString(),
                style: TextStyle(
                  color: MiuixColors.textPrimary,
                  fontSize: MiuixFontSize.lg,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.xs)),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1, height: 36,
      color: MiuixColors.border,
    );
  }

  Widget _buildMenuList(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MiuixGlassContainer(
        borderRadius: MiuixRadius.lg,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: List.generate(_menuItems.length, (index) {
            final item = _menuItems[index];
            final animation = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  (index / _menuItems.length) * 0.6,
                  (index / _menuItems.length) * 0.6 + 0.4,
                  curve: MiuixCurves.easeOut,
                ),
              ),
            );
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
                    .animate(animation),
                child: _buildMenuItem(item, index, isDark),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMenuItem(_ProfileMenuItem item, int index, bool isDark) {
    return MiuixRipple(
      child: ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.15),
            borderRadius: MiuixRadius.smRadius,
          ),
          child: Icon(item.icon, color: item.color, size: 20),
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isDark ? MiuixColors.darkTextPrimary : MiuixColors.textPrimary,
            fontSize: MiuixFontSize.md,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: MiuixColors.textTertiary, size: 20),
        onTap: () => _onMenuItemTap(index),
      ),
    );
  }

  Widget _buildLogoutButton(UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: MiuixRipple(
        borderRadius: MiuixRadius.pill,
        child: GestureDetector(
          onTap: () async {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: MiuixRadius.lgRadius),
                title: const Text('确认退出'),
                content: const Text('确定要退出登录吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('取消', style: TextStyle(color: MiuixColors.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await userProvider.logout();
                      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Text('退出', style: TextStyle(color: MiuixColors.error)),
                  ),
                ],
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: MiuixColors.error.withOpacity(0.08),
              borderRadius: MiuixRadius.pillRadius,
              border: Border.all(color: MiuixColors.error.withOpacity(0.3), width: 1),
            ),
            child: const Center(
              child: Text(
                '退出登录',
                style: TextStyle(color: MiuixColors.error, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem {
  const _ProfileMenuItem({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
}
