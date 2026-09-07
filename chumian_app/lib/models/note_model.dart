/// ============================================================================
/// Note —— 便签数据模型
///
/// 承载单条便签的完整信息，包括标题、正文、颜色标记、
/// 置顶状态以及创建/更新时间。支持本地持久化与搜索。
/// ============================================================================

/// 便签预设颜色枚举
enum NoteColor {
  /// 默认白色
  white,

  /// 粉色
  pink,

  /// 黄色
  yellow,

  /// 绿色
  green,

  /// 蓝色
  blue,

  /// 紫色
  purple,

  /// 橙色
  orange,
}

/// NoteColor 枚举的字符串扩展
extension NoteColorExtension on NoteColor {
  /// 转为存储用字符串
  String get value {
    switch (this) {
      case NoteColor.white:
        return 'white';
      case NoteColor.pink:
        return 'pink';
      case NoteColor.yellow:
        return 'yellow';
      case NoteColor.green:
        return 'green';
      case NoteColor.blue:
        return 'blue';
      case NoteColor.purple:
        return 'purple';
      case NoteColor.orange:
        return 'orange';
    }
  }

  /// 颜色的十六进制值（浅色背景）
  String get hex {
    switch (this) {
      case NoteColor.white:
        return '#FFFFFF';
      case NoteColor.pink:
        return '#FFE4EC';
      case NoteColor.yellow:
        return '#FFF8E1';
      case NoteColor.green:
        return '#E8F5E9';
      case NoteColor.blue:
        return '#E3F2FD';
      case NoteColor.purple:
        return '#F3E5F5';
      case NoteColor.orange:
        return '#FFF3E0';
    }
  }

  static NoteColor fromString(String? color) {
    switch (color) {
      case 'white':
        return NoteColor.white;
      case 'pink':
        return NoteColor.pink;
      case 'yellow':
        return NoteColor.yellow;
      case 'green':
        return NoteColor.green;
      case 'blue':
        return NoteColor.blue;
      case 'purple':
        return NoteColor.purple;
      case 'orange':
        return NoteColor.orange;
      default:
        return NoteColor.white;
    }
  }
}

/// 便签数据模型
class Note {
  /// 便签唯一标识
  final String id;

  /// 便签标题
  String title;

  /// 便签正文内容
  String content;

  /// 便签颜色标记
  NoteColor color;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  DateTime updatedAt;

  /// 是否置顶
  bool isPinned;

  Note({
    required this.id,
    this.title = '',
    this.content = '',
    this.color = NoteColor.white,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      color: NoteColorExtension.fromString(json['color']?.toString()),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isPinned: json['is_pinned'] == true,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_pinned': isPinned,
    };
  }

  /// 创建一条新便签
  factory Note.create({
    String title = '',
    String content = '',
    NoteColor color = NoteColor.white,
  }) {
    return Note(
      id: 'note_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      content: content,
      color: color,
    );
  }

  /// 便签预览文本（取正文前若干字符）
  String get preview {
    final text = content.trim();
    if (text.isEmpty) return '暂无内容';
    if (text.length <= 50) return text;
    return '${text.substring(0, 50)}...';
  }

  /// 是否为空便签（标题和正文都为空）
  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;

  /// 字数统计
  int get wordCount {
    final text = '$title $content'.trim();
    if (text.isEmpty) return 0;
    final chineseChars =
        RegExp(r'[\u4e00-\u9fa5]').allMatches(text).length;
    final englishWords = RegExp(r'[a-zA-Z0-9]+').allMatches(text).length;
    return chineseChars + englishWords;
  }

  /// 搜索匹配：标题或正文包含关键词
  bool matches(String keyword) {
    if (keyword.isEmpty) return true;
    final lower = keyword.toLowerCase();
    return title.toLowerCase().contains(lower) ||
        content.toLowerCase().contains(lower);
  }

  /// 复制一份便签
  Note copyWith({
    String? id,
    String? title,
    String? content,
    NoteColor? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
