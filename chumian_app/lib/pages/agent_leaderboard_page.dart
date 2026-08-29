import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class AgentLeaderboardPage extends StatefulWidget {
  const AgentLeaderboardPage({super.key});
  @override
  State<AgentLeaderboardPage> createState() => _AgentLeaderboardPageState();
}

class _AgentLeaderboardPageState extends State<AgentLeaderboardPage> {
  List<dynamic> _agents = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadAgents(); }

  Future<void> _loadAgents() async {
    try {
      final agents = await ApiService.getAgentLeaderboard(limit: 50);
      if (mounted) setState(() { _agents = agents; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _cloneAgent(dynamic agent) async {
    try {
      await ApiService.cloneAgent(agent['id']);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已添加「${agent['name']}」到我的智能体')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('添加失败: $e')));
    }
  }

  Future<void> _likeAgent(dynamic agent) async {
    try {
      final result = await ApiService.likeAgent(agent['id']);
      if (mounted) setState(() => agent['likes'] = result['likes'] ?? agent['likes']);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('智能体选'), centerTitle: true),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _agents.isEmpty ? const Center(child: Text('暂无排行榜数据', style: TextStyle(color: AppTheme.textSecondary))) : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _agents.length,
        itemBuilder: (context, index) => _buildRankItem(_agents[index], index),
      ),
    );
  }

  Widget _buildRankItem(dynamic agent, int index) {
    final rank = index + 1;
    final isTop3 = rank <= 3;
    final rankColors = [Colors.amber, Colors.grey[400]!, Colors.brown[300]!];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: isTop3 ? rankColors[rank - 1] : Colors.grey[200], shape: BoxShape.circle), child: Center(child: Text('$rank', style: TextStyle(color: isTop3 ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: isTop3 ? 16 : 14)))),
        const SizedBox(width: 12),
        CircleAvatar(radius: 22, backgroundColor: AppTheme.primaryColor.withOpacity(0.15), child: Text((agent['name'] ?? '?')[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(agent['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(agent['author_nickname'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Row(children: [
            GestureDetector(onTap: () => _likeAgent(agent), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.favorite, size: 14, color: (agent['likes'] ?? 0) > 0 ? Colors.red : AppTheme.textSecondary), const SizedBox(width: 3), Text('${agent['likes'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))])),
            const SizedBox(width: 12),
            Icon(Icons.download, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 3),
            Text('${agent['download_count'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        ])),
        ElevatedButton(onPressed: () => _cloneAgent(agent), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('使用', style: TextStyle(fontSize: 12))),
      ]),
    );
  }
}
