import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<dynamic> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await ApiService.getPosts();
      if (mounted) setState(() { _posts = posts; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(dynamic post) async {
    try {
      final result = await ApiService.likePost(post['id']);
      if (mounted) {
        setState(() {
          post['likes'] = (result['liked'] == true) ? (post['likes'] ?? 0) + 1 : (post['likes'] ?? 0) - 1;
        });
      }
    } catch (_) {}
  }

  void _showCreatePostDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('发布帖子'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '标题')),
          const SizedBox(height: 12),
          TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: '内容')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () async {
            if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('请填写标题和内容')));
              return;
            }
            try {
              await ApiService.createPost(titleCtrl.text, contentCtrl.text);
              Navigator.pop(ctx);
              _loadPosts();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('发布成功')));
            } catch (e) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('发布失败（可能包含违规内容）: $e')));
            }
          }, child: const Text('发布')),
        ],
      ),
    );
  }

  void _showPostDetail(dynamic post) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(post: post, onLike: () => _toggleLike(post))));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('探索'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showCreatePostDialog)]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _loadPosts,
        child: _posts.isEmpty ? ListView(children: [SizedBox(height: MediaQuery.of(context).size.height * 0.3), const Center(child: Text('暂无帖子，点击右上角发布', style: TextStyle(color: AppTheme.textSecondary)))]) : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];
            return GestureDetector(
              onTap: () => _showPostDetail(post),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(radius: 18, backgroundColor: AppTheme.primaryColor.withOpacity(0.2), child: Text((post['author_nickname'] ?? '?')[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(post['author_nickname'] ?? '匿名', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    Text(post['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ]),
                  const SizedBox(height: 12),
                  Text(post['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(post['content'] ?? '', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(children: [
                    GestureDetector(onTap: () => _toggleLike(post), child: Row(children: [Icon(Icons.favorite_border, size: 18, color: post['likes'] > 0 ? Colors.red : AppTheme.textSecondary), const SizedBox(width: 4), Text('${post['likes'] ?? 0}', style: const TextStyle(fontSize: 13))])),
                    const SizedBox(width: 20),
                    Row(children: [const Icon(Icons.comment_outlined, size: 18, color: AppTheme.textSecondary), const SizedBox(width: 4), Text('${post['comments_count'] ?? 0}', style: const TextStyle(fontSize: 13))]),
                  ]),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PostDetailPage extends StatefulWidget {
  final dynamic post;
  final VoidCallback onLike;
  const PostDetailPage({super.key, required this.post, required this.onLike});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  List<dynamic> _comments = [];
  final _commentCtrl = TextEditingController();
  bool _loadingComments = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await ApiService.getComments(widget.post['id']);
      if (mounted) setState(() { _comments = comments; _loadingComments = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _submitComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    try {
      await ApiService.createComment(widget.post['id'], _commentCtrl.text.trim());
      _commentCtrl.clear();
      _loadComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('评论失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('帖子详情')),
      body: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [CircleAvatar(radius: 20, backgroundColor: AppTheme.primaryColor.withOpacity(0.2), child: Text((widget.post['author_nickname'] ?? '?')[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))), const SizedBox(width: 8), Expanded(child: Text(widget.post['author_nickname'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)))]),
            const SizedBox(height: 12),
            Text(widget.post['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(widget.post['content'] ?? '', style: const TextStyle(fontSize: 15, height: 1.6)),
            const SizedBox(height: 16),
            Row(children: [
              GestureDetector(onTap: widget.onLike, child: Row(children: [Icon(Icons.favorite, size: 20, color: widget.post['likes'] > 0 ? Colors.red : AppTheme.textSecondary), const SizedBox(width: 4), Text('${widget.post['likes'] ?? 0}')])),
              const SizedBox(width: 20),
              Row(children: [const Icon(Icons.comment_outlined, size: 20, color: AppTheme.textSecondary), const SizedBox(width: 4), Text('${_comments.length}')]),
            ]),
          ])),
          const SizedBox(height: 20),
          const Text('评论', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_loadingComments) const Center(child: CircularProgressIndicator()) else if (_comments.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('暂无评论', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary))) else ..._comments.map((c) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(radius: 16, backgroundColor: AppTheme.primaryColor.withOpacity(0.2), child: Text((c['author_nickname'] ?? '?')[0], style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor))), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['author_nickname'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(c['content'] ?? '', style: const TextStyle(fontSize: 14))])),]))),
        ])),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : AppTheme.surfaceColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]), child: SafeArea(child: Row(children: [Expanded(child: TextField(controller: _commentCtrl, decoration: InputDecoration(hintText: '写评论...', filled: true, fillColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)))), const SizedBox(width: 8), ElevatedButton(onPressed: _submitComment, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), child: const Text('发送'))]))),
      ]),
    );
  }
}
