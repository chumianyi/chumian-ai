import 'package:flutter/material.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/providers/theme_provider.dart';
import 'package:chumian_ai/pages/post_detail_page.dart';
import 'package:chumian_ai/pages/user_profile_page.dart';

/// ============================================================
/// ExplorePage —— 探索页
/// Tab(全部/图片/视频/文字) + 瀑布流帖子卡片 + 下拉刷新 + 上拉加载
/// ============================================================
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final List<PostItem> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;

  static const List<String> _tabs = ['全部', '图片', '视频', '文字'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _refreshPosts();
      }
    });
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _posts.clear();
      _page = 1;
      _hasMore = true;
    });
    await _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getExplore(page: _page);
      final newPosts = (data as List<dynamic>? ?? [])
          .map((e) => PostItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _page++;
          _isLoading = false;
          _hasMore = newPosts.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    await _loadPosts();
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDark ? MiuixColors.darkBackground : MiuixColors.background,
      body: Column(
        children: [
          _buildTabBar(isDark),
          Expanded(
            child: RefreshIndicator(
              color: MiuixColors.primary,
              onRefresh: _refreshPosts,
              child: _posts.isEmpty && _isLoading
                  ? _buildSkeletonList()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _posts.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _posts.length) {
                          return _buildLoadMore();
                        }
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: MiuixDuration.normal,
                          curve: Interval((index % 5) * 0.1, (index % 5) * 0.1 + 0.9, curve: MiuixCurves.easeOut),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(offset: Offset(0, (1 - value) * 30), child: child),
                            );
                          },
                          child: _buildPostCard(_posts[index], isDark),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      color: isDark ? MiuixColors.darkSurface : MiuixColors.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: MiuixColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: MiuixColors.primary,
        unselectedLabelColor: MiuixColors.textTertiary,
        labelStyle: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w400),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildPostCard(PostItem post, bool isDark) {
    return MiuixRipple(
      borderRadius: MiuixRadius.lg,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: PostDetailPage(postId: post.id)),
              transitionDuration: MiuixDuration.page,
            ),
          );
        },
        child: MiuixGlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          borderRadius: MiuixRadius.lg,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostHeader(post, isDark),
              const SizedBox(height: 10),
              Text(
                post.content,
                style: TextStyle(color: isDark ? MiuixColors.darkTextPrimary : MiuixColors.textPrimary, fontSize: MiuixFontSize.md, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (post.imageUrl != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: MiuixRadius.mdRadius,
                  child: Image.network(
                    post.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: MiuixColors.surfaceVariant,
                      child: const Icon(Icons.image_not_supported, color: MiuixColors.textTertiary, size: 40),
                    ),
                  ),
                ),
              ],
              if (post.videoUrl != null) ...[
                const SizedBox(height: 10),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: MiuixRadius.mdRadius,
                  ),
                  child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48)),
                ),
              ],
              const SizedBox(height: 10),
              _buildPostFooter(post),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader(PostItem post, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => UserProfilePage(userId: post.userId)),
        );
      },
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: MiuixColors.softGradient),
            ),
            child: const Center(child: Icon(Icons.person, color: MiuixColors.primary, size: 22)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.nickname, style: TextStyle(color: isDark ? MiuixColors.darkTextPrimary : MiuixColors.textPrimary, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600)),
                Text(_formatTime(post.timestamp), style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
              ],
            ),
          ),
          if (post.type == 'video')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: MiuixColors.primary.withOpacity(0.1), borderRadius: MiuixRadius.xsRadius),
              child: const Icon(Icons.videocam, color: MiuixColors.primary, size: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildPostFooter(PostItem post) {
    return Row(
      children: [
        Icon(Icons.favorite_border, color: MiuixColors.textTertiary, size: 18),
        const SizedBox(width: 4),
        Text('${post.likes}', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)),
        const SizedBox(width: 20),
        Icon(Icons.chat_bubble_outline, color: MiuixColors.textTertiary, size: 18),
        const SizedBox(width: 4),
        Text('${post.comments}', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)),
        const Spacer(),
        Icon(Icons.share_outlined, color: MiuixColors.textTertiary, size: 18),
      ],
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: MiuixColors.surfaceVariant, borderRadius: MiuixRadius.lgRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 40, height: 40, decoration: const BoxDecoration(color: MiuixColors.border, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 80, height: 14, decoration: BoxDecoration(color: MiuixColors.border, borderRadius: MiuixRadius.xsRadius)),
                const SizedBox(height: 6),
                Container(width: 50, height: 10, decoration: BoxDecoration(color: MiuixColors.border, borderRadius: MiuixRadius.xsRadius)),
              ]),
            ]),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: MiuixColors.border, borderRadius: MiuixRadius.xsRadius)),
            const SizedBox(height: 8),
            Container(width: 200, height: 12, decoration: BoxDecoration(color: MiuixColors.border, borderRadius: MiuixRadius.xsRadius)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: MiuixColors.primary, strokeWidth: 2))
            : Text('没有更多了', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

class PostItem {
  PostItem({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.content,
    required this.type,
    this.imageUrl,
    this.videoUrl,
    required this.likes,
    required this.comments,
    required this.timestamp,
  });

  final String id;
  final String userId;
  final String nickname;
  final String avatar;
  final String content;
  final String type;
  final String? imageUrl;
  final String? videoUrl;
  final int likes;
  final int comments;
  final DateTime timestamp;

  factory PostItem.fromJson(Map<String, dynamic> json) {
    return PostItem(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      videoUrl: json['video_url']?.toString() ?? json['videoUrl']?.toString(),
      likes: (json['likes'] ?? 0) as int,
      comments: (json['comments'] ?? 0) as int,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
