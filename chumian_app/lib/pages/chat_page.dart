import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../providers/model_store_provider.dart';
import '../models/local_model.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _selectedModel = 'GLM-4';

  final List<String> _models = ['GLM-4', 'GLM-4-Flash', 'Kimi', 'Kimi-Long'];
  final List<String> _suggestions = [
    '帮我写一首诗',
    '解释量子力学',
    '翻译这段文字',
    '生成Python代码',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        time: DateTime.now(),
      ));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Simulate AI typing response
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: '你好！我是初眠AI，很高兴为你服务。这是一个演示回复，展示了对话界面的效果。',
          isUser: false,
          time: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pink50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.pink400, AppColors.pink500]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.nightlight_round, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text('初眠AI', style: AppTextStyles.headingMedium.copyWith(color: AppColors.pink600)),
          ],
        ),
        actions: [
          _buildModelSelector(),
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.pink400),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState() : _buildMessageList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildModelSelector() {
    return GestureDetector(
      onTap: () => _showModelPicker(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.pink100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isLocalModel ? Icons.memory : Icons.smart_toy,
              size: 16,
              color: _isLocalModel ? Colors.purple : AppColors.pink500,
            ),
            const SizedBox(width: 4),
            Text(_selectedModel, style: AppTextStyles.caption.copyWith(color: AppColors.pink600, fontWeight: FontWeight.w600)),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.pink400),
          ],
        ),
      ),
    );
  }

  bool get _isLocalModel => _selectedModel.startsWith('本地:');

  void _showModelPicker() {
    final provider = Provider.of<ModelStoreProvider>(context, listen: false);
    final localLanguageModels = provider.downloadedModels
        .where((m) => m.isLanguageModel)
        .toList();
    final allLocalModels = provider.languageModels;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.pink200, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('选择模型', style: AppTextStyles.titleLarge.copyWith(color: AppColors.pink500)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('云端模型', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pink400, fontWeight: FontWeight.w600)),
                ),
              ),
              ..._models.map((m) => _buildModelOption(m, false, true)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('本地模型', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pink400, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to model store
                      },
                      child: Text('去模型商店', style: TextStyle(color: AppColors.pink500, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              ...allLocalModels.map((m) => _buildModelOption(
                '本地:${m.name}',
                true,
                m.isDownloaded,
                subtitle: m.isDownloaded ? '已下载 · 端侧推理' : '未下载 · 点击前往下载',
              )),
              if (allLocalModels.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('暂无本地模型，前往模型商店下载', style: TextStyle(color: Colors.black38)),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelOption(String name, bool isLocal, bool enabled, {String? subtitle}) {
    final isSelected = _selectedModel == name;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: ListTile(
        leading: Icon(
          isLocal ? Icons.memory : Icons.cloud,
          color: isLocal ? (enabled ? Colors.purple : Colors.grey) : AppColors.pink500,
        ),
        title: Text(
          name.replaceAll('本地:', ''),
          style: AppTextStyles.bodyLarge.copyWith(
            color: isSelected ? AppColors.pink500 : Colors.black87,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)) : null,
        trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.pink500) : (enabled ? null : const Icon(Icons.lock_outline, size: 18, color: Colors.grey)),
        onTap: enabled
            ? () {
                setState(() => _selectedModel = name);
                Navigator.pop(context);
                if (isLocal) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('本地模型运行中，可能较慢，请耐心等待', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                      backgroundColor: AppColors.pink400,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.pink300, AppColors.pink400]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.pink200.withOpacity(0.5), blurRadius: 20)],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text('有什么可以帮你的？', style: AppTextStyles.headingMedium.copyWith(color: AppColors.pink600)),
          const SizedBox(height: 8),
          Text('选择一个建议开始对话', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pink400)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _suggestions.map((s) => _SuggestionChip(text: s, onTap: () => _sendMessage(s))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _TypingIndicator();
        }
        final msg = _messages[index];
        return _MessageBubble(message: msg);
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppColors.pink100.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.pink400, size: 28),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.pink50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.pink200),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.pink300),
                    border: InputBorder.none,
                  ),
                  style: AppTextStyles.bodyMedium,
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_messageController.text),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.pink400, AppColors.pink500]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.pink300.withOpacity(0.4), blurRadius: 8)],
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  ChatMessage({required this.text, required this.isUser, required this.time});
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.pink400, AppColors.pink500]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.nightlight_round, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.pink400 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: AppColors.pink100.withOpacity(0.5), blurRadius: 6)],
              ),
              child: Text(
                message.text,
                style: AppTextStyles.bodyMedium.copyWith(color: isUser ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.pink200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: AppColors.pink500, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.pink400, AppColors.pink500]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.nightlight_round, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.pink100.withOpacity(0.5), blurRadius: 6)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _TypingDot(delay: i * 150)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final bounce = (0.5 + 0.5 * (1 - (1 - _controller.value).abs())).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, -4 * bounce),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: AppColors.pink400, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.pink200),
          boxShadow: [BoxShadow(color: AppColors.pink100.withOpacity(0.3), blurRadius: 4)],
        ),
        child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.pink500)),
      ),
    );
  }
}
