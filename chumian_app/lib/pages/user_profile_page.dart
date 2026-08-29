import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});
  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ApiService.getUserProfile(widget.userId);
      if (!mounted) return;
      setState(() { _profile = p; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final result = await ApiService.followUser(widget.userId);
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户主页')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _profile == null ? const Center(child: Text('用户不存在')) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            CircleAvatar(radius: 40, backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2), child: Text(_profile!['nickname']?.toString().substring(0, 1) ?? '?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            Text(_profile!['nickname'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (_profile!['qq'] != null) ...[
              const SizedBox(height: 4),
              Text('QQ: ${_profile!['qq']}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
            if (_profile!['birthday'] != null) ...[
              const SizedBox(height: 4),
              Text('生日: ${_profile!['birthday']}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _buildStat('${_profile!['followers_count'] ?? 0}', '粉丝'),
              _buildStat('${_profile!['following_count'] ?? 0}', '关注'),
              _buildStat('${_profile!['likes_count'] ?? 0}', '获赞'),
            ]),
            const SizedBox(height: 16),
            if (_profile!['is_mutual'] == true) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Text('互相关注', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(backgroundColor: _profile!['is_following'] == true ? Colors.grey : Theme.of(context).primaryColor),
              child: Text(_profile!['is_following'] == true ? '取消关注' : '关注'),
            )),
          ]))),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}
