import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'privacy_policy_page.dart';
import 'user_agreement_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pink50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('我的', style: AppTextStyles.headingMedium.copyWith(color: AppColors.pink600)),
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: AppColors.pink400), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(),
          const SizedBox(height: 20),
          _PointsCard(),
          const SizedBox(height: 20),
          _MenuSection(
            items: [
              _MenuItem(icon: Icons.account_circle, title: '账号管理', subtitle: 'GitHub绑定、个人信息', onTap: () {}),
              _MenuItem(icon: Icons.history, title: '历史记录', subtitle: '查看对话和创作历史', onTap: () {}),
              _MenuItem(icon: Icons.favorite_border, title: '我的收藏', subtitle: '收藏的内容和智能体', onTap: () {}),
            ],
          ),
          const SizedBox(height: 16),
          _MenuSection(
            items: [
              _MenuItem(icon: Icons.palette, title: '主题设置', subtitle: '粉色主题、深浅模式', onTap: () {}),
              _MenuItem(icon: Icons.font_download, title: '字体设置', subtitle: '霞鹜文楷', onTap: () {}),
              _MenuItem(icon: Icons.volume_up, title: '语音朗读', subtitle: 'TTS设置', onTap: () {}),
            ],
          ),
          const SizedBox(height: 16),
          _MenuSection(
            items: [
              _MenuItem(icon: Icons.privacy_tip_outlined, title: '隐私声明', subtitle: '查看隐私政策', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()))),
              _MenuItem(icon: Icons.description_outlined, title: '用户协议', subtitle: '查看服务条款', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserAgreementPage()))),
              _MenuItem(icon: Icons.info_outline, title: '关于初眠AI', subtitle: '版本 4.0.0', onTap: () {}),
              _MenuItem(icon: Icons.system_update, title: '检查更新', subtitle: '检测最新版本', onTap: () {}),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('初眠AI v4.0.0', style: AppTextStyles.caption.copyWith(color: AppColors.pink300)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.pink400, AppColors.pink500]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.pink300.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person, color: AppColors.pink400, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('初眠用户', style: AppTextStyles.headingSmall.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text('ID: 10086', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
                  child: Text('VIP会员', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () {}),
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.pink100.withOpacity(0.5), blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _PointsItem(label: '积分', value: '2,580'),
          _PointsDivider(),
          _PointsItem(label: '对话次数', value: '128'),
          _PointsDivider(),
          _PointsItem(label: '创作数', value: '36'),
        ],
      ),
    );
  }
}

class _PointsItem extends StatelessWidget {
  final String label;
  final String value;
  const _PointsItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headingSmall.copyWith(color: AppColors.pink500)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _PointsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 32, color: AppColors.pink100);
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.pink100.withOpacity(0.4), blurRadius: 6)],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast) Padding(padding: const EdgeInsets.only(left: 56), child: Divider(height: 1, color: AppColors.pink50)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.pink100, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.pink500, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.pink300, size: 20),
          ],
        ),
      ),
    );
  }
}
