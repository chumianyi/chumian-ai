import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_dialog.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_empty_state.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';

/// ============================================================
/// FollowingPage —— 关注列表
/// 用户卡片，取消关注，分组，粉色头像
/// ============================================================
class FollowingPage extends StatefulWidget {
  const FollowingPage({super.key});

  @override
  State<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  final TextEditingController _searchController = TextEditingController();

  List<FollowUser> _following = [];
  List<FollowUser> _filtered = [];
  List<String> _groups = ['全部', '特别关注', '朋友', '技术达人', '创作者'];
  int _selectedGroup = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadFollowing();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowing() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _following = [
        FollowUser(id: '1', name: '初眠AI官方', avatar: '🤖', bio: '初眠AI官方账号', group: '特别关注', isMutual: true),
        FollowUser(id: '2', name: 'Flutter大师', avatar: '💙', bio: '分享Flutter开发技巧', group: '技术达人', isMutual: false),
        FollowUser(id: '3', name: '设计小姐姐', avatar: '🎨', bio: 'UI/UX设计师', group: '创作者', isMutual: true),
        FollowUser(id: '4', name: '老朋友们', avatar: '👥', bio: '认识很久的朋友', group: '朋友', isMutual: true),
        FollowUser(id: '5', name: 'AI前沿', avatar: '🧠', bio: '追踪AI最新动态', group: '技术达人', isMutual: false),
        FollowUser(id: '6', name: '生活美学家', avatar: '🌺', bio: '发现生活中的美', group: '创作者', isMutual: false),
        FollowUser(id: '7', name: '程序员老王', avatar: '👨‍💻', bio: '十年开发经验', group: '朋友', isMutual: true),
        FollowUser(id: '8', name: '摄影爱好者', avatar: '📷', bio: '用镜头记录世界', group: '创作者', isMutual: false),
      ];
      _filtered = _following;
      _isLoading = false;
    });
  }

  void _filterByGroup(int index) {
    setState(() {
      _selectedGroup = index;
      if (index == 0) {
        _filtered = _following;
      } else {
        _filtered = _following
            .where((u) => u.group == _groups[index])
            .toList();
      }
    });
  }

  void _search(String query) {
    setState(() {
      final base = _selectedGroup == 0
          ? _following
          : _following.where((u) => u.group == _groups[_selectedGroup]).toList();
      if (query.isEmpty) {
        _filtered = base;
      } else {
        _filtered = base
            .where((u) =>
                u.name.toLowerCase().contains(query.toLowerCase()) ||
                u.bio.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _unfollow(FollowUser user) {
    MiuixDialog.show(
      context,
      title: '取消关注',
      content: '确定要取消关注「${user.name}」吗？',
      type: MiuixDialogType.warning,
      confirmText: '取消关注',
      onConfirm: () {
        setState(() {
          _following.removeWhere((u) => u.id == user.id);
          _filtered.removeWhere((u) => u.id == user.id);
        });
        MiuixToast.show(context,
            message: '已取消关注', type: MiuixToastType.success);
      },
    );
  }

  void _changeGroup(FollowUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: MiuixColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(MiuixRadius.xl)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MiuixColors.border,
                borderRadius: MiuixRadius.pillRadius,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '移动到分组',
              style: TextStyle(
                fontSize: MiuixFontSize.xl,
                fontWeight: FontWeight.bold,
                color: MiuixColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_groups.length - 1, (index) {
              final group = _groups[index + 1];
              return MiuixRipple(
                borderRadius: MiuixRadius.md,
                child: ListTile(
                  leading: Icon(Icons.folder, color: MiuixColors.primary),
                  title: Text(group),
                  trailing: user.group == group
                      ? const Icon(Icons.check, color: MiuixColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      final idx = _following.indexWhere((u) => u.id == user.id);
                      if (idx != -1) {
                        _following[idx] = FollowUser(
                          id: user.id,
                          name: user.name,
                          avatar: user.avatar,
                          bio: user.bio,
                          group: group,
                          isMutual: user.isMutual,
                        );
                      }
                    });
                    Navigator.pop(context);
                    MiuixToast.show(context,
                        message: '已移动到「$group」',
                        type: MiuixToastType.success);
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
        title: '关注 (${_following.length})',
        backgroundColor: MiuixColors.background,
      ),
      body: Column(
        children: [
          _buildGroupTabs(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: MiuixInput(
              controller: _searchController,
              hintText: '搜索关注的人...',
              type: MiuixInputType.search,
              prefixIcon: Icons.search,
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(MiuixColors.primary),
                    ),
                  )
                : _filtered.isEmpty
                    ? const MiuixEmptyState(
                        title: '该分组暂无关注',
                        description: '去发现页面关注更多有趣的人吧',
                        icon: Icons.people_outline,
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

  Widget _buildGroupTabs() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedGroup == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MiuixRipple(
              borderRadius: MiuixRadius.pill,
              child: GestureDetector(
                onTap: () => _filterByGroup(index),
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
                    _groups[index],
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
        },
      ),
    );
  }

  Widget _buildUserCard(FollowUser user) {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
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
                const SizedBox(height: 4),
                MiuixChip(
                  label: user.group,
                  height: 24,
                  onTap: () => _changeGroup(user),
                ),
              ],
            ),
          ),
          Column(
            children: [
              MiuixIconButton(
                icon: Icons.folder_open,
                style: MiuixIconButtonStyle.ghost,
                size: 36,
                iconSize: 18,
                onPressed: () => _changeGroup(user),
              ),
              MiuixButton(
                label: '已关注',
                type: MiuixButtonType.secondary,
                size: MiuixButtonSize.small,
                onPressed: () => _unfollow(user),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FollowUser {
  final String id;
  final String name;
  final String avatar;
  final String bio;
  final String group;
  final bool isMutual;
  const FollowUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.bio,
    required this.group,
    required this.isMutual,
  });
}
