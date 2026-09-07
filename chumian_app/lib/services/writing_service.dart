import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:chumian_ai/models/writing_task.dart';
import 'package:chumian_ai/services/cache_service.dart';
import 'package:chumian_ai/services/local_storage_service.dart';

/// ============================================================================
/// WritingService —— AI 写作服务
///
/// 职责：
///   1. AI 写作任务管理：创建、执行、取消
///   2. 调用后端 API 进行文本生成
///   3. 结果解析与后处理
///   4. 历史记录管理（本地持久化）
///   5. 模板管理：预设写作模板
///   6. 参数校验：输入合法性检查
/// ============================================================================
class WritingService {
  /// 单例实例
  static final WritingService _instance = WritingService._internal();
  factory WritingService() => _instance;
  WritingService._internal();

  /// Dio 实例
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://103.236.99.177:24512',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
    headers: {'Content-Type': 'application/json'},
  ));

  /// 缓存服务
  final CacheService _cache = CacheService();

  /// 本地存储服务
  final LocalStorageService _storage = LocalStorageService();

  /// 历史记录存储键
  static const String _historyKey = 'writing_history';

  /// 历史记录最大数量
  static const int _maxHistory = 100;

  /// 正在执行的任务（用于取消）
  final Map<String, CancelToken> _activeTasks = {};

  // ==========================================================================
  // 参数校验
  // ==========================================================================

  /// 校验写作参数
  ///
  /// 返回错误信息，null 表示校验通过
  String? validateParams({
    required WritingType type,
    required String topic,
    Map<String, dynamic>? params,
  }) {
    if (topic.trim().isEmpty) {
      return '请输入写作主题或内容';
    }
    if (topic.trim().length > 5000) {
      return '输入内容过长，请控制在 5000 字以内';
    }

    switch (type) {
      case WritingType.translate:
        final targetLang = params?['target_language']?.toString() ?? '';
        if (targetLang.isEmpty) {
          return '请选择目标语言';
        }
        break;
      case WritingType.continuation:
        final maxLength = params?['max_length'];
        if (maxLength != null && maxLength is int) {
          if (maxLength < 50 || maxLength > 5000) {
            return '续写长度应在 50-5000 字之间';
          }
        }
        break;
      case WritingType.poem:
        final poemType = params?['poem_type']?.toString() ?? '';
        if (poemType.isEmpty) {
          return '请选择诗歌类型';
        }
        break;
      default:
        break;
    }
    return null;
  }

  // ==========================================================================
  // 任务执行
  // ==========================================================================

  /// 创建并执行写作任务
  ///
  /// 返回完成后的 WritingTask，失败时任务状态为 failed
  Future<WritingTask> executeWriting({
    required WritingType type,
    required String topic,
    Map<String, dynamic>? params,
    String? model,
    void Function(double progress)? onProgress,
  }) async {
    final task = WritingTask.create(
      type: type,
      topic: topic,
      params: params,
      model: model,
    );

    // 校验参数
    final error = validateParams(type: type, topic: topic, params: params);
    if (error != null) {
      task.status = WritingStatus.failed;
      task.errorMessage = error;
      return task;
    }

    task.status = WritingStatus.generating;
    task.progress = 10;
    onProgress?.call(0.1);

    // 创建取消令牌
    final cancelToken = CancelToken();
    _activeTasks[task.id] = cancelToken;

    try {
      // 调用 API
      final resp = await _dio.post(
        '/api/writing/generate',
        data: {
          'type': type.value,
          'topic': topic,
          'params': params ?? {},
          'model': model,
        },
        cancelToken: cancelToken,
      );

      task.progress = 80;
      onProgress?.call(0.8);

      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data is Map
            ? Map<String, dynamic>.from(resp.data as Map)
            : <String, dynamic>{};
        task.result = data['result']?.toString() ?? '';
        task.model = data['model']?.toString() ?? model;
        task.status = WritingStatus.completed;
        task.progress = 100;
        task.completedAt = DateTime.now();
      } else {
        task.status = WritingStatus.failed;
        task.errorMessage = '服务器返回异常';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        task.status = WritingStatus.cancelled;
        task.errorMessage = '已取消';
      } else {
        task.status = WritingStatus.failed;
        task.errorMessage = e.message ?? '网络请求失败';
      }
    } catch (e) {
      task.status = WritingStatus.failed;
      task.errorMessage = e.toString();
    } finally {
      _activeTasks.remove(task.id);
      onProgress?.call(task.progress / 100);
    }

    // 保存到历史记录
    if (task.status == WritingStatus.completed) {
      await _addToHistory(task);
    }

    return task;
  }

  /// 取消任务
  bool cancelTask(String taskId) {
    final cancelToken = _activeTasks[taskId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('用户取消');
      _activeTasks.remove(taskId);
      return true;
    }
    return false;
  }

  /// 重试任务
  Future<WritingTask> retryTask(WritingTask task) async {
    return executeWriting(
      type: task.type,
      topic: task.topic,
      params: task.params,
      model: task.model,
    );
  }

  // ==========================================================================
  // 历史记录
  // ==========================================================================

  /// 添加到历史记录
  Future<void> _addToHistory(WritingTask task) async {
    final history = await getHistory();
    history.insert(0, task);
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }
    await _saveHistory(history);
  }

  /// 获取历史记录
  Future<List<WritingTask>> getHistory() async {
    final list = await _storage.getJsonList(_historyKey);
    return list
        .map((e) =>
            WritingTask.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 保存历史记录
  Future<void> _saveHistory(List<WritingTask> history) async {
    await _storage.setJsonList(
      _historyKey,
      history.map((e) => e.toJson()).toList(),
    );
  }

  /// 删除单条历史
  Future<void> deleteHistory(String taskId) async {
    final history = await getHistory();
    history.removeWhere((t) => t.id == taskId);
    await _saveHistory(history);
  }

  /// 清空历史记录
  Future<void> clearHistory() async {
    await _storage.remove(_historyKey);
  }

  // ==========================================================================
  // 模板管理
  // ==========================================================================

  /// 获取预设写作模板
  List<WritingTemplate> getTemplates() {
    return [
      WritingTemplate(
        id: 'email_formal',
        name: '正式邮件',
        type: WritingType.email,
        description: '适用于商务、工作等正式场合的邮件',
        params: {'tone': 'formal', 'length': 'medium'},
      ),
      WritingTemplate(
        id: 'email_casual',
        name: '日常邮件',
        type: WritingType.email,
        description: '适用于朋友、同事间的轻松邮件',
        params: {'tone': 'casual', 'length': 'short'},
      ),
      WritingTemplate(
        id: 'article_tech',
        name: '技术文章',
        type: WritingType.article,
        description: '技术博客、教程类文章',
        params: {'style': 'technical', 'length': 'long'},
      ),
      WritingTemplate(
        id: 'poem_modern',
        name: '现代诗',
        type: WritingType.poem,
        description: '自由体现代诗歌',
        params: {'poem_type': 'modern'},
      ),
      WritingTemplate(
        id: 'poem_classical',
        name: '古典诗词',
        type: WritingType.poem,
        description: '绝句、律诗等古典诗词',
        params: {'poem_type': 'classical'},
      ),
      WritingTemplate(
        id: 'summary_article',
        name: '文章摘要',
        type: WritingType.summary,
        description: '提取文章核心观点的摘要',
        params: {'length': 'short', 'focus': 'key_points'},
      ),
      WritingTemplate(
        id: 'copy_social',
        name: '社交文案',
        type: WritingType.copywriting,
        description: '适合社交媒体的短文案',
        params: {'platform': 'social', 'tone': 'engaging'},
      ),
      WritingTemplate(
        id: 'translate_en',
        name: '中英翻译',
        type: WritingType.translate,
        description: '中文翻译为英文',
        params: {'target_language': 'english', 'style': 'natural'},
      ),
    ];
  }

  /// 根据类型获取模板
  List<WritingTemplate> getTemplatesByType(WritingType type) {
    return getTemplates().where((t) => t.type == type).toList();
  }
}

/// 写作模板
class WritingTemplate {
  /// 模板 ID
  final String id;

  /// 模板名称
  final String name;

  /// 适用写作类型
  final WritingType type;

  /// 模板描述
  final String description;

  /// 预设参数
  final Map<String, dynamic> params;

  WritingTemplate({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
    Map<String, dynamic>? params,
  }) : params = params ?? {};
}
