/// ============================================================================
/// ExportTask —— 导出任务数据模型
///
/// 承载一个文件导出任务的完整状态，包括类型、格式、进度、
/// 文件路径、创建时间以及过期时间。支持异步导出任务的跟踪与管理。
/// ============================================================================

/// 导出类型枚举
enum ExportType {
  /// 聊天记录
  chat,

  /// 笔记
  note,

  /// 图片
  image,

  /// 报告
  report,

  /// 数据
  data,

  /// 其他
  other,
}

/// ExportType 枚举的字符串扩展
extension ExportTypeExtension on ExportType {
  String get value {
    switch (this) {
      case ExportType.chat:
        return 'chat';
      case ExportType.note:
        return 'note';
      case ExportType.image:
        return 'image';
      case ExportType.report:
        return 'report';
      case ExportType.data:
        return 'data';
      case ExportType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case ExportType.chat:
        return '聊天记录';
      case ExportType.note:
        return '笔记';
      case ExportType.image:
        return '图片';
      case ExportType.report:
        return '报告';
      case ExportType.data:
        return '数据';
      case ExportType.other:
        return '其他';
    }
  }

  static ExportType fromString(String? type) {
    switch (type) {
      case 'chat':
        return ExportType.chat;
      case 'note':
        return ExportType.note;
      case 'image':
        return ExportType.image;
      case 'report':
        return ExportType.report;
      case 'data':
        return ExportType.data;
      default:
        return ExportType.other;
    }
  }
}

/// 导出格式枚举
enum ExportFormat {
  /// PDF
  pdf,

  /// Word
  docx,

  /// Excel
  xlsx,

  /// CSV
  csv,

  /// JSON
  json,

  /// Markdown
  md,

  /// 纯文本
  txt,

  /// PNG 图片
  png,

  /// ZIP 压缩包
  zip,
}

/// ExportFormat 枚举的字符串扩展
extension ExportFormatExtension on ExportFormat {
  String get value {
    switch (this) {
      case ExportFormat.pdf:
        return 'pdf';
      case ExportFormat.docx:
        return 'docx';
      case ExportFormat.xlsx:
        return 'xlsx';
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.json:
        return 'json';
      case ExportFormat.md:
        return 'md';
      case ExportFormat.txt:
        return 'txt';
      case ExportFormat.png:
        return 'png';
      case ExportFormat.zip:
        return 'zip';
    }
  }

  String get extension {
    switch (this) {
      case ExportFormat.pdf:
        return '.pdf';
      case ExportFormat.docx:
        return '.docx';
      case ExportFormat.xlsx:
        return '.xlsx';
      case ExportFormat.csv:
        return '.csv';
      case ExportFormat.json:
        return '.json';
      case ExportFormat.md:
        return '.md';
      case ExportFormat.txt:
        return '.txt';
      case ExportFormat.png:
        return '.png';
      case ExportFormat.zip:
        return '.zip';
    }
  }

  String get mimeType {
    switch (this) {
      case ExportFormat.pdf:
        return 'application/pdf';
      case ExportFormat.docx:
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case ExportFormat.xlsx:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case ExportFormat.csv:
        return 'text/csv';
      case ExportFormat.json:
        return 'application/json';
      case ExportFormat.md:
        return 'text/markdown';
      case ExportFormat.txt:
        return 'text/plain';
      case ExportFormat.png:
        return 'image/png';
      case ExportFormat.zip:
        return 'application/zip';
    }
  }

  static ExportFormat fromString(String? format) {
    switch (format) {
      case 'pdf':
        return ExportFormat.pdf;
      case 'docx':
        return ExportFormat.docx;
      case 'xlsx':
        return ExportFormat.xlsx;
      case 'csv':
        return ExportFormat.csv;
      case 'json':
        return ExportFormat.json;
      case 'md':
        return ExportFormat.md;
      case 'txt':
        return ExportFormat.txt;
      case 'png':
        return ExportFormat.png;
      case 'zip':
        return ExportFormat.zip;
      default:
        return ExportFormat.pdf;
    }
  }
}

/// 导出任务状态枚举
enum ExportStatus {
  /// 等待中
  pending,

  /// 处理中
  processing,

  /// 已完成
  completed,

  /// 失败
  failed,

  /// 已取消
  cancelled,

  /// 已过期
  expired,
}

