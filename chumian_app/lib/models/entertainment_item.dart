/// ============================================================================
/// EntertainmentItem —— 娱乐内容数据模型
///
/// 承载笑话、运势、星座等娱乐内容的完整信息，包括类型、标题、
/// 正文、分类、收藏状态以及创建时间。支持本地缓存与收藏管理。
/// ============================================================================

/// 娱乐内容类型枚举
enum EntertainmentType {
  /// 笑话
  joke,

  /// 每日运势
  fortune,

  /// 星座
  zodiac,

  /// 脑筋急转弯
  riddle,

  /// 毒鸡汤
  poisonSoup,

  /// 土味情话
  loveQuote,

  /// 其他
  other,
}

/// EntertainmentType 枚举的字符串扩展
extension EntertainmentTypeExtension on EntertainmentType {
  /// 转为存储用字符串
  String get value {
    switch (this) {
      case EntertainmentType.joke:
        return 'joke';
      case EntertainmentType.fortune:
        return 'fortune';
      case EntertainmentType.zodiac:
        return 'zodiac';
      case EntertainmentType.riddle:
        return 'riddle';
      case EntertainmentType.poisonSoup:
        return 'poison_soup';
      case EntertainmentType.loveQuote:
        return 'love_quote';
      case EntertainmentType.other:
        return 'other';
    }
  }

  /// 内容显示名称
  String get label {
    switch (this) {
      case EntertainmentType.joke:
        return '笑话';
      case EntertainmentType.fortune:
        return '每日运势';
      case EntertainmentType.zodiac:
        return '星座';
      case EntertainmentType.riddle:
        return '脑筋急转弯';
      case EntertainmentType.poisonSoup:
        return '毒鸡汤';
      case EntertainmentType.loveQuote:
        return '土味情话';
      case EntertainmentType.other:
        return '其他';
    }
  }

  static EntertainmentType fromString(String? type) {
    switch (type) {
      case 'joke':
        return EntertainmentType.joke;
      case 'fortune':
        return EntertainmentType.fortune;
      case 'zodiac':
        return EntertainmentType.zodiac;
      case 'riddle':
        return EntertainmentType.riddle;
      case 'poison_soup':
        return EntertainmentType.poisonSoup;
      case 'love_quote':
        return EntertainmentType.loveQuote;
      default:
        return EntertainmentType.other;
    }
  }
}

/// 娱乐内容数据模型
class EntertainmentItem {
  /// 内容唯一标识
  final String id;

  /// 内容类型
  final EntertainmentType type;

  /// 标题
  final String title;

  /// 正文内容
  final String content;

  /// 分类标签（如：冷笑话、爆笑、星座名等）
  final String category;

  /// 是否已收藏
  bool isFavorite;

  /// 创建时间
  final DateTime createdAt;

  /// 附加元数据（如运势指数、星座日期等）
  final Map<String, dynamic> metadata;

  EntertainmentItem({
    required this.id,
    required this.type,
    this.title = '',
    required this.content,
    this.category = '',
    this.isFavorite = false,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  })  : createdAt = createdAt ?? DateTime.now(),
        metadata = metadata ?? {};

  /// 从 JSON 反序列化
  factory EntertainmentItem.fromJson(Map<String, dynamic> json) {
    return EntertainmentItem(
      id: json['id']?.toString() ?? '',
      type: EntertainmentTypeExtension.fromString(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      isFavorite: json['is_favorite'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'content': content,
      'category': category,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// 创建一条新的娱乐内容
  factory EntertainmentItem.create({
    required EntertainmentType type,
    String title = '',
    required String content,
    String category = '',
    Map<String, dynamic>? metadata,
  }) {
    return EntertainmentItem(
      id: 'ent_${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      title: title,
      content: content,
      category: category,
      metadata: metadata,
    );
  }

  /// 内容预览（取正文前若干字符）
  String get preview {
    final text = content.trim();
    if (text.isEmpty) return '暂无内容';
    if (text.length <= 60) return text;
    return '${text.substring(0, 60)}...';
  }

  /// 搜索匹配：标题、正文或分类包含关键词
  bool matches(String keyword) {
    if (keyword.isEmpty) return true;
    final lower = keyword.toLowerCase();
    return title.toLowerCase().contains(lower) ||
        content.toLowerCase().contains(lower) ||
        category.toLowerCase().contains(lower);
  }

  /// 分享文本
  String get shareText {
    final buffer = StringBuffer();
    if (title.isNotEmpty) buffer.writeln('【$title】');
    buffer.write(content);
    return buffer.toString();
  }

  /// 复制一份娱乐内容
  EntertainmentItem copyWith({
    String? id,
    EntertainmentType? type,
    String? title,
    String? content,
    String? category,
    bool? isFavorite,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return EntertainmentItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
