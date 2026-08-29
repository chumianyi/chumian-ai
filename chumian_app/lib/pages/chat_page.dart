import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import '../models/chat_message.dart';
import '../widgets/context_ext.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/buttons.dart';
import '../widgets/tiles.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'image_preview_page.dart';
import 'video_preview_page.dart';
import '../widgets/gradient_header.dart';

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
  String _pendingChars = '';
  Timer? _typewriterTimer;
  bool _streamDone = false;
  ChatMessage? _currentAiMsg;
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechInitialized = false;

  static const _galleryChannel = MethodChannel('com.chumian.chumian_ai/gallery');

  List<String> get _allModels => AppModels.all.map((m) => m.id).toList();

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
    _typewriterTimer?.cancel();
    _speech.stop();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _newConversation() {
    _stopTypewriter();
    setState(() {
      _messages.clear();
      _currentConvId = null;
      _pendingChars = '';
      _currentAiMsg = null;
    });
  }

  void _startTypewriter() {
    _typewriterTimer?.cancel();
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_pendingChars.isEmpty) {
        if (_streamDone) {
          timer.cancel();
          setState(() => _isSending = false);
        }
        return;
      }
      final charsToAdd = _pendingChars.length > 3 ? 3 : 1;
      final chunk = _pendingChars.substring(0, charsToAdd);
      _pendingChars = _pendingChars.substring(charsToAdd);
      setState(() {
        _currentAiMsg?.content += chunk;
      });
      _scrollToBottom();
    });
  }

  void _stopTypewriter() {
    _typewriterTimer?.cancel();
    _typewriterTimer = null;
  }

  void _stopGeneration() {
    _streamSub?.cancel();
    _streamSub = null;
    _streamDone = true;
    if (_pendingChars.isNotEmpty && _currentAiMsg != null) {
      setState(() {
        _currentAiMsg!.content += _pendingChars;
        _pendingChars = '';
        _currentAiMsg!.isThinking = false;
        _isSending = false;
      });
    } else {
      setState(() {
        _currentAiMsg?.isThinking = false;
        _isSending = false;
      });
    }
    _stopTypewriter();
  }

  Future<void> _initSpeech() async {
    if (_speechInitialized) return;
    try {
      _speechInitialized = await _speech.initialize();
    } catch (_) {
      _speechInitialized = false;
    }
  }

  Future<void> _startListening() async {
    await _initSpeech();
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) _showSnack('需要麦克风权限');
      return;
    }
    if (!_speechInitialized) {
      if (mounted) _showSnack('语音识别不可用');
      return;
    }
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      localeId: 'zh_CN',
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
      if (_controller.text.trim().isNotEmpty) {
        _sendMessage();
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
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
        isThinking: true,
        model: _selectedModel,
      ));
      _isSending = true;
    });
    _scrollToBottom();

    final aiMsg = _messages.last;
    _currentAiMsg = aiMsg;
    _streamDone = false;
    _pendingChars = '';
    _startTypewriter();

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
              aiMsg.thinkContent =
                  (aiMsg.thinkContent ?? '') + (data['content'] ?? '');
            });
          } else if (type == 'content') {
            aiMsg.isThinking = false;
            _pendingChars += data['content'] ?? '';
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
            _streamDone = true;
            setState(() => aiMsg.isThinking = false);
          } else if (type == 'error') {
            _streamDone = true;
            _stopTypewriter();
            setState(() {
              aiMsg.isThinking = false;
              aiMsg.content = '错误: ${data['message']}';
              _isSending = false;
            });
          }
        },
        onError: (e) {
          if (!mounted) return;
          _streamDone = true;
          _stopTypewriter();
          setState(() {
            aiMsg.isThinking = false;
            aiMsg.content = '网络错误: ${ErrorMessages.of(e)}';
            _isSending = false;
          });
        },
        onDone: () {
          _streamDone = true;
        },
      );
    } catch (e) {
      if (!mounted) return;
      _streamDone = true;
      _stopTypewriter();
      setState(() {
        aiMsg.isThinking = false;
        aiMsg.content = '发送失败: ${ErrorMessages.of(e)}';
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

  IconData _modelIcon(String model) {
    if (model.contains('cogview')) return Icons.image_outlined;
    if (model.contains('cogvideo')) return Icons.videocam_outlined;
    if (model.contains('4v') || model.contains('4.6v') || model.contains('4.1v')) {
      return Icons.photo_camera_outlined;
    }
    if (model.contains('z1')) return Icons.psychology_outlined;
    return Icons.chat_bubble_outline;
  }

  void _showModelPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconCircle(
                  icon: Icons.settings_suggest_outlined,
                  size: 38,
                  iconSize: 19,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选择模型',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      '不同模型擅长不同任务',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _allModels.length,
                itemBuilder: (context, index) {
                  final m = _allModels[index];
                  final option = AppModels.optionOf(m);
                  final selected = m == _selectedModel;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedModel = m);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? option.color.withValues(alpha: 0.1)
                              : context.surfaceSubtle,
                          borderRadius: BorderRadius.circular(14),
                          border: selected
                              ? Border.all(
                                  color: option.color.withValues(alpha: 0.5),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: option.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                _modelIcon(m),
                                size: 19,
                                color: option.color,
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
                                        option.name,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: option.color.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          option.tag,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: option.color,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    option.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: option.color,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConversationList() async {
    try {
      final convs = await ApiService.getConversations();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconCircle(
                    icon: Icons.history_rounded,
                    size: 38,
                    iconSize: 19,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '历史对话',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        '选择一段对话继续聊天',
                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (convs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('暂无历史对话'),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: convs.length,
                    itemBuilder: (context, index) {
                      final c = convs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _openConversation(c);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.surfaceSubtle,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: context.primary.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 19,
                                    color: context.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['title'] ?? '新对话',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        c['model'] ?? '未知模型',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: context.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (mounted) _showSnack('历史对话加载失败');
    }
  }

  Future<void> _openConversation(dynamic c) async {
    final msgs = await ApiService.getConversationMessages(c['id']);
    if (!mounted) return;
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconAction(
          icon: Icons.history_rounded,
          tooltip: '历史对话',
          onPressed: _showConversationList,
        ),
        title: const Text('初眠AI'),
        actions: [
          IconAction(
            icon: Icons.add_rounded,
            tooltip: '新对话',
            onPressed: _newConversation,
          ),
          IconAction(
            icon: Icons.tune_rounded,
            tooltip: '切换模型',
            onPressed: _showModelPicker,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessage(_messages[index]),
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final option = AppModels.optionOf(_selectedModel);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: context.primaryGradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 42,
                color: context.onPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '你好，我是初眠',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_modelIcon(_selectedModel), size: 14, color: option.color),
                  const SizedBox(width: 5),
                  Text(
                    option.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: option.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '有什么我可以帮你的吗？',
              style: TextStyle(fontSize: 14, color: context.textSecondary),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _suggestionChip('写一首诗', '帮我写一首关于秋天的诗'),
                _suggestionChip('翻译', '把这段中文翻译成英文'),
                _suggestionChip('学习', '如何高效学习一门新语言'),
                _suggestionChip('代码', '用Python写一个快速排序'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String label, String prompt) {
    return GestureDetector(
      onTap: () {
        _controller.text = prompt;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.surfaceSubtle,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12.5, color: context.textSecondary),
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.role == 'user';
    if (isUser) {
      return GestureDetector(
        onLongPress: () => _showMessageOptions(msg),
        child: UserBubble(
          content: msg.content,
          imageUrl: msg.imageUrl != null
              ? ApiService.getMediaUrl(msg.imageUrl!)
              : null,
          onImageTap: msg.imageUrl != null
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImagePreviewPage(
                      imageUrl: ApiService.getMediaUrl(msg.imageUrl!),
                    ),
                  ),
                )
              : null,
        ),
      );
    }

    return AiBubble(
      message: msg,
      onStop: _stopGeneration,
      onImageTap: msg.imageUrl != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImagePreviewPage(
                  imageUrl: ApiService.getMediaUrl(msg.imageUrl!),
                ),
              ),
            )
          : null,
      onVideoTap: msg.videoUrl != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    VideoPreviewPage(videoUrl: ApiService.getMediaUrl(msg.videoUrl!)),
              ),
            )
          : null,
      markdownBuilder: _buildMarkdown(msg),
    );
  }

  Widget _buildMarkdown(ChatMessage msg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () => _showMessageOptions(msg),
          child: MarkdownBody(
            data: msg.content,
            styleSheet: _markdownStyle(context),
            selectable: false,
          ),
        ),
        if (msg.videoUrl != null) _buildVideoPlayer(msg.videoUrl!),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              msg.model ?? '初眠AI',
              style: TextStyle(fontSize: 10, color: context.textTertiary),
            ),
            const Spacer(),
            Row(
              children: [
                _smallAction(
                  Icons.copy_rounded,
                  '复制',
                  () => _copyText(msg.content),
                ),
                const SizedBox(width: 12),
                _smallAction(
                  Icons.restart_alt_rounded,
                  '重试',
                  () {
                    if (_currentConvId != null) {
                      ApiService.deleteConversation(_currentConvId!);
                    }
                    _messages.removeWhere((m) => identical(m, msg));
                    setState(() {});
                    _sendMessage();
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _smallAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: context.textTertiary),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: context.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _showSnack('已复制到剪贴板');
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeBg =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    final codeFg = isDark ? const Color(0xFFF8F0E8) : const Color(0xFFC7254E);
    return MarkdownStyleSheet(
      p: TextStyle(fontSize: 15, height: 1.55, color: context.textPrimary),
      h1: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.textPrimary, height: 1.4),
      h2: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: context.textPrimary, height: 1.4),
      h3: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.textPrimary, height: 1.4),
      h4: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary),
      strong: TextStyle(fontWeight: FontWeight.w800, color: context.textPrimary),
      em: TextStyle(fontStyle: FontStyle.italic, color: context.textPrimary),
      blockquote: TextStyle(fontSize: 14, color: context.textSecondary, height: 1.5),
      blockquoteDecoration: BoxDecoration(
        color: context.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: context.primary, width: 3)),
      ),
      code: TextStyle(
        fontSize: 13,
        fontFamily: 'monospace',
        color: codeFg,
        backgroundColor: codeBg,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(10),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      listBullet: TextStyle(fontSize: 15, color: context.textSecondary),
      horizontalRuleDecoration: BoxDecoration(
        color: context.divider,
        borderRadius: BorderRadius.circular(2),
      ),
      tableHead: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary),
      tableBody: TextStyle(fontSize: 14, color: context.textPrimary),
      tableBorder: TableBorder.all(color: context.divider),
    );
  }

  Future<void> _saveImage(String url) async {
    try {
      final response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data);
      await _galleryChannel.invokeMethod('saveImage', {
        'bytes': bytes,
        'album': '初眠AI',
      });
      if (mounted) _showSnack('图片已保存到相册');
    } catch (e) {
      if (mounted) _showSnack('保存失败: ${ErrorMessages.of(e)}');
    }
  }

  void _showImageMenu(String imageUrl) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.zoom_in_rounded),
              title: const Text('查看大图'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImagePreviewPage(imageUrl: imageUrl),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('保存到相册'),
              onTap: () {
                Navigator.pop(ctx);
                _saveImage(imageUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: const Text('取消'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(String url) {
    final videoUrl = ApiService.getMediaUrl(url);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoPreviewPage(videoUrl: videoUrl)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 260,
          height: 170,
          color: const Color(0xFF1A1A24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                size: 58,
                color: Colors.white70,
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '点击播放',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MenuTile(
              icon: Icons.copy_rounded,
              title: '复制内容',
              onTap: () {
                Navigator.pop(ctx);
                _copyText(msg.content);
              },
            ),
            const ThinDivider(indent: 16, endIndent: 16),
            MenuTile(
              icon: Icons.delete_outline_rounded,
              title: '清除本对话',
              iconColor: context.danger,
              onTap: () async {
                Navigator.pop(ctx);
                if (_currentConvId != null) {
                  await ApiService.deleteConversation(_currentConvId!);
                }
                setState(() {
                  _messages.clear();
                  _currentConvId = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final option = AppModels.optionOf(_selectedModel);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: context.surface,
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_isListening)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: context.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8445C),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '正在聆听… 松开发送',
                      style: TextStyle(fontSize: 13, color: Color(0xFFE8445C)),
                    ),
                    const SizedBox(width: 8),
                    _buildWaveform(),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 模型胶囊
                GestureDetector(
                  onTap: _showModelPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: option.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _modelIcon(_selectedModel),
                          size: 15,
                          color: option.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          option.name.length > 12
                              ? '${option.name.substring(0, 10)}…'
                              : option.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: option.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 输入框
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: context.surfaceSubtle,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: context.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: TextStyle(
                        fontSize: 15,
                        color: context.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '输入消息…',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: context.textTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 语音按钮
                GestureDetector(
                  onLongPressStart: (_) => _startListening(),
                  onLongPressEnd: (_) => _stopListening(),
                  onLongPressCancel: () => _stopListening(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? context.danger
                          : context.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? Colors.white : context.primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 发送 / 停止
                GestureDetector(
                  onTap: _isSending ? _stopGeneration : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: _isSending ? null : context.vibrantGradient,
                      color: _isSending ? context.danger : null,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isSending ? Icons.stop_rounded : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 3,
          height: 8.0 + (i % 3) * 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE8445C),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
