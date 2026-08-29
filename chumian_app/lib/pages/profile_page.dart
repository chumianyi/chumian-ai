import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/context_ext.dart';
import '../widgets/avatar.dart';
import '../widgets/feedback.dart';
import '../widgets/gradient_header.dart';
import '../widgets/tiles.dart';
import '../widgets/app_card.dart';
import '../widgets/buttons.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'notifications_page.dart';
import 'user_profile_page.dart';

class ProfilePage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const ProfilePage({super.key, required this.themeProvider});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userInfo;
  bool _loading = true;
  bool _loadFailed = false;
  final TextEditingController _qqCtrl = TextEditingController();
  final TextEditingController _nicknameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _qqCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = _userInfo == null;
      _loadFailed = false;
    });
    try {
      final info = await ApiService.getUserInfo();
      if (!mounted) return;
      setState(() {
        _userInfo = info;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showEditProfile() {
    _qqCtrl.text = _userInfo?['qq'] ?? '';
    _nicknameCtrl.text = _userInfo?['nickname'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  IconCircle(
                    icon: Icons.edit,
                    size: 40,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '编辑资料',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        '修改你的昵称、QQ与生日信息',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nicknameCtrl,
                decoration: const InputDecoration(
                  labelText: '昵称',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _qqCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'QQ号（选填，其他用户可见）',
                  prefixIcon: Icon(Icons.chat_bubble_outline),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _pickBirthday(ctx),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cake_rounded, color: context.primary, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        '生日',
                        style: TextStyle(
                          fontSize: 15,
                          color: context.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _userInfo?['birthday'] ?? '未设置',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textSecondary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.textTertiary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: '保存修改',
                  icon: Icons.check_rounded,
                  onPressed: () async {
                    try {
                      await ApiService.updateProfile(
                        nickname: _nicknameCtrl.text,
                        qq: _qqCtrl.text.isEmpty ? null : _qqCtrl.text,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _loadData();
                      _showSnack('资料已更新');
                    } catch (e) {
                      if (!ctx.mounted) return;
                      _showSnack('更新失败: ${ErrorMessages.of(e)}');
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthday(BuildContext sheetCtx) async {
    final date = await showDatePicker(
      context: sheetCtx,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: '选择生日',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (date == null) return;
    try {
      await ApiService.updateProfile(birthday: Formatters.formatDate(date));
      if (!mounted) return;
      _loadData();
      _showSnack('生日已更新');
    } catch (e) {
      if (!mounted) return;
      _showSnack('更新失败: ${ErrorMessages.of(e)}');
    }
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '主题设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '选择你喜欢的配色方案',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _themeOption('默认', AppThemeType.defaultTheme),
                const SizedBox(width: 14),
                _themeOption('绿色', AppThemeType.green),
                const SizedBox(width: 14),
                _themeOption('粉色', AppThemeType.pink),
                const SizedBox(width: 14),
                _themeOption('紫色', AppThemeType.purple),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: context.surfaceSubtle,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                title: const Text('深色模式'),
                subtitle: const Text('减少夜间观看时的眼睛疲劳'),
                value: widget.themeProvider.isDark,
                activeColor: widget.themeProvider.primaryColor,
                onChanged: (_) => widget.themeProvider.toggleDark(),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(String name, AppThemeType type) {
    final tp = widget.themeProvider;
    final selected = tp.themeType == type;
    final color = ThemeColorSet.all[type]!.primary;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          tp.setTheme(type);
          Navigator.pop(context);
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ThemeColorSet.all[type]!.gradientStart,
                    ThemeColorSet.all[type]!.gradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: selected
                    ? Border.all(color: context.textPrimary, width: 3)
                    : null,
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x24000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? Icon(Icons.check_rounded, color: Colors.white, size: 22)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? context.primary : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？退出后需要重新登录才能使用。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ApiService.logout();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const _LoginRedirect()),
                  (route) => false,
                );
              }
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconAction(
            icon: Icons.notifications_outlined,
            tooltip: '消息通知',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListSkeleton(items: 4);
    if (_loadFailed) {
      return ErrorRetry(message: '个人信息加载失败', onRetry: _loadData);
    }
    return AppRefreshable(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildUserCard(),
          const SizedBox(height: 14),
          _buildStatsCard(),
          const SizedBox(height: 24),
          CardSection(
            title: '外观',
            padding: EdgeInsets.zero,
            titlePadding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
            children: [
              SettingsTile(
                icon: Icons.palette_outlined,
                title: '主题设置',
                subtitle: '配色方案与深色模式',
                onTap: _showThemePicker,
                showChevron: true,
              ),
              const ThinDivider(),
              SwitchTile(
                icon: Icons.dark_mode_outlined,
                title: '深色模式',
                subtitle: '跟随系统亮度，夜间更舒适',
                value: widget.themeProvider.isDark,
                onChanged: (_) => widget.themeProvider.toggleDark(),
              ),
            ],
          ),
          CardSection(
            title: '通用',
            padding: EdgeInsets.zero,
            titlePadding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
            children: [
              SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: '消息通知',
                subtitle: '关注、活动与积分动态',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                ),
                showChevron: true,
              ),
              const ThinDivider(),
              SettingsTile(
                icon: Icons.cleaning_services_outlined,
                title: '清除缓存',
                subtitle: '释放本地图片与临时文件空间',
                onTap: () => _showSnack('缓存已清除'),
                showChevron: true,
              ),
              const ThinDivider(),
              SettingsTile(
                icon: Icons.info_outline_rounded,
                title: '关于初眠AI',
                subtitle: '版本 ${AboutTexts.version}.${AboutTexts.build}',
                onTap: _showAbout,
                showChevron: true,
              ),
            ],
          ),
          const SizedBox(height: 28),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              borderRadius: R.allLg,
              onTap: _showLogoutConfirm,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: context.danger),
                    const SizedBox(width: 8),
                    Text(
                      '退出登录',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: AboutTexts.appName,
      applicationVersion: '${AboutTexts.version}.${AboutTexts.build}',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: context.vibrantGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
      ),
      children: [
        const SizedBox(height: 12),
        Text(AboutTexts.slogan),
        const SizedBox(height: 8),
        Text('${AboutTexts.copyright} · 让每一次对话都更有温度'),
      ],
    );
  }

  Widget _buildUserCard() {
    final tp = widget.themeProvider;
    final nickname = _userInfo?['nickname'] ?? '用户';
    final email = _userInfo?['email'] ?? '';
    final isBanned = _userInfo?['is_banned'] == true;
    final banUntil = _userInfo?['ban_until']?.toString();

    return GradientCard(
      onTap: _showEditProfile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  Formatters.initialOf(nickname),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'SVIP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      Formatters.maskEmail(email),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _bannedTag(isBanned, banUntil),
                        if (!isBanned && _userInfo?['qq'] != null) ...[
                          const SizedBox(width: 8),
                          _inlineInfo(Icons.chat_bubble_outline, 'QQ ${_userInfo!['qq']}'),
                        ],
                        if (!isBanned && _userInfo?['birthday'] != null) ...[
                          const SizedBox(width: 8),
                          _inlineInfo(Icons.cake_outlined, _userInfo!['birthday']),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 主题色环
          Row(
            children: [
              _miniDot(tp.primaryColor),
              const SizedBox(width: 6),
              _miniDot(tp.secondaryColor),
              const SizedBox(width: 6),
              _miniDot(tp.tertiaryColor),
              const Spacer(),
              Text(
                '轻触卡片编辑资料',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannedTag(bool isBanned, String? banUntil) {
    if (!isBanned) return const SizedBox.shrink();
    final text = banUntil != null
        ? '封禁至 ${Formatters.formatDateTime(banUntil)}'
        : '账号已被封禁';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8445C),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
    );
  }

  Widget _inlineInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.85)),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _buildStatsCard() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StatTile(
            value: '${_userInfo?['followers_count'] ?? 0}',
            label: '粉丝',
            valueColor: context.primary,
          ),
          StatTile(
            value: '${_userInfo?['following_count'] ?? 0}',
            label: '关注',
            valueColor: context.primary,
          ),
          StatTile(
            value: '${_userInfo?['mutual_count'] ?? 0}',
            label: '互关',
            valueColor: context.primary,
          ),
          StatTile(
            value: '${_userInfo?['likes_count'] ?? 0}',
            label: '获赞',
            valueColor: context.primary,
          ),
        ],
      ),
    );
  }
}

class _LoginRedirect extends StatelessWidget {
  const _LoginRedirect();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const _SplashExit()),
      );
    });
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: context.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '正在退出…',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashExit extends StatelessWidget {
  const _SplashExit();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: context.success, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              '已退出登录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '感谢使用，欢迎下次再来',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
