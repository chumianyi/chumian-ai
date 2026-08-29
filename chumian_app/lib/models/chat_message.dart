/// 聊天消息模型。
library;

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
  List<dynamic>? searchResults;
  String? searchKeyword;

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
    this.searchResults,
    this.searchKeyword,
  });

  bool get isUser => role == 'user';
  bool get isAi => role == 'assistant' || role == 'ai';
}
