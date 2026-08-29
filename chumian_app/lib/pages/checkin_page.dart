import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});
  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  bool _loading = true;
  bool _checkedToday = false;
  int _streak = 0;
  List<dynamic> _history = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.checkinStatus();
      if (!mounted) return;
      setState(() {
        _checkedToday = data['checked_today'] == true;
        _streak = data['current_streak'] ?? 0;
        _history = data['history'] ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkin() async {
    setState(() => _submitting = true);
    try {
      final result = await ApiService.checkin();
      if (!mounted) return;
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text('🎉 签到成功'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('获得 ${result['premium_points']} 高级积分', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 8),
          Text('连续签到 ${result['streak']} 天'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('太棒了'))],
      ));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('签到失败: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final checkedDates = _history.map((h) => h['checkin_date']?.toString().substring(8, 10)).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('每日签到')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            Text('连续签到 $_streak 天', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('每天签到可获得 3~10 高级积分，连续7天额外奖励20高级积分', style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: (_checkedToday || _submitting) ? null : _checkin,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _submitting ? const CircularProgressIndicator(color: Colors.white) : Text(_checkedToday ? '今日已签到' : '立即签到'),
            )),
          ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Text('${now.year}年${now.month}月', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
              itemCount: daysInMonth,
              itemBuilder: (ctx, i) {
                final day = i + 1;
                final isChecked = checkedDates.contains(day.toString().padLeft(2, '0'));
                final isToday = day == now.day;
                return Container(
                  decoration: BoxDecoration(
                    color: isChecked ? Colors.orange.withOpacity(0.2) : isToday ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday ? Border.all(color: Colors.blue, width: 1) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text('$day', style: TextStyle(fontSize: 13, color: isChecked ? Colors.orange : isToday ? Colors.blue : Colors.grey, fontWeight: isChecked || isToday ? FontWeight.bold : FontWeight.normal)),
                );
              },
            ),
          ]))),
        ],
      ),
    );
  }
}
