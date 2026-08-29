import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/context_ext.dart';
import '../widgets/feedback.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notifications = [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _notifications.isEmpty;
      _loadFailed = false;
    });
    try {
      final list = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _markRead(int index) async {
    final n = _notifications[index];
    if (n['is_read'] == 1) return;
    setState(() => n['is_read'] = 1);
    try {
      await ApiService.readNotification(n['id']);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息通知')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListSkeleton(items: 6);
    if (_loadFailed) {
      return ErrorRetry(message: '通知加载失败', onRetry: _load);
    }
    if (_notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none_rounded,
        title: '暂无通知',
        subtitle: '关注、生日祝福与活动消息会出现在这里',
      );
    }
    return AppRefreshable(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final n = _notifications[i];
          return _buildNotification(ctx, n, i);
        },
      ),
    );
  }

  Widget _buildNotification(BuildContext context, dynamic n, int index) {
    final type = n['type'] ?? 'system';
    final style = NotificationTypes.of(type);
    final isRead = n['is_read'] == 1;
    final time = n['created_at']?.toString();

    return Material(
      color: context.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _markRead(index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n['title'] ?? '',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                              color: context.textPrimary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0455C),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n['content'] ?? '',
                      style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(time),
                      style: TextStyle(fontSize: 11, color: context.textTertiary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: context.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.length < 16) return '';
    final raw = iso.replaceAll('T', ' ');
    return raw.length >= 16 ? raw.substring(5, 16) : raw;
  }
}
