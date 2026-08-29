import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});
  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  bool _loading = true;
  bool _playedToday = false;
  Map<String, dynamic>? _todayRecord;
  List<dynamic> _history = [];
  final TextEditingController _pointsCtrl = TextEditingController();
  String _choice = 'big';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final data = await ApiService.guessStatus();
      setState(() {
        _playedToday = data['played_today'] == true;
        _todayRecord = data['today_record'];
        _history = data['history'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _play() async {
    final points = int.tryParse(_pointsCtrl.text) ?? 0;
    if (points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效的积分数量')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ApiService.guessActivity(points, _choice);
      if (!mounted) return;
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text(result['won'] ? '🎉 恭喜赢了！' : '😢 很遗憾输了'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('开出：${result['roll']} (${result['result'] == 'big' ? '大' : '小'})'),
          const SizedBox(height: 8),
          Text('积分变动：${result['points_change'] > 0 ? '+' : ''}${result['points_change']}', style: TextStyle(color: result['won'] ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定'))],
      ));
      _loadStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('参与失败: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('活动中心')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.casino, color: Colors.orange)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('猜大小', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('每天一次，押对积分翻倍', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ])),
            ]),
            const SizedBox(height: 20),
            if (_playedToday) ...[
              Builder(builder: (ctx) {
                final rec = _todayRecord;
                final resultText = rec?['result'] == 'big' ? '大' : '小';
                final roll = rec?['roll'] ?? 0;
                final won = rec?['won'] == 1;
                final change = rec?['points_change'] ?? 0;
                return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Column(children: [
                  const Text('今日已参与', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('开出：$resultText ($roll)'),
                  Text('结果：${won ? '赢了 +$change' : '输了 $change'}', style: TextStyle(color: won ? Colors.green : Colors.red)),
                ]));
              }),
            ] else ...[
              TextField(controller: _pointsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '押注积分数量', hintText: '输入要押的积分')),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: ChoiceChip(label: const Text('开大'), selected: _choice == 'big', onSelected: (_) => setState(() => _choice = 'big'), selectedColor: Colors.red.withOpacity(0.2))),
                const SizedBox(width: 12),
                Expanded(child: ChoiceChip(label: const Text('开小'), selected: _choice == 'small', onSelected: (_) => setState(() => _choice = 'small'), selectedColor: Colors.blue.withOpacity(0.2))),
              ]),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submitting ? null : _play, child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('立即参与'))),
            ],
          ]))),
          const SizedBox(height: 16),
          const Text('历史记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_history.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('暂无记录', style: TextStyle(color: Colors.grey))),
          ..._history.map((h) => Card(child: ListTile(
            leading: Icon(h['won'] == 1 ? Icons.check_circle : Icons.cancel, color: h['won'] == 1 ? Colors.green : Colors.red),
            title: Text('${h['guess_date']}  押${h['choice'] == 'big' ? '大' : '小'}  开${h['result'] == 'big' ? '大' : '小'}'),
            trailing: Text('${h['points_change'] > 0 ? '+' : ''}${h['points_change']}', style: TextStyle(color: h['won'] == 1 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
          ))),
        ],
      ),
    );
  }
}
