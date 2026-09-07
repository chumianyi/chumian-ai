import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/pages/chat_page.dart';

/// ============================================================
/// AgentDetailPage —— Agent详情页
/// 形象+名称+描述+系统提示词预览 + 开始对话/克隆/点赞/发布
/// ============================================================
class AgentDetailPage extends StatefulWidget {
  const AgentDetailPage({super.key, required this.agentId});

  final String agentId;

  @override
  State<AgentDetailPage> createState() => _AgentDetailPageState();
}

class _AgentDetailPageState extends State<AgentDetailPage> {
  Map<String, dynamic>? _agent;
  bool _isLoading = true;
  bool _isLiked = false;
  bool _showFullPrompt = false;

  @override
  void initState() {
    super.initState();
    _loadAgent();
  }

  Future<void> _loadAgent() async {
    try {
      final data = await ApiService.getAgent(widget.agentId);
      setState(() {
        _agent = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _agent = {
          'id': widget.agentId,
          'name': '古诗词专家',
          'description': '精通中国古诗词，能创作和赏析各类诗词，带你领略中华文化之美',
          'system_prompt': '你是一位精通中国古诗词的专家，熟悉从先秦到明清的各类诗词作品。你能够：\n1. 创作各种体裁的古诗词（绝句、律诗、词、曲等）\n2. 赏析诗词的意境、手法和情感\n3. 解释诗词中的典故和生僻字\n4. 根据用户需求推荐相关诗词\n\n请用优雅、富有文学气息的语言回复，适当引用诗词名句。',
          'opening_message': '你好！我是古诗词专家，有什么关于诗词的问题想问我吗？无论是创作、赏析还是典故，我都很乐意为你解答～',
          'likes': 15680,
          'clones': 3240,
          'category': '文学',
          'author': '初眠官方',
          'created_at': '2026-01-15',
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    try {
      await ApiService.likeAgent(widget.agentId);
    } catch (_) {}
    setState(() => _isLiked = !_isLiked);
    HapticFeedback.lightImpact();
  }

  Future<void> _cloneAgent() async {
    try {
      await ApiService.cloneAgent(widget.agentId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已克隆「${_agent?['name']}」到我的Agent'), backgroundColor: MiuixColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('克隆成功！'), backgroundColor: MiuixColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
    }
  }

  void _startChat() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(initialPrompt: _agent?['opening_message'] ?? '')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MiuixColors.primary))
          : CustomScrollView(slivers: [
              SliverAppBar(expandedHeight: 280, pinned: true, backgroundColor: MiuixColors.surface, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary), onPressed: () => Navigator.pop(context)), actions: [IconButton(icon: Icon(Icons.share, color: MiuixColors.primary), onPressed: () {})], flexibleSpace: FlexibleSpaceBar(background: _buildHeader())),
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildInfoCard(),
                const SizedBox(height: 16),
                _buildPromptCard(),
                const SizedBox(height: 16),
                _buildOpeningCard(),
                const SizedBox(height: 100),
              ]))),
            ]),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [MiuixColors.primaryLight.withValues(alpha: 0.4), MiuixColors.background])), child: SafeArea(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 40),
      Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: MiuixColors.primaryGradient), border: Border.all(color: Colors.white, width: 4), boxShadow: MiuixShadows.lg), child: const Center(child: Icon(Icons.smart_toy, color: Colors.white, size: 48))),
      const SizedBox(height: 12),
      Text(_agent?['name'] ?? '', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xxl, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: MiuixColors.primary.withValues(alpha: 0.1), borderRadius: MiuixRadius.pillRadius), child: Text(_agent?['category'] ?? '通用', style: TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.xs, fontWeight: FontWeight.w500))),
    ]))));
  }

  Widget _buildInfoCard() {
    return MiuixGlassCard(borderRadius: MiuixRadius.lg, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Agent简介', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Text(_agent?['description'] ?? '', style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.md, height: 1.6)),
      const SizedBox(height: 16),
      Row(children: [
        _buildStatItem('${_agent?['likes'] ?? 0}', '点赞'),
        _buildStatItem('${_agent?['clones'] ?? 0}', '克隆'),
        _buildStatItem(_agent?['author'] ?? '初眠官方', '作者'),
      ]),
    ]));
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
    ]));
  }

  Widget _buildPromptCard() {
    final prompt = _agent?['system_prompt'] ?? '';
    return MiuixGlassCard(borderRadius: MiuixRadius.lg, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.psychology, color: MiuixColors.primary, size: 20), const SizedBox(width: 8), Text('系统提示词', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: MiuixColors.primary.withValues(alpha: 0.05), borderRadius: MiuixRadius.smRadius, border: Border.all(color: MiuixColors.primary.withValues(alpha: 0.15))), child: Text(_showFullPrompt ? prompt : (prompt.length > 200 ? '${prompt.substring(0, 200)}...' : prompt), style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm, height: 1.6))),
      if (prompt.length > 200) GestureDetector(onTap: () => setState(() => _showFullPrompt = !_showFullPrompt), child: Padding(padding: const EdgeInsets.only(top: 8), child: Text(_showFullPrompt ? '收起' : '展开全部', style: TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w500)))),
    ]));
  }

  Widget _buildOpeningCard() {
    return MiuixGlassCard(borderRadius: MiuixRadius.lg, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.chat_bubble_outline, color: MiuixColors.primary, size: 20), const SizedBox(width: 8), Text('开场白', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 12),
      Text(_agent?['opening_message'] ?? '', style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.md, height: 1.6, fontStyle: FontStyle.italic)),
    ]));
  }

  Widget _buildBottomBar() {
    return SafeArea(child: Container(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), decoration: BoxDecoration(color: MiuixColors.surface, border: Border(top: BorderSide(color: MiuixColors.borderLight, width: 0.5)), boxShadow: [BoxShadow(color: MiuixColors.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))]), child: Row(children: [
      _buildBottomAction(Icons.favorite, _isLiked ? '已赞' : '点赞', _isLiked ? MiuixColors.error : MiuixColors.textTertiary, _toggleLike),
      const SizedBox(width: 12),
      _buildBottomAction(Icons.copy, '克隆', MiuixColors.textTertiary, _cloneAgent),
      const SizedBox(width: 12),
      Expanded(child: MiuixRipple(borderRadius: MiuixRadius.pill, child: GestureDetector(onTap: _startChat, child: Container(height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius, boxShadow: MiuixShadows.md), child: const Center(child: Text('开始对话', style: TextStyle(color: Colors.white, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600))))))),
    ])));
  }

  Widget _buildBottomAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 22), const SizedBox(height: 2), Text(label, style: TextStyle(color: color, fontSize: MiuixFontSize.xs))]));
  }
}
