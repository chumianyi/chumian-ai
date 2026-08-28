import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
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
  String? videoTaskId;
  bool videoLoading = false;

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
    this.videoTaskId,
  });
}

class ChatPage extends StatefulWidget {
  final String? initialPrompt;
  final String? initialModel;
  const ChatPage({super.key, this.initialPrompt, this.initialModel});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  String _selectedModel = 'glm-4-flash';
  String? _currentConvId;
  StreamSubscription? _streamSub;
  VideoPlayerController? _videoController;

  final List<String> _allModels = [
    'glm-4-flash', 'glm-4-flash-250414', 'glm-4.7-flash', 'glm-z1-flash',
    'glm-4v-flash', 'glm-4.6v-flash', 'glm-4.1v-thinking-flash',
    'cogview-3-flash', 'cogvideox-flash',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialModel != null) _selectedModel = widget.initialModel!;
    if (widget.initialPrompt != null) {
      _controller.text = widget.initialPrompt!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendMessage());
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _newConversation() {
    setState(() {
      _messages.clear();
      _currentConvId = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    _controller.clear();
    _focusNode.unfocus();

    final isImageModel = _selectedModel == 'cogview-3-flash';
    final isVideoModel = _selectedModel == 'cogvideox-flash';

    setState(() {
      _messages.add(ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), role: 'user', content: text));
      _messages.add(ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        role: 'assistant',
        content: '',
        isThinking: true,
        model: _selectedModel,
      ));
      _isSending = true;
    });
    _scrollToBottom();

    final aiMsg = _messages.last;

