class MailItem {
  final String id;
  final String sender;
  final String title;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  MailItem({
    required this.id,
    required this.sender,
    required this.title,
    this.content = '',
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MailItem.fromJson(Map<String, dynamic> json) {
    return MailItem(
      id: json['id'] ?? '',
      sender: json['sender'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      isRead: (json['is_read'] ?? 0) == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Agent {
  final String id;
  final String name;
  final String description;
  final String? systemPrompt;
  final String? openingMessage;
  final String? avatar;
  final int likes;
  final String userId;

  Agent({
    required this.id,
    required this.name,
    required this.description,
    this.systemPrompt,
    this.openingMessage,
    this.avatar,
    this.likes = 0,
    required this.userId,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      systemPrompt: json['system_prompt'],
      openingMessage: json['opening_message'],
      avatar: json['avatar'],
      likes: json['likes'] ?? 0,
      userId: json['user_id'] ?? '',
    );
  }
}

class Post {
  final String id;
  final String title;
  final String content;
  final int likes;
  final int commentsCount;
  final String userId;
  final String? nickname;
  final String? avatar;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.title,
    required this.content,
    this.likes = 0,
    this.commentsCount = 0,
    required this.userId,
    this.nickname,
    this.avatar,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      likes: json['likes'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      userId: json['user_id'] ?? '',
      nickname: json['nickname'],
      avatar: json['avatar'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ModelInfo {
  final String id;
  final String name;
  final String type; // text, vision, image, video
  final String description;

  ModelInfo({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] ?? json['model'] ?? '',
      name: json['name'] ?? json['id'] ?? '',
      type: json['type'] ?? 'text',
      description: json['description'] ?? '',
    );
  }
}
