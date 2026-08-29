import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() { _notifications = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'follow': return Icons.person_add;
      case 'birthday': return Icons.cake;
      case 'activity': return Icons.notifications_active;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'follow': return Colors.blue;
      case 'birthday': return Colors.pink;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息通知')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _notifications.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_none, size: 64, color: Colors.grey), SizedBox(height: 12), Text('暂无通知', style: TextStyle(color: Colors.grey))])) : ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (ctx, i) {
          final n = _notifications[i];
          return ListTile(
            leading: CircleAvatar(backgroundColor: _getColor(n['type'] ?? '').withOpacity(0.15), child: Icon(_getIcon(n['type'] ?? ''), color: _getColor(n['type'] ?? ''))),
            title: Text(n['title'] ?? '', style: TextStyle(fontWeight: n['is_read'] == 0 ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text(n['content'] ?? ''),
            trailing: Text(n['created_at']?.toString().substring(5, 16) ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            onTap: () async {
              if (n['is_read'] == 0) {
                try { await ApiService.readNotification(n['id']); } catch (_) {}
                setState(() => n['is_read'] = 1);
              }
            },
          );
        },
      ),
    );
  }
}
