import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/mail_agent_post.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<Post> _posts = [];
  List<Agent> _agents = [];
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([ApiService().getPosts(), ApiService().getAgents()]);
      setState(() { _posts = results[0] as List<Post>; _agents = results[1] as List<Agent>; });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('发现', style: TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.bold, fontFamily: 'LXGW WenKai'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Row(children: [
              _tabButton('社区帖子', 0),
              _tabButton('智能体', 1),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) : _tab == 0 ? _buildPosts() : _buildAgents()),
      ]),
    );
  }

  Widget _tabButton(String label, int idx) {
    final selected = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: AnimatedContainer(duration: const Duration(milliseconds: 250), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: selected ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(24)), child: Center(child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, fontFamily: 'LXGW WenKai')))),
      ),
    );
  }

  Widget _buildPosts() {
    if (_posts.isEmpty) return const Center(child: Text('暂无帖子', style: TextStyle(color: AppColors.textHint, fontFamily: 'LXGW WenKai')));
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _posts.length, itemBuilder: (_, i) => _buildPostCard(_posts[i])),
    );
  }

  Widget _buildPostCard(Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 18, backgroundColor: AppColors.primaryLight, child: Text(post.nickname?.substring(0, 1) ?? 'U', style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'LXGW WenKai'))),
          const SizedBox(width: 10),
          Expanded(child: Text(post.nickname ?? '匿名用户', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai'))),
          Text('${post.createdAt.month}/${post.createdAt.day}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontFamily: 'LXGW WenKai')),
        ]),
        const SizedBox(height: 10),
        Text(post.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai')),
        const SizedBox(height: 6),
        Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontFamily: 'LXGW WenKai')),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.favorite_border, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 4), Text('${post.likes}', style: const TextStyle(fontSize: 13, color: AppColors.textTertiary, fontFamily: 'LXGW WenKai')),
          const SizedBox(width: 16),
          Icon(Icons.comment_outlined, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 4), Text('${post.commentsCount}', style: const TextStyle(fontSize: 13, color: AppColors.textTertiary, fontFamily: 'LXGW WenKai')),
        ]),
      ]),
    );
  }

  Widget _buildAgents() {
    if (_agents.isEmpty) return const Center(child: Text('暂无智能体', style: TextStyle(color: AppColors.textHint, fontFamily: 'LXGW WenKai')));
    return GridView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.85, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: _agents.length, itemBuilder: (_, i) => _buildAgentCard(_agents[i]));
  }

  Widget _buildAgentCard(Agent agent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: CircleAvatar(radius: 28, backgroundColor: AppColors.primaryLight, child: Text(agent.name.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 22, fontFamily: 'LXGW WenKai')))),
        const SizedBox(height: 10),
        Text(agent.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai')),
        const SizedBox(height: 4),
        Text(agent.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'LXGW WenKai')),
        const Spacer(),
        Row(children: [const Icon(Icons.favorite, size: 14, color: AppColors.primary), const SizedBox(width: 4), Text('${agent.likes}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontFamily: 'LXGW WenKai'))]),
      ]),
    );
  }
}
