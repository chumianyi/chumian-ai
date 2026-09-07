import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:chumian_ai/models/writing_task.dart';
import 'package:chumian_ai/services/writing_service.dart';

/// ============================================================================
/// WritingProvider —— 写作任务状态管理 Provider
///
/// 职责：
///   1. 管理写作任务列表与当前任务
///   2. 生成写作内容（调用 WritingService）
///   3. 取消、重试任务
///   4. 管理历史记录
/// ============================================================================
class WritingProvider extends ChangeNotifier {
  /// 写作服务实例
  final WritingService _writingService = WritingService();

  /// 任务历史记录
  final List<WritingTask> _history = [];

  /// 当前正在执行的任务
  WritingTask? _currentTask;

  /// 是否正在生成
  bool _isGenerating = false;

  /// 当前生成进度（0.0-1.0）
  double _progress = 0.0;

  /// 错误信息
  String? _errorMessage;

  // ===== Getters =====
  List<WritingTask> get history => List.unmodifiable(_history);
  WritingTask? get currentTask => _currentTask;
  bool get isGenerating => _isGenerating;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasHistory => _history.isNotEmpty;

  /// 已完成的任务数
  int get completedCount =>
      _history.where((t) => t.status == WritingStatus.completed).length;

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化：加载历史记录
  Future<void> init() async {
    await _loadHistory();
  }

  /// 从服务加载历史记录
  Future<void> _loadHistory() async {
    try {
      final history = await _writingService.getHistory();
      _history.clear();
      _history.addAll(history);
      notifyListeners();
    } catch (_) {
      // 加载失败静默处理
    }
  }

  // ==========================================================================
  // 生成写作
  // ==========================================================================

  /// 开始生成写作
  Future<WritingTask?> generate({
    required WritingType type,
    required String topic,
    Map<String, dynamic>? params,
    String? model,
  }) async {
    if (_isGenerating) return null;

    // 校验参数
    final validationError = _writingService.validateParams(
      type: type,
      topic: topic,
      params: params,
    );
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    _progress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final task = await _writingService.executeWriting(
        type: type,
        topic: topic,
        params: params,
        model: model,
        onProgress: (p) {
          _progress = p;
          notifyListeners();
        },
      );

      _currentTask = task;
      _progress = 1.0;

      if (task.status == WritingStatus.completed) {
        // 插入到历史记录最前面
        _history.insert(0, task);
        // 限制历史记录数量
        if (_history.length > 100) {
          _history.removeRange(100, _history.length);
        }
      } else if (task.status == WritingStatus.failed) {
        _errorMessage = task.errorMessage ?? '生成失败';
      }

      return task;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// 取消当前任务
  void cancel() {
    if (_currentTask != null) {
      _writingService.cancelTask(_currentTask!.id);
      _currentTask = null;
      _isGenerating = false;
      _progress = 0.0;
      notifyListeners();
    }
  }

  /// 重试指定任务
  Future<WritingTask?> retry(WritingTask task) async {
    return generate(
      type: task.type,
      topic: task.topic,
      params: task.params,
      model: task.model,
    );
  }

  // ==========================================================================
  // 历史记录管理
  // ==========================================================================

  /// 删除单条历史记录
  Future<void> deleteHistory(String taskId) async {
    _history.removeWhere((t) => t.id == taskId);
    await _writingService.deleteHistory(taskId);
    notifyListeners();
  }

  /// 清空历史记录
  Future<void> clearHistory() async {
    _history.clear();
    await _writingService.clearHistory();
    notifyListeners();
  }

  /// 按类型筛选历史记录
  List<WritingTask> getHistoryByType(WritingType type) {
    return _history.where((t) => t.type == type).toList();
  }

  /// 搜索历史记录
  List<WritingTask> searchHistory(String keyword) {
    if (keyword.isEmpty) return List.unmodifiable(_history);
    final lower = keyword.toLowerCase();
    return _history
        .where((t) =>
            t.topic.toLowerCase().contains(lower) ||
            t.result.toLowerCase().contains(lower))
        .toList();
  }

  // ==========================================================================
  // 其他
  // ==========================================================================

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 设置当前任务（用于查看历史详情）
  void setCurrentTask(WritingTask? task) {
    _currentTask = task;
    notifyListeners();
  }

  /// 刷新历史记录
  Future<void> refreshHistory() async {
    await _loadHistory();
  }
}
