import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/providers/theme_provider.dart';
import 'package:chumian_ai/providers/settings_provider.dart';

/// ============================================================
/// SettingsPage —— 设置页
/// 深色模式 / 通知 / 音效震动 / 清除缓存 / 版本 / 检查更新
/// ============================================================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  double _cacheSize = 128.5;
  static const String _appVersion = '2.0.0';

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;
    final bgColor = isDark ? MiuixColors.darkBackground : MiuixColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('通用设置'),
            const SizedBox(height: 8),
            _buildCard(isDark, [
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: '深色模式',
                subtitle: '跟随系统或手动切换',
                value: isDark,
                onChanged: (v) => themeProvider.toggleDark(),
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: '消息通知',
                subtitle: '接收推送和提醒',
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.volume_up_outlined,
                title: '音效',
                subtitle: '操作提示音',
                value: _soundEnabled,
                onChanged: (v) => setState(() => _soundEnabled = v),
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.vibration,
                title: '震动反馈',
                subtitle: '点击和操作时震动',
                value: _vibrationEnabled,
                onChanged: (v) => setState(() => _vibrationEnabled = v),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('存储与缓存'),
            const SizedBox(height: 8),
            _buildCard(isDark, [
              _buildActionTile(
                icon: Icons.cleaning_services_outlined,
                title: '清除缓存',
                subtitle: '当前缓存 ${_cacheSize.toStringAsFixed(1)} MB',
                onTap: _clearCache,
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.storage_outlined,
                title: '存储空间',
                subtitle: '查看应用存储使用情况',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('关于'),
            const SizedBox(height: 8),
            _buildCard(isDark, [
              _buildInfoTile(icon: Icons.info_outline, title: '版本号', value: _appVersion),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.system_update,
                title: '检查更新',
                subtitle: '当前已是最新版本',
                onTap: _checkUpdate,
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? MiuixColors.darkSurface : MiuixColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '设置',
        style: TextStyle(
          color: isDark ? MiuixColors.darkTextPrimary : MiuixColors.textPrimary,
          fontSize: MiuixFontSize.xl,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: MiuixColors.textSecondary,
          fontSize: MiuixFontSize.sm,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark, List<Widget> children) {
    return MiuixGlassContainer(
      borderRadius: MiuixRadius.lg,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return MiuixRipple(
      child: SwitchListTile(
        secondary: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: MiuixColors.primary.withOpacity(0.12),
            borderRadius: MiuixRadius.smRadius,
          ),
          child: Icon(icon, color: MiuixColors.primary, size: 20),
        ),
        title: Text(title, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md)),
        subtitle: Text(subtitle, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
        value: value,
        activeColor: MiuixColors.primary,
        activeTrackColor: MiuixColors.primary.withOpacity(0.3),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return MiuixRipple(
      child: ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: MiuixColors.primary.withOpacity(0.12),
            borderRadius: MiuixRadius.smRadius,
          ),
          child: Icon(icon, color: MiuixColors.primary, size: 20),
        ),
        title: Text(title, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md)),
        subtitle: Text(subtitle, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
        trailing: Icon(Icons.chevron_right, color: MiuixColors.textTertiary, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String value}) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: MiuixColors.primary.withOpacity(0.12),
          borderRadius: MiuixRadius.smRadius,
        ),
        child: Icon(icon, color: MiuixColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md)),
      trailing: Text(value, style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.md)),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(height: 1, color: MiuixColors.divider, thickness: 0.5),
    );
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: MiuixRadius.lgRadius),
        title: const Text('清除缓存'),
        content: Text('将清除 ${_cacheSize.toStringAsFixed(1)} MB 缓存数据，确定继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: MiuixColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _cacheSize = 0);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('缓存已清除'),
                  backgroundColor: MiuixColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius),
                ),
              );
            },
            child: Text('确定', style: TextStyle(color: MiuixColors.primary)),
          ),
        ],
      ),
    );
  }

  void _checkUpdate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: MiuixRadius.lgRadius),
        title: const Text('检查更新'),
        content: const Text('当前已是最新版本 v$_appVersion'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定', style: TextStyle(color: MiuixColors.primary)),
          ),
        ],
      ),
    );
  }
}
