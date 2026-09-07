/// 社区帖子类型枚举
enum PostType { text, image, video, link }

/// 帖子类型扩展
extension PostTypeExtension on PostType {
  String get value {
    switch (this) {
      case PostType.text:
        return 'text';
      case PostType.image:
        return 'image';
      case PostType.video:
        return 'video';
      case PostType.link:
        return 'link';
    }
  }

  static PostType fromString(String? type) {
    switch (type) {
      case 'image':
        return PostType.image;
      case 'video':
        return PostType.video;
      case 'link':
        return PostType.link;
      default:
        return PostType.text;
    }
  }
}

/// 社区帖子数据模型
///
/// 代表社区中的一条动态/帖子，包含文本内容、多媒体附件、
/// 互动数据以及发布者信息。
class Post {
  /// 帖子唯一标识
  final String id;

  /// 发布者用户 ID
  final String? userId;

  /// 帖子标题
  final String title;

  /// 帖子正文内容
  final String content;

  /// 帖子类型：text / image / video / link
  final PostType type;

  /// 多媒体附件 URL（图片或视频）
  final String? mediaUrl;

  /// 点赞数
  final int likes;

  /// 评论数
  final int commentsCount;

  /// 是否已通过审核
  final bool approved;

  /// 发布时间
  final DateTime? createdAt;

  /// 发布者昵称（冗余字段，避免二次查询）
  final String? userNickname;

  /// 发布者头像 URL（冗余字段）
  final String? userAvatar;

  Post({
    required this.id,
    this.userId,
    this.title = '',
    this.content = '',
    this.type = PostType.text,
    this.mediaUrl,
    this.likes = 0,
    this.commentsCount = 0,
    this.approved = true,
    this.createdAt,
    this.userNickname,
    this.userAvatar,
  });

  /// 从 JSON 反序列化
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: PostTypeExtension.fromString(json['type']?.toString()),
      mediaUrl: json['media_url']?.toString() ??
          json['mediaUrl']?.toString(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ??
          (json['comment_count'] as num?)?.toInt() ??
          0,
      approved: json['approved'] != false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      userNickname: json['user_nickname']?.toString() ??
          json['nickname']?.toString(),
      userAvatar: json['user_avatar']?.toString() ??
          json['avatar']?.toString(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'type': type.value,
      'media_url': mediaUrl,
      'likes': likes,
      'comments_count': commentsCount,
      'approved': approved,
      'created_at': createdAt?.toIso8601String(),
      'user_nickname': userNickname,
      'user_avatar': userAvatar,
    };
  }

  /// 从列表批量解析
  static List<Post> fromList(List<dynamic> list) {
    return list
        .map((e) => Post.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 是否包含多媒体附件
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  /// 是否为图片帖子
  bool get isImagePost => type == PostType.image && hasMedia;

  /// 是否为视频帖子
  bool get isVideoPost => type == PostType.video && hasMedia;

  /// 展示用发布者名称
  String get displayAuthor => userNickname ?? '匿名用户';

  /// 复制并修改部分字段
  Post copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    PostType? type,
    String? mediaUrl,
    int? likes,
    int? commentsCount,
    bool? approved,
    DateTime? createdAt,
    String? userNickname,
    String? userAvatar,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      approved: approved ?? this.approved,
      createdAt: createdAt ?? this.createdAt,
      userNickname: userNickname ?? this.userNickname,
      userAvatar: userAvatar ?? this.userAvatar,
    );
  }
}
