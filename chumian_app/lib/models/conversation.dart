/// 会话（对话）数据模型
///
/// 代表一次完整的对话会话，包含元信息和最后一条消息摘要，
/// 用于会话列表展示和会话管理。
class Conversation {
  /// 会话唯一标识
  final String id;

  /// 所属用户 ID
  final String? userId;

  /// 会话标题（通常由首条消息自动生成或用户重命名）
  final String title;

  /// 该会话使用的模型标识
  final String? model;

  /// 会话创建时间
  final DateTime createdAt;

  /// 消息总数
  final int messageCount;

  /// 最后一条消息的摘要文本（用于列表预览）
  final String? lastMessage;

  Conversation({
    required this.id,
    this.userId,
    this.title = '新对话',
    this.model,
    DateTime? createdAt,
    this.messageCount = 0,
    this.lastMessage,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      title: json['title']?.toString() ?? '新对话',
      model: json['model']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
      lastMessage: json['last_message']?.toString(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'model': model,
      'created_at': createdAt.toIso8601String(),
      'message_count': messageCount,
      'last_message': lastMessage,
    };
  }

  /// 从服务端列表响应批量解析
  static List<Conversation> fromList(List<dynamic> list) {
    return list
        .map((e) =>
            Conversation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 创建一个新的本地会话（尚未同步到服务端）
  factory Conversation.local({
    required String id,
    String? userId,
    String? model,
  }) {
    return Conversation(
      id: id,
      userId: userId,
      title: '新对话',
      model: model,
      messageCount: 0,
    );
  }

  /// 会话标题是否为默认标题（未重命名）
  bool get isDefaultTitle => title == '新对话' || title.isEmpty;

  /// 复制并修改部分字段
  Conversation copyWith({
    String? id,
    String? userId,
    String? title,
    String? model,
    DateTime? createdAt,
    int? messageCount,
    String? lastMessage,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
      messageCount: messageCount ?? this.messageCount,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
