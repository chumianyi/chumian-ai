import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/user_provider.dart';
import 'mail_page.dart';
import 'privacy_policy_page.dart';
import 'user_agreement_page.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('我的', style: TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.bold, fontFamily: 'LXGW WenKai'))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildProfileHeader(context, user),
        const SizedBox(height: 20),
        _buildMenuGroup([
          _menuItem(Icons.mail_outline, '我的信件', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MailPage()))),
          _menuItem(Icons.history, '对话历史', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('对话历史开发中')))),
          _menuItem(Icons.favorite_border, '我的收藏', () {}),
          _menuItem(Icons.download_outlined, '下载管理', () {}),
        ]),
        const SizedBox(height: 12),
        _buildMenuGroup([
          _menuItem(Icons.privacy_tip_outlined, '隐私声明', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()))),
          _menuItem(Icons.description_outlined, '用户协议', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserAgreementPage()))),
          _menuItem(Icons.feedback_outlined, '意见反馈', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('反馈邮箱：3835347820@qq.com（已复制）')));
          }),
          _menuItem(Icons.info_outline, '关于初眠AI', () {
            showAboutDialog(context: context, applicationName: '初眠AI', applicationVersion: '4.1.0', children: [const Text('反馈邮箱：3835347820@qq.com', style: TextStyle(fontFamily: 'LXGW WenKai'))]);
          }),
        ]),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () async {
            await context.read<UserProvider>().logout();
            if (context.mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
          },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8)]), child: const Center(child: Text('退出登录', style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'LXGW WenKai')))),
        ),
        const SizedBox(height: 16),
        const Text('反馈邮箱：3835347820@qq.com', style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontFamily: 'LXGW WenKai')),
      ])),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.primaryVibrantGradient, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))]),
      child: Row(children: [
        CircleAvatar(radius: 32, backgroundColor: Colors.white.withOpacity(0.3), child: Text(user?.nickname?.substring(0, 1) ?? 'U', style: const TextStyle(fontSize: 28, color: Colors.white, fontFamily: 'LXGW WenKai'))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user?.nickname ?? '未登录', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'LXGW WenKai')),
          const SizedBox(height: 4),
          Text(user?.email ?? '', style: const TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'LXGW WenKai')),
        ])),
        const Icon(Icons.chevron_right, color: Colors.white70),
      ]),
    );
  }

  Widget _buildMenuGroup(List<Widget> items) {
    return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8)]), child: Column(children: items));
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai'))),
        const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
      ])),
    );
  }
}
