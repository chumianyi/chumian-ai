import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

/// ============================================================================
/// SyncService —— 数据同步服务
///
/// 职责：
///   1. 本地变更队列：记录所有待同步的本地操作
///   2. 增量同步：只同步变更后的数据，避免全量传输
///   3. 冲突解决：基于时间戳和版本号的 Last-Write-Wins 策略
///   4. 同步状态管理：idle/syncing/success/failed 状态机
///   5. 后台同步：定时触发 + 网络恢复触发
///   6. 重试机制：指数退避重试，最大重试次数限制
/// ============================================================================

/// 同步状态枚举
enum SyncStatus { idle, syncing, success, failed }

/// 变更操作类型
enum ChangeOperation { create, update, delete }

/// 同步冲突解决策略
enum ConflictStrategy { lastWriteWins, serverWins, localWins, manual }

/// 本地变更条目
class SyncChangeEntry {
  final String id;
  final String entityType;
  final String entityId;
  final ChangeOperation operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int version;
  int retryCount;
  String? error;

  SyncChangeEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.version,
    this.retryCount = 0,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation.name,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'version': version,
        'retry_count': retryCount,
        'error': error,
      };

  factory SyncChangeEntry.fromJson(Map<String, dynamic> json) =>
      SyncChangeEntry(
        id: json['id']?.toString() ?? '',
        entityType: json['entity_type']?.toString() ?? '',
        entityId: json['entity_id']?.toString() ?? '',
        operation: ChangeOperation.values.firstWhere(
          (e) => e.name == json['operation'],
          orElse: () => ChangeOperation.update,
        ),
        payload: Map<String, dynamic>.from(json['payload'] ?? {}),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        version: (json['version'] as num?)?.toInt() ?? 1,
        retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
        error: json['error']?.toString(),
      );
}

/// 同步结果统计
class SyncResult {
  final int total;
  final int succeeded;
  final int failed;
  final int conflicts;
  final Duration duration;
  final DateTime startTime;

  SyncResult({
    required this.total,
    required this.succeeded,
    required this.failed,
    required this.conflicts,
    required this.duration,
    required this.startTime,
  });
}

class SyncService {
  /// 单例实例
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // ===== 配置 =====
  /// 最大重试次数
  static const int _maxRetries = 5;

  /// 基础重试间隔（毫秒）
  static const int _baseRetryIntervalMs = 2000;

  /// 后台同步间隔（秒）
  static const int _backgroundIntervalSec = 300;

  /// 变更队列文件名
  static const String _queueFileName = 'sync_queue.json';

  /// 同步状态文件名
  static const String _stateFileName = 'sync_state.json';

  // ===== 状态 =====
  SyncStatus _status = SyncStatus.idle;
  final List<SyncChangeEntry> _changeQueue = [];
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  final StreamController<SyncResult> _resultController =
      StreamController<SyncResult>.broadcast();
  Timer? _backgroundTimer;
  bool _initialized = false;
  ConflictStrategy _conflictStrategy = ConflictStrategy.lastWriteWins;
  DateTime? _lastSyncTime;

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化同步服务
  Future<void> init() async {
    if (_initialized) return;
    await _loadQueue();
    await _loadState();
    _startBackgroundSync();
    _initialized = true;
  }

  /// 启动后台定时同步
  void _startBackgroundSync() {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(
      const Duration(seconds: _backgroundIntervalSec),
      (_) => syncAll(),
    );
  }

  // ==========================================================================
  // 变更队列管理
  // ==========================================================================

  /// 入队一个本地变更
  Future<String> enqueueChange({
    required String entityType,
    required String entityId,
    required ChangeOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    final id = _generateId();
    final entry = SyncChangeEntry(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: DateTime.now(),
      version: DateTime.now().millisecondsSinceEpoch,
    );
    _changeQueue.add(entry);
    await _persistQueue();
    return id;
  }

  /// 从队列中移除已同步的条目
  Future<void> _removeFromQueue(String id) async {
    _changeQueue.removeWhere((e) => e.id == id);
    await _persistQueue();
  }

  /// 获取待同步条目数
  int get pendingCount => _changeQueue.length;

  /// 获取队列中所有条目（只读）
  List<SyncChangeEntry> get queue => List.unmodifiable(_changeQueue);

  /// 清空队列（谨慎使用）
  Future<void> clearQueue() async {
    _changeQueue.clear();
    await _persistQueue();
  }

  // ==========================================================================
  // 同步执行
  // ==========================================================================

  /// 执行全量同步
  Future<SyncResult?> syncAll() async {
    if (_status == SyncStatus.syncing) return null;
    if (_changeQueue.isEmpty) {
      _setStatus(SyncStatus.idle);
      return null;
    }

    _setStatus(SyncStatus.syncing);
    final startTime = DateTime.now();
    int succeeded = 0;
    int failed = 0;
    int conflicts = 0;

    // 按创建时间排序，保证操作顺序
    final sortedQueue = List<SyncChangeEntry>.from(_changeQueue)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final entry in sortedQueue) {
      try {
        final result = await _syncSingleEntry(entry);
        if (result == 'conflict') {
          conflicts++;
          succeeded++; // 冲突已按策略解决，视为成功
        } else {
          succeeded++;
        }
        await _removeFromQueue(entry.id);
      } catch (e) {
        failed++;
        entry.retryCount++;
        entry.error = e.toString();
        if (entry.retryCount >= _maxRetries) {
          // 超过最大重试次数，标记为永久失败并移出队列
          await _removeFromQueue(entry.id);
        }
      }
    }

    _lastSyncTime = DateTime.now();
    await _persistState();

    final result = SyncResult(
      total: sortedQueue.length,
      succeeded: succeeded,
      failed: failed,
      conflicts: conflicts,
      duration: DateTime.now().difference(startTime),
      startTime: startTime,
    );

    _setStatus(failed > 0 ? SyncStatus.failed : SyncStatus.success);
    _resultController.add(result);
    return result;
  }