    try {
      _streamSub = ApiService.chatStream(
        conversationId: _currentConvId,
        message: text,
        model: _selectedModel,
      ).listen(
        (data) {
          if (!mounted) return;
          final type = data['type'];
          if (type == 'think') {
            setState(() {
              aiMsg.thinkContent = (aiMsg.thinkContent ?? '') + (data['content'] ?? '');
            });
          } else if (type == 'content') {
            setState(() {
              aiMsg.isThinking = false;
              aiMsg.content += data['content'] ?? '';
            });
            _scrollToBottom();
          } else if (type == 'image') {
            setState(() {
              aiMsg.imageUrl = data['url'];
              aiMsg.isThinking = false;
            });
          } else if (type == 'video_task') {
            setState(() {
              aiMsg.videoTaskId = data['task_id'];
              aiMsg.videoLoading = true;
            });
            _pollVideoStatus(aiMsg);
          } else if (type == 'done') {
            if (data['conversation_id'] != null) {
              _currentConvId = data['conversation_id'];
            }
            setState(() {
              aiMsg.isThinking = false;
              _isSending = false;
            });
          } else if (type == 'error') {
            setState(() {
              aiMsg.isThinking = false;
              aiMsg.content = '错误: ${data['message']}';
              _isSending = false;
            });
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            aiMsg.isThinking = false;
            aiMsg.content = '网络错误: $e';
            _isSending = false;
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _isSending = false);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        aiMsg.isThinking = false;
        aiMsg.content = '发送失败: $e';
        _isSending = false;
      });
    }
  }

  Future<void> _pollVideoStatus(ChatMessage msg) async {
    if (msg.videoTaskId == null) return;
    while (mounted && msg.videoLoading) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final status = await ApiService.getVideoStatus(msg.videoTaskId!);
        if (status['status'] == 'completed' && status['url'] != null) {
          if (mounted) {
            setState(() {
              msg.videoUrl = status['url'];
              msg.videoLoading = false;
              msg.content = '视频生成完成！';
            });
          }
          break;
        } else if (status['status'] == 'failed') {
          if (mounted) {
            setState(() {
              msg.videoLoading = false;
              msg.content = '视频生成失败: ${status['error']}';
            });
          }
          break;
        }
      } catch (_) {}
    }
  }

  void _showModelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: Theme.of(ctx).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择模型', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._allModels.map((m) => ListTile(
              leading: Icon(_getModelIcon(m), color: AppTheme.primaryColor),
              title: Text(m, style: const TextStyle(fontSize: 14)),
              trailing: m == _selectedModel ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
              onTap: () {
                setState(() => _selectedModel = m);
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getModelIcon(String model) {
    if (model.contains('cogview')) return Icons.image_outlined;
    if (model.contains('cogvideo')) return Icons.videocam_outlined;
    if (model.contains('4v') || model.contains('4.6v') || model.contains('4.1v')) return Icons.photo_camera_outlined;
    if (model.contains('z1')) return Icons.psychology_outlined;
    return Icons.chat_outlined;
  }

  Future<void> _showConversationList() async {
    try {
      final convs = await ApiService.getConversations();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: BoxDecoration(color: Theme.of(ctx).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('历史对话', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (convs.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('暂无历史对话', textAlign: TextAlign.center)),
              ...convs.take(20).map((c) => ListTile(
                leading: const Icon(Icons.history, color: AppTheme.primaryColor),
                title: Text(c['title'] ?? '新对话', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(c['model'] ?? '', style: const TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final msgs = await ApiService.getConversationMessages(c['id']);
                  setState(() {
                    _currentConvId = c['id'];
                    _messages.clear();
                    for (final m in msgs) {
                      _messages.add(ChatMessage(
                        id: m['id'] ?? DateTime.now().toString(),
                        role: m['role'],
                        content: m['content'] ?? '',
                        thinkContent: m['think_content'],
                        model: m['model'],
                        imageUrl: m['image_url'],
                        videoUrl: m['video_url'],
                      ));
                    }
                  });
                },
              )),
            ],
          ),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.history), onPressed: _showConversationList, tooltip: '历史对话'),
        title: const Text('初眠AI'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _newConversation, tooltip: '新对话'),
          IconButton(icon: Icon(_getModelIcon(_selectedModel)), onPressed: _showModelPicker, tooltip: '切换模型'),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildEmptyState() : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.auto_awesome, size: 40, color: AppTheme.primaryColor)),
          const SizedBox(height: 24),
          const Text('你好，我是初眠', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('当前模型: $_selectedModel', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          const Text('有什么我可以帮你的吗？', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isUser ? null : () => _showMessageOptions(msg),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (msg.thinkContent != null && msg.thinkContent!.isNotEmpty) _buildThinkSection(msg),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUser ? AppTheme.primaryColor : (isDark ? AppTheme.darkSurface : AppTheme.surfaceColor),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4), bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.isThinking && msg.content.isEmpty)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                    if (msg.content.isNotEmpty)
                      isUser
                          ? Text(msg.content, style: const TextStyle(color: Colors.white, fontSize: 15))
                          : MarkdownBody(data: msg.content, styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 15), h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), code: const TextStyle(fontSize: 13, backgroundColor: Colors.black12), codeblockDecoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)))),
                    if (msg.imageUrl != null)
                      Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(ApiService.getMediaUrl(msg.imageUrl!), width: 250, fit: BoxFit.cover))),
                    if (msg.videoUrl != null) _buildVideoPlayer(msg.videoUrl!),
                    if (msg.videoLoading) const Padding(padding: EdgeInsets.only(top: 8), child: Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text('视频生成中...', style: TextStyle(fontSize: 13))])),
                  ],
                ),
              ),
              if (!isUser && msg.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.model != null) Text(msg.model!, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      const Text('AI生成不一定代表真实，如果您感觉到了异常，请立即停止使用。', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThinkSection(ChatMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => msg.isExpanded = !msg.isExpanded),
            child: Row(children: [
              Icon(msg.isExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(msg.isExpanded ? '思考过程' : '正在思考中...', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
            ]),
          ),
          if (msg.isExpanded) Padding(padding: const EdgeInsets.only(top: 8), child: Text(msg.thinkContent!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(String url) {
    return FutureBuilder<VideoPlayerController>(
      future: () async {
        final ctrl = VideoPlayerController.networkUrl(Uri.parse(ApiService.getMediaUrl(url)));
        await ctrl.initialize();
        return ctrl;
      }(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: AspectRatio(aspectRatio: snapshot.data!.value.aspectRatio, child: VideoPlayer(snapshot.data!))));
        }
        return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
      },
    );
  }

  void _showMessageOptions(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: Theme.of(ctx).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: const Icon(Icons.copy, color: AppTheme.primaryColor), title: const Text('复制内容'), onTap: () { Navigator.pop(ctx); }),
              ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('清除本对话'), onTap: () async {
                Navigator.pop(ctx);
                if (_currentConvId != null) {
                  await ApiService.deleteConversation(_currentConvId!);
                }
                setState(() {
                  _messages.clear();
                  _currentConvId = null;
                });
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : AppTheme.surfaceColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(onTap: _showModelPicker, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(_getModelIcon(_selectedModel), size: 16, color: AppTheme.primaryColor), const SizedBox(width: 4), Text(_selectedModel.length > 12 ? '${_selectedModel.substring(0, 10)}..' : _selectedModel, style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w500))]))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _controller, focusNode: _focusNode, maxLines: null, textInputAction: TextInputAction.send, onSubmitted: (_) => _sendMessage(), decoration: InputDecoration(hintText: '输入消息...', filled: true, fillColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)))),
                const SizedBox(width: 8),
                GestureDetector(onTap: _isSending ? null : _sendMessage, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: _isSending ? AppTheme.textSecondary : AppTheme.primaryColor, shape: BoxShape.circle), child: const Icon(Icons.send, color: Colors.white, size: 20))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
