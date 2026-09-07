/// ============================================================================
/// ToolHistory —— 工具使用历史数据模型
///
/// 承载每次 AI 工具调用的完整记录，包括工具类型、输入、输出、
/// 调用时间以及参数。支持按工具类型筛选与全文搜索。
/// ============================================================================

/// 工具类型枚举
enum ToolType {
  /// 翻译
  translate,

  /// 写作
  writing,

  /// 摘要
  summary,

  /// 代码
  code,

  /// 图片生成
  imageGen,

  /// OCR 识别
  ocr,

  /// 语音转文字
  voiceToText,

  /// 文字转语音
  textToVoice,

  /// PDF 总结
  pdfSummary,

  /// 思维导图
  mindmap,

  /// PPT 大纲
  pptOutline,

  /// 简历
  resume,

  /// 邮件
  email,

  /// 其他
  other,
}

/// ToolType 枚举的字符串扩展
extension ToolTypeExtension on ToolType {
  /// 转为存储用字符串
  String get value {
    switch (this) {
      case ToolType.translate:
        return 'translate';
      case ToolType.writing:
        return 'writing';
      case ToolType.summary:
        return 'summary';
      case ToolType.code:
        return 'code';
      case ToolType.imageGen:
        return 'image_gen';
      case ToolType.ocr:
        return 'ocr';
      case ToolType.voiceToText:
        return 'voice_to_text';
      case ToolType.textToVoice:
        return 'text_to_voice';
      case ToolType.pdfSummary:
        return 'pdf_summary';
      case ToolType.mindmap:
        return 'mindmap';
      case ToolType.pptOutline:
        return 'ppt_outline';
      case ToolType.resume:
        return 'resume';
      case ToolType.email:
        return 'email';
      case ToolType.other:
        return 'other';
    }
  }

  /// 工具显示名称
  String get label {
    switch (this) {
      case ToolType.translate:
        return '翻译';
      case ToolType.writing:
        return '写作';
      case ToolType.summary:
        return '摘要';
      case ToolType.code:
        return '代码';
      case ToolType.imageGen:
        return '图片生成';
      case ToolType.ocr:
        return 'OCR 识别';
      case ToolType.voiceToText:
        return '语音转文字';
      case ToolType.textToVoice:
        return '文字转语音';
      case ToolType.pdfSummary:
        return 'PDF 总结';
      case ToolType.mindmap:
        return '思维导图';
      case ToolType.pptOutline:
        return 'PPT 大纲';
      case ToolType.resume:
        return '简历';
      case ToolType.email:
        return '邮件';
      case ToolType.other:
        return '其他工具';
    }
  }

  static ToolType fromString(String? type) {
    switch (type) {
      case 'translate':
        return ToolType.translate;
      case 'writing':
        return ToolType.writing;
      case 'summary':
        return ToolType.summary;
      case 'code':
        return ToolType.code;
      case 'image_gen':
        return ToolType.imageGen;
      case 'ocr':
        return ToolType.ocr;
      case 'voice_to_text':
        return ToolType.voiceToText;
      case 'text_to_voice':
        return ToolType.textToVoice;
      case 'pdf_summary':
        return ToolType.pdfSummary;
      case 'mindmap':
        return ToolType.mindmap;
      case 'ppt_outline':
        return ToolType.pptOutline;
      case 'resume':
        return ToolType.resume;
      case 'email':
        return ToolType.email;
      default:
        return ToolType.other;
    }
  }
}

/// 工具使用历史数据模型
class ToolHistory {
  /// 记录唯一标识
  final String id;

  /// 工具类型
  final ToolType toolType;

  /// 输入内容
  final String input;

  /// 输出内容
  final String output;

  /// 调用时间
  final DateTime createdAt;

  /// 调用参数（如语言、风格、长度等）
  final Map<String, dynamic> params;

  /// 执行耗时（毫秒）
  final int durationMs;

  /// 是否成功
  final bool isSuccess;

  ToolHistory({
    required this.id,
    required this.toolType,
    required this.input,
    required this.output,
    DateTime? createdAt,
    Map<String, dynamic>? params,
    this.durationMs = 0,
    this.isSuccess = true,
  })  : createdAt = createdAt ?? DateTime.now(),
        params = params ?? {};

  /// 从 JSON 反序列化
  factory ToolHistory.fromJson(Map<String, dynamic> json) {
    return ToolHistory(
      id: json['id']?.toString() ?? '',
      toolType: ToolTypeExtension.fromString(json['tool_type']?.toString()),
      input: json['input']?.toString() ?? '',
      output: json['output']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      params: json['params'] != null
          ? Map<String, dynamic>.from(json['params'] as Map)
          : {},
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
      isSuccess: json['is_success'] != false,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tool_type': toolType.value,
      'input': input,
      'output': output,
      'created_at': createdAt.toIso8601String(),
      'params': params,
      'duration_ms': durationMs,
      'is_success': isSuccess,
    };
  }

  /// 创建一条新的工具使用记录
  factory ToolHistory.create({
    required ToolType toolType,
    required String input,
    required String output,
    Map<String, dynamic>? params,
    int durationMs = 0,
    bool isSuccess = true,
  }) {
    return ToolHistory(
      id: 'th_${DateTime.now().microsecondsSinceEpoch}',
      toolType: toolType,
      input: input,
      output: output,
      params: params,
      durationMs: durationMs,
      isSuccess: isSuccess,
    );
  }

  /// 输入预览
  String get inputPreview {
    final text = input.trim();
    if (text.isEmpty) return '无输入';
    if (text.length <= 50) return text;
    return '${text.substring(0, 50)}...';
  }

  /// 输出预览
  String get outputPreview {
    final text = output.trim();
    if (text.isEmpty) return '无输出';
    if (text.length <= 80) return text;
    return '${text.substring(0, 80)}...';
  }

  /// 搜索匹配：输入或输出包含关键词
  bool matches(String keyword) {
    if (keyword.isEmpty) return true;
    final lower = keyword.toLowerCase();
    return input.toLowerCase().contains(lower) ||
        output.toLowerCase().contains(lower);
  }

  /// 格式化耗时
  String get formattedDuration {
    if (durationMs < 1000) return '${durationMs}ms';
    return '${(durationMs / 1000).toStringAsFixed(1)}s';
  }

  /// 复制一份工具历史
  ToolHistory copyWith({
    String? id,
    ToolType? toolType,
    String? input,
    String? output,
    DateTime? createdAt,
    Map<String, dynamic>? params,
    int? durationMs,
    bool? isSuccess,
  }) {
    return ToolHistory(
      id: id ?? this.id,
      toolType: toolType ?? this.toolType,
      input: input ?? this.input,
      output: output ?? this.output,
      createdAt: createdAt ?? this.createdAt,
      params: params ?? this.params,
      durationMs: durationMs ?? this.durationMs,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
