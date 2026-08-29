import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'checkin_page.dart';
import 'shop_page.dart';

class PointsPage extends StatefulWidget {
  const PointsPage({super.key});
  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  Map<String, dynamic>? _info;
  List<dynamic> _logs = [];
  bool _loading = true;
  bool _checkedToday = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await ApiService.getUserInfo();
      final logs = await ApiService.getPointsLog();
      final checkin = await ApiService.checkinStatus();
      if (!mounted) return;
      setState(() {
        _info = info;
        _logs = logs;
        _checkedToday = checkin['checked_today'] == true;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatPoints(dynamic p) {
    final v = (p ?? 0) as int;
    if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}亿';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}万';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('积分中心')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                Column(children: [
                  Text(_formatPoints(_info?['daily_points']), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const Text('普通积分', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ]),
                Column(children: [
                  Text('${_info?['premium_points'] ?? 0}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const Text('高级积分', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ]),
              ]),
              const SizedBox(height: 16),
              if ((_info?['svip_type'] ?? 'none') != 'none') Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]), borderRadius: BorderRadius.circular(20)),
                child: Text('SVIP ${_info?['svip_type'] == 'monthly' ? '月卡' : _info?['svip_type'] == 'yearly' ? '年卡' : '终身'}  到期: ${_info?['svip_expire'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ]))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildActionCard(Icons.calendar_today, '每日签到', _checkedToday ? '已签到' : '立即签到', () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckinPage()));
                _load();
              }, highlight: !_checkedToday)),
              const SizedBox(width: 12),
              Expanded(child: _buildActionCard(Icons.store, '积分商店', '兑换好礼', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopPage()));
              })),
            ]),
            const SizedBox(height: 20),
            const Text('积分记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_logs.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('暂无记录', style: TextStyle(color: Colors.grey))),
            ..._logs.take(20).map((log) => Card(child: ListTile(
              dense: true,
              title: Text(log['reason'] ?? ''),
              subtitle: Text(log['created_at']?.toString().substring(0, 16) ?? ''),
              trailing: Text('${(log['points'] ?? 0) > 0 ? '+' : ''}${log['points']}', style: TextStyle(color: (log['points'] ?? 0) > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            ))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, VoidCallback onTap, {bool highlight = false}) {
    return Card(
      color: highlight ? Colors.orange.withOpacity(0.08) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Icon(icon, size: 32, color: highlight ? Colors.orange : Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: highlight ? Colors.orange : Colors.grey)),
        ])),
      ),
    );
  }
}
