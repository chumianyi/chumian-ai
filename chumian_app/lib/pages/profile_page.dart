import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userInfo;
  List<dynamic> _pointsLog = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final info = await ApiService.getUserInfo();
      final log = await ApiService.getPointsLog();
      if (mounted) setState(() { _userInfo = info; _pointsLog = log; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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

  void _showAbout() {
    showAboutDialog(context: context, applicationName: '初眠AI', applicationVersion: '1.2.0', children: [const Text('初眠AI - 温柔、聪明、善解人意的AI助手。支持对话、图片生成、视频生成、社区互动等功能。')]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('我的')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _buildUserCard(),
          const SizedBox(height: 16),
          _buildPointsCard(),
          const SizedBox(height: 16),
          _buildSettingsList(),
          const SizedBox(height: 16),
          if (_pointsLog.isNotEmpty) ...[const Text('积分记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 8), ..._pointsLog.take(10).map((log) => ListTile(leading: const Icon(Icons.trending_down, color: Colors.orange), title: Text(log['reason'] ?? '消耗'), subtitle: Text(log['created_at']?.toString().substring(0, 16) ?? ''), trailing: Text('${log['points']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500))))],
        ]),
      ),
    );
  }

  Widget _buildUserCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nickname = _userInfo?['nickname'] ?? '用户';
    final email = _userInfo?['email'] ?? '';
    final isBanned = _userInfo?['is_banned'] == true;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        CircleAvatar(radius: 32, backgroundColor: Colors.white.withOpacity(0.3), child: Text(nickname[0], style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          if (isBanned) ...[const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), child: Text('封禁至 ${_userInfo?['ban_until']?.toString().substring(0, 10)}', style: const TextStyle(fontSize: 11, color: Colors.white)))],
        ])),
      ]),
    );
  }

  Widget _buildPointsCard() {
    final points = _userInfo?['daily_points'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.bolt, color: Colors.amber)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('今日积分', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text('$points', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ])),
        const Text('/ 9000万', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      ]),
    );
  }

  Widget _buildSettingsList() {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        ListTile(leading: const Icon(Icons.palette_outlined, color: AppTheme.primaryColor), title: const Text('主题设置'), trailing: const Icon(Icons.chevron_right), onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('跟随系统主题')))),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.cleaning_services_outlined, color: AppTheme.primaryColor), title: const Text('清除缓存'), trailing: const Icon(Icons.chevron_right), onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('缓存已清除')))),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor), title: const Text('关于'), trailing: const Icon(Icons.chevron_right), onTap: _showAbout),
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
