import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_empty_state.dart';
import 'package:chumian_ai/widgets/miuix/miuix_avatar.dart';

/// ============================================================
/// FollowersPage —— 粉丝列表
/// 用户卡片，关注/互关状态，粉色头像，搜索
/// ============================================================
class FollowersPage extends StatefulWidget {
  const FollowersPage({super.key});

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  final TextEditingController _searchController = TextEditingController();

  List<UserItem> _followers = [];
  List<UserItem> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadFollowers();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _followers = [
        UserItem(id: '1', name: '樱花飘落', avatar: '🌸', bio: '热爱生活的二次元少女', followers: 1234, isFollowing: true, isMutual: true),
        UserItem(id: '2', name: '星辰大海', avatar: '⭐', bio: '追逐梦想的旅人', followers: 567, isFollowing: false, isMutual: false),
        UserItem(id: '3', name: '月光骑士', avatar: '🌙', bio: '夜行侠，代码为生', followers: 890, isFollowing: true, isMutual: false),
        UserItem(id: '4', name: '小确幸', avatar: '🍀', bio: '记录生活中的小美好', followers: 2345, isFollowing: true, isMutual: true),
        UserItem(id: '5', name: '风中追风', avatar: '🍃', bio: '自由如风', followers: 432, isFollowing: false, isMutual: false),
        UserItem(id: '6', name: '暖阳微醺', avatar: '☀️', bio: '温暖治愈系', followers: 1567, isFollowing: true, isMutual: false),
        UserItem(id: '7', name: '深海蓝鲸', avatar: '🐋', bio: '在代码的海洋里遨游', followers: 789, isFollowing: false, isMutual: false),
        UserItem(id: '8', name: '云端漫步', avatar: '☁️', bio: '梦想家', followers: 345, isFollowing: true, isMutual: true),
      ];
      _filtered = _followers;
      _isLoading = false;
    });
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _followers;
      } else {
        _filtered = _followers
            .where((u) =>
                u.name.toLowerCase().contains(query.toLowerCase()) ||
                u.bio.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleFollow(UserItem user) {
    setState(() {
      final index = _followers.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _followers[index] = UserItem(
          id: user.id,
          name: user.name,
          avatar: user.avatar,
          bio: user.bio,
          followers: user.followers,
          isFollowing: !user.isFollowing,
          isMutual: !user.isFollowing ? user.isMutual : false,
        );
        _filtered = List.from(_filtered);
        final fIndex = _filtered.indexWhere((u) => u.id == user.id);
        if (fIndex != -1) _filtered[fIndex] = _followers[index];
      }
    });
    MiuixToast.show(
      context,
      message: user.isFollowing ? '已取消关注' : '已关注',
      type: MiuixToastType.success,
    );
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.05, (index * 0.05) + 0.35,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.05, (index * 0.05) + 0.35,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '粉丝 (${_followers.length})',
        backgroundColor: MiuixColors.background,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(MiuixColors.primary),
                    ),
                  )
                : _filtered.isEmpty
                    ? const MiuixEmptyState(
                        title: '没有找到相关用户',
                        description: '换个关键词试试吧',
                        icon: Icons.search_off,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          return _buildAnimatedItem(
                            _buildUserCard(_filtered[index]),
                            index,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: MiuixInput(
        controller: _searchController,
        hintText: '搜索粉丝...',
        type: MiuixInputType.search,
        prefixIcon: Icons.search,
        onChanged: _search,
      ),
    );
  }

  Widget _buildUserCard(UserItem user) {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () {
        MiuixToast.show(context,
            message: '查看 ${user.name} 的主页', type: MiuixToastType.info);
      },
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB6C1), Color(0xFFFF69B4)],
              ),
              borderRadius: MiuixRadius.lgRadius,
              boxShadow: MiuixShadows.sm,
            ),
            child: Center(
              child: Text(user.avatar, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: MiuixFontSize.md,
                        fontWeight: FontWeight.w600,
                        color: MiuixColors.textPrimary,
                      ),
                    ),
                    if (user.isMutual) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MiuixColors.primaryLight.withOpacity(0.2),
                          borderRadius: MiuixRadius.pillRadius,
                        ),
                        child: const Text(
                          '互相关注',
                          style: TextStyle(
                            fontSize: 10,
                            color: MiuixColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.bio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.sm,
                    color: MiuixColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.followers} 粉丝',
                  style: const TextStyle(
                    fontSize: MiuixFontSize.xs,
                    color: MiuixColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          MiuixButton(
            label: user.isFollowing ? '已关注' : '回关',
            type: user.isFollowing
                ? MiuixButtonType.secondary
                : MiuixButtonType.primary,
            size: MiuixButtonSize.small,
            onPressed: () => _toggleFollow(user),
          ),
        ],
      ),
    );
  }
}

class UserItem {
  final String id;
  final String name;
  final String avatar;
  final String bio;
  final int followers;
  final bool isFollowing;
  final bool isMutual;
  const UserItem({
    required this.id,
    required this.name,
    required this.avatar,
    required this.bio,
    required this.followers,
    required this.isFollowing,
    required this.isMutual,
  });
}
