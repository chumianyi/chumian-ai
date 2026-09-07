import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/widgets/common/lottie_loading.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/services/sound_service.dart';
import 'package:chumian_ai/services/web_search_service.dart';
import 'package:chumian_ai/providers/chat_provider.dart';
import 'package:chumian_ai/providers/theme_provider.dart';
import 'package:chumian_ai/providers/settings_provider.dart';
import 'package:chumian_ai/utils/app_icons.dart';
import 'package:chumian_ai/utils/markdown_stripper.dart';
import 'package:chumian_ai/utils/clipboard_utils.dart';
import 'package:chumian_ai/pages/conversation_list_page.dart';
import 'package:chumian_ai/pages/model_picker_page.dart';
import 'package:chumian_ai/pages/web_search_results_page.dart';

/// ============================================================
/// ChatPage —— 对话页（最核心）
/// AppBar + 消息列表 + 扁平化输入框 + 双胶囊按钮
/// 真实 SSE 流式打字机 / 真实联网搜索 / 语音输入 / 视频生成轮询
/// 错误时显示红色错误气泡 + 重试按钮，绝不本地伪造回答
/// ============================================================

/// 消息模型
class ChatMessageItem {
  ChatMessageItem({
    required this.id,
    required this.role,
    required this.content,
    this.thinking = '',
    this.showThinking = false,
    this.isStreaming = false,
    this.searchSources = const [],
    this.imageUrl,
    this.videoUrl,
    this.timestamp,
    this.hasError = false,
    this.errorMessage = '',
  });

  final String id;
  final String role; // 'user' | 'assistant'
  String content;
  String thinking;
  bool showThinking;
  bool isStreaming;
  List<SearchSource> searchSources;
  String? imageUrl;
  String? videoUrl;
  DateTime? timestamp;

  /// 错误状态：请求失败时为 true，显示错误气泡 + 重试按钮
  bool hasError;
  String errorMessage;
}

