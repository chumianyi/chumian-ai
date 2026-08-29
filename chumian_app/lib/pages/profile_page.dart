import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
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
  final TextEditingController _qqCtrl = TextEditingController();
  final TextEditingController _nicknameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final info = await ApiService.getUserInfo();
      if (mounted) setState(() { _userInfo = info; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEditProfile() {
    _qqCtrl.text = _userInfo?['qq'] ?? '';
    _nicknameCtrl.text = _userInfo?['nickname'] ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('编辑资料', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _nicknameCtrl, decoration: const InputDecoration(labelText: '昵称')),
            const SizedBox(height: 12),
            TextField(controller: _qqCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'QQ号（选填，其他用户可见）')),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.cake),
              title: Text('生日: ${_userInfo?['birthday'] ?? '未设置'}'),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final date = await showDatePicker(context: ctx, initialDate: DateTime(2000, 1, 1), firstDate: DateTime(1950), lastDate: DateTime.now());
                if (date != null) {
                  try {
                    await ApiService.updateProfile(birthday: date.toString().substring(0, 10));
                    if (!mounted) return;
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('生日已更新')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失败: $e')));
                  }
                }
              },
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async {
              try {
                await ApiService.updateProfile(nickname: _nicknameCtrl.text, qq: _qqCtrl.text.isEmpty ? null : _qqCtrl.text);
                if (!mounted) return;
                Navigator.pop(ctx);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('资料已更新')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失败: $e')));
              }
            }, child: const Text('保存'))),
          ]),
        ),
      ),
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('主题设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _themeOption('默认', const Color(0xFFE8B4D8), AppThemeType.defaultTheme),
            _themeOption('绿色', const Color(0xFF6BCB77), AppThemeType.green),
            _themeOption('粉色', const Color(0xFFFF6B9D), AppThemeType.pink),
            _themeOption('紫色', const Color(0xFF9C6ADE), AppThemeType.purple),
          ]),
          const SizedBox(height: 16),
          SwitchListTile(title: const Text('深色模式'), value: widget.themeProvider.isDark, onChanged: (_) => widget.themeProvider.toggleDark()),
        ]),
      ),
    );
  }

  Widget _themeOption(String name, Color color, AppThemeType type) {
    final selected = widget.themeProvider.themeType == type;
    return GestureDetector(
      onTap: () {
        widget.themeProvider.setTheme(type);
        Navigator.pop(context);
      },
      child: Column(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: selected ? Border.all(color: Colors.black, width: 3) : null)),
        const SizedBox(height: 6),
        Text(name, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async {
            await ApiService.logout();
            if (mounted) {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const _LoginRedirect()), (route) => false);
            }
          }, child: const Text('退出', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = widget.themeProvider;
    return Scaffold(
      appBar: AppBar(title: const Text('我的'), actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()))),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _buildUserCard(tp),
          const SizedBox(height: 16),
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildSettingsList(tp),
        ]),
      ),
    );
  }

  Widget _buildUserCard(ThemeProvider tp) {
    final nickname = _userInfo?['nickname'] ?? '用户';
    final email = _userInfo?['email'] ?? '';
    final isBanned = _userInfo?['is_banned'] == true;
    return GestureDetector(
      onTap: _showEditProfile,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [tp.primaryColor, tp.secondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          CircleAvatar(radius: 32, backgroundColor: Colors.white.withOpacity(0.3), child: Text(nickname[0], style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            if (_userInfo?['qq'] != null) Text('QQ: ${_userInfo!['qq']}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
            if (isBanned) ...[const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), child: Text('封禁至 ${_userInfo?['ban_until']?.toString().substring(0, 10)}', style: const TextStyle(fontSize: 11, color: Colors.white)))],
          ])),
          const Icon(Icons.edit, color: Colors.white70, size: 20),
        ]),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _statItem('${_userInfo?['followers_count'] ?? 0}', '粉丝'),
      _statItem('${_userInfo?['following_count'] ?? 0}', '关注'),
      _statItem('${_userInfo?['mutual_count'] ?? 0}', '互关'),
      _statItem('${_userInfo?['likes_count'] ?? 0}', '获赞'),
    ])));
  }

  Widget _statItem(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }

  Widget _buildSettingsList(ThemeProvider tp) {
    return Container(
      decoration: BoxDecoration(color: tp.surfaceColor, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        ListTile(leading: Icon(Icons.palette_outlined, color: tp.primaryColor), title: const Text('主题设置'), trailing: const Icon(Icons.chevron_right), onTap: _showThemePicker),
        const Divider(height: 1),
        ListTile(leading: Icon(Icons.notifications_outlined, color: tp.primaryColor), title: const Text('消息通知'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()))),
        const Divider(height: 1),
        ListTile(leading: Icon(Icons.cleaning_services_outlined, color: tp.primaryColor), title: const Text('清除缓存'), trailing: const Icon(Icons.chevron_right), onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('缓存已清除')))),
        const Divider(height: 1),
        ListTile(leading: Icon(Icons.info_outline, color: tp.primaryColor), title: const Text('关于'), trailing: const Icon(Icons.chevron_right), onTap: () => showAboutDialog(context: context, applicationName: '初眠AI', applicationVersion: '2.0.0', children: const [Text('初眠AI - 温柔、聪明、善解人意的AI助手。')])),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('退出登录', style: TextStyle(color: Colors.red)), onTap: _showLogoutConfirm),
      ]),
    );
  }
}

class _LoginRedirect extends StatelessWidget {
  const _LoginRedirect();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const _SplashExit()));
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _SplashExit extends StatelessWidget {
  const _SplashExit();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, color: Colors.green, size: 64), SizedBox(height: 16), Text('已退出登录', style: TextStyle(fontSize: 18))])));
  }
}
