import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// ============================================================================
/// BackgroundTaskService —— 后台任务管理服务
///
/// 职责：
///   1. 任务队列：FIFO + 优先级排序的任务调度
///   2. 任务优先级：high/normal/low 三级，高优先级优先执行
///   3. 并发控制：同时运行的任务数上限，避免资源争抢
///   4. 任务持久化：未完成任务写入磁盘，应用重启后恢复
///   5. 进度回调：任务执行进度实时通知
///   6. 取消任务：支持取消等待中或执行中的任务
/// ============================================================================

/// 任务优先级
enum TaskPriority { high, normal, low }

/// 任务状态
enum TaskState { pending, running, completed, failed, cancelled }

/// 后台任务定义
class BackgroundTask {
  final String id;
  final String name;
  final TaskPriority priority;
  final Map<String, dynamic> params;
  final DateTime createdAt;
  TaskState state;
  double progress;
  String? result;
  String? error;
  DateTime? startedAt;
  DateTime? completedAt;
  int retryCount;

  BackgroundTask({
    required this.id,
    required this.name,
    required this.priority,
    required this.params,
    required this.createdAt,
    this.state = TaskState.pending,
    this.progress = 0.0,
    this.result,
    this.error,
    this.startedAt,
    this.completedAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'priority': priority.name,
        'params': params,
        'created_at': createdAt.toIso8601String(),
        'state': state.name,
        'progress': progress,
        'result': result,
        'error': error,
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'retry_count': retryCount,
      };

  factory BackgroundTask.fromJson(Map<String, dynamic> json) =>
      BackgroundTask(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        priority: TaskPriority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => TaskPriority.normal,
        ),
        params: Map<String, dynamic>.from(json['params'] ?? {}),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        state: TaskState.values.firstWhere(
          (e) => e.name == json['state'],
          orElse: () => TaskState.pending,
        ),
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        result: json['result']?.toString(),
        error: json['error']?.toString(),
        startedAt: json['started_at'] != null
            ? DateTime.tryParse(json['started_at'].toString())
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'].toString())
            : null,
        retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      );
}

/// 任务执行器函数类型
typedef TaskExecutor = Future<Map<String, dynamic>> Function(
  BackgroundTask task,
  void Function(double progress) onProgress,
);

class BackgroundTaskService {
  /// 单例实例
  static final BackgroundTaskService _instance =
      BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  // ===== 配置 =====
  /// 最大并发任务数
  static const int _maxConcurrent = 3;

  /// 最大重试次数
  static const int _maxRetries = 3;

  /// 持久化文件名
  static const String _persistFileName = 'background_tasks.json';

  // ===== 状态 =====
  final List<BackgroundTask> _pendingQueue = [];
  final Map<String, BackgroundTask> _runningTasks = {};
  final Map<String, BackgroundTask> _completedTasks = {};
  final Map<String, TaskExecutor> _executors = {};
  final StreamController<BackgroundTask> _taskController =
      StreamController<BackgroundTask>.broadcast();
  bool _initialized = false;
  bool _isProcessing = false;

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化后台任务服务
  Future<void> init() async {
    if (_initialized) return;
    await _restorePersistedTasks();
    _initialized = true;
    _processQueue();
  }

  /// 注册任务执行器
  void registerExecutor(String taskType, TaskExecutor executor) {
    _executors[taskType] = executor;
  }

  // ==========================================================================
  // 任务提交
  // ==========================================================================

  /// 提交一个后台任务
  Future<String> submitTask({
    required String name,
    required String taskType,
    Map<String, dynamic> params = const {},
    TaskPriority priority = TaskPriority.normal,
  }) async {
    final id = _generateTaskId();
    final task = BackgroundTask(
      id: id,
      name: name,
      priority: priority,
      params: {...params, 'task_type': taskType},
      createdAt: DateTime.now(),
    );

    _pendingQueue.add(task);
    _sortQueue();
    await _persistTasks();
    _processQueue();
    return id;
  }

