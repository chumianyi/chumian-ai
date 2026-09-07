import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';

/// ============================================================
/// AboutPage —— 关于页
/// 应用图标、名称、版本、开源协议、团队介绍、mascot展示
/// ============================================================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _appName = '初眠AI';
  static const String _appVersion = '2.0.0';
  static const String _buildNumber = '20260901';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: AppBar(
        backgroundColor: MiuixColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '关于初眠',
          style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAppIcon(),
            const SizedBox(height: 16),
            _buildAppInfo(),
            const SizedBox(height: 24),
            _buildMascotShowcase(),
            const SizedBox(height: 24),
            _buildTeamSection(),
            const SizedBox(height: 24),
            _buildOpenSourceSection(),
            const SizedBox(height: 24),
            _buildLinksSection(),
            const SizedBox(height: 32),
            Text(
              '© 2026 初眠AI团队 版权所有',
              style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs),
            ),
            const SizedBox(height: 8),
            Text(
              'Made with ❤️ in China',
              style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: MiuixDuration.elastic,
      curve: MiuixCurves.miuixSpring,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF8FB5), Color(0xFFFF6B9D), Color(0xFFFF5588)],
              ),
              boxShadow: [
                BoxShadow(
                  color: MiuixColors.primary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/mascot/mascot_full.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.smart_toy, color: Colors.white, size: 48),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: MiuixColors.primaryGradient,
          ).createShader(bounds),
          child: const Text(
            _appName,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '版本 $_appVersion (build $_buildNumber)',
          style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: MiuixColors.success.withValues(alpha: 0.1),
            borderRadius: MiuixRadius.pillRadius,
          ),
          child: Text(
            '最新版本',
            style: TextStyle(color: MiuixColors.success, fontSize: MiuixFontSize.xs, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildMascotShowcase() {
    return MiuixGlassCard(
      borderRadius: MiuixRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: MiuixColors.primary.withValues(alpha: 0.12),
                  borderRadius: MiuixRadius.smRadius,
                ),
                child: const Icon(Icons.favorite, color: MiuixColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                '初眠吉祥物',
                style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMascotItem('assets/mascot/mascot_full.png', '完整版', 80),
              _buildMascotItem('assets/mascot/mascot_small.png', '头像版', 60),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '初眠的吉祥物是一只可爱的AI小精灵，代表着智慧、温暖和创造力。它将陪伴你度过每一次对话和创作。',
            style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotItem(String path, String label, double size) {
    return Column(
      children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: MiuixColors.softGradient),
            boxShadow: MiuixShadows.sm,
          ),
          child: ClipOval(
            child: Image.asset(
              path,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.smart_toy, color: MiuixColors.primary, size: size * 0.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.xs)),
      ],
    );
  }

  Widget _buildTeamSection() {
    return MiuixGlassCard(
      borderRadius: MiuixRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: MiuixColors.primary.withValues(alpha: 0.12),
                  borderRadius: MiuixRadius.smRadius,
                ),
                child: const Icon(Icons.groups, color: MiuixColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                '团队介绍',
                style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '初眠AI团队是一支充满激情的年轻团队，成员来自国内外知名高校和科技公司。我们致力于将最前沿的人工智能技术与温暖的产品设计相结合，为每一位用户带来贴心、智能的AI体验。',
            style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm, height: 1.7),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTeamStat('50+', '团队成员'),
              _buildTeamStat('3', '年研发'),
              _buildTeamStat('100万+', '用户'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
        ],
      ),
    );
  }

  Widget _buildOpenSourceSection() {
    return MiuixGlassCard(
      borderRadius: MiuixRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: MiuixColors.primary.withValues(alpha: 0.12),
                  borderRadius: MiuixRadius.smRadius,
                ),
                child: const Icon(Icons.code, color: MiuixColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                '开源协议',
                style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOpenSourceItem('Flutter', 'BSD-3-Clause', 'UI框架'),
          _buildOpenSourceItem('Dio', 'MIT', '网络请求'),
          _buildOpenSourceItem('Provider', 'MIT', '状态管理'),
          _buildOpenSourceItem('flutter_markdown', 'BSD-3-Clause', 'Markdown渲染'),
          _buildOpenSourceItem('video_player', 'BSD-3-Clause', '视频播放'),
          _buildOpenSourceItem('photo_view', 'MIT', '图片预览'),
          _buildOpenSourceItem('flutter_svg', 'MIT', 'SVG图标'),
          const SizedBox(height: 8),
          Text(
            '本应用使用了上述开源项目，我们感谢所有开源贡献者的辛勤工作。',
            style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenSourceItem(String name, String license, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: MiuixColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w500)),
          ),
          Text(desc, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: MiuixColors.primary.withValues(alpha: 0.08),
              borderRadius: MiuixRadius.xsRadius,
            ),
            child: Text(license, style: TextStyle(color: MiuixColors.primary, fontSize: 9, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksSection() {
    return MiuixGlassCard(
      borderRadius: MiuixRadius.lg,
      child: Column(
        children: [
          _buildLinkTile(Icons.language, '官方网站', 'www.chumian-ai.com'),
          _buildDivider(),
          _buildLinkTile(Icons.email, '联系邮箱', 'support@chumian-ai.com'),
          _buildDivider(),
          _buildLinkTile(Icons.feedback, '意见反馈', '帮助我们做得更好'),
          _buildDivider(),
          _buildLinkTile(Icons.star, '给我们评分', '您的支持是我们的动力'),
        ],
      ),
    );
  }

  Widget _buildLinkTile(IconData icon, String title, String subtitle) {
    return MiuixRipple(
      child: ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: MiuixColors.primary.withValues(alpha: 0.12),
            borderRadius: MiuixRadius.smRadius,
          ),
          child: Icon(icon, color: MiuixColors.primary, size: 20),
        ),
        title: Text(title, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md)),
        subtitle: Text(subtitle, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
        trailing: Icon(Icons.chevron_right, color: MiuixColors.textTertiary, size: 20),
        onTap: () {},
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(height: 1, color: MiuixColors.divider, thickness: 0.5),
    );
  }
}
