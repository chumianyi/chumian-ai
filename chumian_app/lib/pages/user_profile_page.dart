import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/services/api_service.dart';

/// ============================================================
/// UserProfilePage —— 他人主页
/// 头像+昵称+关注数+粉丝数+帖子列表 + 关注/取消关注按钮
/// ============================================================
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  final List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _user = {
        'id': widget.userId,
        'nickname': '初眠创作者',
        'bio': '热爱AI创作，分享初眠AI的使用技巧和创意作品 ✨',
        'followers': 2340,
        'following': 156,
        'posts_count': 42,
        'level': 8,
      };
      _posts.addAll(List.generate(6, (i) => {
        'id': 'post_$i',
        'content': ['粉色系AI插画分享', '初眠AI代码生成技巧', '用AI写的小诗', '联网搜索功能实测', '签到积分攻略', 'Agent创建教程'][i],
        'image_url': 'https://picsum.photos/300/300?random=${i + 100}',
        'likes': 50 + i * 20,
        'type': i % 3 == 0 ? 'image' : 'text',
      }));
      _isLoading = false;
    });
  }

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing ? '关注成功' : '已取消关注'),
        backgroundColor: MiuixColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MiuixColors.primary))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: MiuixColors.surface,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildProfileHeader(),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      color: MiuixColors.surface,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: MiuixColors.primary,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: MiuixColors.primary,
                        unselectedLabelColor: MiuixColors.textTertiary,
                        labelStyle: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600),
                        tabs: const [Tab(text: '帖子'), Tab(text: '喜欢')],
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsGrid(),
                  _buildPostsGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [MiuixColors.primaryLight.withValues(alpha: 0.3), MiuixColors.background],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: MiuixShadows.md,
                    ),
                    child: const Center(child: Icon(Icons.person, color: Colors.white, size: 40)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_user?['nickname'] ?? '', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.xsRadius),
                              child: Text('Lv.${_user?['level']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_user?['bio'] ?? '', style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatItem('${_user?['posts_count']}', '帖子'),
                  _buildStatItem('${_user?['following']}', '关注'),
                  _buildStatItem('${_user?['followers']}', '粉丝'),
                  const Spacer(),
                  MiuixRipple(
                    borderRadius: MiuixRadius.pill,
                    child: GestureDetector(
                      onTap: _toggleFollow,
                      child: AnimatedContainer(
                        duration: MiuixDuration.fast,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: _isFollowing ? null : const LinearGradient(colors: MiuixColors.primaryGradient),
                          color: _isFollowing ? MiuixColors.surfaceVariant : null,
                          borderRadius: MiuixRadius.pillRadius,
                          border: _isFollowing ? Border.all(color: MiuixColors.primary.withValues(alpha: 0.3)) : null,
                          boxShadow: _isFollowing ? null : MiuixShadows.sm,
                        ),
                        child: Text(
                          _isFollowing ? '已关注' : '+ 关注',
                          style: TextStyle(color: _isFollowing ? MiuixColors.primary : Colors.white, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: MiuixColors.textTertiary, size: 48),
            const SizedBox(height: 8),
            Text('暂无内容', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return MiuixRipple(
          borderRadius: MiuixRadius.md,
          child: GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius: MiuixRadius.mdRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (post['image_url'] != null)
                    Image.network(post['image_url'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: MiuixColors.surfaceVariant, child: const Icon(Icons.image, color: MiuixColors.textTertiary, size: 32)))
                  else
                    Container(color: MiuixColors.primary.withValues(alpha: 0.1), padding: const EdgeInsets.all(12), child: Center(child: Text(post['content'], style: TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w500), maxLines: 3, overflow: TextOverflow.ellipsis))),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)])),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text('${post['likes']}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