  /// 按优先级排序队列（高优先级在前，同优先级按创建时间）
  void _sortQueue() {
    _pendingQueue.sort((a, b) {
      final priorityCompare = a.priority.index.compareTo(b.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  // ==========================================================================
  // 任务调度与执行
  // ==========================================================================

  /// 处理任务队列
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (_pendingQueue.isNotEmpty &&
          _runningTasks.length < _maxConcurrent) {
        final task = _pendingQueue.removeAt(0);
        await _executeTask(task);
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// 执行单个任务
  Future<void> _executeTask(BackgroundTask task) async {
    final taskType = task.params['task_type']?.toString() ?? 'default';
    final executor = _executors[taskType];

    task.state = TaskState.running;
    task.startedAt = DateTime.now();
    _runningTasks[task.id] = task;
    _taskController.add(task);
    await _persistTasks();

    try {
      if (executor != null) {
        final result = await executor(task, (progress) {
          task.progress = progress.clamp(0.0, 1.0);
          _taskController.add(task);
        });
        task.result = jsonEncode(result);
        task.progress = 1.0;
        task.state = TaskState.completed;
      } else {
        // 无注册执行器时，执行默认模拟任务
        await _defaultExecute(task);
        task.state = TaskState.completed;
      }
    } catch (e) {
      task.error = e.toString();
      if (task.retryCount < _maxRetries) {
        task.retryCount++;
        task.state = TaskState.pending;
        task.progress = 0.0;
        _pendingQueue.add(task);
        _sortQueue();
      } else {
        task.state = TaskState.failed;
      }
    } finally {
      task.completedAt = DateTime.now();
      _runningTasks.remove(task.id);
      if (task.state == TaskState.completed ||
          task.state == TaskState.failed) {
        _completedTasks[task.id] = task;
      }
      _taskController.add(task);
      await _persistTasks();
      _processQueue();
    }
  }

  /// 默认任务执行（模拟进度）
  Future<void> _defaultExecute(BackgroundTask task) async {
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      task.progress = i / 10;
      _taskController.add(task);
    }
    task.result = jsonEncode({'status': 'done', 'task': task.name});
  }

  // ==========================================================================
  // 任务查询与控制
  // ==========================================================================

  /// 获取任务状态
  BackgroundTask? getTask(String taskId) {
    return _runningTasks[taskId] ??
        _completedTasks[taskId] ??
        _pendingQueue.firstWhere((t) => t.id == taskId,
            orElse: () => _emptyTask());
  }

  BackgroundTask _emptyTask() => BackgroundTask(
        id: '',
        name: '',
        priority: TaskPriority.normal,
        params: {},
        createdAt: DateTime.now(),
      );

  /// 取消任务
  Future<bool> cancelTask(String taskId) async {
    // 从等待队列移除
    final pendingIndex =
        _pendingQueue.indexWhere((t) => t.id == taskId);
    if (pendingIndex >= 0) {
      final task = _pendingQueue.removeAt(pendingIndex);
      task.state = TaskState.cancelled;
      task.completedAt = DateTime.now();
      _completedTasks[taskId] = task;
      _taskController.add(task);
      await _persistTasks();
      return true;
    }

    // 运行中的任务标记取消（执行器需自行检查）
    final running = _runningTasks[taskId];
    if (running != null) {
      running.params['__cancelled'] = true;
      return true;
    }

    return false;
  }

  /// 获取等待队列长度
  int get pendingCount => _pendingQueue.length;

  /// 获取运行中任务数
  int get runningCount => _runningTasks.length;

  /// 任务状态变化流
  Stream<BackgroundTask> get taskStream => _taskController.stream;

  /// 获取所有运行中的任务
  List<BackgroundTask> get runningTasks =>
      List.unmodifiable(_runningTasks.values);

  /// 获取最近完成的任务
  List<BackgroundTask> getRecentCompleted({int limit = 20}) {
    final list = _completedTasks.values.toList()
      ..sort((a, b) =>
          (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
    return list.take(limit).toList();
  }

  // ==========================================================================
  // 持久化
  // ==========================================================================

  Future<Directory> _getDocDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final taskDir = Directory('${dir.path}/background_tasks');
    if (!taskDir.existsSync()) {
      taskDir.createSync(recursive: true);
    }
    return taskDir;
  }

  Future<void> _persistTasks() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_persistFileName');
      final allTasks = [
        ..._pendingQueue,
        ..._runningTasks.values,
      ];
      await file.writeAsString(
          jsonEncode(allTasks.map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _restorePersistedTasks() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_persistFileName');
      if (!file.existsSync()) return;
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      for (final item in list) {
        final task = BackgroundTask.fromJson(
            Map<String, dynamic>.from(item as Map));
        // 恢复时运行中的任务重置为等待
        if (task.state == TaskState.running) {
          task.state = TaskState.pending;
          task.progress = 0.0;
        }
        if (task.state == TaskState.pending) {
          _pendingQueue.add(task);
        }
      }
      _sortQueue();
    } catch (_) {}
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  String _generateTaskId() {
    return 'task_${DateTime.now().microsecondsSinceEpoch}_'
        '${_pendingQueue.length + _runningTasks.length}';
  }

  /// 清理已完成的任务记录
  Future<int> cleanupCompleted({Duration olderThan = const Duration(days: 7)}) async {
    final cutoff = DateTime.now().subtract(olderThan);
    final toRemove = <String>[];
    _completedTasks.forEach((id, task) {
      if ((task.completedAt ?? task.createdAt).isBefore(cutoff)) {
        toRemove.add(id);
      }
    });
    for (final id in toRemove) {
      _completedTasks.remove(id);
    }
    await _persistTasks();
    return toRemove.length;
  }

  /// 销毁服务
  void dispose() {
    _taskController.close();
  }
}
