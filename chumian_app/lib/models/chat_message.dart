class ChatMessage {
  final String id;
  final String role; // user, assistant
  final String content;
  final String? thinkContent;
  final String? model;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime createdAt;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.thinkContent,
    this.model,
    this.imageUrl,
    this.videoUrl,
    DateTime? createdAt,
    this.isStreaming = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      role: json['role'] ?? 'assistant',
      content: json['content'] ?? '',
      thinkContent: json['think_content'],
      model: json['model'],
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Conversation {
  final String id;
  final String title;
  final String? model;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.title,
    this.model,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      title: json['title'] ?? '新对话',
      model: json['model'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
