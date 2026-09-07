import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// CommentDetailPage —— 评论详情页
/// 评论内容+用户信息，回复列表，回复输入框
/// 点赞，粉色卡片，错落入场动画
/// ============================================================

class CommentDetailPage extends StatefulWidget {
  const CommentDetailPage({
    super.key,
    this.postId = '1',
    this.postTitle = '初眠AI 3.0体验分享',
  });

  final String postId;
  final String postTitle;

  @override
  State<CommentDetailPage> createState() => _CommentDetailPageState();
}

class _CommentDetailPageState extends State<CommentDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocus = FocusNode();
  bool _isLoading = true;
  String? _errorMessage;
  List<_CommentItem> _comments = [];
  String? _replyingTo;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadComments();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _replyController.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ApiService.getComments(widget.postId);
      setState(() {
        _comments = data
            .map((e) => _CommentItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleLike(String commentId) {
    setState(() {
      final comment = _comments.firstWhere((c) => c.id == commentId);
      comment.isLiked = !comment.isLiked;
      comment.likes += comment.isLiked ? 1 : -1;
    });
  }

  void _submitReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(0, _CommentItem(
        id: DateTime.now().toString(),
        user: '我',
        content: text,
        time: '刚刚',
        likes: 0,
        isLiked: false,
        replies: [],
      ));
    });
    _replyController.clear();
    _replyFocus.unfocus();
    setState(() => _replyingTo = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '评论详情',
        actions: [
          MiuixIconButton(
            icon: Icons.more_vert,
            style: MiuixIconButtonStyle.ghost,
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPostPreview(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(MiuixColors.primary),
                  ))
                : _errorMessage != null
                    ? _buildErrorState()
                    : _comments.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(MiuixSpacing.md),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) => _buildCommentItem(_comments[index], index),
                          ),
          ),
          _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildPostPreview() {
    return MiuixCard(
      margin: const EdgeInsets.all(MiuixSpacing.md),
      padding: const EdgeInsets.all(MiuixSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
              borderRadius: MiuixRadius.mdRadius,
            ),
            child: const Icon(Icons.article, size: 20, color: Colors.white),
          ),
          const SizedBox(width: MiuixSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.postTitle,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_comments.length} 条评论',
                  style: const TextStyle(
                    fontSize: MiuixFontSize.xs,
                    color: MiuixColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(_CommentItem comment, int index) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(
        0.1 + index * 0.06,
        1.0,
        curve: MiuixCurves.easeOut,
      ),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(anim),
        child: Padding(
          padding: const EdgeInsets.only(bottom: MiuixSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(comment.user),
                  const SizedBox(width: MiuixSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              comment.user,
                              style: const TextStyle(
                                fontSize: MiuixFontSize.md,
                                fontWeight: FontWeight.w600,
                                color: MiuixColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: MiuixSpacing.sm),
                            Text(
                              comment.time,
                              style: const TextStyle(
                                fontSize: MiuixFontSize.xs,
                                color: MiuixColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: MiuixSpacing.xs),
                        Text(
                          comment.content,
                          style: const TextStyle(
                            fontSize: MiuixFontSize.md,
                            color: MiuixColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: MiuixSpacing.sm),
                        Row(
                          children: [
                            MiuixRipple(
                              onTap: () => _toggleLike(comment.id),
                              borderRadius: MiuixRadius.pill,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      comment.isLiked ? Icons.favorite : Icons.favorite_border,
                                      size: 14,
                                      color: comment.isLiked ? MiuixColors.error : MiuixColors.textTertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${comment.likes}',
                                      style: TextStyle(
                                        fontSize: MiuixFontSize.xs,
                                        color: comment.isLiked ? MiuixColors.error : MiuixColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: MiuixSpacing.lg),
                            MiuixRipple(
                              onTap: () {
                                setState(() => _replyingTo = comment.user);
                                _replyFocus.requestFocus();
                              },
                              borderRadius: MiuixRadius.pill,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.reply, size: 14, color: MiuixColors.textTertiary),
                                    SizedBox(width: 4),
                                    Text('回复', style: TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (comment.replies.isNotEmpty) ...[
                const SizedBox(height: MiuixSpacing.sm),
                _buildReplies(comment.replies),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplies(List<_ReplyItem> replies) {
    return Container(
      margin: const EdgeInsets.only(left: 44),
      padding: const EdgeInsets.all(MiuixSpacing.md),
      decoration: BoxDecoration(
        color: MiuixColors.surfaceVariant.withOpacity(0.5),
        borderRadius: MiuixRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: replies.asMap().entries.map((entry) {
          final reply = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: entry.key == replies.length - 1 ? 0 : MiuixSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSmallAvatar(reply.user),
                const SizedBox(width: MiuixSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            reply.user,
                            style: const TextStyle(
                              fontSize: MiuixFontSize.sm,
                              fontWeight: FontWeight.w600,
                              color: MiuixColors.primary,
                            ),
                          ),
                          const SizedBox(width: MiuixSpacing.xs),
                          Text(
                            reply.time,
                            style: const TextStyle(
                              fontSize: MiuixFontSize.xs,
                              color: MiuixColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reply.content,
                        style: const TextStyle(
                          fontSize: MiuixFontSize.sm,
                          color: MiuixColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MiuixColors.primaryLight,
            MiuixColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: const TextStyle(
            fontSize: MiuixFontSize.md,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallAvatar(String name) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: MiuixColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: const TextStyle(
            fontSize: MiuixFontSize.xs,
            fontWeight: FontWeight.w600,
            color: MiuixColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.all(MiuixSpacing.md),
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        border: Border(top: BorderSide(color: MiuixColors.borderLight, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_replyingTo != null)
              Padding(
                padding: const EdgeInsets.only(right: MiuixSpacing.sm),
                child: MiuixRipple(
                  onTap: () => setState(() => _replyingTo = null),
                  borderRadius: MiuixRadius.pill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: MiuixColors.primary.withOpacity(0.1),
                      borderRadius: MiuixRadius.pillRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '回复 $_replyingTo',
                          style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.primary),
                        ),
                        const Icon(Icons.close, size: 12, color: MiuixColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: MiuixInput(
                controller: _replyController,
                focusNode: _replyFocus,
                hintText: _replyingTo != null ? '回复 $_replyingTo...' : '写下你的评论...',
                onSubmitted: (_) => _submitReply(),
              ),
            ),
            const SizedBox(width: MiuixSpacing.sm),
            MiuixRipple(
              onTap: _submitReply,
              borderRadius: MiuixRadius.pill,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: MiuixColors.primaryGradient),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: MiuixColors.error),
          const SizedBox(height: 12),
          const Text('加载失败', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 4),
          SizedBox(
            width: 240,
            child: Text(_errorMessage ?? '未知错误', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 16),
          TextButton.icon(onPressed: _loadComments, icon: const Icon(Icons.refresh, size: 18), label: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: MiuixColors.surfaceVariant, shape: BoxShape.circle), child: const Icon(Icons.chat_bubble_outline, size: 36, color: MiuixColors.textTertiary)),
          const SizedBox(height: MiuixSpacing.lg),
          const Text('暂无评论', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textSecondary)),
          const SizedBox(height: MiuixSpacing.sm),
          const Text('快来发表第一条评论吧', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
        ],
      ),
    );
  }
}

class _CommentItem {
  final String id;
  final String user;
  final String content;
  final String time;
  int likes;
  bool isLiked;
  final List<_ReplyItem> replies;

  _CommentItem({
    required this.id,
    required this.user,
    required this.content,
    required this.time,
    required this.likes,
    required this.isLiked,
    required this.replies,
  });

  factory _CommentItem.fromMap(Map<String, dynamic> map) {
    return _CommentItem(
      id: map['id']?.toString() ?? '',
      user: map['user']?.toString() ??
          map['nickname']?.toString() ??
          map['username']?.toString() ??
          '匿名用户',
      content: map['content']?.toString() ?? '',
      time: map['time']?.toString() ??
          map['created_at']?.toString() ??
          map['createdAt']?.toString() ??
          '',
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      isLiked: map['isLiked'] == true || map['is_liked'] == true,
      replies: (map['replies'] as List<dynamic>? ?? [])
          .map((e) => _ReplyItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class _ReplyItem {
  final String user;
  final String content;
  final String time;
  final int likes;

  _ReplyItem({
    required this.user,
    required this.content,
    required this.time,
    required this.likes,
  });

  factory _ReplyItem.fromMap(Map<String, dynamic> map) {
    return _ReplyItem(
      user: map['user']?.toString() ??
          map['nickname']?.toString() ??
          '匿名用户',
      content: map['content']?.toString() ?? '',
      time: map['time']?.toString() ??
          map['created_at']?.toString() ??
          '',
      likes: (map['likes'] as num?)?.toInt() ?? 0,
    );
  }
}
