import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/services/api_service.dart';

/// ============================================================
/// NotificationsPage —— 通知列表页
/// 类型图标+标题+内容+时间 + 已读/未读状态 + 点击跳转 + 全部已读
/// ============================================================
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications.clear();
          _notifications.addAll(data.map((e) => NotificationItem.fromJson(e)).toList());
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _markAllRead() async {
    for (final n in _notifications) {
      if (!n.isRead) {
        try { await ApiService.readNotification(n.id); } catch (_) {}
        n.isRead = true;
      }
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('已全部标记为已读'), backgroundColor: MiuixColors.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'like': return Icons.favorite;
      case 'comment': return Icons.chat_bubble;
      case 'follow': return Icons.person_add;
      case 'system': return Icons.notifications;
      case 'points': return Icons.stars;
      case 'activity': return Icons.local_activity;
      default: return Icons.notifications_none;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'like': return MiuixColors.error;
      case 'comment': return MiuixColors.primary;
      case 'follow': return MiuixColors.info;
      case 'system': return MiuixColors.warning;
      case 'points': return Colors.amber;
      case 'activity': return MiuixColors.success;
      default: return MiuixColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: AppBar(backgroundColor: MiuixColors.surface, elevation: 0, scrolledUnderElevation: 0, centerTitle: true, leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary), onPressed: () => Navigator.pop(context)), title: Text('消息通知', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w600)), actions: [TextButton(onPressed: unreadCount > 0 ? _markAllRead : null, child: Text('全部已读', style: TextStyle(color: unreadCount > 0 ? MiuixColors.primary : MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)))]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MiuixColors.primary))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _notifications.length, itemBuilder: (context, index) {
                  final n = _notifications[index];
                  return TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: MiuixDuration.normal, curve: Interval((index % 5) * 0.1, (index % 5) * 0.1 + 0.9, curve: MiuixCurves.easeOut), builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, (1 - value) * 20), child: child)), child: _buildNotificationItem(n));
                }),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: MiuixColors.surfaceVariant, shape: BoxShape.circle), child: const Icon(Icons.notifications_none, color: MiuixColors.textTertiary, size: 40)),
      const SizedBox(height: 16),
      Text('暂无通知', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.md)),
    ]));
  }

  Widget _buildNotificationItem(NotificationItem n) {
    return MiuixRipple(borderRadius: MiuixRadius.lg, child: GestureDetector(onTap: () async {
      if (!n.isRead) {
        try { await ApiService.readNotification(n.id); } catch (_) {}
        setState(() => n.isRead = true);
      }
    }, child: MiuixGlassContainer(margin: const EdgeInsets.only(bottom: 10), borderRadius: MiuixRadius.lg, padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Stack(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: _getIconColor(n.type).withValues(alpha: 0.12), shape: BoxShape.circle), child: Center(child: Icon(_getIcon(n.type), color: _getIconColor(n.type), size: 22))),
        if (!n.isRead) Positioned(top: 0, right: 0, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: MiuixColors.error, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1))))),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(n.title, style: TextStyle(color: n.isRead ? MiuixColors.textSecondary : MiuixColors.textPrimary, fontSize: MiuixFontSize.md, fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600))), Text(_formatTime(n.time), style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs))]),
        const SizedBox(height: 4),
        Text(n.content, style: TextStyle(color: n.isRead ? MiuixColors.textTertiary : MiuixColors.textSecondary, fontSize: MiuixFontSize.sm, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
      ])),
    ]))));
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }
}

class NotificationItem {
  NotificationItem({required this.id, required this.type, required this.title, required this.content, required this.time, required this.isRead});
  final String id;
  final String type;
  final String title;
  final String content;
  final DateTime time;
  bool isRead;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(id: json['id']?.toString() ?? '', type: json['type'] ?? 'system', title: json['title'] ?? '通知', content: json['content'] ?? '', time: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(), isRead: json['is_read'] ?? false);
  }
}
