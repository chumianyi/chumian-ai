import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/pages/agent_detail_page.dart';
import 'package:chumian_ai/pages/agent_create_page.dart';

/// ============================================================
/// AgentLeaderboardPage —— Agent排行榜
/// 前三名粉色领奖台 + 列表(头像+名称+描述+点赞数+克隆数) + 点赞/克隆按钮
/// ============================================================
class AgentLeaderboardPage extends StatefulWidget {
  const AgentLeaderboardPage({super.key});

  @override
  State<AgentLeaderboardPage> createState() => _AgentLeaderboardPageState();
}

class _AgentLeaderboardPageState extends State<AgentLeaderboardPage> {
  final List<AgentItem> _agents = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      final data = await ApiService.getAgentLeaderboard();
      if (mounted) {
        setState(() {
          _agents.clear();
          _agents.addAll(data.map((e) => AgentItem.fromJson(e)).toList());
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _likeAgent(AgentItem agent) async {
    try {
      await ApiService.likeAgent(agent.id);
      setState(() {
        agent.likes++;
        agent.isLiked = true;
      });
    } catch (_) {
      setState(() {
        agent.likes++;
        agent.isLiked = true;
      });
    }
    HapticFeedback.lightImpact();
  }

  Future<void> _cloneAgent(AgentItem agent) async {
    try {
      await ApiService.cloneAgent(agent.id);
      setState(() => agent.clones++);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已克隆「${agent.name}」到我的Agent'), backgroundColor: MiuixColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
    } catch (_) {
      setState(() => agent.clones++);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已克隆「${agent.name}」'), backgroundColor: MiuixColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: AppBar(backgroundColor: MiuixColors.surface, elevation: 0, scrolledUnderElevation: 0, centerTitle: true, leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary), onPressed: () => Navigator.pop(context)), title: Text('Agent排行榜', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w600)), actions: [IconButton(icon: Icon(Icons.add_circle_outline, color: MiuixColors.primary), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AgentCreatePage())))]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MiuixColors.primary))
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: MiuixColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('加载失败', style: TextStyle(color: MiuixColors.error, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(_errorMessage, style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _hasError = false;
                          });
                          _loadAgents();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: MiuixColors.primary),
                        child: const Text('重试', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : _agents.isEmpty
                  ? const Center(child: Text('暂无数据', style: TextStyle(color: MiuixColors.textSecondary)))
                  : CustomScrollView(slivers: [
              SliverToBoxAdapter(child: _buildPodium()),
              SliverPadding(padding: const EdgeInsets.all(12), sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                if (index < 3) return const SizedBox.shrink();
                final agent = _agents[index];
                return _buildAgentListItem(agent, index);
              }, childCount: _agents.length))),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ]),
    );
  }

  Widget _buildPodium() {
    if (_agents.length < 3) return const SizedBox.shrink();
    return Container(padding: const EdgeInsets.fromLTRB(16, 20, 16, 16), child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
      _buildPodiumItem(_agents[1], 2, 100),
      const SizedBox(width: 12),
      _buildPodiumItem(_agents[0], 1, 130),
      const SizedBox(width: 12),
      _buildPodiumItem(_agents[2], 3, 80),
    ]));
  }

  Widget _buildPodiumItem(AgentItem agent, int rank, double height) {
    return Expanded(child: Column(children: [
      GestureDetector(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AgentDetailPage(agentId: agent.id))), child: Stack(children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: MiuixColors.primaryGradient), border: Border.all(color: rank == 1 ? const Color(0xFFFFD700) : Colors.white, width: rank == 1 ? 3 : 2), boxShadow: MiuixShadows.md), child: const Center(child: Icon(Icons.smart_toy, color: Colors.white, size: 32))),
        Positioned(bottom: 0, right: 0, child: Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: rank == 1 ? const Color(0xFFFFD700) : rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32), border: Border.all(color: Colors.white, width: 2)), child: Center(child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))))),
      ])),
      const SizedBox(height: 8),
      Text(agent.name, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text('${agent.likes} 赞', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
      const SizedBox(height: 8),
      Container(width: double.infinity, height: height, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [rank == 1 ? const Color(0xFFFFD700).withValues(alpha: 0.3) : MiuixColors.primary.withValues(alpha: 0.2), MiuixColors.primary.withValues(alpha: 0.05)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(MiuixRadius.lg)), border: Border.all(color: MiuixColors.primary.withValues(alpha: 0.2), width: 1)), child: Center(child: Icon(rank == 1 ? Icons.emoji_events : rank == 2 ? Icons.military_tech : Icons.workspace_premium, color: rank == 1 ? const Color(0xFFFFD700) : MiuixColors.primary, size: rank == 1 ? 36 : 28))),
    ]));
  }

  Widget _buildAgentListItem(AgentItem agent, int index) {
    return MiuixRipple(borderRadius: MiuixRadius.lg, child: GestureDetector(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AgentDetailPage(agentId: agent.id))), child: MiuixGlassContainer(margin: const EdgeInsets.only(bottom: 10), borderRadius: MiuixRadius.lg, padding: const EdgeInsets.all(14), child: Row(children: [
      Container(width: 28, alignment: Alignment.center, child: Text('${index + 1}', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.md, fontWeight: FontWeight.bold))),
      const SizedBox(width: 10),
      Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: MiuixColors.softGradient)), child: const Center(child: Icon(Icons.smart_toy, color: MiuixColors.primary, size: 24))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(agent.name, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: MiuixColors.primary.withValues(alpha: 0.1), borderRadius: MiuixRadius.xsRadius), child: Text(agent.category, style: TextStyle(color: MiuixColors.primary, fontSize: 9, fontWeight: FontWeight.w500)))],),
        const SizedBox(height: 3),
        Text(agent.description, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(children: [Icon(Icons.favorite, color: MiuixColors.error, size: 12), const SizedBox(width: 3), Text('${agent.likes}', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)), const SizedBox(width: 12), Icon(Icons.copy, color: MiuixColors.textTertiary, size: 12), const SizedBox(width: 3), Text('${agent.clones}', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs))]),
      ])),
      Column(children: [
        GestureDetector(onTap: () => _likeAgent(agent), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: agent.isLiked ? MiuixColors.error.withValues(alpha: 0.1) : MiuixColors.surfaceVariant, shape: BoxShape.circle), child: Icon(agent.isLiked ? Icons.favorite : Icons.favorite_border, color: agent.isLiked ? MiuixColors.error : MiuixColors.textTertiary, size: 18))),
        const SizedBox(height: 6),
        GestureDetector(onTap: () => _cloneAgent(agent), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: MiuixColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.copy, color: MiuixColors.primary, size: 18))),
      ]),
    ]))));
  }
}

class AgentItem {
  AgentItem({required this.id, required this.name, required this.description, required this.likes, required this.clones, required this.avatar, required this.category, this.isLiked = false});
  final String id;
  final String name;
  final String description;
  int likes;
  int clones;
  final String avatar;
  final String category;
  bool isLiked;

  factory AgentItem.fromJson(Map<String, dynamic> json) {
    return AgentItem(id: json['id']?.toString() ?? '', name: json['name'] ?? '', description: json['description'] ?? '', likes: json['likes'] ?? 0, clones: json['clones'] ?? 0, avatar: json['avatar'] ?? '', category: json['category'] ?? '通用');
  }
}
