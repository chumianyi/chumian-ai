/// ============================================================================
/// WritingTask —— AI 写作任务数据模型
///
/// 承载一次 AI 写作请求的完整生命周期：从任务创建、参数配置、
/// 生成中状态，到最终结果与错误信息。支持多种写作类型
/// （续写 / 润色 / 翻译 / 摘要 / 扩写 / 诗歌 / 邮件等）。
/// ============================================================================

/// 写作任务类型枚举
enum WritingType {
  /// 续写
  continuation,

  /// 润色
  polish,

  /// 翻译
  translate,

  /// 摘要
  summary,

  /// 扩写
  expand,

  /// 诗歌
  poem,

  /// 邮件
  email,

  /// 文章
  article,

  /// 文案
  copywriting,

  /// 自定义
  custom,
}

/// WritingType 枚举的字符串扩展
extension WritingTypeExtension on WritingType {
  /// 转为服务端可识别的字符串值
  String get value {
    switch (this) {
      case WritingType.continuation:
        return 'continuation';
      case WritingType.polish:
        return 'polish';
      case WritingType.translate:
        return 'translate';
      case WritingType.summary:
        return 'summary';
      case WritingType.expand:
        return 'expand';
      case WritingType.poem:
        return 'poem';
      case WritingType.email:
        return 'email';
      case WritingType.article:
        return 'article';
      case WritingType.copywriting:
        return 'copywriting';
      case WritingType.custom:
        return 'custom';
    }
  }

  /// 中文显示名称
  String get label {
    switch (this) {
      case WritingType.continuation:
        return '续写';
      case WritingType.polish:
        return '润色';
      case WritingType.translate:
        return '翻译';
      case WritingType.summary:
        return '摘要';
      case WritingType.expand:
        return '扩写';
      case WritingType.poem:
        return '诗歌';
      case WritingType.email:
        return '邮件';
      case WritingType.article:
        return '文章';
      case WritingType.copywriting:
        return '文案';
      case WritingType.custom:
        return '自定义';
    }
  }

  /// 从字符串反序列化
  static WritingType fromString(String? type) {
    switch (type) {
      case 'continuation':
        return WritingType.continuation;
      case 'polish':
        return WritingType.polish;
      case 'translate':
        return WritingType.translate;
      case 'summary':
        return WritingType.summary;
      case 'expand':
        return WritingType.expand;
      case 'poem':
        return WritingType.poem;
      case 'email':
        return WritingType.email;
      case 'article':
        return WritingType.article;
      case 'copywriting':
        return WritingType.copywriting;
      case 'custom':
        return WritingType.custom;
      default:
        return WritingType.custom;
    }
  }
}

/// 写作任务状态枚举
enum WritingStatus {
  /// 等待中（已创建，尚未开始）
  pending,

  /// 生成中
  generating,

  /// 已完成
  completed,

  /// 失败
  failed,

  /// 已取消
  cancelled,
}

/// WritingStatus 枚举的字符串扩展
extension WritingStatusExtension on WritingStatus {
  String get value {
    switch (this) {
      case WritingStatus.pending:
        return 'pending';
      case WritingStatus.generating:
        return 'generating';
      case WritingStatus.completed:
        return 'completed';
      case WritingStatus.failed:
        return 'failed';
      case WritingStatus.cancelled:
        return 'cancelled';
    }
  }

  /// 中文显示名称
  String get label {
    switch (this) {
      case WritingStatus.pending:
        return '等待中';
      case WritingStatus.generating:
        return '生成中';
      case WritingStatus.completed:
        return '已完成';
      case WritingStatus.failed:
        return '失败';
      case WritingStatus.cancelled:
        return '已取消';
    }
  }

  static WritingStatus fromString(String? status) {
    switch (status) {
      case 'pending':
        return WritingStatus.pending;
      case 'generating':
        return WritingStatus.generating;
      case 'completed':
        return WritingStatus.completed;
      case 'failed':
        return WritingStatus.failed;
      case 'cancelled':
        return WritingStatus.cancelled;
      default:
        return WritingStatus.pending;
    }
  }
}

/// AI 写作任务数据模型
class WritingTask {
  /// 任务唯一标识
  final String id;

  /// 写作类型
  final WritingType type;

  /// 写作主题 / 输入文本
  final String topic;

  /// 额外参数（如目标语言、字数、语气、风格等）
  final Map<String, dynamic> params;

  /// 生成结果文本
  String result;

  /// 任务状态
  WritingStatus status;

  /// 任务创建时间
  final DateTime createdAt;

  /// 使用的 AI 模型标识
  final String? model;

  /// 错误信息（status 为 failed 时填充）
  String? errorMessage;

  /// 生成进度百分比（0-100，流式生成时更新）
  double progress;

  /// 任务完成时间
  DateTime? completedAt;

  WritingTask({
    required this.id,
    required this.type,
    required this.topic,
    Map<String, dynamic>? params,
    this.result = '',
    this.status = WritingStatus.pending,
    DateTime? createdAt,
    this.model,
    this.errorMessage,
    this.progress = 0.0,
    this.completedAt,
  })  : params = params ?? {},
        createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory WritingTask.fromJson(Map<String, dynamic> json) {
    return WritingTask(
      id: json['id']?.toString() ?? '',
      type: WritingTypeExtension.fromString(json['type']?.toString()),
      topic: json['topic']?.toString() ?? '',
      params: json['params'] != null
          ? Map<String, dynamic>.from(json['params'] as Map)
          : {},
      result: json['result']?.toString() ?? '',
      status: WritingStatusExtension.fromString(json['status']?.toString()),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      model: json['model']?.toString(),
      errorMessage: json['error_message']?.toString(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'topic': topic,
      'params': params,
      'result': result,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'model': model,
      'error_message': errorMessage,
      'progress': progress,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// 创建一个新的待执行任务
  factory WritingTask.create({
    required WritingType type,
    required String topic,
    Map<String, dynamic>? params,
    String? model,
  }) {
    return WritingTask(
      id: 'wt_${DateTime.now().millisecondsSinceEpoch}_'
          '${topic.length.hashCode.toRadixString(16)}',
      type: type,
      topic: topic,
      params: params,
      model: model,
      status: WritingStatus.pending,
    );
  }

  /// 是否处于终态（完成 / 失败 / 取消）
  bool get isFinished =>
      status == WritingStatus.completed ||
      status == WritingStatus.failed ||
      status == WritingStatus.cancelled;

  /// 是否正在生成
  bool get isGenerating => status == WritingStatus.generating;

  /// 是否有可用结果
  bool get hasResult => result.trim().isNotEmpty;

  /// 获取参数字符串值（带默认值）
  String paramString(String key, {String defaultValue = ''}) {
    final v = params[key];
    return v?.toString() ?? defaultValue;
  }

  /// 获取参数整数值（带默认值）
  int paramInt(String key, {int defaultValue = 0}) {
    final v = params[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? defaultValue;
  }

  /// 获取参数布尔值（带默认值）
  bool paramBool(String key, {bool defaultValue = false}) {
    final v = params[key];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return defaultValue;
  }

  /// 复制一份任务（用于重试等场景）
  WritingTask copyWith({
    String? id,
    WritingType? type,
    String? topic,
    Map<String, dynamic>? params,
    String? result,
    WritingStatus? status,
    DateTime? createdAt,
    String? model,
    String? errorMessage,
    double? progress,
    DateTime? completedAt,
  }) {
    return WritingTask(
      id: id ?? this.id,
      type: type ?? this.type,
      topic: topic ?? this.topic,
      params: params ?? this.params,
      result: result ?? this.result,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      model: model ?? this.model,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
