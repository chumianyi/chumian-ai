/// AI Agent（智能体）数据模型
///
/// 代表一个可被用户克隆、使用、发布的自定义 AI 角色，
/// 包含系统提示词、开场白、头像等角色设定信息。
class Agent {
  /// Agent 唯一标识
  final String id;

  /// 创建者用户 ID
  final String? userId;

  /// Agent 名称
  final String name;

  /// Agent 简介描述
  final String description;

  /// 系统提示词（定义 Agent 行为与人格）
  final String systemPrompt;

  /// 开场白（进入对话时的首条消息）
  final String openingMessage;

  /// 头像 URL
  final String? avatar;

  /// 点赞数
  final int likes;

  /// 是否已公开发布
  final bool isPublished;

  /// 创建时间
  final DateTime? createdAt;

  Agent({
    required this.id,
    this.userId,
    this.name = '',
    this.description = '',
    this.systemPrompt = '',
    this.openingMessage = '',
    this.avatar,
    this.likes = 0,
    this.isPublished = false,
    this.createdAt,
  });

  /// 从 JSON 反序列化
  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      systemPrompt: json['system_prompt']?.toString() ??
          json['systemPrompt']?.toString() ??
          '',
      openingMessage: json['opening_message']?.toString() ??
          json['openingMessage']?.toString() ??
          '',
      avatar: json['avatar']?.toString(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      isPublished: json['is_published'] == true ||
          json['published'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'system_prompt': systemPrompt,
      'opening_message': openingMessage,
      'avatar': avatar,
      'likes': likes,
      'is_published': isPublished,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// 从列表批量解析
  static List<Agent> fromList(List<dynamic> list) {
    return list
        .map((e) => Agent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 是否有头像
  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;

  /// 是否有开场白
  bool get hasOpeningMessage => openingMessage.isNotEmpty;

  /// 复制并修改部分字段
  Agent copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? systemPrompt,
    String? openingMessage,
    String? avatar,
    int? likes,
    bool? isPublished,
    DateTime? createdAt,
  }) {
    return Agent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      openingMessage: openingMessage ?? this.openingMessage,
      avatar: avatar ?? this.avatar,
      likes: likes ?? this.likes,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
