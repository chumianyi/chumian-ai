/// ============================================================================
/// ImageTask —— AI 绘画任务数据模型
///
/// 承载一次 AI 图像生成请求的完整状态，包括提示词、风格、
/// 尺寸、生成进度、结果 URL 以及失败信息。支持多种预设风格
/// 与尺寸，适配不同的展示场景。
/// ============================================================================

/// 图像生成风格枚举
enum ImageStyle {
  /// 写实
  realistic,

  /// 动漫
  anime,

  /// 油画
  oilPainting,

  /// 水彩
  watercolor,

  /// 赛博朋克
  cyberpunk,

  /// 像素风
  pixel,

  /// 3D 渲染
  render3d,

  /// 插画
  illustration,

  /// 素描
  sketch,

  /// 国风
  chineseStyle,

  /// 自定义
  custom,
}

/// ImageStyle 枚举的字符串扩展
extension ImageStyleExtension on ImageStyle {
  String get value {
    switch (this) {
      case ImageStyle.realistic:
        return 'realistic';
      case ImageStyle.anime:
        return 'anime';
      case ImageStyle.oilPainting:
        return 'oil_painting';
      case ImageStyle.watercolor:
        return 'watercolor';
      case ImageStyle.cyberpunk:
        return 'cyberpunk';
      case ImageStyle.pixel:
        return 'pixel';
      case ImageStyle.render3d:
        return '3d_render';
      case ImageStyle.illustration:
        return 'illustration';
      case ImageStyle.sketch:
        return 'sketch';
      case ImageStyle.chineseStyle:
        return 'chinese_style';
      case ImageStyle.custom:
        return 'custom';
    }
  }

  /// 中文显示名称
  String get label {
    switch (this) {
      case ImageStyle.realistic:
        return '写实';
      case ImageStyle.anime:
        return '动漫';
      case ImageStyle.oilPainting:
        return '油画';
      case ImageStyle.watercolor:
        return '水彩';
      case ImageStyle.cyberpunk:
        return '赛博朋克';
      case ImageStyle.pixel:
        return '像素风';
      case ImageStyle.render3d:
        return '3D 渲染';
      case ImageStyle.illustration:
        return '插画';
      case ImageStyle.sketch:
        return '素描';
      case ImageStyle.chineseStyle:
        return '国风';
      case ImageStyle.custom:
        return '自定义';
    }
  }

  static ImageStyle fromString(String? style) {
    switch (style) {
      case 'realistic':
        return ImageStyle.realistic;
      case 'anime':
        return ImageStyle.anime;
      case 'oil_painting':
        return ImageStyle.oilPainting;
      case 'watercolor':
        return ImageStyle.watercolor;
      case 'cyberpunk':
        return ImageStyle.cyberpunk;
      case 'pixel':
        return ImageStyle.pixel;
      case '3d_render':
        return ImageStyle.render3d;
      case 'illustration':
        return ImageStyle.illustration;
      case 'sketch':
        return ImageStyle.sketch;
      case 'chinese_style':
        return ImageStyle.chineseStyle;
      case 'custom':
        return ImageStyle.custom;
      default:
        return ImageStyle.custom;
    }
  }
}

/// 图像尺寸预设
enum ImageSize {
  /// 方形 1:1，1024x1024
  square,

  /// 竖版 3:4，768x1024
  portrait,

  /// 横版 4:3，1024x768
  landscape,

  /// 宽屏 16:9，1024x576
  wide,

  /// 手机壁纸 9:16，576x1024
  wallpaper,
}

/// ImageSize 枚举的字符串扩展
extension ImageSizeExtension on ImageSize {
  String get value {
    switch (this) {
      case ImageSize.square:
        return '1024x1024';
      case ImageSize.portrait:
        return '768x1024';
      case ImageSize.landscape:
        return '1024x768';
      case ImageSize.wide:
        return '1024x576';
      case ImageSize.wallpaper:
        return '576x1024';
    }
  }

  /// 中文显示名称
  String get label {
    switch (this) {
      case ImageSize.square:
        return '方形 1:1';
      case ImageSize.portrait:
        return '竖版 3:4';
      case ImageSize.landscape:
        return '横版 4:3';
      case ImageSize.wide:
        return '宽屏 16:9';
      case ImageSize.wallpaper:
        return '壁纸 9:16';
    }
  }

  /// 宽度像素
  int get width {
    switch (this) {
      case ImageSize.square:
        return 1024;
      case ImageSize.portrait:
        return 768;
      case ImageSize.landscape:
        return 1024;
      case ImageSize.wide:
        return 1024;
      case ImageSize.wallpaper:
        return 576;
    }
  }

  /// 高度像素
  int get height {
    switch (this) {
      case ImageSize.square:
        return 1024;
      case ImageSize.portrait:
        return 1024;
      case ImageSize.landscape:
        return 768;
      case ImageSize.wide:
        return 576;
      case ImageSize.wallpaper:
        return 1024;
    }
  }

  /// 宽高比
  double get aspectRatio => width / height;

  static ImageSize fromString(String? size) {
    switch (size) {
      case '1024x1024':
        return ImageSize.square;
      case '768x1024':
        return ImageSize.portrait;
      case '1024x768':
        return ImageSize.landscape;
      case '1024x576':
        return ImageSize.wide;
      case '576x1024':
        return ImageSize.wallpaper;
      default:
        return ImageSize.square;
    }
  }
}