class SearchSource {
  SearchSource({
    required this.title,
    required this.url,
    this.snippet = '',
    this.source = '',
  });
  final String title;
  final String url;
  final String snippet;
  final String source;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.conversationId, this.initialPrompt});

  final String? conversationId;
  final String? initialPrompt;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  /// 联网搜索服务（真实调用后端）
  final WebSearchService _webSearchService = WebSearchService();

  final List<ChatMessageItem> _messages = [];
  String _currentModel = 'glm-4-flash';
  String _currentModelName = 'GLM-4 Flash';
  bool _webSearchEnabled = false;
  bool _isGenerating = false;
  bool _isRecording = false;
  bool _showVoiceWave = false;
  String? _conversationId;
  StreamSubscription? _streamSub;
  Timer? _videoPollTimer;

  late AnimationController _inputGlowController;
  late Animation<double> _inputGlowAnim;
  late AnimationController _listAnimController;

  /// 空状态建议提示（仅作 UI 引导，不是伪造 AI 内容）
  static const List<String> _suggestions = [
    '帮我写一首关于春天的诗',
    '用简单的话解释量子力学',
    '给我一个一周健身计划',
    '写一段产品发布会的开场白',
  ];

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _inputGlowController = AnimationController(
      vsync: this,
      duration: MiuixDuration.normal,
    );
    _inputGlowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _inputGlowController, curve: MiuixCurves.easeInOut),
    );
    _listAnimController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _inputFocus.addListener(() {
      if (_inputFocus.hasFocus) {
        _inputGlowController.forward();
      } else {
        _inputGlowController.reverse();
      }
    });

    // 初始化音效服务并注入 SettingsProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final settings = context.read<SettingsProvider>();
        SoundService().setSettingsProvider(settings);
        SoundService().init();
      }
    });

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _inputController.text = widget.initialPrompt!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage();
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    _scrollController.dispose();
    _inputGlowController.dispose();
    _listAnimController.dispose();
    _streamSub?.cancel();
    _videoPollTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: MiuixDuration.fast,
          curve: MiuixCurves.easeOut,
        );
      }
    });
  }

  /// 发送消息（真实 SSE，无任何本地伪造兜底）
  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    _inputController.clear();
    _inputFocus.unfocus();

    // 播放发送音效
    SoundService().playSend();

    final userMsg = ChatMessageItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMsg);
      _isGenerating = true;
    });
    _scrollToBottom();

    // AI 回复占位（空内容 + 流式状态，等待真实 SSE 数据）
    final aiMsg = ChatMessageItem(
      id: 'ai_${DateTime.now().microsecondsSinceEpoch}',
      role: 'assistant',
      content: '',
      isStreaming: true,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(aiMsg));

    // 真实联网搜索：若启用，先调用后端搜索接口获取真实结果
    String enhancedText = text;
    if (_webSearchEnabled) {
      try {
        final results = await _webSearchService.search(text);
        if (results.isNotEmpty && mounted) {
          setState(() {
            aiMsg.searchSources = results
                .map((r) => SearchSource(
                      title: r.title,
                      url: r.url,
                      snippet: r.summary,
                      source: r.displaySource,
                    ))
                .toList();
          });
          enhancedText = _webSearchService.formatResultsForPrompt(results);
        }
      } catch (_) {
        // 搜索失败不阻塞对话，使用原始文本继续
      }
    }

    // 真实 SSE 流式连接
    try {
      final stream = ApiService.chatStream(
        conversationId: _conversationId,
        message: enhancedText,
        model: _currentModel,
        webSearchEnabled: _webSearchEnabled,
      );

      _streamSub = stream.listen(
        (data) {
          if (!mounted) return;
          final type = data['type'] as String?;
          if (type == 'thinking') {
            aiMsg.thinking += (data['content'] as String? ?? '');
            aiMsg.showThinking = true;
          } else if (type == 'content' || type == 'delta') {
            aiMsg.content += (data['content'] as String? ?? '');
          } else if (type == 'conversation_id') {
            _conversationId = data['id'] as String?;
          } else if (type == 'video_task') {
            _pollVideoStatus(data['task_id'] as String, aiMsg);
          } else if (type == 'done') {
            aiMsg.isStreaming = false;
            // 收到完整回复后播放接收音效
            SoundService().playReceive();
          } else if (type == 'error') {
            // 服务端返回错误：设置错误状态，绝不伪造回答
            aiMsg.hasError = true;
            aiMsg.errorMessage =
                data['message']?.toString() ?? '服务端返回错误';
            aiMsg.isStreaming = false;
            SoundService().playError();
          }
          if (mounted) setState(() {});
          _scrollToBottom();
        },
        onError: (e) {
          if (!mounted) return;
          // 网络/连接错误：设置错误状态，显示错误气泡 + 重试
          aiMsg.hasError = true;
          aiMsg.errorMessage = '网络连接失败：$e';
          aiMsg.isStreaming = false;
          SoundService().playError();
          if (mounted) setState(() {});
        },
        onDone: () {
          if (!mounted) return;
          if (aiMsg.isStreaming) {
            aiMsg.isStreaming = false;
          }
          // 如果流正常结束但内容为空且无错误，标记为异常
          if (aiMsg.content.isEmpty && !aiMsg.hasError) {
            aiMsg.hasError = true;
            aiMsg.errorMessage = 'AI 返回内容为空，请稍后重试';
          }
          if (mounted) setState(() {});
        },
        cancelOnError: false,
      );

      // 等待流结束
      await _streamSub!.asFuture<void>().catchError((_) {});
    } catch (e) {
      if (mounted) {
        aiMsg.hasError = true;
        aiMsg.errorMessage = '请求失败：$e';
        aiMsg.isStreaming = false;
        SoundService().playError();
        setState(() {});
      }
    }

    if (mounted) {
      setState(() => _isGenerating = false);
    }
  }

  /// 重试失败的消息：找到对应的用户消息重新发送
  void _retryMessage(ChatMessageItem errorMsg) {
    final index = _messages.indexOf(errorMsg);
    if (index <= 0) return;
    final prevUserMsg = _messages[index - 1];
    if (prevUserMsg.role != 'user') return;
    SoundService().playClick();
    setState(() {
      _messages.removeRange(index, _messages.length);
    });
    _inputController.text = prevUserMsg.content;
    _sendMessage();
  }

  /// 停止生成
  void _stopGeneration() {
    _streamSub?.cancel();
    for (final m in _messages) {
      if (m.isStreaming) {
        m.isStreaming = false;
      }
    }
    setState(() => _isGenerating = false);
  }

  /// 视频生成轮询
  void _pollVideoStatus(String taskId, ChatMessageItem msg) {
    _videoPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final status = await ApiService.getVideoStatus(taskId);
        if (status['status'] == 'completed') {
          msg.videoUrl = status['video_url'] as String?;
          msg.isStreaming = false;
          timer.cancel();
          if (mounted) setState(() {});
        } else if (status['status'] == 'failed') {
          msg.hasError = true;
          msg.errorMessage = '视频生成失败';
          msg.isStreaming = false;
          timer.cancel();
          if (mounted) setState(() {});
        }
      } catch (_) {
        // 轮询异常继续尝试
      }
    });
  }

  /// 重新生成
  void _regenerateMessage(ChatMessageItem msg) {
    final index = _messages.indexOf(msg);
    if (index <= 0) return;
    final prevUserMsg = _messages[index - 1];
    if (prevUserMsg.role != 'user') return;
    SoundService().playClick();
    setState(() {
      _messages.removeRange(index, _messages.length);
    });
    _inputController.text = prevUserMsg.content;
    _sendMessage();
  }

  /// 删除消息
  void _deleteMessage(ChatMessageItem msg) {
    SoundService().playDelete();
    setState(() => _messages.remove(msg));
  }

  /// 长按菜单
  void _showMessageMenu(ChatMessageItem msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: MiuixColors.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(MiuixRadius.xl)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MiuixColors.border,
                  borderRadius: MiuixRadius.pillRadius,
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuTile(Icons.copy, '复制', () async {
                Navigator.pop(context);
                final plain = MarkdownStripper.strip(msg.content);
                await ClipboardUtils.copy(plain);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('已复制到剪贴板'),
                      backgroundColor: MiuixColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: MiuixRadius.mdRadius),
                    ),
                  );
                }
              }),
              if (msg.role == 'assistant' && !msg.hasError)
                _buildMenuTile(Icons.refresh, '重新生成', () {
                  Navigator.pop(context);
                  _regenerateMessage(msg);
                }),
              _buildMenuTile(Icons.delete_outline, '删除', () {
                Navigator.pop(context);
                _deleteMessage(msg);
              }, isDestructive: true),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    return MiuixRipple(
      child: ListTile(
        leading: Icon(icon,
            color: isDestructive ? MiuixColors.error : MiuixColors.primary),
        title: Text(label,
            style: TextStyle(
                color: isDestructive
                    ? MiuixColors.error
                    : MiuixColors.textPrimary)),
        onTap: onTap,
      ),
    );
  }

  /// 打开模型选择
  void _openModelPicker() {
    SoundService().playClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModelPickerPage(
        currentModel: _currentModel,
        onSelected: (modelId, modelName) {
          setState(() {
            _currentModel = modelId;
            _currentModelName = modelName;
          });
        },
      ),
    );
  }

  /// 语音输入（长按说话）—— 仅 UI 状态，识别结果由系统语音服务填入
  void _startRecording() {
    HapticFeedback.lightImpact();
    SoundService().playRecordStart();
    setState(() {
      _isRecording = true;
      _showVoiceWave = true;
    });
  }

  void _stopRecording() {
    SoundService().playRecordStop();
    setState(() {
      _isRecording = false;
      _showVoiceWave = false;
    });
    // 真实语音识别需接入系统 STT 服务，此处不伪造识别结果
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final bgColor =
        isDark ? MiuixColors.darkBackground : MiuixColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(isDark)
                : _buildMessageList(isDark),
          ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  // ===== AppBar =====
  PreferredSizeWidget _buildAppBar(bool isDark) {
    final bgColor = isDark ? MiuixColors.darkSurface : MiuixColors.surface;
    final textColor =
        isDark ? MiuixColors.darkTextPrimary : MiuixColors.textPrimary;

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: MiuixRipple(
        borderRadius: MiuixRadius.pill,
        child: IconButton(
          icon: SvgPicture.asset(
            AppIcons.history,
            width: 22,
            height: 22,
            colorFilter:
                ColorFilter.mode(MiuixColors.primary, BlendMode.srcIn),
          ),
          onPressed: () {
            SoundService().playClick();
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, anim, __) => FadeTransition(
                  opacity: anim,
                  child: const ConversationListPage(),
                ),
                transitionDuration: MiuixDuration.page,
              ),
            );
          },
        ),
      ),
      title: GestureDetector(
        onTap: _openModelPicker,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '初眠AI',
              style: TextStyle(
                  color: textColor,
                  fontSize: MiuixFontSize.lg,
                  fontWeight: FontWeight.w600),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz, size: 12, color: MiuixColors.primary),
                const SizedBox(width: 2),
                Text(
                  _currentModelName,
                  style: TextStyle(
                      color: MiuixColors.primary, fontSize: MiuixFontSize.xs),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        MiuixRipple(
          borderRadius: MiuixRadius.pill,
          child: IconButton(
            icon: SvgPicture.asset(
              AppIcons.robot,
              width: 22,
              height: 22,
              colorFilter:
                  ColorFilter.mode(MiuixColors.primary, BlendMode.srcIn),
            ),
            onPressed: _openModelPicker,
          ),
        ),
        MiuixRipple(
          borderRadius: MiuixRadius.pill,
          child: IconButton(
            icon: SvgPicture.asset(
              AppIcons.plus,
              width: 22,
              height: 22,
              colorFilter:
                  ColorFilter.mode(MiuixColors.primary, BlendMode.srcIn),
            ),
            onPressed: () {
              SoundService().playClick();
              setState(() {
                _messages.clear();
                _conversationId = null;
              });
            },
          ),
        ),
      ],
    );
  }

  // ===== 空状态（使用 empty_chat.png 插画）=====
  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // 空状态插画
            Image.asset(
              'assets/illustrations/empty_chat.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      LinearGradient(colors: MiuixColors.primaryGradient),
                ),
                child: const Icon(Icons.smart_toy,
                    color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '你好，我是初眠',
              style: TextStyle(
                color: isDark
                    ? MiuixColors.darkTextPrimary
                    : MiuixColors.textPrimary,
                fontSize: MiuixFontSize.xxl,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当前模型：$_currentModelName',
              style: TextStyle(
                  color: MiuixColors.textSecondary,
                  fontSize: MiuixFontSize.sm),
            ),
            const SizedBox(height: 32),
            ..._suggestions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MiuixRipple(
                  borderRadius: MiuixRadius.md,
                  child: GestureDetector(
                    onTap: () {
                      SoundService().playClick();
                      _inputController.text = entry.value;
                      _sendMessage();
                    },
                    child: MiuixGlassContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      borderRadius: MiuixRadius.md,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppIcons.sparkles,
                            width: 18,
                            height: 18,
                            colorFilter: ColorFilter.mode(
                                MiuixColors.primary, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                color: isDark
                                    ? MiuixColors.darkTextPrimary
                                    : MiuixColors.textPrimary,
                                fontSize: MiuixFontSize.md,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ===== 消息列表 =====
  Widget _buildMessageList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: MiuixDuration.normal,
          curve: MiuixCurves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 20),
                child: child,
              ),
            );
          },
          child: _buildMessageBubble(msg, isDark),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageItem msg, bool isDark) {
    final isUser = msg.role == 'user';

    // 错误消息：红色/粉色错误气泡 + 错误图标 + 错误文字 + 重试按钮
    if (msg.hasError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAiAvatar(),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: MiuixColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(4),
                    topRight: Radius.circular(MiuixRadius.lg),
                    bottomLeft: const Radius.circular(MiuixRadius.lg),
                    bottomRight: const Radius.circular(MiuixRadius.lg),
                  ),
                  border: Border.all(
                      color: MiuixColors.error.withOpacity(0.3),
                      width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          AppIcons.error,
                          width: 18,
                          height: 18,
                          colorFilter: ColorFilter.mode(
                              MiuixColors.error, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '请求失败',
                          style: TextStyle(
                            color: MiuixColors.error,
                            fontSize: MiuixFontSize.sm,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      msg.errorMessage,
                      style: TextStyle(
                        color: MiuixColors.error.withOpacity(0.8),
                        fontSize: MiuixFontSize.sm,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 重试按钮
                    MiuixRipple(
                      borderRadius: MiuixRadius.pill,
                      child: GestureDetector(
                        onTap: () => _retryMessage(msg),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: MiuixColors.primaryGradient),
                            borderRadius: MiuixRadius.pillRadius,
                            boxShadow: MiuixShadows.sm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                AppIcons.retry,
                                width: 14,
                                height: 14,
                                colorFilter: const ColorFilter.mode(
                                    Colors.white, BlendMode.srcIn),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                '重试',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MiuixFontSize.sm,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAiAvatar(),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageMenu(msg),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // 思考过程
                  if (msg.thinking.isNotEmpty)
                    _buildThinkingSection(msg, isDark),
                  // 消息内容
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser
                          ? MiuixColors.primary
                          : (isDark
                              ? MiuixColors.darkSurfaceVariant
                              : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                            isUser ? MiuixRadius.lg : 4),
                        topRight: Radius.circular(
                            isUser ? 4 : MiuixRadius.lg),
                        bottomLeft:
                            const Radius.circular(MiuixRadius.lg),
                        bottomRight:
                            const Radius.circular(MiuixRadius.lg),
                      ),
                      border: isUser
                          ? null
                          : Border.all(
                              color: isDark
                                  ? MiuixColors.darkBorder
                                  : MiuixColors.borderLight,
                              width: 0.5),
                      boxShadow: isUser ? null : MiuixShadows.xs,
                    ),
                    child: msg.content.isEmpty && msg.isStreaming
                        ? _buildTypingIndicator()
                        : isUser
                            ? Text(
                                msg.content,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: MiuixFontSize.md,
                                    height: 1.5),
                              )
                            : MarkdownBody(
                                data: msg.content,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                      color: isDark
                                          ? MiuixColors.darkTextPrimary
                                          : MiuixColors.textPrimary,
                                      fontSize: MiuixFontSize.md,
                                      height: 1.6),
                                  h1: TextStyle(
                                      color: MiuixColors.primary,
                                      fontSize: MiuixFontSize.xl,
                                      fontWeight: FontWeight.bold),
                                  h2: TextStyle(
                                      color: MiuixColors.primary,
                                      fontSize: MiuixFontSize.lg,
                                      fontWeight: FontWeight.bold),
                                  code: TextStyle(
                                      color: MiuixColors.primaryDeep,
                                      fontSize: MiuixFontSize.sm),
                                  codeblockDecoration: BoxDecoration(
                                      color: MiuixColors.surfaceVariant,
                                      borderRadius:
                                          MiuixRadius.smRadius),
                                  blockquote: TextStyle(
                                      color: MiuixColors.textSecondary),
                                  a: TextStyle(
                                      color: MiuixColors.textLink),
                                ),
                              ),
                  ),
                  // 图片消息
                  if (msg.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: MiuixRadius.mdRadius,
                        child: Image.network(msg.imageUrl!,
                            width: 200, fit: BoxFit.cover),
                      ),
                    ),
                  // 视频消息
                  if (msg.videoUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: 200,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: MiuixRadius.mdRadius,
                        ),
                        child: const Center(
                            child: Icon(Icons.play_circle_fill,
                                color: Colors.white, size: 40)),
                      ),
                    ),
                  // 联网搜索来源（真实搜索结果）
                  if (msg.searchSources.isNotEmpty)
                    _buildSearchSources(msg, isDark),
                  // 流式光标
                  if (msg.isStreaming && msg.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Container(
                        width: 8,
                        height: 16,
                        color: MiuixColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildUserAvatar(isDark),
        ],
      ),
    );
  }

  Widget _buildAiAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: MiuixColors.primaryGradient),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/mascot/mascot_small.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.smart_toy, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? MiuixColors.darkSurfaceVariant
            : MiuixColors.surfaceVariant,
        border: Border.all(
            color: MiuixColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Icon(Icons.person, color: MiuixColors.primary, size: 20),
    );
  }

  /// 打字指示器（使用 Lottie loading 动画）
  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LottieLoading(
          type: LottieLoadingType.loading,
          size: 32,
        ),
      ],
    );
  }

  Widget _buildThinkingSection(ChatMessageItem msg, bool isDark) {
    return StatefulBuilder(
      builder: (context, setLocal) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: MiuixGlassContainer(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderRadius: MiuixRadius.sm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () =>
                      setLocal(() => msg.showThinking = !msg.showThinking),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology,
                          size: 14, color: MiuixColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('思考过程',
                          style: TextStyle(
                              color: MiuixColors.textSecondary,
                              fontSize: MiuixFontSize.xs)),
                      Icon(
                        msg.showThinking
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 16,
                        color: MiuixColors.textTertiary,
                      ),
                    ],
                  ),
                ),
                if (msg.showThinking) ...[
                  const SizedBox(height: 6),
                  Text(
                    msg.thinking,
                    style: TextStyle(
                        color: MiuixColors.textTertiary,
                        fontSize: MiuixFontSize.sm,
                        height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchSources(ChatMessageItem msg, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                AppIcons.globe,
                width: 14,
                height: 14,
                colorFilter:
                    ColorFilter.mode(MiuixColors.primary, BlendMode.srcIn),
              ),
              const SizedBox(width: 4),
              Text('联网搜索来源',
                  style: TextStyle(
                      color: MiuixColors.primary,
                      fontSize: MiuixFontSize.xs,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ...msg.searchSources.map((source) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: MiuixRipple(
                borderRadius: MiuixRadius.sm,
                child: GestureDetector(
                  onTap: () {
                    SoundService().playClick();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              WebSearchResultsPage(query: source.title)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: MiuixColors.primary.withOpacity(0.05),
                      borderRadius: MiuixRadius.smRadius,
                      border: Border.all(
                          color:
                              MiuixColors.primary.withOpacity(0.15),
                          width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(source.title,
                            style: TextStyle(
                                color: MiuixColors.textLink,
                                fontSize: MiuixFontSize.sm,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (source.snippet.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(source.snippet,
                              style: TextStyle(
                                  color: MiuixColors.textSecondary,
                                  fontSize: MiuixFontSize.xs),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===== 输入区域 =====
  Widget _buildInputArea(bool isDark) {
    return MiuixGlassContainer(
      blur: 24,
      borderRadius: 0,
      backgroundColor: isDark
          ? MiuixColors.darkSurface.withOpacity(0.85)
          : Colors.white.withOpacity(0.85),
      borderColor: Colors.transparent,
      shadow: [
        BoxShadow(
          color: MiuixColors.primary.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ],
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 两个胶囊按钮（使用新 SVG 图标 globe / robot）
              Row(
                children: [
                  _buildCapsuleButton(
                    iconPath: AppIcons.globe,
                    label: '联网搜索',
                    isActive: _webSearchEnabled,
                    onTap: () {
                      SoundService().playClick();
                      setState(() => _webSearchEnabled = !_webSearchEnabled);
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildCapsuleButton(
                    iconPath: AppIcons.robot,
                    label: '更换模型',
                    isActive: false,
                    onTap: _openModelPicker,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 语音波形
              if (_showVoiceWave) _buildVoiceWaveform(),
              // 输入框行
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 麦克风按钮
                  GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
                    child: AnimatedContainer(
                      duration: MiuixDuration.fast,
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? MiuixColors.error
                            : MiuixColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        _isRecording ? AppIcons.stop : AppIcons.microphone,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                            _isRecording ? Colors.white : MiuixColors.primary,
                            BlendMode.srcIn),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 扁平化输入框
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _inputGlowAnim,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: MiuixRadius.pillRadius,
                            boxShadow: _inputGlowAnim.value > 0
                                ? [
                                    BoxShadow(
                                      color: MiuixColors.primary.withOpacity(0.15 * _inputGlowAnim.value),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? MiuixColors.darkSurfaceVariant
                                  : MiuixColors.surface,
                              borderRadius: MiuixRadius.pillRadius,
                              border: Border.all(
                                color: _inputFocus.hasFocus
                                    ? MiuixColors.primary
                                    : MiuixColors.border,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _inputController,
                              focusNode: _inputFocus,
                              maxLines: 5,
                              minLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              style: TextStyle(
                                color: isDark
                                    ? MiuixColors.darkTextPrimary
                                    : MiuixColors.textPrimary,
                                fontSize: MiuixFontSize.md,
                              ),
                              decoration: InputDecoration(
                                hintText: '输入消息...',
                                hintStyle: TextStyle(
                                    color: MiuixColors.textTertiary),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 发送/停止按钮
                  GestureDetector(
                    onTap: _isGenerating
                        ? _stopGeneration
                        : _sendMessage,
                    child: AnimatedContainer(
                      duration: MiuixDuration.fast,
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        gradient: _isGenerating
                            ? null
                            : const LinearGradient(
                                colors: MiuixColors.primaryGradient),
                        color:
                            _isGenerating ? MiuixColors.error : null,
                        shape: BoxShape.circle,
                        boxShadow:
                            _isGenerating ? null : MiuixShadows.sm,
                      ),
                      child: SvgPicture.asset(
                        _isGenerating ? AppIcons.stop : AppIcons.send,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn),
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

  Widget _buildCapsuleButton({
    required String iconPath,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return MiuixRipple(
      borderRadius: MiuixRadius.pill,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: MiuixDuration.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(colors: MiuixColors.primaryGradient)
                : null,
            color: isActive ? null : Colors.white,
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : MiuixColors.primary.withOpacity(0.4),
              width: 1,
            ),
            borderRadius: MiuixRadius.pillRadius,
            boxShadow: isActive ? MiuixShadows.sm : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                  isActive ? Colors.white : MiuixColors.primary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : MiuixColors.primary,
                  fontSize: MiuixFontSize.sm,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceWaveform() {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(24, (i) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 100 + (i % 5) * 50),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3,
            height: 8 + (i * 7 % 20).toDouble(),
            decoration: BoxDecoration(
              color: MiuixColors.error.withOpacity(0.6 + (i % 3) * 0.13),
              borderRadius: MiuixRadius.pillRadius,
            ),
          );
        }),
      ),
    );
  }
}
