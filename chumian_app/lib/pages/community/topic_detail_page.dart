import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/models/post_model.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_avatar.dart';

/// ============================================================
/// TopicDetailPage —— 话题详情页
/// 话题标题+热度+参与人数，帖子列表，发帖按钮
/// 粉色主题，下拉刷新，错落入场动画
/// ============================================================

class TopicDetailPage extends StatefulWidget {
  const TopicDetailPage({
    super.key,
    this.topicId = '1',
    this.topicTitle = '初眠AI新版本发布',
  });

  final String topicId;
  final String topicTitle;

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isJoined = false;
  String? _errorMessage;
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadPosts();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ApiService.getPostsByTopic(widget.topicId);
      setState(() {
        _posts = Post.fromList(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      final data = await ApiService.getPostsByTopic(widget.topicId);
      setState(() {
        _posts = Post.fromList(data);
        _isRefreshing = false;
      });
    } catch (_) {
      setState(() => _isRefreshing = false);
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}月${date.day}日';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: MiuixColors.surface,
            leading: MiuixIconButton(
              icon: Icons.arrow_back_ios_new,
              style: MiuixIconButtonStyle.glass,
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              MiuixIconButton(
                icon: Icons.share,
                style: MiuixIconButtonStyle.glass,
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildTopicHeader(),
            ),
          ),
          SliverToBoxAdapter(child: _buildTopicInfo()),
          SliverToBoxAdapter(child: _buildPostListHeader()),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(MiuixSpacing.xxl),
                child: Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(MiuixColors.primary),
                )),
              ),
            )
          else if (_errorMessage != null)
            SliverToBoxAdapter(child: _buildErrorState())
          else if (_posts.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPostCard(_posts[index], index),
                childCount: _posts.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildTopicHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MiuixColors.primary,
            MiuixColors.primaryLight,
            MiuixColors.softGradient.first,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MiuixSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: MiuixRadius.pillRadius,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('热门话题', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: MiuixSpacing.sm),
                Text(
                  '#${widget.topicTitle}',
                  style: const TextStyle(
                    fontSize: MiuixFontSize.xxl,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicInfo() {
    return Container(
      margin: const EdgeInsets.all(MiuixSpacing.md),
      padding: const EdgeInsets.all(MiuixSpacing.lg),
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: MiuixRadius.lgRadius,
        boxShadow: MiuixShadows.sm,
      ),
      child: Row(
        children: [
          _buildStatItem('98.5k', '热度'),
          _buildVerticalDivider(),
          _buildStatItem('1,256', '帖子'),
          _buildVerticalDivider(),
          _buildStatItem('8,932', '参与'),
          const Spacer(),
          MiuixButton(
            label: _isJoined ? '已参与' : '参与话题',
            type: _isJoined ? MiuixButtonType.secondary : MiuixButtonType.primary,
            size: MiuixButtonSize.small,
            icon: _isJoined ? Icons.check : Icons.add,
            onPressed: () => setState(() => _isJoined = !_isJoined),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: MiuixFontSize.lg,
            fontWeight: FontWeight.w700,
            color: MiuixColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: MiuixFontSize.xs,
            color: MiuixColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: MiuixSpacing.lg),
      color: MiuixColors.divider,
    );
  }

  Widget _buildPostListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(MiuixSpacing.lg, MiuixSpacing.sm, MiuixSpacing.lg, MiuixSpacing.sm),
      child: Row(
        children: [
          const Text(
            '全部帖子',
            style: TextStyle(
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const Spacer(),
          MiuixRipple(
            onTap: () {},
            borderRadius: MiuixRadius.pill,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: MiuixSpacing.sm, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.sort, size: 14, color: MiuixColors.textSecondary),
                  SizedBox(width: 4),
                  Text('最新', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post, int index) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(
        0.2 + index * 0.06,
        1.0,
        curve: MiuixCurves.easeOut,
      ),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(anim),
        child: MiuixCard(
          margin: const EdgeInsets.symmetric(
            horizontal: MiuixSpacing.md,
            vertical: MiuixSpacing.xs,
          ),
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: MiuixColors.softGradient),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, size: 18, color: MiuixColors.primary),
                  ),
                  const SizedBox(width: MiuixSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userNickname ?? '匿名用户',
                          style: const TextStyle(
                            fontSize: MiuixFontSize.md,
                            fontWeight: FontWeight.w600,
                            color: MiuixColors.textPrimary,
                          ),
                        ),
                        Text(
                          _formatTime(post.createdAt),
                          style: const TextStyle(
                            fontSize: MiuixFontSize.xs,
                            color: MiuixColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  MiuixIconButton(
                    icon: Icons.more_horiz,
                    style: MiuixIconButtonStyle.ghost,
                    size: 32,
                    iconSize: 18,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: MiuixSpacing.sm),
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const SizedBox(height: MiuixSpacing.xs),
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: MiuixFontSize.sm,
                  color: MiuixColors.textSecondary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: MiuixSpacing.md),
              Row(
                children: [
                  _buildActionChip(Icons.favorite_border, '${post.likes}', MiuixColors.error),
                  const SizedBox(width: MiuixSpacing.lg),
                  _buildActionChip(Icons.chat_bubble_outline, '${post.commentsCount}', MiuixColors.primary),
                  const SizedBox(width: MiuixSpacing.lg),
                  _buildActionChip(Icons.share, '分享', MiuixColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: MiuixFontSize.sm, color: color),
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return MiuixRipple(
      onTap: () {},
      borderRadius: MiuixRadius.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MiuixSpacing.lg,
          vertical: MiuixSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
          borderRadius: MiuixRadius.pillRadius,
          boxShadow: [
            BoxShadow(
              color: MiuixColors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 18, color: Colors.white),
            SizedBox(width: 6),
            Text(
              '发帖',
              style: TextStyle(
                fontSize: MiuixFontSize.md,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(MiuixSpacing.xxl),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: MiuixColors.error),
          const SizedBox(height: 12),
          const Text('加载失败', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 4),
          Text(_errorMessage ?? '未知错误', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          TextButton.icon(onPressed: _loadPosts, icon: const Icon(Icons.refresh, size: 18), label: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(MiuixSpacing.xxl),
      child: Column(
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: MiuixColors.surfaceVariant, shape: BoxShape.circle), child: const Icon(Icons.article_outlined, size: 36, color: MiuixColors.textTertiary)),
          const SizedBox(height: MiuixSpacing.lg),
          const Text('暂无帖子', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textSecondary)),
          const SizedBox(height: MiuixSpacing.sm),
          const Text('快来发布第一条帖子吧', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
        ],
      ),
    );
  }
}
