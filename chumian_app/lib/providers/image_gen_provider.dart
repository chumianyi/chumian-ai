import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:chumian_ai/models/image_task.dart';
import 'package:chumian_ai/services/image_gen_service.dart';

/// ============================================================================
/// ImageGenProvider —— 绘画任务状态管理 Provider
///
/// 职责：
///   1. 管理绘画任务队列
///   2. 进度轮询与状态更新
///   3. 结果展示与历史记录
///   4. 任务取消与重试
/// ============================================================================
class ImageGenProvider extends ChangeNotifier {
  /// 绘画服务实例
  final ImageGenService _imageGenService = ImageGenService();

  /// 任务历史记录
  final List<ImageTask> _history = [];

  /// 当前任务队列（等待中 + 生成中）
  final List<ImageTask> _taskQueue = [];

  /// 当前正在生成的任务
  ImageTask? _currentTask;

  /// 是否正在生成
  bool _isGenerating = false;

  /// 当前进度（0.0-1.0）
  double _progress = 0.0;

  /// 错误信息
  String? _errorMessage;

  // ===== Getters =====
  List<ImageTask> get history => List.unmodifiable(_history);
  List<ImageTask> get taskQueue => List.unmodifiable(_taskQueue);
  ImageTask? get currentTask => _currentTask;
  bool get isGenerating => _isGenerating;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasHistory => _history.isNotEmpty;
  bool get hasQueue => _taskQueue.isNotEmpty;

  /// 已完成的任务数
  int get completedCount =>
      _history.where((t) => t.status == ImageTaskStatus.completed).length;

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
      final history = await _imageGenService.getHistory();
      _history.clear();
      _history.addAll(history);
      notifyListeners();
    } catch (_) {}
  }

  // ==========================================================================
  // 生成图片
  // ==========================================================================

  /// 提交绘画任务
  Future<ImageTask?> generate({
    required String prompt,
    String negativePrompt = '',
    ImageStyle style = ImageStyle.realistic,
    ImageSize size = ImageSize.square,
    int? seed,
  }) async {
    // 校验参数
    final validationError = _imageGenService.validateParams(prompt: prompt);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return null;
    }

    _errorMessage = null;

    // 创建任务并加入队列
    final task = ImageTask.create(
      prompt: prompt,
      negativePrompt: negativePrompt,
      style: style,
      size: size,
      seed: seed,
    );
    _taskQueue.add(task);
    notifyListeners();

    // 如果当前没有任务在生成，立即开始
    if (!_isGenerating) {
      _processNextTask();
    }

    return task;
  }

  /// 处理队列中的下一个任务
  Future<void> _processNextTask() async {
    if (_taskQueue.isEmpty || _isGenerating) return;

    final task = _taskQueue.removeAt(0);
    _currentTask = task;
    _isGenerating = true;
    _progress = 0.0;
    task.status = ImageTaskStatus.generating;
    notifyListeners();

    try {
      final result = await _imageGenService.generateImage(
        prompt: task.prompt,
        negativePrompt: task.negativePrompt,
        style: task.style,
        size: task.size,
        seed: task.seed,
        onProgress: (p) {
          _progress = p;
          task.progress = p * 100;
          notifyListeners();
        },
      );

      // 更新任务状态
      task.status = result.status;
      task.resultUrl = result.resultUrl;
      task.errorMessage = result.errorMessage;
      task.progress = result.progress;
      task.completedAt = result.completedAt;
      task.serverTaskId = result.serverTaskId;

      if (task.status == ImageTaskStatus.completed) {
        // 加入历史记录
        _history.insert(0, task);
        if (_history.length > 50) {
          _history.removeRange(50, _history.length);
        }
      } else if (task.status == ImageTaskStatus.failed) {
        _errorMessage = task.errorMessage ?? '生成失败';
      }
    } catch (e) {
      task.status = ImageTaskStatus.failed;
      task.errorMessage = e.toString();
      _errorMessage = e.toString();
    } finally {
      _isGenerating = false;
      _currentTask = null;
      _progress = 0.0;
      notifyListeners();

      // 处理下一个任务
      if (_taskQueue.isNotEmpty) {
        _processNextTask();
      }
    }
  }

  /// 取消指定任务
  void cancelTask(String taskId) {
    // 从队列中移除
    _taskQueue.removeWhere((t) => t.id == taskId);

    // 如果是当前任务，取消它
    if (_currentTask?.id == taskId) {
      _imageGenService.cancelTask(taskId);
      _currentTask?.status = ImageTaskStatus.cancelled;
      _isGenerating = false;
      _currentTask = null;
      _progress = 0.0;

      // 处理下一个任务
      if (_taskQueue.isNotEmpty) {
        _processNextTask();
      }
    }

    notifyListeners();
  }

  /// 取消所有任务
  void cancelAll() {
    for (final task in _taskQueue) {
      task.status = ImageTaskStatus.cancelled;
    }
    _taskQueue.clear();
    if (_currentTask != null) {
      _imageGenService.cancelTask(_currentTask!.id);
      _currentTask?.status = ImageTaskStatus.cancelled;
      _currentTask = null;
    }
    _isGenerating = false;
    _progress = 0.0;
    notifyListeners();
  }

  /// 重试指定任务
  Future<ImageTask?> retry(ImageTask task) {
    return generate(
      prompt: task.prompt,
      negativePrompt: task.negativePrompt,
      style: task.style,
      size: task.size,
      seed: task.seed,
    );
  }

  // ==========================================================================
  // 历史记录管理
  // ==========================================================================

  /// 删除单条历史记录
  Future<void> deleteHistory(String taskId) async {
    _history.removeWhere((t) => t.id == taskId);
    await _imageGenService.deleteHistory(taskId);
    notifyListeners();
  }

  /// 清空历史记录
  Future<void> clearHistory() async {
    _history.clear();
    await _imageGenService.clearHistory();
    notifyListeners();
  }

  /// 按风格筛选历史记录
  List<ImageTask> getHistoryByStyle(ImageStyle style) {
    return _history.where((t) => t.style == style).toList();
  }

  /// 搜索历史记录
  List<ImageTask> searchHistory(String keyword) {
    if (keyword.isEmpty) return List.unmodifiable(_history);
    final lower = keyword.toLowerCase();
    return _history
        .where((t) => t.prompt.toLowerCase().contains(lower))
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

  /// 设置当前查看的任务
  void setCurrentTask(ImageTask? task) {
    _currentTask = task;
    notifyListeners();
  }

  /// 刷新历史记录
  Future<void> refreshHistory() async {
    await _loadHistory();
  }

  /// 获取风格预设
  List<ImageStylePreset> getStylePresets() {
    return _imageGenService.getStylePresets();
  }

  /// 获取尺寸预设
  List<ImageSizePreset> getSizePresets() {
    return _imageGenService.getSizePresets();
  }
}
