import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'agent_leaderboard_page.dart';
import 'image_preview_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with SingleTickerProviderStateMixin {
  List<dynamic> _posts = [];
  bool _loading = true;
  late TabController _tabController;
  final List<String> _tabs = ['全部', '智能体', '图片', '视频'];
  final List<String> _types = ['all', 'agent', 'image', 'video'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadPosts();
    });
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final posts = await ApiService.getExplore(type: _types[_tabController.index]);
      if (mounted) setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(dynamic post) async {
    try {
      final result = await ApiService.likePost(post['id']);
      if (mounted) {
        setState(() {
          final liked = result['liked'] == true;
          final current = (post['likes'] ?? 0) as int;
          post['likes'] = liked ? current + 1 : (current - 1 < 0 ? 0 : current - 1);
        });
      }
    } catch (_) {}
  }

  Future<void> _cloneAgent(dynamic post) async {
    try {
      await ApiService.cloneAgent(post['agent_id']);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('智能体已添加到我的智能体')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('添加失败: $e')));
    }
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final mediaCtrl = TextEditingController();
    String selectedType = 'image';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('发布内容'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: '类型'),
                items: const [
                  DropdownMenuItem(value: 'image', child: Text('图片')),
                  DropdownMenuItem(value: 'video', child: Text('视频')),
                  DropdownMenuItem(value: 'agent', child: Text('智能体')),
                ],
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '标题')),
              const SizedBox(height: 12),
              TextField(controller: contentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: '描述')),
              if (selectedType != 'agent') ...[
                const SizedBox(height: 12),
                TextField(controller: mediaCtrl, decoration: const InputDecoration(labelText: '媒体URL')),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('请填写标题')));
                  return;
                }
                try {
                  await ApiService.createMediaPost(
                    title: titleCtrl.text,
                    content: contentCtrl.text,
                    type: selectedType,
                    mediaUrl: mediaCtrl.text,
                  );
                  Navigator.pop(ctx);
                  _loadPosts();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('发布成功')));
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('发布失败: $e')));
                }
              },
              child: const Text('发布'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('探索'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: '智能体选',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentLeaderboardPage())),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _showCreateDialog),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: _posts.isEmpty
                  ? ListView(children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      const Center(child: Text('暂无内容', style: TextStyle(color: AppTheme.textSecondary))),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) => _buildPostCard(_posts[index]),
                    ),
            ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    final type = post['type'] ?? 'image';
    final mediaUrl = post['media_url'] ?? '';
    final isAgent = type == 'agent' && post['agent_name'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: Text(
                (post['author_nickname'] ?? '?')[0],
                style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(post['author_nickname'] ?? '匿名', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _typeColor(type).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Text(_typeLabel(type), style: TextStyle(fontSize: 11, color: _typeColor(type), fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
        if (mediaUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ImagePreviewPage(imageUrl: mediaUrl))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: mediaUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Container(height: 180, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                  errorWidget: (_, __, ___) => Container(height: 180, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                ),
              ),
            ),
          ),
        if (isAgent)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Text((post['agent_name'] ?? '?')[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(post['agent_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(post['content'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                if (post['agent_id'] != null)
                  ElevatedButton(
                    onPressed: () => _cloneAgent(post),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('使用', style: TextStyle(fontSize: 12)),
                  ),
              ]),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Text(post['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        if (type != 'agent' && (post['content'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(post['content'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(children: [
            GestureDetector(
              onTap: () => _toggleLike(post),
              child: Row(children: [
                Icon(Icons.favorite, size: 18, color: (post['likes'] ?? 0) > 0 ? Colors.red : AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text('${post['likes'] ?? 0}', style: const TextStyle(fontSize: 13)),
              ]),
            ),
            const Spacer(),
            Text(post['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ]),
        ),
      ]),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'agent':
        return Colors.purple;
      case 'video':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'agent':
        return '智能体';
      case 'video':
        return '视频';
      default:
        return '图片';
    }
  }
}
