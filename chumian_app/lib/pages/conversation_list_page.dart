import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/pages/chat_page.dart';

/// ============================================================
/// ConversationListPage —— 历史对话列表
/// 标题+模型+时间+最后消息预览 + 左滑删除 + 点击加载 + 新对话按钮
/// ============================================================
class ConversationListPage extends StatefulWidget {
  const ConversationListPage({super.key});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  final List<ConversationItem> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final data = await ApiService.getConversations();
      if (mounted) {
        setState(() {
          _conversations.clear();
          _conversations.addAll(data.map((e) => ConversationItem.fromJson(e)).toList());
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteConversation(ConversationItem conv) async {
    try {
      await ApiService.deleteConversation(conv.id);
    } catch (_) {}
    setState(() => _conversations.remove(conv));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('对话已删除'), backgroundColor: MiuixColors.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
  }

  void _openConversation(ConversationItem conv) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(conversationId: conv.id)));
  }

  void _newConversation() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: AppBar(backgroundColor: MiuixColors.surface, elevation: 0, scrolledUnderElevation: 0, centerTitle: true, leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary), onPressed: () => Navigator.pop(context)), title: Text('历史对话', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w600)), actions: [IconButton(icon: Icon(Icons.add_comment, color: MiuixColors.primary), onPressed: _newConversation)]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MiuixColors.primary))
          : _conversations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _conversations.length, itemBuilder: (context, index) {
                  final conv = _conversations[index];
                  return Dismissible(
                    key: ValueKey(conv.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: MiuixColors.error, borderRadius: BorderRadius.circular(MiuixRadius.lg)),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      _deleteConversation(conv);
                      return false;
                    },
                    child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: MiuixDuration.normal, curve: Interval((index % 5) * 0.1, (index % 5) * 0.1 + 0.9, curve: MiuixCurves.easeOut), builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, (1 - value) * 20), child: child)), child: _buildConversationItem(conv))));
                }),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: MiuixColors.surfaceVariant, shape: BoxShape.circle), child: const Icon(Icons.chat_bubble_outline, color: MiuixColors.textTertiary, size: 40)),
      const SizedBox(height: 16),
      Text('暂无历史对话', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.md)),
      const SizedBox(height: 16),
      MiuixRipple(borderRadius: MiuixRadius.pill, child: GestureDetector(onTap: _newConversation, child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius, boxShadow: MiuixShadows.md), child: const Text('开始新对话', style: TextStyle(color: Colors.white, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600))))),
    ]));
  }

  Widget _buildConversationItem(ConversationItem conv) {
    return MiuixRipple(borderRadius: MiuixRadius.lg, child: GestureDetector(onTap: () => _openConversation(conv), child: MiuixGlassContainer(margin: const EdgeInsets.only(bottom: 10), borderRadius: MiuixRadius.lg, padding: const EdgeInsets.all(14), child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.softGradient), shape: BoxShape.circle), child: const Center(child: Icon(Icons.chat_bubble, color: MiuixColors.primary, size: 22))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(conv.title, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)), Text(_formatTime(conv.updatedAt), style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs))]),
        const SizedBox(height: 4),
        Text(conv.lastMessage, style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: MiuixColors.primary.withOpacity(0.1), borderRadius: MiuixRadius.xsRadius), child: Text(conv.model, style: TextStyle(color: MiuixColors.primary, fontSize: 10, fontWeight: FontWeight.w500))), const SizedBox(width: 8), Text('${conv.messageCount}条消息', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs))]),
      ])),
      const SizedBox(width: 8),
      Icon(Icons.chevron_right, color: MiuixColors.textTertiary, size: 20),
    ]))));
  }
}

class ConversationItem {
  ConversationItem({required this.id, required this.title, required this.model, required this.lastMessage, required this.updatedAt, required this.messageCount});
  final String id;
  final String title;
  final String model;
  final String lastMessage;
  final DateTime updatedAt;
  final int messageCount;

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(id: json['id']?.toString() ?? '', title: json['title'] ?? '新对话', model: json['model'] ?? 'GLM-4 Flash', lastMessage: json['last_message'] ?? '', updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(), messageCount: json['message_count'] ?? 0);
  }
}
