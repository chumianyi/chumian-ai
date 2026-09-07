import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/services/api_service.dart';

/// ============================================================
/// PostDetailPage —— 帖子详情页
/// 内容+图片/视频 + 评论列表 + 评论输入框 + 点赞
/// ============================================================
class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLiked = false;
  int _likeCount = 256;
  bool _isLoading = true;
  Map<String, dynamic>? _post;
  final List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _post = {
        'id': widget.postId,
        'user_id': 'user_1',
        'nickname': '初眠用户',
        'content': '今天用初眠AI生成了一幅超美的插画，粉色系太治愈了！分享给大家～用了新出的图像生成模型，效果真的惊艳，细节处理非常到位。大家也可以试试，提示词写详细一点效果更好！',
        'type': 'image',
        'image_url': 'https://picsum.photos/600/400?random=42',
        'likes': 256,
        'comments': 18,
        'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      };
      _likeCount = 256;
      _comments.addAll(List.generate(6, (i) => {
        'id': 'comment_$i',
        'user_id': 'user_${i + 2}',
        'nickname': ['AI爱好者', '创作者', '设计师', '程序员', '诗人', '摄影师'][i],
        'content': [
          '太美了！请问用的什么模型？',
          '粉色系绝了，收藏了！',
          '提示词能分享一下吗？',
          '初眠AI的图像生成越来越强了',
          '已关注，期待更多作品！',
          '这个配色太治愈了～',
        ][i],
        'created_at': DateTime.now().subtract(Duration(minutes: 30 - i * 5)).toIso8601String(),
      }));
      _isLoading = false;
    });
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    setState(() {
      _comments.insert(0, {
        'id': 'comment_new_${DateTime.now().microsecondsSinceEpoch}',
        'user_id': 'me',
        'nickname': '我',
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('评论发布成功'),
        backgroundColor: MiuixColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius),
      ),
    );
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: AppBar(
        backgroundColor: MiuixColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('帖子详情', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: Icon(Icons.share, color: MiuixColors.primary), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MiuixColors.primary))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPostHeader(),
                      const SizedBox(height: 14),
                      _buildPostContent(),
                      if (_post?['image_url'] != null) ...[
                        const SizedBox(height: 14),
                        _buildPostImage(),
                      ],
                      const SizedBox(height: 16),
                      _buildActionBar(),
                      const SizedBox(height: 20),
                      _buildCommentSection(),
                    ],
                  ),
                ),
                _buildCommentInput(),
              ],
            ),
    );
  }

  Widget _buildPostHeader() {
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: MiuixColors.softGradient)),
          child: const Center(child: Icon(Icons.person, color: MiuixColors.primary, size: 26)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_post?['nickname'] ?? '', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600)),
              Text('3小时前', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
            ],
          ),
        ),
        MiuixRipple(
          borderRadius: MiuixRadius.pill,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
              borderRadius: MiuixRadius.pillRadius,
            ),
            child: const Text('关注', style: TextStyle(color: Colors.white, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }

  Widget _buildPostContent() {
    return Text(
      _post?['content'] ?? '',
      style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md, height: 1.7),
    );
  }

  Widget _buildPostImage() {
    return ClipRRect(
      borderRadius: MiuixRadius.lgRadius,
      child: Image.network(
        _post!['image_url'],
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(height: 200, color: MiuixColors.surfaceVariant, child: const Icon(Icons.image_not_supported, color: MiuixColors.textTertiary, size: 48)),
      ),
    );
  }

  Widget _buildActionBar() {
    return MiuixGlassContainer(
      borderRadius: MiuixRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: _toggleLike,
            child: AnimatedScale(
              scale: _isLiked ? 1.2 : 1.0,
              duration: MiuixDuration.fast,
              child: Row(
                children: [
                  Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? MiuixColors.error : MiuixColors.textTertiary, size: 22),
                  const SizedBox(width: 6),
                  Text('$_likeCount', style: TextStyle(color: _isLiked ? MiuixColors.error : MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: MiuixColors.textTertiary, size: 22),
              const SizedBox(width: 6),
              Text('${_comments.length}', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)),
            ],
          ),
          Row(
            children: [
              Icon(Icons.bookmark_border, color: MiuixColors.textTertiary, size: 22),
              const SizedBox(width: 6),
              Text('收藏', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('评论 (${_comments.length})', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, color: MiuixColors.textTertiary, size: 48),
                  const SizedBox(height: 8),
                  Text('暂无评论，快来抢沙发吧', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)),
                ],
              ),
            ),
          )
        else
          ..._comments.asMap().entries.map((entry) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: MiuixDuration.normal,
              curve: Interval((entry.key % 5) * 0.1, (entry.key % 5) * 0.1 + 0.9, curve: MiuixCurves.easeOut),
              builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, (1 - value) * 20), child: child)),
              child: _buildCommentItem(entry.value),
            );
          }),
      ],
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: MiuixColors.primary.withValues(alpha: 0.1)),
            child: const Center(child: Icon(Icons.person, color: MiuixColors.primary, size: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment['nickname'], style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                MiuixGlassContainer(
                  borderRadius: MiuixRadius.md,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(comment['content'], style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.sm, height: 1.5)),
                ),
                const SizedBox(height: 4),
                Text('刚刚', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return MiuixGlassContainer(
      blur: 24,
      borderRadius: 0,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      borderColor: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: MiuixColors.surface,
                    borderRadius: MiuixRadius.pillRadius,
                    border: Border.all(color: MiuixColors.border, width: 1),
                  ),
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md),
                    decoration: InputDecoration(
                      hintText: '说点什么...',
                      hintStyle: TextStyle(color: MiuixColors.textTertiary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MiuixRipple(
                borderRadius: MiuixRadius.pill,
                child: GestureDetector(
                  onTap: _submitComment,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
