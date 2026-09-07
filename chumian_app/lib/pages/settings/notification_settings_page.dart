import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_switch.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';

/// ============================================================
/// NotificationSettingsPage —— 通知设置
/// 消息通知/活动通知/营销通知开关，免打扰时段
/// 振动/声音，MiuixSwitch
/// ============================================================
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  // 消息通知
  bool _messageNotify = true;
  bool _chatNotify = true;
  bool _mentionNotify = true;
  bool _followNotify = true;

  // 活动通知
  bool _activityNotify = true;
  bool _systemNotify = true;

  // 营销通知
  bool _marketingNotify = false;
  bool _promotionNotify = false;

  // 免打扰
  bool _doNotDisturb = false;
  TimeOfDay _dndStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _dndEnd = const TimeOfDay(hour: 8, minute: 0);

  // 提醒方式
  bool _vibration = true;
  bool _sound = true;
  bool _ledLight = true;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.05, (index * 0.05) + 0.35,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.05, (index * 0.05) + 0.35,
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

  Future<void> _pickTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _dndStart : _dndEnd,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MiuixColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _dndStart = time;
        } else {
          _dndEnd = time;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '通知设置',
        backgroundColor: MiuixColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildMessageSection(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildActivitySection(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildMarketingSection(), 2),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildDNDSection(), 3),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildAlertSection(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
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
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.chat_bubble_outline, '消息通知'),
        MiuixCard(
          style: MiuixCardStyle.surface,
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              _buildSwitchRow(
                icon: Icons.notifications_active,
                title: '消息通知总开关',
                subtitle: '接收所有消息通知',
                value: _messageNotify,
                onChanged: (v) => setState(() => _messageNotify = v),
              ),
              _buildDivider(),
              _buildSwitchRow(
                icon: Icons.chat,
                title: '聊天消息',
                subtitle: 'AI对话和私信通知',
                value: _chatNotify,
                onChanged: (v) => setState(() => _chatNotify = v),
              ),
              _buildDivider(),
              _buildSwitchRow(
                icon: Icons.alternate_email,
                title: '@我的提醒',
                subtitle: '有人@你时通知',
                value: _mentionNotify,
                onChanged: (v) => setState(() => _mentionNotify = v),
              ),
              _buildDivider(),
              _buildSwitchRow(
                icon: Icons.person_add,
                title: '新粉丝通知',
                subtitle: '有人关注你时通知',
                value: _followNotify,
                onChanged: (v) => setState(() => _followNotify = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.local_activity, '活动与系统'),
        MiuixCard(
          style: MiuixCardStyle.surface,
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              _buildSwitchRow(
                icon: Icons.event_available,
                title: '活动通知',
                subtitle: '社区活动和签到提醒',
                value: _activityNotify,
                onChanged: (v) => setState(() => _activityNotify = v),
              ),
              _buildDivider(),
              _buildSwitchRow(
                icon: Icons.system_update,
                title: '系统通知',
                subtitle: '版本更新和系统公告',
                value: _systemNotify,
                onChanged: (v) => setState(() => _systemNotify = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarketingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.card_giftcard, '营销通知'),
        MiuixCard(
          style: MiuixCardStyle.surface,
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              _buildSwitchRow(
                icon: Icons.campaign,
                title: '营销推送',
                subtitle: '新品上线和优惠活动',
                value: _marketingNotify,
                onChanged: (v) => setState(() => _marketingNotify = v),
              ),
              _buildDivider(),
              _buildSwitchRow(
                icon: Icons.local_offer,
                title: '促销通知',
                subtitle: '限时折扣和积分兑换',
                value: _promotionNotify,
                onChanged: (v) => setState(() => _promotionNotify = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDNDSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.do_not_disturb, '免打扰'),
        MiuixCard(
          style: MiuixCardStyle.surface,
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              _buildSwitchRow(
                icon: Icons.bedtime,
                title: '免打扰模式',
                subtitle: '指定时段不接收通知',
                value: _doNotDisturb,
                onChanged: (v) => setState(() => _doNotDisturb = v),
              ),
              if (_doNotDisturb) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(height: 1, color: MiuixColors.divider),
                ),
                _buildTimeRow(
                  icon: Icons.schedule,
                  title: '开始时间',
                  time: _dndStart,
                  onTap: () => _pickTime(true),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(height: 1, color: MiuixColors.divider),
                ),
                _buildTimeRow(
                  icon: Icons.wb_sunny,
                  title: '结束时间',
                  time: _dndEnd,
                  onTap: () => _pickTime(false),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.volume_up, '提醒方式'),
        MiuixCard(
          style: MiuixCardStyle.surface,
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              _buildSwitchRow(
                icon: Icons.vibration,
                title: '振动',
                subtitle: '收到通知时振动',
                value: _vibration,
                onChanged: (v) => setState(() => _vibration = v),
              ),
              _buildDivider(),
              _buildSwitchRow(
                icon: Icons.music_note,
                title: '声音',
                subtitle: '收到通知时播放提示音',
                value: _sound,
                onChanged: (v) => setState(() => _sound = v),
              ),
              _buildDivider(),
              _buildSwitchRow(
                icon: Icons.lightbulb,
                title: '指示灯',
                subtitle: '收到通知时闪烁指示灯',
                value: _ledLight,
                onChanged: (v) => setState(() => _ledLight = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: MiuixButton(
            label: '发送测试通知',
            icon: Icons.send,
            type: MiuixButtonType.secondary,
            onPressed: () {
              MiuixToast.show(context,
                  message: '测试通知已发送', type: MiuixToastType.success);
            },
          ),
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

  Widget _buildTimeRow({
    required IconData icon,
    required String title,
    required TimeOfDay time,
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
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w500,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: MiuixColors.primaryLight.withOpacity(0.15),
                borderRadius: MiuixRadius.pillRadius,
              ),
              child: Text(
                time.format(context),
                style: const TextStyle(
                  color: MiuixColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: MiuixFontSize.sm,
                ),
              ),
            ),
            const SizedBox(width: 8),
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
