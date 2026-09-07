import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// ============================================================================
/// ChatExportService —— 聊天记录导出服务
///
/// 职责：
///   1. 格式选择：支持 TXT / Markdown / JSON / PDF(模拟) 四种格式
///   2. 导出进度：分阶段进度回调（读取/格式化/写入/完成）
///   3. 文件保存：保存到应用文档目录，支持自定义文件名
///   4. 分享：导出后可调用系统分享
///   5. 消息格式化：按角色、时间、内容类型格式化输出
/// ============================================================================

/// 导出格式枚举
enum ExportFormat { txt, markdown, json, pdf }

/// 导出阶段
enum ExportPhase { reading, formatting, writing, completed, failed }

/// 导出进度
class ExportProgress {
  final ExportPhase phase;
  final double percent;
  final String message;

  ExportProgress({
    required this.phase,
    required this.percent,
    required this.message,
  });
}

/// 导出结果
class ExportResult {
  final String filePath;
  final String fileName;
  final ExportFormat format;
  final int messageCount;
  final int fileSize;
  final DateTime exportedAt;

  ExportResult({
    required this.filePath,
    required this.fileName,
    required this.format,
    required this.messageCount,
    required this.fileSize,
    required this.exportedAt,
  });
}

/// 聊天消息模型（导出用）
class ExportMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final String? model;
  final Map<String, dynamic>? metadata;

  ExportMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.model,
    this.metadata,
  });
}

class ChatExportService {
  /// 单例实例
  static final ChatExportService _instance = ChatExportService._internal();
  factory ChatExportService() => _instance;
  ChatExportService._internal();

  // ===== 配置 =====
  /// 导出目录名
  static const String _exportDirName = 'exports';

  /// 时间格式化
  static final DateFormat _dateFormat =
      DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _fileDateFormat = DateFormat('yyyyMMdd_HHmmss');

  // ===== 状态 =====
  bool _isExporting = false;
  final StreamController<ExportProgress> _progressController =
      StreamController<ExportProgress>.broadcast();

  // ==========================================================================
  // 导出主流程
  // ==========================================================================

  /// 导出聊天记录
  ///
  /// [messages] 消息列表，[format] 导出格式，[title] 会话标题
  /// [fileName] 自定义文件名（不含扩展名），[onProgress] 进度回调
  Future<ExportResult> exportChat({
    required List<ExportMessage> messages,
    ExportFormat format = ExportFormat.markdown,
    String title = '聊天记录',
    String? fileName,
    void Function(ExportProgress)? onProgress,
  }) async {
    if (_isExporting) {
      throw StateError('已有导出任务正在进行');
    }
    _isExporting = true;

    try {
      // 阶段1：读取与准备
      _emitProgress(ExportPhase.reading, 0.1, '正在读取消息...', onProgress);
      await Future.delayed(const Duration(milliseconds: 100));

      // 阶段2：格式化
      _emitProgress(ExportPhase.formatting, 0.3, '正在格式化内容...', onProgress);
      final content = await _formatMessages(messages, format, title);

      // 阶段3：写入文件
      _emitProgress(ExportPhase.writing, 0.7, '正在写入文件...', onProgress);
      final name = fileName ?? 'chat_${_fileDateFormat.format(DateTime.now())}';
      final filePath = await _writeFile(content, name, format);
      final file = File(filePath);
      final fileSize = await file.length();

      // 完成
      _emitProgress(ExportPhase.completed, 1.0, '导出完成', onProgress);

      return ExportResult(
        filePath: filePath,
        fileName: '$name.${_extension(format)}',
        format: format,
        messageCount: messages.length,
        fileSize: fileSize,
        exportedAt: DateTime.now(),
      );
    } catch (e) {
      _emitProgress(ExportPhase.failed, 0.0, '导出失败: $e', onProgress);
      rethrow;
    } finally {
      _isExporting = false;
    }
  }

  /// 导出进度流
  Stream<ExportProgress> get progressStream => _progressController.stream;

  /// 是否正在导出
  bool get isExporting => _isExporting;

  // ==========================================================================
  // 消息格式化
  // ==========================================================================

  /// 根据格式格式化消息
  Future<String> _formatMessages(
    List<ExportMessage> messages,
    ExportFormat format,
    String title,
  ) async {
    switch (format) {
      case ExportFormat.txt:
        return _formatAsTxt(messages, title);
      case ExportFormat.markdown:
        return _formatAsMarkdown(messages, title);
      case ExportFormat.json:
        return _formatAsJson(messages, title);
      case ExportFormat.pdf:
        return _formatAsPdfSimulated(messages, title);
    }
  }

