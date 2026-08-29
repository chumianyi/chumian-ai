import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../widgets/context_ext.dart';
import '../widgets/app_card.dart';
import '../widgets/avatar.dart';
import '../widgets/feedback.dart';
import '../widgets/gradient_header.dart';
import '../widgets/buttons.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'agent_leaderboard_page.dart';
import 'image_preview_page.dart';
import 'user_profile_page.dart';
import '../utils/animations.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _posts = [];
  bool _loading = true;
  bool _loadFailed = false;
  late TabController _tabController;
  final Set<String> _likedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: ExploreCategories.all.length, vsync: this);
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
    setState(() {
      _loading = _posts.isEmpty;
      _loadFailed = false;
    });
    try {
      final posts = await ApiService.getExplore(type: _types[_tabController.index]);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  List<String> get _types {
    return ExploreCategories.all.map((c) => c.id).toList();
  }

  Future<void> _toggleLike(dynamic post) async {
    final id = post['id']?.toString() ?? '';
    final wasLiked = _likedIds.contains(id);
    setState(() {
      if (wasLiked) {
        _likedIds.remove(id);
        post['likes'] = math.max(0, ((post['likes'] ?? 0) as num) - 1);
      } else {
        _likedIds.add(id);
        post['likes'] = (post['likes'] ?? 0) + 1;
      }
    });
    try {
      await ApiService.likePost(id);
    } catch (_) {
      if (mounted) {
        setState(() {
          if (wasLiked) {
            _likedIds.add(id);
          } else {
            _likedIds.remove(id);
          }
          post['likes'] = math.max(0, (post['likes'] ?? 0) as num);
        });
      }
    }
  }

  Future<void> _cloneAgent(dynamic post) async {
    try {
      await ApiService.cloneAgent(post['agent_id']);
      if (!mounted) return;
      _showSnack('智能体已添加到我的智能体');
    } catch (e) {
      if (!mounted) return;
      _showSnack('添加失败: ${ErrorMessages.of(e)}');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openUser(String? nickname, String? userId) {
    if (userId == null || userId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfilePage(userId: userId)),
    );
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final mediaCtrl = TextEditingController();
    String selectedType = 'image';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 8,
        ),
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (ctx, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '发布内容',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: '类型'),
                        items: const [
                          DropdownMenuItem(value: 'image', child: Text('图片')),
                          DropdownMenuItem(value: 'video', child: Text('视频')),
                          DropdownMenuItem(value: 'agent', child: Text('智能体')),
                        ],
                        onChanged: (v) =>
                            setSheetState(() => selectedType = v ?? 'image'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: '标题'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? '请填写标题' : null,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contentCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: '描述'),
                      ),
                      if (selectedType != 'agent') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: mediaCtrl,
                          decoration: const InputDecoration(labelText: '媒体URL'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: '发布',
                    icon: Icons.send_rounded,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        await ApiService.createMediaPost(
                          title: titleCtrl.text,
                          content: contentCtrl.text,
                          type: selectedType,
                          mediaUrl: mediaCtrl.text,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _loadPosts();
                        _showSnack('发布成功');
                      } catch (e) {
                        if (!ctx.mounted) return;
                        _showSnack('发布失败: ${ErrorMessages.of(e)}');
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('探索'),
        actions: [
          IconAction(
            icon: Icons.emoji_events_outlined,
            tooltip: '智能体选',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AgentLeaderboardPage()),
            ),
          ),
          IconAction(
            icon: Icons.add_circle_outline_rounded,
            tooltip: '发布内容',
            onPressed: _showCreateDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: ExploreCategories.all
              .map((c) => Tab(
                    height: 42,
                    text: c.label,
                    iconMargin: const EdgeInsets.only(right: 4),
                  ))
              .toList(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const ListSkeleton(items: 4);
    }
    if (_loadFailed) {
      return ErrorRetry(message: '内容加载失败，请检查网络', onRetry: _loadPosts);
    }
    return AppRefreshable(
      onRefresh: _loadPosts,
      child: _posts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                const EmptyState(
                  icon: Icons.explore_off_outlined,
                  title: '暂无内容',
                  subtitle: '来发布第一条内容吧，或切换到其他分类看看',
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _posts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHeroBanner();
                }
                return _buildPostCard(_posts[index - 1]);
              },
            ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: context.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '发现有趣的内容',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.onPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '创作者、智能体与灵感都在这里',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: context.onPrimary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.explore_rounded, color: context.onPrimary, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    final type = post['type'] ?? 'image';
    final mediaUrl = post['media_url'] ?? '';
    final isAgent = type == 'agent' && post['agent_name'] != null;
    final authorName = post['author_nickname'] ?? '匿名';
    final userId = post['author_id']?.toString();
    final likes = post['likes'] ?? 0;
    final id = post['id']?.toString() ?? '';
    final liked = _likedIds.contains(id);
    final category = ExploreCategories.of(type);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 作者行
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openUser(authorName, userId),
                  child: AppAvatar(
                    imageUrl: post['author_avatar']?.toString(),
                    name: authorName,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openUser(authorName, userId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        if (post['created_at'] != null)
                          Text(
                            Formatters.formatDateTime(post['created_at']?.toString()),
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                PillTag(
                  text: category.label,
                  icon: category.icon,
                  color: _typeColor(type),
                  background: _typeColor(type).withValues(alpha: 0.12),
                ),
              ],
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Text(
              post['title'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
                height: 1.3,
              ),
            ),
          ),
          // 媒体
          if (mediaUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImagePreviewPage(imageUrl: mediaUrl),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: CachedNetworkImage(
                      imageUrl: mediaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        color: context.surfaceSubtle,
                        child: const Center(child: Spinner(size: 22)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: context.surfaceSubtle,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: context.textTertiary,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          // 智能体卡
          if (isAgent)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: context.vibrantGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.smart_toy_outlined,
                        size: 22,
                        color: context.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['agent_name'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            post['content'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (post['agent_id'] != null)
                      GestureDetector(
                        onTap: () => _cloneAgent(post),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: context.vibrantGradient,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '使用',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.onPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // 描述
          if (type != 'agent' && (post['content'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(
                post['content'] ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          // 互动行
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Row(
              children: [
                _LikeButton(
                  liked: liked,
                  count: likes,
                  onTap: () => _toggleLike(post),
                ),
                const SizedBox(width: 4),
                _MetaIcon(
                  icon: Icons.remove_red_eye_outlined,
                  label: '${post['views'] ?? 0}',
                  color: context.textTertiary,
                ),
                const Spacer(),
                if (type == 'video')
                  PillTag(
                    text: '视频',
                    icon: Icons.play_arrow_rounded,
                    color: context.danger,
                    fontSize: 10,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'agent':
        return const Color(0xFF9C6ADE);
      case 'video':
        return const Color(0xFFE8445C);
      case 'image':
        return const Color(0xFF3D7BF0);
      default:
        return context.info;
    }
  }
}

/// 点赞按钮（带动画）。
class _LikeButton extends StatefulWidget {
  final bool liked;
  final num count;
  final VoidCallback onTap;

  const _LikeButton({
    required this.liked,
    required this.count,
    required this.onTap,
  });

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.6,
      upperBound: 1.3,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void didUpdateWidget(_LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liked != widget.liked) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Icon(
                widget.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 20,
                color: widget.liked ? context.danger : context.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              Formatters.compactNumber(widget.count),
              style: TextStyle(
                fontSize: 13,
                fontWeight: widget.liked ? FontWeight.w700 : FontWeight.w500,
                color: widget.liked ? context.danger : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 元信息小图标。
class _MetaIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaIcon({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}
