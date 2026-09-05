import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../models/chat_message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<String> _models = ['glm-4-flash', 'glm-4.7-flash', 'glm-z1-flash', 'kimi-k2.5', 'kimi-k2.6'];
  bool _loadingModels = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    try {
      final models = await ApiService().getModels();
      if (models.isNotEmpty) {
        setState(() => _models = models.map((e) => e.id).toList());
      }
    } catch (_) {}
    setState(() => _loadingModels = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final userProvider = context.watch<UserProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('初眠对话', style: TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.bold, fontFamily: 'LXGW WenKai')),
        actions: [
          _buildModelSelector(chatProvider),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary), onPressed: () => chatProvider.clearChat()),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.messages.isEmpty
                ? _buildEmptyState(userProvider)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (_, i) => _buildMessageBubble(chatProvider.messages[i]),
                  ),
          ),
          _buildInputBar(chatProvider),
        ],
      ),
    );
  }

  Widget _buildModelSelector(ChatProvider chat) {
    return PopupMenuButton<String>(
      initialValue: chat.currentModel,
      onSelected: (v) => chat.setModel(v),
      itemBuilder: (_) => _models.map((m) => PopupMenuItem(value: m, child: Text(m, style: const TextStyle(fontFamily: 'LXGW WenKai', fontSize: 13)))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(chat.currentModel, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'LXGW WenKai')),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(UserProvider user) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(gradient: AppColors.primaryVibrantGradient, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20)]), child: const Icon(Icons.nightlight_round, color: Colors.white, size: 40)),
        const SizedBox(height: 16),
        Text('你好，${user.user?.nickname ?? '朋友'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDeep, fontFamily: 'LXGW WenKai')),
        const SizedBox(height: 8),
        const Text('有什么我可以帮你的吗？', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontFamily: 'LXGW WenKai')),
        const SizedBox(height: 24),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _suggestionChip('写一首关于春天的诗'),
          _suggestionChip('帮我解释量子力学'),
          _suggestionChip('推荐一部科幻电影'),
          _suggestionChip('写一段Python排序代码'),
        ]),
      ]),
    );
  }

  Widget _suggestionChip(String text) {
    return GestureDetector(
      onTap: () { _inputCtrl.text = text; },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderLight), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 6)]),
        child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'LXGW WenKai')),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(false),
          if (!isUser) const SizedBox(width: 10),
          Flexible(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(18),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: isUser
                  ? Text(msg.content, style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'LXGW WenKai'))
                  : msg.isStreaming && msg.content.isEmpty
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : MarkdownBody(data: msg.content, styleSheet: MarkdownStyleSheet.fromTheme(ThemeData(textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 15, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai'))))),
            ),
          ),
          if (isUser) const SizedBox(width: 10),
          if (isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        gradient: isUser ? const LinearGradient(colors: [Color(0xFFB39DDB), Color(0xFF9575CD)]) : AppColors.primaryVibrantGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(isUser ? Icons.person : Icons.nightlight_round, color: Colors.white, size: 20),
    );
  }

  Widget _buildInputBar(ChatProvider chat) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _inputCtrl,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(chat),
                style: const TextStyle(fontFamily: 'LXGW WenKai', fontSize: 15),
                decoration: const InputDecoration(hintText: '输入消息...', hintStyle: TextStyle(color: AppColors.textHint, fontFamily: 'LXGW WenKai'), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: chat.isStreaming ? null : () => _send(chat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: chat.isStreaming ? null : AppColors.primaryVibrantGradient,
                color: chat.isStreaming ? AppColors.textHint : null,
                borderRadius: BorderRadius.circular(23),
                boxShadow: chat.isStreaming ? null : [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)],
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  void _send(ChatProvider chat) {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    chat.sendMessage(text);
    _scrollToBottom();
  }
}