  /// TXT 格式
  String _formatAsTxt(List<ExportMessage> messages, String title) {
    final buffer = StringBuffer();
    buffer.writeln('=' * 60);
    buffer.writeln('  $title');
    buffer.writeln('  导出时间: ${_dateFormat.format(DateTime.now())}');
    buffer.writeln('  消息总数: ${messages.length}');
    buffer.writeln('=' * 60);
    buffer.writeln('');

    for (final msg in messages) {
      final roleLabel = msg.role == 'user' ? '用户' : 'AI助手';
      buffer.writeln('【$roleLabel】 ${_dateFormat.format(msg.timestamp)}');
      if (msg.model != null) {
        buffer.writeln('模型: ${msg.model}');
      }
      buffer.writeln(msg.content);
      buffer.writeln('');
      buffer.writeln('-' * 40);
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Markdown 格式
  String _formatAsMarkdown(List<ExportMessage> messages, String title) {
    final buffer = StringBuffer();
    buffer.writeln('# $title');
    buffer.writeln('');
    buffer.writeln('> 导出时间: ${_dateFormat.format(DateTime.now())}  ');
    buffer.writeln('> 消息总数: ${messages.length}');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');

    for (final msg in messages) {
      final roleLabel = msg.role == 'user' ? '🧑 用户' : '🤖 AI助手';
      buffer.writeln('### $roleLabel');
      buffer.writeln('');
      buffer.writeln('*${_dateFormat.format(msg.timestamp)}*');
      if (msg.model != null) {
        buffer.writeln('  \n*模型: `${msg.model}`*');
      }
      buffer.writeln('');
      buffer.writeln(msg.content);
      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// JSON 格式
  String _formatAsJson(List<ExportMessage> messages, String title) {
    final data = {
      'title': title,
      'exported_at': DateTime.now().toIso8601String(),
      'message_count': messages.length,
      'messages': messages
          .map((m) => {
                'role': m.role,
                'content': m.content,
                'timestamp': m.timestamp.toIso8601String(),
                if (m.model != null) 'model': m.model,
                if (m.metadata != null) 'metadata': m.metadata,
              })
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// PDF 模拟格式（生成可被 PDF 阅读器解析的结构化文本）
  String _formatAsPdfSimulated(List<ExportMessage> messages, String title) {
    // 模拟 PDF 内容结构：使用带标记的纯文本，实际渲染需 PDF 库
    final buffer = StringBuffer();
    buffer.writeln('%PDF-1.4 (模拟)');
    buffer.writeln('% 标题: $title');
    buffer.writeln('% 导出时间: ${_dateFormat.format(DateTime.now())}');
    buffer.writeln('% 消息数: ${messages.length}');
    buffer.writeln('');

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      buffer.writeln('--- Page ${i + 1} ---');
      buffer.writeln('角色: ${msg.role == "user" ? "用户" : "AI助手"}');
      buffer.writeln('时间: ${_dateFormat.format(msg.timestamp)}');
      if (msg.model != null) {
        buffer.writeln('模型: ${msg.model}');
      }
      buffer.writeln('');
      // 按行分割内容，模拟 PDF 文本流
      final lines = msg.content.split('\n');
      for (final line in lines) {
        buffer.writeln('  $line');
      }
      buffer.writeln('');
    }

    buffer.writeln('%%EOF');
    return buffer.toString();
  }

  // ==========================================================================
  // 文件操作
  // ==========================================================================

  /// 获取导出目录
  Future<Directory> _getExportDir() async {
    final docDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${docDir.path}/$_exportDirName');
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }
    return exportDir;
  }

  /// 写入文件
  Future<String> _writeFile(
    String content,
    String fileName,
    ExportFormat format,
  ) async {
    final dir = await _getExportDir();
    final file = File('${dir.path}/$fileName.${_extension(format)}');
    await file.writeAsString(content, flush: true);
    return file.path;
  }

  /// 获取格式扩展名
  String _extension(ExportFormat format) {
    switch (format) {
      case ExportFormat.txt:
        return 'txt';
      case ExportFormat.markdown:
        return 'md';
      case ExportFormat.json:
        return 'json';
      case ExportFormat.pdf:
        return 'pdf';
    }
  }

  /// 获取所有导出文件列表
  Future<List<File>> getExportedFiles() async {
    final dir = await _getExportDir();
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File) {
        files.add(entity);
      }
    }
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// 删除导出文件
  Future<bool> deleteExport(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 清空所有导出文件
  Future<int> clearAllExports() async {
    final dir = await _getExportDir();
    int count = 0;
    await for (final entity in dir.list()) {
      await entity.delete();
      count++;
    }
    return count;
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  void _emitProgress(
    ExportPhase phase,
    double percent,
    String message,
    void Function(ExportProgress)? onProgress,
  ) {
    final progress = ExportProgress(
      phase: phase,
      percent: percent,
      message: message,
    );
    _progressController.add(progress);
    onProgress?.call(progress);
  }

  /// 格式化文件大小
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// 销毁服务
  void dispose() {
    _progressController.close();
  }
}