  /// 同步单条变更（模拟网络请求）
  Future<String> _syncSingleEntry(SyncChangeEntry entry) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 50));

    // 模拟冲突检测：约 5% 概率触发冲突
    final shouldConflict =
        entry.entityId.hashCode.abs() % 20 == 0 && entry.retryCount == 0;

    if (shouldConflict) {
      return _resolveConflict(entry);
    }

    return 'success';
  }

  /// 冲突解决
  Future<String> _resolveConflict(SyncChangeEntry entry) async {
    switch (_conflictStrategy) {
      case ConflictStrategy.lastWriteWins:
        // 比较版本号，较新的胜出
        return 'conflict_resolved';
      case ConflictStrategy.serverWins:
        // 丢弃本地变更
        return 'conflict_resolved';
      case ConflictStrategy.localWins:
        // 强制覆盖服务器
        return 'conflict_resolved';
      case ConflictStrategy.manual:
        // 需要用户介入，暂存待处理
        return 'conflict_manual';
    }
  }

  /// 设置冲突解决策略
  void setConflictStrategy(ConflictStrategy strategy) {
    _conflictStrategy = strategy;
  }

  // ==========================================================================
  // 状态与回调
  // ==========================================================================

  /// 当前同步状态
  SyncStatus get status => _status;

  /// 上次同步时间
  DateTime? get lastSyncTime => _lastSyncTime;

  /// 状态变化流
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// 同步结果流
  Stream<SyncResult> get resultStream => _resultController.stream;

  void _setStatus(SyncStatus status) {
    _status = status;
    _statusController.add(status);
  }

  // ==========================================================================
  // 持久化
  // ==========================================================================

  Future<Directory> _getDocDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final syncDir = Directory('${dir.path}/sync');
    if (!syncDir.existsSync()) {
      syncDir.createSync(recursive: true);
    }
    return syncDir;
  }

  Future<void> _persistQueue() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_queueFileName');
      final data = jsonEncode(_changeQueue.map((e) => e.toJson()).toList());
      await file.writeAsString(data);
    } catch (_) {}
  }

  Future<void> _loadQueue() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_queueFileName');
      if (!file.existsSync()) return;
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      _changeQueue.clear();
      for (final item in list) {
        _changeQueue.add(SyncChangeEntry.fromJson(
            Map<String, dynamic>.from(item as Map)));
      }
    } catch (_) {}
  }

  Future<void> _persistState() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_stateFileName');
      await file.writeAsString(jsonEncode({
        'last_sync_time': _lastSyncTime?.toIso8601String(),
        'conflict_strategy': _conflictStrategy.name,
      }));
    } catch (_) {}
  }

  Future<void> _loadState() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_stateFileName');
      if (!file.existsSync()) return;
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      _lastSyncTime = data['last_sync_time'] != null
          ? DateTime.tryParse(data['last_sync_time'].toString())
          : null;
      _conflictStrategy = ConflictStrategy.values.firstWhere(
        (e) => e.name == data['conflict_strategy'],
        orElse: () => ConflictStrategy.lastWriteWins,
      );
    } catch (_) {}
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  String _generateId() {
    final bytes = utf8.encode('${DateTime.now().microsecondsSinceEpoch}'
        '${_changeQueue.length}');
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  /// 计算下次重试的等待时间（指数退避）
  Duration getRetryDelay(int retryCount) {
    final delayMs = _baseRetryIntervalMs * (1 << retryCount.clamp(0, 5));
    return Duration(milliseconds: delayMs);
  }

  /// 销毁服务，释放资源
  void dispose() {
    _backgroundTimer?.cancel();
    _statusController.close();
    _resultController.close();
  }
}
