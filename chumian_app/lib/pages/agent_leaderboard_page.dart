import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/context_ext.dart';
import '../widgets/avatar.dart';
import '../widgets/app_card.dart';
import '../widgets/feedback.dart';
import '../widgets/buttons.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';

class AgentLeaderboardPage extends StatefulWidget {
  const AgentLeaderboardPage({super.key});
  @override
  State<AgentLeaderboardPage> createState() => _AgentLeaderboardPageState();
}

class _AgentLeaderboardPageState extends State<AgentLeaderboardPage> {
  List<dynamic> _agents = [];
  bool _loading = true;
  bool _loadFailed = false;
  Set<String> _cloning = {};
  Set<String> _liking = {};

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    setState(() {
      _loading = _agents.isEmpty;
      _loadFailed = false;
    });
    try {
      final agents = await ApiService.getAgentLeaderboard(limit: 50);
      if (!mounted) return;
      setState(() {
        _agents = agents;
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

  Future<void> _cloneAgent(dynamic agent) async {
    final id = agent['id'].toString();
    if (_cloning.contains(id)) return;
    setState(() => _cloning.add(id));
    try {
      await ApiService.cloneAgent(agent['id']);
      if (!mounted) return;
      _showSnack('已添加「${agent['name']}」到我的智能体');
    } catch (e) {
      if (!mounted) return;
      _showSnack('添加失败: ${ErrorMessages.of(e)}');
    } finally {
      if (mounted) setState(() => _cloning.remove(id));
    }
  }

  Future<void> _likeAgent(dynamic agent) async {
    final id = agent['id'].toString();
    if (_liking.contains(id)) return;
    setState(() => _liking.add(id));
    try {
      final result = await ApiService.likeAgent(agent['id']);
      if (!mounted) return;
      setState(() => agent['likes'] = result['likes'] ?? agent['likes']);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _liking.remove(id));
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('智能体榜'), centerTitle: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListSkeleton(items: 8);
    if (_loadFailed) {
      return ErrorRetry(message: '排行榜加载失败', onRetry: _loadAgents);
    }
    if (_agents.isEmpty) {
      return const EmptyState(
        icon: Icons.emoji_events_outlined,
        title: '暂无排行榜数据',
        subtitle: '还没有上榜的智能体，快去创作吧',
      );
    }
    return AppRefreshable(
      onRefresh: _loadAgents,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: _agents.length,
        itemBuilder: (context, index) => _buildRankItem(_agents[index], index),
      ),
    );
  }

  Widget _buildRankItem(dynamic agent, int index) {
    final rank = index + 1;
    final isTop3 = rank <= 3;
    final rankColors = [const Color(0xFFF5A623), const Color(0xFF9AA7B5), const Color(0xFFB98A5E)];
    final rankColor = isTop3 ? rankColors[rank - 1] : context.textTertiary;
    final id = agent['id'].toString();
    final cloning = _cloning.contains(id);
    final likes = agent['likes'] ?? 0;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: null,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isTop3
                    ? [rankColor, rankColor.withValues(alpha: 0.75)]
                    : [context.surfaceSubtle, context.surfaceSubtle],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                color: isTop3 ? Colors.white : context.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: isTop3 ? 16 : 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppAvatar(
            imageUrl: agent['avatar'] as String?,
            name: agent['name'] as String?,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent['name'] ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  agent['author_nickname'] ?? '',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _likeAgent(agent),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: likes > 0 ? context.danger : context.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            Formatters.compactNumber(likes),
                            style: TextStyle(fontSize: 12, color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, size: 14, color: context.textTertiary),
                        const SizedBox(width: 3),
                        Text(
                          Formatters.compactNumber(agent['download_count'] ?? 0),
                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GradientButton(
            label: cloning ? '添加中' : '使用',
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            loading: cloning,
            onPressed: cloning ? null : () => _cloneAgent(agent),
          ),
        ],
      ),
    );
  }
}
