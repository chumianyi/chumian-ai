/// ============================================================================
/// MediaItem —— 媒体项数据模型
///
/// 承载图片/视频等媒体资源的统一描述，包括类型、URL、
/// 缩略图、时长、文件大小以及创建时间。适用于聊天附件、
/// 动态发布、媒体库等多种场景。
/// ============================================================================

/// 媒体类型枚举
enum MediaType {
  /// 图片
  image,

  /// 视频
  video,

  /// 音频
  audio,

  /// GIF 动图
  gif,

  /// 文件
  file,
}

/// MediaType 枚举的字符串扩展
extension MediaTypeExtension on MediaType {
  String get value {
    switch (this) {
      case MediaType.image:
        return 'image';
      case MediaType.video:
        return 'video';
      case MediaType.audio:
        return 'audio';
      case MediaType.gif:
        return 'gif';
      case MediaType.file:
        return 'file';
    }
  }

  /// 中文显示名称
  String get label {
    switch (this) {
      case MediaType.image:
        return '图片';
      case MediaType.video:
        return '视频';
      case MediaType.audio:
        return '音频';
      case MediaType.gif:
        return '动图';
      case MediaType.file:
        return '文件';
    }
  }

  static MediaType fromString(String? type) {
    switch (type) {
      case 'image':
        return MediaType.image;
      case 'video':
        return MediaType.video;
      case 'audio':
        return MediaType.audio;
      case 'gif':
        return MediaType.gif;
      case 'file':
        return MediaType.file;
      default:
        return MediaType.image;
    }
  }

  /// 从文件扩展名推断类型
  static MediaType fromExtension(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if (['jpg', 'jpeg', 'png', 'webp', 'bmp'].contains(ext)) {
      return MediaType.image;
    }
    if (ext == 'gif') return MediaType.gif;
    if (['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv'].contains(ext)) {
      return MediaType.video;
    }
    if (['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'].contains(ext)) {
      return MediaType.audio;
    }
    return MediaType.file;
  }
}

/// 媒体项数据模型
class MediaItem {
  /// 唯一标识
  final String id;

  /// 媒体类型
  final MediaType type;

  /// 媒体资源 URL
  final String url;

  /// 缩略图 URL（视频/音频时使用）
  final String? thumbnail;

  /// 时长（秒，视频/音频时使用）
  final int? duration;

  /// 文件大小（字节）
  final int size;

  /// 创建时间
  final DateTime createdAt;

  /// 图片宽度（像素，图片/GIF 时使用）
  final int? width;

  /// 图片高度（像素，图片/GIF 时使用）
  final int? height;

  /// 文件名
  final String? fileName;

  /// MIME 类型
  final String? mimeType;

  /// 本地文件路径（如果是本地文件）
  final String? localPath;

  MediaItem({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnail,
    this.duration,
    this.size = 0,
    DateTime? createdAt,
    this.width,
    this.height,
    this.fileName,
    this.mimeType,
    this.localPath,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id']?.toString() ?? '',
      type: MediaTypeExtension.fromString(json['type']?.toString()),
      url: json['url']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
      duration: (json['duration'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      fileName: json['file_name']?.toString(),
      mimeType: json['mime_type']?.toString(),
      localPath: json['local_path']?.toString(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'url': url,
      'thumbnail': thumbnail,
      'duration': duration,
      'size': size,
      'created_at': createdAt.toIso8601String(),
      'width': width,
      'height': height,
      'file_name': fileName,
      'mime_type': mimeType,
      'local_path': localPath,
    };
  }

  /// 创建一个图片媒体项
  factory MediaItem.image({
    required String url,
    String? thumbnail,
    int size = 0,
    int? width,
    int? height,
    String? fileName,
    String? localPath,
  }) {
    return MediaItem(
      id: 'media_${DateTime.now().microsecondsSinceEpoch}',
      type: MediaType.image,
      url: url,
      thumbnail: thumbnail,
      size: size,
      width: width,
      height: height,
      fileName: fileName,
      localPath: localPath,
    );
  }

  /// 创建一个视频媒体项
  factory MediaItem.video({
    required String url,
    required String thumbnail,
    int duration = 0,
    int size = 0,
    String? fileName,
    String? localPath,
  }) {
    return MediaItem(
      id: 'media_${DateTime.now().microsecondsSinceEpoch}',
      type: MediaType.video,
      url: url,
      thumbnail: thumbnail,
      duration: duration,
      size: size,
      fileName: fileName,
      localPath: localPath,
    );
  }

  /// 是否为图片类型
  bool get isImage => type == MediaType.image || type == MediaType.gif;

  /// 是否为视频类型
  bool get isVideo => type == MediaType.video;

  /// 是否为音频类型
  bool get isAudio => type == MediaType.audio;

  /// 时长格式化文本，如 "01:30"
  String get durationText {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// 文件大小格式化文本
  String get sizeText {
    if (size <= 0) return '未知';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 宽高比
  double get aspectRatio {
    if (width == null || height == null || height == 0) return 1.0;
    return width! / height!;
  }

  /// 复制一份
  MediaItem copyWith({
    String? id,
    MediaType? type,
    String? url,
    String? thumbnail,
    int? duration,
    int? size,
    DateTime? createdAt,
    int? width,
    int? height,
    String? fileName,
    String? mimeType,
    String? localPath,
  }) {
    return MediaItem(
      id: id ?? this.id,
      type: type ?? this.type,
      url: url ?? this.url,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      width: width ?? this.width,
      height: height ?? this.height,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      localPath: localPath ?? this.localPath,
    );
  }
}
