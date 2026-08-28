import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import '../theme.dart';

class ChatMessage {
  final String id;
  final String role;
  String content;
  String? thinkContent;
  bool isThinking;
  bool isExpanded;
  final String? model;
  String? imageUrl;
  String? videoUrl;

  ChatMessage({
    required this.id,
    required this.role,
    this.content = '',
    this.thinkContent,
    this.isThinking = false,
    this.isExpanded = false,
    this.model,
    this.imageUrl,
    this.videoUrl,
  });
}

class ChatPage extends StatefulWidget {
  final String? initialPrompt;
  final String? agentId;

  const ChatPage({super.key, this.initialPrompt, this.agentId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  String? _conversationId;
  String _selectedModel = 'glm-4-flash';
  String? _agentId;
  StreamSubscription? _streamSub;
  List<dynamic> _conversations = [];
  bool _showSidebar = false;

  final List<String> _textModels = [
    'glm-4-flash',
    'glm-4-flash-250414',
    'glm-4.7-flash',
    'glm-z1-flash',
  ];

  @override
  void initState() {
    super.initState();
    _agentId = widget.agentId;
    _loadConversations();
    if (widget.initialPrompt != null) {
      _controller.text = widget.initialPrompt!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage();
      });
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      _conversations = await ApiService.getConversations();
      setState(() {});
    } catch (e) {
      // ignore
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _newConversation() async {
    setState(() {
      _messages.clear();
      _conversationId = null;
    });
    Navigator.pop(context);
  }

  Future<void> _loadConversation(String id) async {
    if (id.isEmpty) return;
    try {
      final msgs = await ApiService.getMessages(id);
      if (!mounted) return;
      setState(() {
        _conversationId = id;
        _messages.clear();
        _messages.addAll(msgs.map<ChatMessage>((m) {
          return ChatMessage(
            id: (m['id'] ?? '').toString(),
            role: m['role'] ?? 'assistant',
            content: m['content'] ?? '',
            thinkContent: m['think_content'],
            model: m['model'],
          );
        }).toList());
      });
      Navigator.pop(context);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _deleteConversation(String id) async {
    try {
      await ApiService.deleteConversation(id);
      if (_conversationId == id) {
        _messages.clear();
        _conversationId = null;
      }
      _loadConversations();
    } catch (e) {
      // ignore
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear();
    _focusNode.unfocus();

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: text,
      ));
      _messages.add(ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        role: 'assistant',
        content: '',
        thinkContent: '',
        isThinking: true,
        model: _selectedModel,
      ));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final aiMsg = _messages.last;
      _streamSub = ApiService.chatStream(
        conversationId: _conversationId,
        message: text,
        model: _selectedModel,
        agentId: _agentId,
      ).listen(
        (data) {
          if (data['type'] == 'think') {
            setState(() {
              aiMsg.thinkContent = (aiMsg.thinkContent ?? '') + data['content'];
            });
          } else if (data['type'] == 'content') {
            setState(() {
              aiMsg.isThinking = false;
              aiMsg.content += data['content'];
            });
            _scrollToBottom();
          } else if (data['type'] == 'done') {
            setState(() {
              aiMsg.isThinking = false;
              _conversationId = data['conversation_id'];
              _isSending = false;
            });
            _loadConversations();
          } else if (data['type'] == 'error') {
            setState(() {
              aiMsg.isThinking = false;
              aiMsg.content = '错误: ${data['message']}';
              _isSending = false;
            });
          }
        },
        onError: (e) {
          setState(() {
            aiMsg.isThinking = false;
            aiMsg.content = '网络错误: $e';
            _isSending = false;
          });
        },
        onDone: () {
          setState(() => _isSending = false);
        },
      );
    } catch (e) {
      setState(() {
        _messages.last.isThinking = false;
        _messages.last.content = '发送失败: $e';
        _isSending = false;
      });
    }
  }

  void _toggleThink(ChatMessage msg) {
    setState(() => msg.isExpanded = !msg.isExpanded);
  }

  Future<void> _generateImage() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入图片描述')),
      );
      return;
    }
    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: '生成图片: $prompt',
      ));
      _messages.add(ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_img',
        role: 'assistant',
        content: '正在生成图片...',
        isThinking: true,
      ));
    });

    try {
      final result = await ApiService.generateImage(prompt);
      setState(() {
        _messages.last.isThinking = false;
        _messages.last.content = '图片生成完成！';
        _messages.last.imageUrl = ApiService.getMediaUrl(result['url']);
      });
    } catch (e) {
      setState(() {
        _messages.last.isThinking = false;
        _messages.last.content = '图片生成失败: $e';
      });
    }
  }

  Future<void> _generateVideo() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入视频描述')),
      );
      return;
    }
    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: '生成视频: $prompt',
      ));
      _messages.add(ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_video',
        role: 'assistant',
        content: '视频生成中，请耐心等待...',
        isThinking: true,
      ));
    });

    try {
      final result = await ApiService.generateVideo(prompt);
      final taskId = result['task_id'];
      
      // Poll for result
      bool done = false;
      while (!done) {
        await Future.delayed(const Duration(seconds: 5));
        final status = await ApiService.getVideoStatus(taskId);
        if (status['status'] == 'completed') {
          setState(() {
            _messages.last.isThinking = false;
            _messages.last.content = '视频生成完成！';
            _messages.last.videoUrl = ApiService.getMediaUrl(status['url']);
          });
          done = true;
        } else if (status['status'] == 'failed') {
          setState(() {
            _messages.last.isThinking = false;
            _messages.last.content = '视频生成失败';
          });
          done = true;
        }
      }
    } catch (e) {
      setState(() {
        _messages.last.isThinking = false;
        _messages.last.content = '视频生成失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => setState(() => _showSidebar = true),
        ),
        title: const Text('初眠AI'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.model_training_outlined),
            onSelected: (m) => setState(() => _selectedModel = m),
            itemBuilder: (context) => _textModels
                .map((m) => PopupMenuItem(
                      value: m,
                      child: Row(
                        children: [
                          if (m == _selectedModel)
                            const Icon(Icons.check, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(m),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) =>
                            _buildMessage(_messages[index]),
                      ),
              ),
              _buildInputBar(),
            ],
          ),
          if (_showSidebar) _buildSidebar(),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '你好，我是初眠',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '有什么我可以帮你的吗？',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryColor : AppTheme.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Think section
                  if (msg.thinkContent != null &&
                      msg.thinkContent!.isNotEmpty)
                    GestureDetector(
                      onTap: () => _toggleThink(msg),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  msg.isThinking
                                      ? Icons.hourglass_empty
                                      : Icons.lightbulb_outline,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  msg.isThinking ? '正在思考中...' : '思考过程',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  msg.isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ),
                            if (msg.isExpanded) ...[
                              const SizedBox(height: 8),
                              Text(
                                msg.thinkContent!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  // Image
                  if (msg.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        msg.imageUrl!,
                        width: 250,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 250,
                            height: 250,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          width: 250,
                          height: 150,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Video placeholder
                  if (msg.videoUrl != null) ...[
                    Container(
                      width: 250,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_outline,
                                color: Colors.white, size: 48),
                            SizedBox(height: 8),
                            Text('视频已生成',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Content
                  if (msg.content.isNotEmpty)
                    isUser
                        ? Text(
                            msg.content,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          )
                        : MarkdownBody(
                            data: msg.content,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: AppTheme.textPrimary,
                              ),
                              h1: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              h2: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              h3: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              code: TextStyle(
                                backgroundColor: Colors.grey[200],
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: const Color(0xFF2D2D3A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              codeblockPadding: const EdgeInsets.all(12),
                              strong: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              em: const TextStyle(fontStyle: FontStyle.italic),
                              listBullet: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                  if (msg.isThinking && msg.content.isEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '思考中...',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Disclaimer
            if (!isUser && msg.content.isNotEmpty && !msg.isThinking)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'AI生成不一定代表真实，如果您感觉到了异常，请立即停止使用。',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary.withOpacity(0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.add_circle_outline,
                  color: AppTheme.primaryColor),
              onSelected: (v) {
                if (v == 'image') _generateImage();
                if (v == 'video') _generateVideo();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'image',
                  child: Row(children: [
                    Icon(Icons.image_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('生成图片')
                  ]),
                ),
                const PopupMenuItem(
                  value: 'video',
                  child: Row(children: [
                    Icon(Icons.videocam_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('生成视频')
                  ]),
                ),
              ],
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: '输入消息...',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return GestureDetector(
      onTap: () => setState(() => _showSidebar = false),
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: double.infinity,
              color: AppTheme.surfaceColor,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          const Text(
                            '历史对话',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _newConversation,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conv = _conversations[index] as Map<String, dynamic>;
                          final convId = (conv['id'] ?? '').toString();
                          return ListTile(
                            leading: const Icon(Icons.chat_bubble_outline,
                                size: 20),
                            title: Text(
                              conv['title'] ?? '新对话',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: PopupMenuButton(
                              icon: const Icon(Icons.more_vert, size: 18),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: const Text('删除对话'),
                                  onTap: () {
                                    if (convId.isNotEmpty) {
                                      _deleteConversation(convId);
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              if (convId.isNotEmpty) {
                                _loadConversation(convId);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
