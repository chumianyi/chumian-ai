import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/context_ext.dart';
import '../widgets/avatar.dart';
import '../widgets/feedback.dart';
import '../widgets/gradient_header.dart';
import '../widgets/app_card.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});
  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _loadFailed = false;
  bool _followingBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _profile == null;
      _loadFailed = false;
    });
    try {
      final p = await ApiService.getUserProfile(widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_followingBusy) return;
    setState(() => _followingBusy = true);
    try {
      await ApiService.followUser(widget.userId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _followingBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户主页')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListSkeleton(items: 2, showHeader: false);
    if (_loadFailed) {
      return ErrorRetry(message: '用户信息加载失败', onRetry: _load);
    }
    final p = _profile!;
    final nickname = p['nickname'] ?? '';

    return AppRefreshable(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Stack(
                  children: [
                    AppAvatar(
                      imageUrl: p['avatar'] as String?,
                      name: nickname,
                      size: 80,
                    ),
                    if (p['is_mutual'] == true)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.info,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '互关',
                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  nickname,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (p['qq'] != null) ...[
                  _metaRow(context, Icons.qr_code_2_rounded, 'QQ: ${p['qq']}'),
                  const SizedBox(height: 4),
                ],
                if (p['birthday'] != null) ...[
                  _metaRow(context, Icons.cake_rounded, '生日: ${p['birthday']}'),
                  const SizedBox(height: 4),
                ],
                if (p['signature'] != null && (p['signature'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _metaRow(context, Icons.format_quote_rounded, p['signature']),
                  const SizedBox(height: 4),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StatTile(value: '${p['followers_count'] ?? 0}', label: '粉丝'),
                    StatTile(value: '${p['following_count'] ?? 0}', label: '关注'),
                    StatTile(value: '${p['likes_count'] ?? 0}', label: '获赞'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _followingBusy
                      ? const Center(child: CircularProgressIndicator())
                      : FollowButton(
                          isFollowing: p['is_following'] == true,
                          onChanged: (_) => _toggleFollow(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(BuildContext context, IconData icon, dynamic text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: context.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$text',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
        ),
      ],
    );
  }
}
