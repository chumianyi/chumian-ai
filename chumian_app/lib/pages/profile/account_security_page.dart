import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_dialog.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_switch.dart';

/// ============================================================
/// AccountSecurityPage —— 账号安全
/// 修改密码，绑定手机，登录设备管理，注销账号
/// 粉色列表，危险操作红色确认
/// ============================================================
class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  bool _biometricEnabled = true;
  bool _loginNotification = true;
  List<DeviceInfo> _devices = [];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadDevices();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _loadDevices() {
    _devices = [
      DeviceInfo(
        id: '1',
        name: 'iPhone 15 Pro',
        model: 'iOS 17.5',
        location: '安徽六安',
        lastActive: DateTime.now(),
        isCurrent: true,
      ),
      DeviceInfo(
        id: '2',
        name: '小米 14 Ultra',
        model: 'Android 14',
        location: '安徽合肥',
        lastActive: DateTime.now().subtract(const Duration(days: 2)),
        isCurrent: false,
      ),
      DeviceInfo(
        id: '3',
        name: 'iPad Pro',
        model: 'iPadOS 17.4',
        location: '上海',
        lastActive: DateTime.now().subtract(const Duration(days: 7)),
        isCurrent: false,
      ),
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

  void _changePassword() {
    final oldPwd = TextEditingController();
    final newPwd = TextEditingController();
    final confirmPwd = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MiuixColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: MiuixRadius.xlRadius,
        ),
        title: const Text(
          '修改密码',
          style: TextStyle(
            color: MiuixColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiuixInput(
              controller: oldPwd,
              hintText: '当前密码',
              type: MiuixInputType.password,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: 12),
            MiuixInput(
              controller: newPwd,
              hintText: '新密码',
              type: MiuixInputType.password,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: 12),
            MiuixInput(
              controller: confirmPwd,
              hintText: '确认新密码',
              type: MiuixInputType.password,
              prefixIcon: Icons.lock_outline,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消',
                style: TextStyle(color: MiuixColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              MiuixToast.show(context,
                  message: '密码修改成功', type: MiuixToastType.success);
            },
            child: const Text('确认',
                style: TextStyle(color: MiuixColors.primary)),
          ),
        ],
      ),
    );
  }

  void _bindPhone() {
    final phoneController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MiuixColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: MiuixRadius.xlRadius,
        ),
        title: const Text(
          '绑定手机',
          style: TextStyle(
            color: MiuixColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiuixInput(
              controller: phoneController,
              hintText: '手机号码',
              type: MiuixInputType.number,
              prefixIcon: Icons.phone_android,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MiuixInput(
                    controller: codeController,
                    hintText: '验证码',
                    type: MiuixInputType.number,
                    prefixIcon: Icons.verified_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                MiuixButton(
                  label: '获取',
                  type: MiuixButtonType.secondary,
                  size: MiuixButtonSize.small,
                  onPressed: () {
                    MiuixToast.show(context,
                        message: '验证码已发送', type: MiuixToastType.info);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消',
                style: TextStyle(color: MiuixColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              MiuixToast.show(context,
                  message: '手机绑定成功', type: MiuixToastType.success);
            },
            child: const Text('绑定',
                style: TextStyle(color: MiuixColors.primary)),
          ),
        ],
      ),
    );
  }

  void _removeDevice(DeviceInfo device) {
    MiuixDialog.show(
      context,
      title: '下线设备',
      content: '确定要下线「${device.name}」吗？下线后需要重新登录。',
      type: MiuixDialogType.warning,
      confirmText: '下线',
      onConfirm: () {
        setState(() => _devices.removeWhere((d) => d.id == device.id));
        MiuixToast.show(context,
            message: '设备已下线', type: MiuixToastType.success);
      },
    );
  }

  void _deleteAccount() {
    MiuixDialog.show(
      context,
      title: '注销账号',
      content:
          '注销账号将清除所有数据，包括帖子、积分、Agent等，且不可恢复。确定要继续吗？',
      type: MiuixDialogType.error,
      confirmText: '确认注销',
      onConfirm: () {
        MiuixDialog.show(
          context,
          title: '再次确认',
          content: '此操作不可逆，请输入"确认注销"以继续。',
          type: MiuixDialogType.error,
          confirmText: '我已确认',
          onConfirm: () {
            MiuixToast.show(context,
                message: '注销申请已提交', type: MiuixToastType.warning);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '账号安全',
        backgroundColor: MiuixColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildSecurityScore(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildAccountSection(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildSecurityOptions(), 2),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildDeviceSection(), 3),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildDangerZone(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityScore() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF8FB5), Color(0xFFFF6B9D), Color(0xFFFF5588)],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: 0.85,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const Text(
                '85',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '安全等级：良好',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MiuixFontSize.lg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '建议开启生物识别并定期修改密码',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: MiuixFontSize.sm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          _buildListItem(
            icon: Icons.lock_outline,
            title: '修改密码',
            subtitle: '定期修改密码更安全',
            onTap: _changePassword,
          ),
          _buildDivider(),
          _buildListItem(
            icon: Icons.phone_android,
            title: '绑定手机',
            subtitle: '未绑定',
            onTap: _bindPhone,
            showArrow: true,
          ),
          _buildDivider(),
          _buildListItem(
            icon: Icons.email_outlined,
            title: '绑定邮箱',
            subtitle: 'user@example.com',
            onTap: () {
              MiuixToast.show(context,
                  message: '邮箱绑定', type: MiuixToastType.info);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOptions() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          _buildSwitchItem(
            icon: Icons.fingerprint,
            title: '生物识别登录',
            subtitle: '使用指纹/面容快速登录',
            value: _biometricEnabled,
            onChanged: (v) => setState(() => _biometricEnabled = v),
          ),
          _buildDivider(),
          _buildSwitchItem(
            icon: Icons.notifications_active_outlined,
            title: '异地登录提醒',
            subtitle: '新设备登录时发送通知',
            value: _loginNotification,
            onChanged: (v) => setState(() => _loginNotification = v),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSection() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.devices, color: MiuixColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                '登录设备管理',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_devices.length, (index) {
            final device = _devices[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: device.isCurrent
                      ? MiuixColors.primaryLight.withValues(alpha: 0.1)
                      : MiuixColors.surfaceVariant,
                  borderRadius: MiuixRadius.mdRadius,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: MiuixColors.primaryLight.withValues(alpha: 0.2),
                        borderRadius: MiuixRadius.smRadius,
                      ),
                      child: Icon(
                        device.name.toLowerCase().contains('ipad') ||
                                device.name.toLowerCase().contains('iphone')
                            ? Icons.phone_iphone
                            : Icons.smartphone,
                        color: MiuixColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                device.name,
                                style: const TextStyle(
                                  fontSize: MiuixFontSize.md,
                                  fontWeight: FontWeight.w600,
                                  color: MiuixColors.textPrimary,
                                ),
                              ),
                              if (device.isCurrent) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: MiuixColors.success
                                        .withValues(alpha: 0.15),
                                    borderRadius: MiuixRadius.pillRadius,
                                  ),
                                  child: const Text(
                                    '当前设备',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: MiuixColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${device.model} · ${device.location}',
                            style: const TextStyle(
                              fontSize: MiuixFontSize.xs,
                              color: MiuixColors.textTertiary,
                            ),
                          ),
                          Text(
                            '最后活跃：${_formatTime(device.lastActive)}',
                            style: const TextStyle(
                              fontSize: MiuixFontSize.xs,
                              color: MiuixColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!device.isCurrent)
                      MiuixIconButton(
                        icon: Icons.logout,
                        style: MiuixIconButtonStyle.ghost,
                        size: 36,
                        iconSize: 18,
                        color: MiuixColors.error,
                        onPressed: () => _removeDevice(device),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return MiuixCard(
      style: MiuixCardStyle.outlined,
      borderColor: MiuixColors.error.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_outlined,
                  color: MiuixColors.error, size: 20),
              SizedBox(width: 8),
              Text(
                '危险操作',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '以下操作不可逆，请谨慎处理',
            style: TextStyle(
              fontSize: MiuixFontSize.sm,
              color: MiuixColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: MiuixButton(
              label: '注销账号',
              icon: Icons.delete_forever,
              type: MiuixButtonType.danger,
              onPressed: _deleteAccount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return MiuixRipple(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MiuixColors.primaryLight.withValues(alpha: 0.15),
            borderRadius: MiuixRadius.smRadius,
          ),
          child: Icon(icon, color: MiuixColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: MiuixFontSize.md,
            fontWeight: FontWeight.w500,
            color: MiuixColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: MiuixFontSize.xs,
            color: MiuixColors.textTertiary,
          ),
        ),
        trailing: showArrow
            ? const Icon(Icons.chevron_right,
                color: MiuixColors.textTertiary, size: 20)
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MiuixColors.primaryLight.withValues(alpha: 0.15),
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Container(
        height: 1,
        color: MiuixColors.divider,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

class DeviceInfo {
  final String id;
  final String name;
  final String model;
  final String location;
  final DateTime lastActive;
  final bool isCurrent;
  const DeviceInfo({
    required this.id,
    required this.name,
    required this.model,
    required this.location,
    required this.lastActive,
    required this.isCurrent,
  });
}
