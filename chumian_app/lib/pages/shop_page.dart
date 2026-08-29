import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int _premiumPoints = 0;
  final TextEditingController _exchangeCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await ApiService.getUserInfo();
      if (!mounted) return;
      setState(() {
        _premiumPoints = info['premium_points'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exchange() async {
    final amount = int.tryParse(_exchangeCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效的数量')));
      return;
    }
    if (amount > _premiumPoints) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('高级积分不足')));
      return;
    }
    try {
      final result = await ApiService.exchangePoints(amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('兑换成功，获得 ${result['normal_points_added']} 普通积分')));
      _exchangeCtrl.clear();
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('兑换失败: $e')));
    }
  }

  Future<void> _buySvip(String plan, int cost, String name) async {
    if (_premiumPoints < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('高级积分不足')));
      return;
    }
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('购买SVIP $name'),
      content: Text('确认花费 $cost 高级积分购买SVIP $name？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        TextButton(onPressed: () async {
          Navigator.pop(ctx);
          try {
            await ApiService.buySvip(plan);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('购买成功！')));
            _load();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('购买失败: $e')));
          }
        }, child: const Text('确认')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('积分商店')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('我的高级积分', style: TextStyle(fontSize: 16)),
            Text('$_premiumPoints', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
          ]))),
          const SizedBox(height: 16),
          const Text('积分兑换', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('1 高级积分 = 2000万 普通积分', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(controller: _exchangeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '兑换数量（高级积分）', hintText: '输入要兑换的高级积分数量')),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _exchange, child: const Text('立即兑换'))),
          ]))),
          const SizedBox(height: 20),
          const Text('SVIP 会员', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildSvipCard('月卡', '200', 'monthly', 200, Icons.star, Colors.amber),
          _buildSvipCard('年卡', '2000', 'yearly', 2000, Icons.workspace_premium, Colors.orange),
          _buildSvipCard('终身', '100000', 'lifetime', 100000, Icons.diamond, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildSvipCard(String name, String price, String plan, int cost, IconData icon, Color color) {
    return Card(child: InkWell(
      onTap: () => _buySvip(plan, cost, name),
      borderRadius: BorderRadius.circular(16),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SVIP $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('$price 高级积分', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ])),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ])),
    ));
  }
}
