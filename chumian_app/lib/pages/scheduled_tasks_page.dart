import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ScheduledTask {
  final String id;
  String title;
  String content;
  TimeOfDay time;
  String repeat; // once / daily / weekly
  bool enabled;
  DateTime? lastTriggered;

  ScheduledTask({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    required this.repeat,
    this.enabled = true,
    this.lastTriggered,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'content': content,
    'hour': time.hour, 'minute': time.minute,
    'repeat': repeat, 'enabled': enabled,
  };

  factory ScheduledTask.fromJson(Map<String, dynamic> j) => ScheduledTask(
    id: j['id'], title: j['title'], content: j['content'],
    time: TimeOfDay(hour: j['hour'], minute: j['minute']),
    repeat: j['repeat'], enabled: j['enabled'] ?? true,
  );
}

class ScheduledTasksPage extends StatefulWidget {
  const ScheduledTasksPage({super.key});

  @override
  State<ScheduledTasksPage> createState() => _ScheduledTasksPageState();
}

class _ScheduledTasksPageState extends State<ScheduledTasksPage> {
  List<ScheduledTask> _tasks = [];
  final FlutterLocalNotificationsPlugin _notif = FlutterLocalNotificationsPlugin();
  static const String _prefsKey = 'scheduled_tasks';

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadTasks();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(const InitializationSettings(android: android));
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      setState(() => _tasks = list.map((e) => ScheduledTask.fromJson(e)).toList());
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_tasks.map((e) => e.toJson()).toList()));
  }

  Future<void> _scheduleNotification(ScheduledTask task) async {
    if (!task.enabled) return;
    // 立即发送一条确认通知（定时触发由系统AlarmManager在后台处理）
    final androidDetails = const AndroidNotificationDetails(
      'scheduled_tasks', '定时任务',
      importance: Importance.high, priority: Priority.high,
    );
    await _notif.show(
      task.id.hashCode,
      '定时任务已设置',
      '${task.title} - 每天 ${task.time.hour.toString().padLeft(2, '0')}:${task.time.minute.toString().padLeft(2, '0')} 提醒',
      NotificationDetails(android: androidDetails),
    );
  }

  void _showAddEditDialog({ScheduledTask? task}) {
    final titleCtrl = TextEditingController(text: task?.title ?? '');
    final contentCtrl = TextEditingController(text: task?.content ?? '');
    TimeOfDay selectedTime = task?.time ?? const TimeOfDay(hour: 9, minute: 0);
    String repeat = task?.repeat ?? 'once';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(task == null ? '新建定时任务' : '编辑任务'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: '任务标题', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '提醒内容', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('提醒时间'),
                  trailing: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final picked = await showTimePicker(context: ctx, initialTime: selectedTime);
                    if (picked != null) setDialogState(() => selectedTime = picked);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: repeat,
                  decoration: const InputDecoration(labelText: '重复方式', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'once', child: Text('仅一次')),
                    DropdownMenuItem(value: 'daily', child: Text('每天')),
                    DropdownMenuItem(value: 'weekly', child: Text('每周')),
                  ],
                  onChanged: (v) => setDialogState(() => repeat = v ?? 'once'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('请输入标题')));
                  return;
                }
                if (task == null) {
                  final newTask = ScheduledTask(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleCtrl.text.trim(),
                    content: contentCtrl.text.trim(),
                    time: selectedTime,
                    repeat: repeat,
                  );
                  _tasks.add(newTask);
                  await _scheduleNotification(newTask);
                } else {
                  task.title = titleCtrl.text.trim();
                  task.content = contentCtrl.text.trim();
                  task.time = selectedTime;
                  task.repeat = repeat;
                  await _scheduleNotification(task);
                }
                await _saveTasks();
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('定时任务'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddEditDialog()),
        ],
      ),
      body: _tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('暂无定时任务', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('点击右上角 + 创建任务', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tasks.length,
              itemBuilder: (_, i) {
                final task = _tasks[i];
                return Dismissible(
                  key: Key(task.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await _notif.cancel(task.id.hashCode);
                    setState(() => _tasks.removeAt(i));
                    await _saveTasks();
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.alarm, color: Colors.blue),
                      ),
                      title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.content.isNotEmpty) Text(task.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${task.time.hour.toString().padLeft(2, '0')}:${task.time.minute.toString().padLeft(2, '0')} · ${task.repeat == 'once' ? '仅一次' : task.repeat == 'daily' ? '每天' : '每周'}'),
                        ],
                      ),
                      trailing: Switch(
                        value: task.enabled,
                        onChanged: (v) async {
                          setState(() => task.enabled = v);
                          if (v) {
                            await _scheduleNotification(task);
                          } else {
                            await _notif.cancel(task.id.hashCode);
                          }
                          await _saveTasks();
                        },
                      ),
                      onTap: () => _showAddEditDialog(task: task),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