/// 图像任务状态枚举
enum ImageTaskStatus {
  /// 排队中
  queued,

  /// 生成中
  generating,

  /// 已完成
  completed,

  /// 失败
  failed,

  /// 已取消
  cancelled,
}

/// ImageTaskStatus 枚举的字符串扩展
extension ImageTaskStatusExtension on ImageTaskStatus {
  String get value {
    switch (this) {
      case ImageTaskStatus.queued:
        return 'queued';
      case ImageTaskStatus.generating:
        return 'generating';
      case ImageTaskStatus.completed:
        return 'completed';
      case ImageTaskStatus.failed:
        return 'failed';
      case ImageTaskStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case ImageTaskStatus.queued:
        return '排队中';
      case ImageTaskStatus.generating:
        return '生成中';
      case ImageTaskStatus.completed:
        return '已完成';
      case ImageTaskStatus.failed:
        return '失败';
      case ImageTaskStatus.cancelled:
        return '已取消';
    }
  }

  static ImageTaskStatus fromString(String? status) {
    switch (status) {
      case 'queued':
        return ImageTaskStatus.queued;
      case 'generating':
        return ImageTaskStatus.generating;
      case 'completed':
        return ImageTaskStatus.completed;
      case 'failed':
        return ImageTaskStatus.failed;
      case 'cancelled':
        return ImageTaskStatus.cancelled;
      default:
        return ImageTaskStatus.queued;
    }
  }
}

/// AI 绘画任务数据模型
class ImageTask {
  /// 任务唯一标识
  final String id;

  /// 正向提示词
  final String prompt;

  /// 负向提示词（可选）
  final String negativePrompt;

  /// 图像风格
  final ImageStyle style;

  /// 图像尺寸
  final ImageSize size;

  /// 任务状态
  ImageTaskStatus status;

  /// 生成结果图片 URL（完成后填充）
  String? resultUrl;

  /// 任务创建时间
  final DateTime createdAt;

  /// 生成进度百分比（0-100）
  double progress;

  /// 错误信息
  String? errorMessage;

  /// 服务端任务 ID（用于轮询）
  final String? serverTaskId;

  /// 种子值（用于复现）
  final int? seed;

  /// 任务完成时间
  DateTime? completedAt;

  ImageTask({
    required this.id,
    required this.prompt,
    this.negativePrompt = '',
    this.style = ImageStyle.realistic,
    this.size = ImageSize.square,
    this.status = ImageTaskStatus.queued,
    this.resultUrl,
    DateTime? createdAt,
    this.progress = 0.0,
    this.errorMessage,
    this.serverTaskId,
    this.seed,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory ImageTask.fromJson(Map<String, dynamic> json) {
    return ImageTask(
      id: json['id']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      negativePrompt: json['negative_prompt']?.toString() ?? '',
      style: ImageStyleExtension.fromString(json['style']?.toString()),
      size: ImageSizeExtension.fromString(json['size']?.toString()),
      status: ImageTaskStatusExtension.fromString(json['status']?.toString()),
      resultUrl: json['result_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      errorMessage: json['error_message']?.toString(),
      serverTaskId: json['server_task_id']?.toString(),
      seed: (json['seed'] as num?)?.toInt(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'negative_prompt': negativePrompt,
      'style': style.value,
      'size': size.value,
      'status': status.value,
      'result_url': resultUrl,
      'created_at': createdAt.toIso8601String(),
      'progress': progress,
      'error_message': errorMessage,
      'server_task_id': serverTaskId,
      'seed': seed,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// 创建一个新的绘画任务
  factory ImageTask.create({
    required String prompt,
    String negativePrompt = '',
    ImageStyle style = ImageStyle.realistic,
    ImageSize size = ImageSize.square,
    int? seed,
  }) {
    return ImageTask(
      id: 'img_${DateTime.now().millisecondsSinceEpoch}_'
          '${prompt.length.hashCode.toRadixString(16)}',
      prompt: prompt,
      negativePrompt: negativePrompt,
      style: style,
      size: size,
      seed: seed,
      status: ImageTaskStatus.queued,
    );
  }

  /// 是否处于终态
  bool get isFinished =>
      status == ImageTaskStatus.completed ||
      status == ImageTaskStatus.failed ||
      status == ImageTaskStatus.cancelled;

  /// 是否正在生成
  bool get isGenerating =>
      status == ImageTaskStatus.generating ||
      status == ImageTaskStatus.queued;

  /// 是否有可用结果
  bool get hasResult => resultUrl != null && resultUrl!.isNotEmpty;

  /// 复制一份任务
  ImageTask copyWith({
    String? id,
    String? prompt,
    String? negativePrompt,
    ImageStyle? style,
    ImageSize? size,
    ImageTaskStatus? status,
    String? resultUrl,
    DateTime? createdAt,
    double? progress,
    String? errorMessage,
    String? serverTaskId,
    int? seed,
    DateTime? completedAt,
  }) {
    return ImageTask(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      style: style ?? this.style,
      size: size ?? this.size,
      status: status ?? this.status,
      resultUrl: resultUrl ?? this.resultUrl,
      createdAt: createdAt ?? this.createdAt,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      serverTaskId: serverTaskId ?? this.serverTaskId,
      seed: seed ?? this.seed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