/// ExportStatus 枚举的字符串扩展
extension ExportStatusExtension on ExportStatus {
  String get value {
    switch (this) {
      case ExportStatus.pending:
        return 'pending';
      case ExportStatus.processing:
        return 'processing';
      case ExportStatus.completed:
        return 'completed';
      case ExportStatus.failed:
        return 'failed';
      case ExportStatus.cancelled:
        return 'cancelled';
      case ExportStatus.expired:
        return 'expired';
    }
  }

  String get label {
    switch (this) {
      case ExportStatus.pending:
        return '等待中';
      case ExportStatus.processing:
        return '处理中';
      case ExportStatus.completed:
        return '已完成';
      case ExportStatus.failed:
        return '失败';
      case ExportStatus.cancelled:
        return '已取消';
      case ExportStatus.expired:
        return '已过期';
    }
  }

  static ExportStatus fromString(String? status) {
    switch (status) {
      case 'pending':
        return ExportStatus.pending;
      case 'processing':
        return ExportStatus.processing;
      case 'completed':
        return ExportStatus.completed;
      case 'failed':
        return ExportStatus.failed;
      case 'cancelled':
        return ExportStatus.cancelled;
      case 'expired':
        return ExportStatus.expired;
      default:
        return ExportStatus.pending;
    }
  }
}

/// 导出任务数据模型
class ExportTask {
  /// 任务唯一标识
  final String id;

  /// 导出类型
  final ExportType type;

  /// 导出格式
  final ExportFormat format;

  /// 任务状态
  ExportStatus status;

  /// 进度（0.0 - 1.0）
  double progress;

  /// 导出文件路径（完成后有效）
  String filePath;

  /// 文件名
  final String fileName;

  /// 文件大小（字节，完成后有效）
  int fileSize;

  /// 创建时间
  final DateTime createdAt;

  /// 完成时间
  DateTime? completedAt;

  /// 过期时间
  final DateTime? expiresAt;

  /// 错误信息（失败时有效）
  String? errorMessage;

  /// 源数据标识（如会话ID、笔记ID等）
  final String sourceId;

  ExportTask({
    required this.id,
    required this.type,
    required this.format,
    this.status = ExportStatus.pending,
    this.progress = 0.0,
    this.filePath = '',
    required this.fileName,
    this.fileSize = 0,
    DateTime? createdAt,
    this.completedAt,
    this.expiresAt,
    this.errorMessage,
    this.sourceId = '',
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory ExportTask.fromJson(Map<String, dynamic> json) {
    return ExportTask(
      id: json['id']?.toString() ?? '',
      type: ExportTypeExtension.fromString(json['type']?.toString()),
      format: ExportFormatExtension.fromString(json['format']?.toString()),
      status: ExportStatusExtension.fromString(json['status']?.toString()),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      filePath: json['file_path']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      errorMessage: json['error_message']?.toString(),
      sourceId: json['source_id']?.toString() ?? '',
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'format': format.value,
      'status': status.value,
      'progress': progress,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'error_message': errorMessage,
      'source_id': sourceId,
    };
  }

  /// 创建一个新的导出任务
  factory ExportTask.create({
    required ExportType type,
    required ExportFormat format,
    required String fileName,
    String sourceId = '',
    Duration? expiresIn,
  }) {
    return ExportTask(
      id: 'export_${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      format: format,
      fileName: fileName,
      sourceId: sourceId,
      expiresAt: expiresIn != null ? DateTime.now().add(expiresIn) : null,
    );
  }

  /// 是否处于活动状态（等待中或处理中）
  bool get isActive =>
      status == ExportStatus.pending || status == ExportStatus.processing;

  /// 是否已完成
  bool get isCompleted => status == ExportStatus.completed;

  /// 是否已过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 格式化文件大小
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 进度百分比文本
  String get progressText => '${(progress * 100).toStringAsFixed(0)}%';

  /// 复制一份导出任务
  ExportTask copyWith({
    String? id,
    ExportType? type,
    ExportFormat? format,
    ExportStatus? status,
    double? progress,
    String? filePath,
    String? fileName,
    int? fileSize,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    String? errorMessage,
    String? sourceId,
  }) {
    return ExportTask(
      id: id ?? this.id,
      type: type ?? this.type,
      format: format ?? this.format,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      errorMessage: errorMessage ?? this.errorMessage,
      sourceId: sourceId ?? this.sourceId,
    );
  }
}
