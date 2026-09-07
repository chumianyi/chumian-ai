import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_dialog.dart';
import 'package:chumian_ai/widgets/miuix/miuix_empty_state.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// BlockedUsersPage —— 黑名单
/// 被屏蔽用户列表，解除屏蔽
/// 粉色主题，错落入场动画
/// ============================================================

class BlockedUser {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final String reason;
  final DateTime blockedAt;

  const BlockedUser({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.reason,
    required this.blockedAt,
  });

  factory BlockedUser.fromMap(Map<String, dynamic> map) {
    return BlockedUser(
      id: map['id']?.toString() ?? '',
      nickname: map['nickname']?.toString() ??
          map['user_nickname']?.toString() ??
          map['username']?.toString() ??
          '未知用户',
      avatarUrl: map['avatar']?.toString() ?? map['avatar_url']?.toString(),
      reason: map['reason']?.toString() ?? '违规行为',
      blockedAt: map['blocked_at'] != null
          ? DateTime.tryParse(map['blocked_at'].toString()) ?? DateTime.now()
          : map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  bool _isLoading = true;
  String? _errorMessage;
  List<BlockedUser> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadBlockedUsers();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ApiService.getBlockedUsers();
      setState(() {
        _blockedUsers = data
            .map((e) => BlockedUser.fromMap(Map<String, dynamic>.from(e as Map)))
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}周前';
    return '${date.year}年${date.month}月${date.day}日';
  }

  void _unblockUser(BlockedUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: MiuixRadius.lgRadius),
        title: Text('解除屏蔽', style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600)),
        content: Text('确定要解除对「${user.nickname}」的屏蔽吗？解除后该用户可以再次与你互动。'),
        contentTextStyle: const TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary, height: 1.5),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消', style: TextStyle(color: MiuixColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _blockedUsers.removeWhere((u) => u.id == user.id);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已解除对 ${user.nickname} 的屏蔽'),
                  backgroundColor: MiuixColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: MiuixRadius.lgRadius),
                ),
              );
            },
            child: const Text('解除屏蔽', style: TextStyle(color: MiuixColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '黑名单',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: MiuixSpacing.md),
            child: Center(
              child: Text(
                '${_blockedUsers.length}人',
                style: const TextStyle(
                  fontSize: MiuixFontSize.sm,
                  color: MiuixColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(MiuixColors.primary),
            ))
          : _errorMessage != null
              ? _buildErrorState()
              : _blockedUsers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(MiuixSpacing.md),
                      itemCount: _blockedUsers.length,
                      itemBuilder: (context, index) =>
                          _buildUserCard(_blockedUsers[index], index),
                    ),
    );
  }

  Widget _buildUserCard(BlockedUser user, int index) {
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
        child: MiuixCard(
          margin: const EdgeInsets.only(bottom: MiuixSpacing.md),
          child: Row(
            children: [
              _buildAvatar(user),
              const SizedBox(width: MiuixSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.nickname,
                            style: const TextStyle(
                              fontSize: MiuixFontSize.md,
                              fontWeight: FontWeight.w600,
                              color: MiuixColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: MiuixColors.error.withValues(alpha: 0.08),
                            borderRadius: MiuixRadius.xsRadius,
                          ),
                          child: const Text(
                            '已屏蔽',
                            style: TextStyle(fontSize: 10, color: MiuixColors.error, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.block, size: 12, color: MiuixColors.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.reason,
                            style: const TextStyle(
                              fontSize: MiuixFontSize.xs,
                              color: MiuixColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: MiuixColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          '屏蔽于 ${_formatDate(user.blockedAt)}',
                          style: const TextStyle(
                            fontSize: MiuixFontSize.xs,
                            color: MiuixColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MiuixSpacing.sm),
              MiuixButton(
                label: '解除',
                type: MiuixButtonType.secondary,
                size: MiuixButtonSize.small,
                onPressed: () => _unblockUser(user),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BlockedUser user) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MiuixColors.textTertiary,
            MiuixColors.textSecondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            user.nickname.isNotEmpty ? user.nickname[0] : '?',
            style: const TextStyle(
              fontSize: MiuixFontSize.xl,
              fontWeight: FontWeight.w700,
              color: Colors.white54,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: MiuixColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: MiuixColors.surface, width: 2),
              ),
              child: const Icon(Icons.block, size: 10, color: Colors.white),
            ),
          ),
        ],
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
          SizedBox(width: 240, child: Text(_errorMessage ?? '未知错误', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
          const SizedBox(height: 16),
          TextButton.icon(onPressed: _loadBlockedUsers, icon: const Icon(Icons.refresh, size: 18), label: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MiuixColors.primary.withValues(alpha: 0.1),
                  MiuixColors.primaryLight.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_outlined, size: 40, color: MiuixColors.primary),
          ),
          const SizedBox(height: MiuixSpacing.xl),
          const Text(
            '黑名单为空',
            style: TextStyle(
              fontSize: MiuixFontSize.xl,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: MiuixSpacing.sm),
          const Text(
            '你还没有屏蔽任何人\n保持友善，享受社区',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              color: MiuixColors.textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
