import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:chumian_ai/models/chat_message.dart';
import 'package:chumian_ai/models/conversation.dart';
import 'package:chumian_ai/models/search_result.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/services/chat_service.dart';
import 'package:chumian_ai/services/web_search_service.dart';
import 'package:chumian_ai/utils/markdown_stripper.dart';

/// ============================================================================
/// ChatProvider —— 聊天状态管理 Provider（ChangeNotifier）
///
/// 职责：
///   1. 管理当前会话的消息列表、会话 ID、选中模型
///   2. 发送消息：添加用户消息 + AI 占位，调用 SSE 流式接口
///   3. 处理 SSE 事件：think / content / image / video_task /
///      search_results / done / error，实现打字机效果
///   4. 联网搜索：用户手动开关胶囊；发送时若开启则先搜索再注入 prompt；
///      AI 回复中若包含搜索引用则展示来源条目
///   5. 消息操作：复制（纯文本去 Markdown）、删除、重新生成
///   6. 会话管理：新建会话、加载历史会话、删除会话、重命名
///   7. 模型列表管理与切换
/// ============================================================================
class ChatProvider extends ChangeNotifier {
  // ===== 核心状态 =====
  final List<ChatMessage> _messages = [];
  String? _currentConvId;
  String _selectedModel = 'glm-4-flash';
  bool _isSending = false;
  bool _isListening = false;

  // ===== 联网搜索状态 =====
  bool _webSearchEnabled = false; // 用户手动开关
  bool _aiDecidedSearch = false; // AI 决定是否搜索（服务端返回）
  bool _isSearching = false; // 正在搜索中

  // ===== 会话列表 =====
  final List<Conversation> _conversations = [];
  bool _conversationsLoaded = false;

  // ===== 模型列表 =====
  final List<Map<String, dynamic>> _availableModels = [];
  bool _modelsLoaded = false;

  // ===== 服务实例 =====
  final ChatService _chatService = ChatService();
  final WebSearchService _webSearchService = WebSearchService();

  // ===== 流式订阅（用于停止生成）=====
  StreamSubscription<Map<String, dynamic>>? _streamSubscription;

