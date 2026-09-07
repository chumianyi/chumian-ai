import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_dialog.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_empty_state.dart';
import 'package:chumian_ai/widgets/miuix/miuix_avatar.dart';

/// ============================================================
/// MyPostsPage —— 我的帖子
/// 帖子列表，编辑/删除，粉色卡片，错落入场，空状态
/// ============================================================
class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _refreshController;

  List<PostItem> _posts = [];
  bool _isLoading = true;
  int _selectedFilter = 0;

  static const List<String> _filters = ['全部', '已发布', '草稿', '已删除'];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _refreshController = AnimationController(
      vsync: this,
      duration: MiuixDuration.normal,
    );
    _entryController.forward();
    _loadPosts();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _posts = [
        PostItem(
          id: '1',
          title: '初眠AI使用体验分享',
          content: '用了初眠AI一段时间了，整体体验非常棒！界面设计精美，AI回复速度快，特别是写作功能帮了大忙...',
          type: '分享',
          likes: 128,
          comments: 32,
          views: 1024,
          time: DateTime.now().subtract(const Duration(hours: 3)),
          status: 'published',
          images: 2,
        ),
        PostItem(
          id: '2',
          title: '关于AI绘画的一些技巧',
          content: '分享几个AI绘画的prompt技巧，让生成的图片更符合预期。首先要明确主体，然后描述环境和氛围...',
          type: '教程',
          likes: 256,
          comments: 45,
          views: 2048,
          time: DateTime.now().subtract(const Duration(days: 1)),
          status: 'published',
          images: 4,
        ),
        PostItem(
          id: '3',
          title: '社区活动参与感想',
          content: '参加了这次社区的创作活动，收获满满！认识了很多志同道合的朋友，也学到了很多新知识...',
          type: '活动',
          likes: 89,
          comments: 12,
          views: 512,
          time: DateTime.now().subtract(const Duration(days: 3)),
          status: 'published',
          images: 1,
        ),
        PostItem(
          id: '4',
          title: '草稿：待完善的技术文章',
          content: '这篇文章还在构思中，主要想聊聊Flutter开发中的一些最佳实践和性能优化技巧...',
          type: '技术',
          likes: 0,
          comments: 0,
          views: 0,
          time: DateTime.now().subtract(const Duration(days: 5)),
          status: 'draft',
          images: 0,
        ),
      ];
      _isLoading = false;
    });
  }

  List<PostItem> get _filteredPosts {
    if (_selectedFilter == 0) return _posts;
    if (_selectedFilter == 1) {
      return _posts.where((p) => p.status == 'published').toList();
    }
    if (_selectedFilter == 2) {
      return _posts.where((p) => p.status == 'draft').toList();
    }
    return _posts.where((p) => p.status == 'deleted').toList();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
            curve: Curves.easeOutCubic),
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: slide.value, child: child),
      ),
    );
  }

  void _deletePost(PostItem post) {
    MiuixDialog.show(
      context,
      title: '删除确认',
      content: '确定要删除帖子「${post.title}」吗？删除后不可恢复。',
      type: MiuixDialogType.warning,
      confirmText: '删除',
      onConfirm: () {
        setState(() {
          _posts.removeWhere((p) => p.id == post.id);
        });
        MiuixToast.show(context,
            message: '帖子已删除', type: MiuixToastType.success);
      },
    );
  }

  void _editPost(PostItem post) {
    MiuixToast.show(context,
        message: '正在打开编辑器...', type: MiuixToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '我的帖子',
        backgroundColor: MiuixColors.background,
        actions: [
          MiuixIconButton(
            icon: Icons.add,
            style: MiuixIconButtonStyle.filled,
            onPressed: () {
              MiuixToast.show(context,
                  message: '打开发帖页面', type: MiuixToastType.info);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(MiuixColors.primary),
                    ),
                  )
                : _filteredPosts.isEmpty
                    ? const MiuixEmptyState(
                        title: '暂无帖子',
                        description: '快去发布你的第一篇帖子吧',
                        icon: Icons.edit_note,
                        actionLabel: '去发帖',
                      )
                    : RefreshIndicator(
                        color: MiuixColors.primary,
                        onRefresh: _loadPosts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPosts.length,
                          itemBuilder: (context, index) {
                            return _buildAnimatedItem(
                              _buildPostCard(_filteredPosts[index]),
                              index,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilter == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MiuixRipple(
              borderRadius: MiuixRadius.pill,
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: AnimatedContainer(
                  duration: MiuixDuration.fast,
                  curve: MiuixCurves.miuixSpring,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(colors: MiuixColors.primaryGradient)
                        : null,
                    color: isSelected ? null : MiuixColors.surface,
                    borderRadius: MiuixRadius.pillRadius,
                    border: Border.all(
                      color: isSelected
                          ? MiuixColors.primary
                          : MiuixColors.borderLight,
                    ),
                  ),
                  child: Text(
                    _filters[index],
                    style: TextStyle(
                      fontSize: MiuixFontSize.sm,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : MiuixColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPostCard(PostItem post) {
    final isDraft = post.status == 'draft';
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _editPost(post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDraft
                      ? MiuixColors.warning.withOpacity(0.15)
                      : MiuixColors.primaryLight.withOpacity(0.2),
                  borderRadius: MiuixRadius.pillRadius,
                ),
                child: Text(
                  isDraft ? '草稿' : post.type,
                  style: TextStyle(
                    fontSize: MiuixFontSize.xs,
                    fontWeight: FontWeight.w600,
                    color: isDraft
                        ? MiuixColors.warning
                        : MiuixColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(post.time),
                style: const TextStyle(
                  fontSize: MiuixFontSize.xs,
                  color: MiuixColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: MiuixFontSize.md,
              color: MiuixColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (post.images > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: List.generate(post.images.clamp(0, 3), (index) {
                return Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MiuixColors.primaryLight.withOpacity(0.3),
                        MiuixColors.primary.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: MiuixRadius.smRadius,
                  ),
                  child: const Icon(Icons.image,
                      color: MiuixColors.primary, size: 24),
                );
              }),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStat(Icons.favorite_border, post.likes.toString()),
              const SizedBox(width: 16),
              _buildStat(Icons.chat_bubble_outline, post.comments.toString()),
              const SizedBox(width: 16),
              _buildStat(Icons.visibility, post.views.toString()),
              const Spacer(),
              MiuixIconButton(
                icon: Icons.edit,
                style: MiuixIconButtonStyle.ghost,
                size: 36,
                iconSize: 18,
                onPressed: () => _editPost(post),
              ),
              MiuixIconButton(
                icon: Icons.delete_outline,
                style: MiuixIconButtonStyle.ghost,
                size: 36,
                iconSize: 18,
                color: MiuixColors.error,
                onPressed: () => _deletePost(post),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: MiuixColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          count,
          style: const TextStyle(
            fontSize: MiuixFontSize.sm,
            color: MiuixColors.textTertiary,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}月${time.day}日';
  }
}

class PostItem {
  final String id;
  final String title;
  final String content;
  final String type;
  final int likes;
  final int comments;
  final int views;
  final DateTime time;
  final String status;
  final int images;
  const PostItem({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.likes,
    required this.comments,
    required this.views,
    required this.time,
    required this.status,
    required this.images,
  });
}
