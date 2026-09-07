import 'package:chumian_ai/models/search_result.dart';

/// 聊天消息角色枚举
enum MessageRole { user, assistant, system }

/// 角色枚举的字符串扩展
extension MessageRoleExtension on MessageRole {
  String get value {
    switch (this) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
        return 'system';
    }
  }

  static MessageRole fromString(String? role) {
    switch (role) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        return MessageRole.assistant;
    }
  }
}

/// 聊天消息数据模型
///
/// 承载单条对话消息的完整状态，包括文本内容、思考过程、
/// 多媒体附件、联网搜索结果以及流式生成过程中的中间状态。
class ChatMessage {
  /// 消息唯一标识（客户端生成，用于本地追踪）
  final String id;

  /// 消息角色：user / assistant / system
  final MessageRole role;

  /// 消息正文内容（Markdown 格式）
  String content;

  /// AI 思考过程内容（流式 think 事件累积）
  String thinkContent;

  /// 是否正在思考中（流式 think 阶段标记）
  bool isThinking;

  /// 思考内容是否展开显示
  bool isExpanded;

  /// 使用的模型标识，如 'glm-4-flash'
  final String? model;

  /// 附带图片 URL（用户发送图片或 AI 生成图片）
  final String? imageUrl;

  /// 附带视频 URL（AI 生成视频完成后填充）
  String? videoUrl;

  /// 视频生成任务 ID（用于轮询视频状态）
  final String? videoTaskId;

  /// 视频是否正在加载/生成中
  bool videoLoading;

  /// 联网搜索结果列表（AI 回复中引用的搜索来源）
  List<SearchResult> searchResults;

  /// 消息创建时间
  final DateTime createdAt;

  /// 本条消息消耗的 token 数
  final int? tokensUsed;

  ChatMessage({
    required this.id,
    required this.role,
    this.content = '',
    this.thinkContent = '',
    this.isThinking = false,
    this.isExpanded = false,
    this.model,
    this.imageUrl,
    this.videoUrl,
    this.videoTaskId,
    this.videoLoading = false,
    List<SearchResult>? searchResults,
    DateTime? createdAt,
    this.tokensUsed,
  })  : searchResults = searchResults ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      role: MessageRoleExtension.fromString(json['role']?.toString()),
      content: json['content']?.toString() ?? '',
      thinkContent: json['think_content']?.toString() ?? '',
      isThinking: json['is_thinking'] == true,
      isExpanded: json['is_expanded'] == true,
      model: json['model']?.toString(),
      imageUrl: json['image_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
      videoTaskId: json['video_task_id']?.toString(),
      videoLoading: json['video_loading'] == true,
      searchResults: (json['search_results'] as List<dynamic>?)
              ?.map((e) => SearchResult.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      tokensUsed: (json['tokens_used'] as num?)?.toInt(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.value,
      'content': content,
      'think_content': thinkContent,
      'is_thinking': isThinking,
      'is_expanded': isExpanded,
      'model': model,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'video_task_id': videoTaskId,
      'video_loading': videoLoading,
      'search_results':
          searchResults.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'tokens_used': tokensUsed,
    };
  }

  /// 创建一条用户消息的便捷工厂
  factory ChatMessage.user({
    required String id,
    required String content,
    String? imageUrl,
    String? model,
  }) {
    return ChatMessage(
      id: id,
      role: MessageRole.user,
      content: content,
      imageUrl: imageUrl,
      model: model,
    );
  }

  /// 创建一条 AI 占位消息（流式开始前插入）
  factory ChatMessage.assistantPlaceholder({
    required String id,
    String? model,
  }) {
    return ChatMessage(
      id: id,
      role: MessageRole.assistant,
      content: '',
      isThinking: true,
      model: model,
    );
  }

  /// 创建一条系统消息
  factory ChatMessage.system({
    required String id,
    required String content,
  }) {
    return ChatMessage(
      id: id,
      role: MessageRole.system,
      content: content,
    );
  }

  /// 判断消息是否有实质内容（非空文本或有附件）
  bool get hasContent =>
      content.trim().isNotEmpty ||
      imageUrl != null ||
      videoUrl != null ||
      searchResults.isNotEmpty;

  /// 判断是否为纯文本消息（无附件）
  bool get isTextOnly =>
      imageUrl == null && videoUrl == null && searchResults.isEmpty;

  /// 复制一份消息（用于重新生成等场景）
  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    String? thinkContent,
    bool? isThinking,
    bool? isExpanded,
    String? model,
    String? imageUrl,
    String? videoUrl,
    String? videoTaskId,
    bool? videoLoading,
    List<SearchResult>? searchResults,
    DateTime? createdAt,
    int? tokensUsed,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      thinkContent: thinkContent ?? this.thinkContent,
      isThinking: isThinking ?? this.isThinking,
      isExpanded: isExpanded ?? this.isExpanded,
      model: model ?? this.model,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      videoTaskId: videoTaskId ?? this.videoTaskId,
      videoLoading: videoLoading ?? this.videoLoading,
      searchResults: searchResults ?? this.searchResults,
      createdAt: createdAt ?? this.createdAt,
      tokensUsed: tokensUsed ?? this.tokensUsed,
    );
  }
}
