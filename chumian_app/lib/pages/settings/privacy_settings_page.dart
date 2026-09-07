import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_switch.dart';
import 'package:chumian_ai/widgets/miuix/miuix_dialog.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';

/// ============================================================
/// PrivacySettingsPage —— 隐私设置
/// 聊天记录保存，个性化推荐，数据清除，黑名单，隐私声明入口
/// ============================================================
class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  bool _saveChatHistory = true;
  bool _personalizedRecommend = true;
  bool _showOnlineStatus = true;
  bool _allowSearch = true;
  bool _dataCollection = true;
  bool _adPersonalization = false;

  List<BlacklistUser> _blacklist = [];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadBlacklist();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _loadBlacklist() {
    _blacklist = [
      BlacklistUser(id: '1', name: '广告推广号', avatar: '🚫', reason: '发送垃圾广告'),
      BlacklistUser(id: '2', name: '骚扰用户', avatar: '⚠️', reason: '多次骚扰'),
    ];
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
            curve: Curves.easeOutCubic),
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: slide.value, child: child),
      ),
    );
  }

  void _clearData() {
    MiuixDialog.show(
      context,
      title: '清除数据',
      content: '将清除本地缓存的聊天记录、搜索历史和临时文件。此操作不可恢复，确定继续吗？',
      type: MiuixDialogType.warning,
      confirmText: '清除',
      onConfirm: () {
        MiuixToast.show(context,
            message: '数据清除成功', type: MiuixToastType.success);
      },
    );
  }

  void _exportData() {
    MiuixToast.show(context,
        message: '正在准备数据导出...', type: MiuixToastType.info);
  }

  void _removeFromBlacklist(BlacklistUser user) {
    MiuixDialog.show(
      context,
      title: '移出黑名单',
      content: '确定要将「${user.name}」移出黑名单吗？',
      type: MiuixDialogType.info,
      confirmText: '移出',
      onConfirm: () {
        setState(() => _blacklist.removeWhere((u) => u.id == user.id));
        MiuixToast.show(context,
            message: '已移出黑名单', type: MiuixToastType.success);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '隐私设置',
        backgroundColor: MiuixColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildPrivacyIntro(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildDataSection(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildVisibilitySection(), 2),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildRecommendationSection(), 3),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildBlacklistSection(), 4),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildDataManagement(), 5),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildLinksSection(), 6),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyIntro() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
              borderRadius: MiuixRadius.lgRadius,
            ),
            child: const Icon(Icons.privacy_tip, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '隐私保护',
                  style: TextStyle(
                    fontSize: MiuixFontSize.lg,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '我们重视您的隐私，您可以在此管理数据和隐私设置',
                  style: TextStyle(
                    fontSize: MiuixFontSize.sm,
                    color: MiuixColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return _buildSection(
      icon: Icons.storage,
      title: '数据存储',
      children: [
        _buildSwitchRow(
          icon: Icons.chat,
          title: '保存聊天记录',
          subtitle: '在本地保存AI对话历史',
          value: _saveChatHistory,
          onChanged: (v) => setState(() => _saveChatHistory = v),
        ),
        _buildDivider(),
        _buildSwitchRow(
          icon: Icons.analytics,
          title: '使用数据收集',
          subtitle: '帮助我们改进产品体验',
          value: _dataCollection,
          onChanged: (v) => setState(() => _dataCollection = v),
        ),
      ],
    );
  }

  Widget _buildVisibilitySection() {
    return _buildSection(
      icon: Icons.visibility,
      title: '可见性',
      children: [
        _buildSwitchRow(
          icon: Icons.circle,
          title: '显示在线状态',
          subtitle: '其他用户可看到你的在线状态',
          value: _showOnlineStatus,
          onChanged: (v) => setState(() => _showOnlineStatus = v),
        ),
        _buildDivider(),
        _buildSwitchRow(
          icon: Icons.search,
          title: '允许被搜索',
          subtitle: '其他用户可通过昵称搜索到你',
          value: _allowSearch,
          onChanged: (v) => setState(() => _allowSearch = v),
        ),
      ],
    );
  }

  Widget _buildRecommendationSection() {
    return _buildSection(
      icon: Icons.recommend,
      title: '个性化推荐',
      children: [
        _buildSwitchRow(
          icon: Icons.auto_awesome,
          title: '个性化内容推荐',
          subtitle: '根据你的兴趣推荐内容',
          value: _personalizedRecommend,
          onChanged: (v) => setState(() => _personalizedRecommend = v),
        ),
        _buildDivider(),
        _buildSwitchRow(
          icon: Icons.ad_units,
          title: '个性化广告',
          subtitle: '根据你的偏好展示相关广告',
          value: _adPersonalization,
          onChanged: (v) => setState(() => _adPersonalization = v),
        ),
      ],
    );
  }

  Widget _buildBlacklistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            children: [
              const Icon(Icons.block, color: MiuixColors.primary, size: 18),
              const SizedBox(width: 6),
              const Text(
                '黑名单管理',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_blacklist.length} 人',
                style: const TextStyle(
                  fontSize: MiuixFontSize.sm,
                  color: MiuixColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        MiuixCard(
          style: MiuixCardStyle.surface,
          padding: const EdgeInsets.all(0),
          child: _blacklist.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      '黑名单为空',
                      style: TextStyle(color: MiuixColors.textTertiary),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(_blacklist.length, (index) {
                    final user = _blacklist[index];
                    return Column(
                      children: [
                        if (index > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 72),
                            child:
                                Container(height: 1, color: MiuixColors.divider),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: MiuixColors.error.withOpacity(0.1),
                                  borderRadius: MiuixRadius.lgRadius,
                                ),
                                child: Center(
                                  child: Text(user.avatar,
                                      style: const TextStyle(fontSize: 22)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontSize: MiuixFontSize.md,
                                        fontWeight: FontWeight.w500,
                                        color: MiuixColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      user.reason,
                                      style: const TextStyle(
                                        fontSize: MiuixFontSize.xs,
                                        color: MiuixColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              MiuixButton(
                                label: '移出',
                                type: MiuixButtonType.text,
                                size: MiuixButtonSize.small,
                                onPressed: () => _removeFromBlacklist(user),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildDataManagement() {
    return _buildSection(
      icon: Icons.data_usage,
      title: '数据管理',
      children: [
        _buildActionRow(
          icon: Icons.delete_sweep,
          title: '清除本地数据',
          subtitle: '清除缓存和临时文件',
          onTap: _clearData,
        ),
        _buildDivider(),
        _buildActionRow(
          icon: Icons.download,
          title: '导出我的数据',
          subtitle: '下载你的个人数据副本',
          onTap: _exportData,
        ),
      ],
    );
  }

  Widget _buildLinksSection() {
    return _buildSection(
      icon: Icons.link,
      title: '相关声明',
      children: [
        _buildActionRow(
          icon: Icons.privacy_tip_outlined,
          title: '隐私政策',
          subtitle: '查看我们如何处理你的数据',
          onTap: () {
            MiuixToast.show(context,
                message: '打开隐私政策', type: MiuixToastType.info);
          },
        ),
        _buildDivider(),
        _buildActionRow(
          icon: Icons.description_outlined,
          title: '用户协议',
          subtitle: '查看服务使用条款',
          onTap: () {
            MiuixToast.show(context,
                message: '打开用户协议', type: MiuixToastType.info);
          },
        ),
        _buildDivider(),
        _buildActionRow(
          icon: Icons.cookie,
          title: 'Cookie 设置',
          subtitle: '管理 Cookie 偏好',
          onTap: () {
            MiuixToast.show(context,
                message: '打开 Cookie 设置', type: MiuixToastType.info);
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            children: [
              Icon(icon, color: MiuixColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        MiuixCard(
          style: MiuixCardStyle.surface,
          padding: const EdgeInsets.all(0),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MiuixColors.primaryLight.withOpacity(0.15),
              borderRadius: MiuixRadius.smRadius,
            ),
            child: Icon(icon, color: MiuixColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w500,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.xs,
                    color: MiuixColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          MiuixSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return MiuixRipple(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MiuixColors.primaryLight.withOpacity(0.15),
                borderRadius: MiuixRadius.smRadius,
              ),
              child: Icon(icon, color: MiuixColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: MiuixFontSize.md,
                      fontWeight: FontWeight.w500,
                      color: MiuixColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: MiuixFontSize.xs,
                      color: MiuixColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: MiuixColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Container(height: 1, color: MiuixColors.divider),
    );
  }
}

class BlacklistUser {
  final String id;
  final String name;
  final String avatar;
  final String reason;
  const BlacklistUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.reason,
  });
}