  // ===== Getters =====
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get currentConvId => _currentConvId;
  String get selectedModel => _selectedModel;
  bool get isSending => _isSending;
  bool get isListening => _isListening;
  bool get webSearchEnabled => _webSearchEnabled;
  bool get aiDecidedSearch => _aiDecidedSearch;
  bool get isSearching => _isSearching;
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  bool get conversationsLoaded => _conversationsLoaded;
  List<Map<String, dynamic>> get availableModels =>
      List.unmodifiable(_availableModels);
  bool get modelsLoaded => _modelsLoaded;
  bool get hasMessages => _messages.isNotEmpty;
  ChatMessage? get lastMessage =>
      _messages.isNotEmpty ? _messages.last : null;
  ChatMessage? get lastAssistantMessage {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == MessageRole.assistant) return _messages[i];
    }
    return null;
  }

  // ==========================================================================
  // 联网搜索开关
  // ==========================================================================

  /// 切换联网搜索开关（用户手动）
  void toggleWebSearch() {
    _webSearchEnabled = !_webSearchEnabled;
    notifyListeners();
  }

  /// 设置联网搜索开关
  void setWebSearchEnabled(bool enabled) {
    if (_webSearchEnabled == enabled) return;
    _webSearchEnabled = enabled;
    notifyListeners();
  }

  // ==========================================================================
  // 模型管理
  // ==========================================================================

  /// 加载可用模型列表
  Future<void> loadModels() async {
    if (_modelsLoaded) return;
    try {
      final result = await ApiService.getModels();
      final models = result['models'] ?? result['data'] ?? [];
      if (models is List) {
        _availableModels.clear();
        for (final m in models) {
          if (m is Map) {
            _availableModels.add(Map<String, dynamic>.from(m));
          }
        }
      }
      // 如果当前模型不在列表中，使用第一个
      if (_availableModels.isNotEmpty) {
        final modelIds = _availableModels
            .map((e) => e['id']?.toString() ?? e['name']?.toString() ?? '')
            .toList();
        if (!modelIds.contains(_selectedModel)) {
          _selectedModel = modelIds.first;
        }
      }
      _modelsLoaded = true;
      notifyListeners();
    } catch (_) {
      _modelsLoaded = true; // 标记为已加载，避免重复请求
    }
  }

  /// 切换模型
  void setModel(String modelId) {
    if (_selectedModel == modelId) return;
    _selectedModel = modelId;
    notifyListeners();
  }

  // ==========================================================================
  // 发送消息（核心方法）
  // ==========================================================================

  /// 发送一条消息
  ///
  /// 流程：
  ///   1. 创建用户消息并添加到列表
  ///   2. 创建 AI 占位消息（thinking 状态）
  ///   3. 若启用联网搜索，先执行搜索并将结果注入 prompt
  ///   4. 建立 SSE 流式连接，逐事件更新 AI 消息
  ///   5. 处理 done / error 事件，结束流式状态
  Future<void> sendMessage(String text, {String? imageUrl}) async {
    if (_isSending || text.trim().isEmpty) return;

    _isSending = true;
    _aiDecidedSearch = false;
    notifyListeners();

    // 步骤 1：添加用户消息
    final userMsg = ChatMessage.user(
      id: _chatService.generateMessageId(),
      content: text.trim(),
      imageUrl: imageUrl,
      model: _selectedModel,
    );
    _messages.add(userMsg);

    // 步骤 2：添加 AI 占位消息
    final aiMsgId = _chatService.generateMessageId();
    final aiMsg = ChatMessage.assistantPlaceholder(
      id: aiMsgId,
      model: _selectedModel,
    );
    _messages.add(aiMsg);
    notifyListeners();

    // 步骤 3 & 4：建立流式连接并处理事件
    final eventStream = _chatService.sendMessage(
      conversationId: _currentConvId,
      text: text.trim(),
      model: _selectedModel,
      imageUrl: imageUrl,
      webSearchEnabled: _webSearchEnabled,
    );

    _streamSubscription = eventStream.listen(
      (event) => _handleStreamEvent(event, aiMsgId),
      onDone: () {
        _finalizeMessage(aiMsgId);
      },
      onError: (e) {
        _handleStreamError(aiMsgId, e.toString());
      },
      cancelOnError: false,
    );
  }

  /// 处理 SSE 流式事件
  void _handleStreamEvent(Map<String, dynamic> event, String aiMsgId) {
    final type = event['type']?.toString() ?? '';
    final idx = _messages.indexWhere((m) => m.id == aiMsgId);
    if (idx == -1) return;
    final msg = _messages[idx];

    switch (type) {
      case 'searching':
        _isSearching = true;
        _aiDecidedSearch = true;
        notifyListeners();
        break;

      case 'search_results':
        _isSearching = false;
        final results = (event['results'] as List<dynamic>?)
                ?.map((e) => SearchResult.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [];
        msg.searchResults = results;
        notifyListeners();
        break;

      case 'thinking':
        msg.isThinking = true;
        final thinkDelta = event['content']?.toString() ?? '';
        if (thinkDelta.isNotEmpty) {
          msg.thinkContent += thinkDelta;
        }
        notifyListeners();
        break;

      case 'content':
        // 收到正文后，思考阶段结束
        if (msg.isThinking) {
          msg.isThinking = false;
        }
        final contentDelta = event['content']?.toString() ?? '';
        if (contentDelta.isNotEmpty) {
          msg.content += contentDelta;
        }
        notifyListeners();
        break;

      case 'image':
        final imgUrl = event['url']?.toString() ?? '';
        if (imgUrl.isNotEmpty) {
          // 通过 copyWith 更新 imageUrl（保留已累积的 content / thinkContent）
          _messages[idx] = msg.copyWith(imageUrl: imgUrl);
        }
        notifyListeners();
        break;

      case 'video_loading':
        final taskId = event['task_id']?.toString() ?? '';
        if (taskId.isNotEmpty) {
          _messages[idx] = msg.copyWith(
            videoTaskId: taskId,
            videoLoading: true,
          );
          // 启动视频轮询
          _pollVideo(taskId, aiMsgId);
        }
        notifyListeners();
        break;

      case 'done':
        msg.isThinking = false;
        final convId = event['conversation_id']?.toString();
        if (convId != null && convId.isNotEmpty) {
          _currentConvId = convId;
        }
        final tokens = (event['tokens_used'] as num?)?.toInt();
        if (tokens != null) {
          _messages[idx] = msg.copyWith(tokensUsed: tokens);
        }
        notifyListeners();
        break;

      case 'error':
        _handleStreamError(aiMsgId, event['message']?.toString() ?? '生成失败');
        break;
    }
  }

  /// 处理流式错误
  void _handleStreamError(String aiMsgId, String errorMsg) {
    final idx = _messages.indexWhere((m) => m.id == aiMsgId);
    if (idx != -1) {
      final msg = _messages[idx];
      msg.isThinking = false;
      if (msg.content.isEmpty) {
        msg.content = '抱歉，生成过程中出现错误：$errorMsg';
      }
    }
    _isSending = false;
    _isSearching = false;
    notifyListeners();
  }

  /// 完成消息生成（流结束时调用）
  void _finalizeMessage(String aiMsgId) {
    final idx = _messages.indexWhere((m) => m.id == aiMsgId);
    if (idx != -1) {
      _messages[idx].isThinking = false;
    }
    _isSending = false;
    _isSearching = false;
    _streamSubscription = null;
    notifyListeners();
  }

  /// 视频生成状态轮询
  Future<void> _pollVideo(String taskId, String aiMsgId) async {
    const interval = Duration(seconds: 3);
    const maxAttempts = 60;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(interval);
      try {
        final status = await ApiService.getVideoStatus(taskId);
        final state = status['status']?.toString() ??
            status['state']?.toString() ??
            '';
        if (state == 'success' || state == 'completed') {
          final videoUrl = status['video_url']?.toString() ??
              status['url']?.toString();
          final idx = _messages.indexWhere((m) => m.id == aiMsgId);
          if (idx != -1 && videoUrl != null) {
            _messages[idx] = _messages[idx].copyWith(
              videoUrl: videoUrl,
              videoLoading: false,
            );
            notifyListeners();
          }
          return;
        }
        if (state == 'failed' || state == 'error') {
          final idx = _messages.indexWhere((m) => m.id == aiMsgId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(videoLoading: false);
            notifyListeners();
          }
          return;
        }
      } catch (_) {
        // 继续轮询
      }
    }
    // 超时
    final idx = _messages.indexWhere((m) => m.id == aiMsgId);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(videoLoading: false);
      notifyListeners();
    }
  }

  // ==========================================================================
  // 停止生成
  // ==========================================================================

  /// 停止当前正在进行的流式生成
  void stopGeneration() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _isSending = false;
    _isSearching = false;
    // 将所有 thinking 状态的消息标记为完成
    for (final msg in _messages) {
      if (msg.isThinking) {
        msg.isThinking = false;
      }
    }
    notifyListeners();
  }

  // ==========================================================================
  // 会话管理
  // ==========================================================================

  /// 新建会话（清空当前消息和会话 ID）
  void newConversation() {
    stopGeneration();
    _messages.clear();
    _currentConvId = null;
    _aiDecidedSearch = false;
    notifyListeners();
  }

  /// 加载指定会话的历史消息
  Future<void> loadConversation(String convId) async {
    stopGeneration();
    _currentConvId = convId;
    _messages.clear();
    notifyListeners();

    try {
      final rawMessages = await ApiService.getConversationMessages(convId);
      final parsed = _chatService.parseHistoryMessages(rawMessages);
      // 按时间排序
      parsed.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _messages.addAll(parsed);
    } catch (_) {}
    notifyListeners();
  }

  /// 加载会话列表
  Future<void> loadConversations() async {
    try {
      final raw = await ApiService.getConversations();
      _conversations.clear();
      for (final item in raw) {
        _conversations.add(
            Conversation.fromJson(Map<String, dynamic>.from(item as Map)));
      }
      // 按创建时间倒序
      _conversations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {}
    _conversationsLoaded = true;
    notifyListeners();
  }

  /// 删除会话
  Future<void> deleteConversation(String convId) async {
    try {
      await ApiService.deleteConversation(convId);
    } catch (_) {}
    _conversations.removeWhere((c) => c.id == convId);
    if (_currentConvId == convId) {
      newConversation();
    }
    notifyListeners();
  }

  /// 重命名会话
  Future<void> renameConversation(String convId, String title) async {
    try {
      await ApiService.renameConversation(convId, title);
      final idx = _conversations.indexWhere((c) => c.id == convId);
      if (idx != -1) {
        _conversations[idx] = _conversations[idx].copyWith(title: title);
      }
      notifyListeners();
    } catch (_) {}
  }

  // ==========================================================================
  // 消息操作
  // ==========================================================================

  /// 复制消息内容为纯文本（剥离 Markdown 符号）
  String copyMessage(String messageId) {
    final msg = _messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => ChatMessage(
          id: '', role: MessageRole.assistant, content: ''),
    );
    if (msg.id.isEmpty) return '';
    return MarkdownStripper.strip(msg.content);
  }

  /// 删除指定消息
  void deleteMessage(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }

  /// 重新生成最后一条 AI 回复
  ///
  /// 找到最后一条用户消息，删除其后的所有 AI 消息，然后重新发送
  Future<void> regenerate() async {
    if (_isSending) return;
    // 找到最后一条用户消息的索引
    int lastUserIdx = -1;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == MessageRole.user) {
        lastUserIdx = i;
        break;
      }
    }
    if (lastUserIdx == -1) return;

    final userMsg = _messages[lastUserIdx];
    // 删除该用户消息之后的所有消息（包括 AI 回复）
    _messages.removeRange(lastUserIdx + 1, _messages.length);
    // 重新发送
    await sendMessage(userMsg.content, imageUrl: userMsg.imageUrl);
  }

  /// 切换消息的思考内容展开/收起
  void toggleMessageExpanded(String messageId) {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      _messages[idx].isExpanded = !_messages[idx].isExpanded;
      notifyListeners();
    }
  }

  // ==========================================================================
  // 语音输入状态
  // ==========================================================================

  void setListening(bool listening) {
    if (_isListening == listening) return;
    _isListening = listening;
    notifyListeners();
  }

  // ==========================================================================
  // 清理
  // ==========================================================================

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    super.dispose();
  }
}
