/// 应用内通知类型枚举
enum NotificationType {
  system,
  like,
  comment,
  follow,
  points,
  activity,
  announcement,
}

/// 通知类型扩展
extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.system:
        return 'system';
      case NotificationType.like:
        return 'like';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.follow:
        return 'follow';
      case NotificationType.points:
        return 'points';
      case NotificationType.activity:
        return 'activity';
      case NotificationType.announcement:
        return 'announcement';
    }
  }

  static NotificationType fromString(String? type) {
    switch (type) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'points':
        return NotificationType.points;
      case 'activity':
        return NotificationType.activity;
      case 'announcement':
        return NotificationType.announcement;
      default:
        return NotificationType.system;
    }
  }
}

/// 应用内通知数据模型
///
/// 代表推送或应用内消息中心的一条通知，支持多种类型，
/// 可关联到具体的帖子、用户或活动。
class AppNotification {
  /// 通知唯一标识
  final String id;

  /// 通知类型
  final NotificationType type;

  /// 通知标题
  final String title;

  /// 通知内容正文
  final String content;

  /// 是否已读
  final bool isRead;

  /// 通知创建时间
  final DateTime? createdAt;

  /// 关联对象 ID（如帖子 ID、用户 ID、活动 ID）
  final String? relatedId;

  AppNotification({
    required this.id,
    this.type = NotificationType.system,
    this.title = '',
    this.content = '',
    this.isRead = false,
    this.createdAt,
    this.relatedId,
  });

  /// 从 JSON 反序列化
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: NotificationTypeExtension.fromString(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ??
          json['body']?.toString() ??
          '',
      isRead: json['is_read'] == true || json['read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      relatedId: json['related_id']?.toString() ??
          json['relatedId']?.toString(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
      'related_id': relatedId,
    };
  }

  /// 从列表批量解析
  static List<AppNotification> fromList(List<dynamic> list) {
    return list
        .map((e) => AppNotification.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 是否为未读通知
  bool get isUnread => !isRead;

  /// 是否有关联对象（可点击跳转）
  bool get hasRelated => relatedId != null && relatedId!.isNotEmpty;

  /// 复制并修改部分字段
  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    String? relatedId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      relatedId: relatedId ?? this.relatedId,
    );
  }
}
