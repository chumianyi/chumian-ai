import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

/// ============================================================================
/// CacheService —— 缓存服务
///
/// 职责：
///   1. LRU 内存缓存：固定容量，最近最少使用淘汰
///   2. 磁盘缓存：基于 path_provider 的文件级持久化缓存
///   3. 图片缓存管理：缓存大小计算与清理
///   4. TTL（生存时间）：自动过期失效
///   5. 缓存清除策略：按容量、按时间、全部清除
/// ============================================================================
class CacheService {
  /// 单例实例
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // ===== 配置 =====
  /// 内存缓存最大条目数
  static const int _maxMemoryEntries = 200;

  /// 磁盘缓存最大字节数（默认 100MB）
  static const int _maxDiskBytes = 100 * 1024 * 1024;

  /// 默认 TTL（毫秒，1 小时）
  static const int _defaultTtlMs = 60 * 60 * 1000;

  /// 磁盘缓存子目录名
  static const String _cacheDirName = 'chumian_cache';

  // ===== 内存缓存 =====
  final Map<String, _CacheEntry> _memoryCache = {};

  /// 磁盘缓存目录
  Directory? _cacheDir;

  /// 是否已初始化
  bool _initialized = false;

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化缓存服务
  Future<void> init() async {
    if (_initialized) return;
    try {
      final baseDir = await getTemporaryDirectory();
      _cacheDir = Directory('${baseDir.path}/$_cacheDirName');
      if (!_cacheDir!.existsSync()) {
        _cacheDir!.createSync(recursive: true);
      }
    } catch (_) {
      _cacheDir = null;
    }
    _initialized = true;
  }

  /// 确保已初始化
  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }

  // ==========================================================================
  // 内存缓存（LRU）
  // ==========================================================================

  /// 写入内存缓存
  ///
  /// [key] 缓存键，[value] 缓存值，[ttlMs] 生存时间（毫秒）
  void setMemory(String key, dynamic value, {int? ttlMs}) {
    // 达到容量上限时淘汰最旧的条目
    if (_memoryCache.length >= _maxMemoryEntries &&
        !_memoryCache.containsKey(key)) {
      _evictOldest();
    }
    _memoryCache[key] = _CacheEntry(
      value: value,
      createdAt: DateTime.now(),
      ttlMs: ttlMs ?? _defaultTtlMs,
      lastAccess: DateTime.now(),
    );
  }

  /// 读取内存缓存
  ///
  /// 返回 null 表示不存在或已过期
  T? getMemory<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return null;

    // 检查是否过期
    if (entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }

    // 更新最近访问时间
    entry.lastAccess = DateTime.now();
    return entry.value as T?;
  }

  /// 判断内存缓存是否存在且有效
  bool hasMemory(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _memoryCache.remove(key);
      return false;
    }
    return true;
  }

  /// 删除内存缓存
  bool removeMemory(String key) {
    return _memoryCache.remove(key) != null;
  }

  /// 清除所有内存缓存
  void clearMemory() {
    _memoryCache.clear();
  }

  /// 淘汰最旧（最少使用）的条目
  void _evictOldest() {
    if (_memoryCache.isEmpty) return;
    String? oldestKey;
    DateTime? oldestTime;
    _memoryCache.forEach((key, entry) {
      if (oldestTime == null || entry.lastAccess.isBefore(oldestTime!)) {
        oldestTime = entry.lastAccess;
        oldestKey = key;
      }
    });
    if (oldestKey != null) {
      _memoryCache.remove(oldestKey);
    }
  }

  /// 清理过期的内存缓存
  void cleanupExpiredMemory() {
    final expiredKeys = <String>[];
    _memoryCache.forEach((key, entry) {
      if (entry.isExpired) expiredKeys.add(key);
    });
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }
  }

  /// 内存缓存条目数
  int get memoryCount => _memoryCache.length;

  // ==========================================================================
  // 磁盘缓存
  // ==========================================================================

  /// 写入磁盘缓存
  Future<bool> setDisk(String key, String data, {int? ttlMs}) async {
    await _ensureInit();
    if (_cacheDir == null) return false;

    try {
      final fileName = _hashKey(key);
      final file = File('${_cacheDir!.path}/$fileName');
      final entry = _DiskCacheEntry(
        key: key,
        data: data,
        createdAt: DateTime.now(),
        ttlMs: ttlMs ?? _defaultTtlMs,
      );
      await file.writeAsString(jsonEncode(entry.toJson()));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 写入磁盘缓存（JSON 对象）
  Future<bool> setDiskJson(String key, Map<String, dynamic> data,
      {int? ttlMs}) async {
    return setDisk(key, jsonEncode(data), ttlMs: ttlMs);
  }

  /// 读取磁盘缓存
  Future<String?> getDisk(String key) async {
    await _ensureInit();
    if (_cacheDir == null) return null;

    try {
      final fileName = _hashKey(key);
      final file = File('${_cacheDir!.path}/$fileName');
      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      final entry = _DiskCacheEntry.fromJson(
          Map<String, dynamic>.from(jsonDecode(content) as Map));

      // 检查过期
      if (entry.isExpired) {
        await file.delete();
        return null;
      }

      return entry.data;
    } catch (_) {
      return null;
    }
  }

  /// 读取磁盘缓存（JSON 对象）
  Future<Map<String, dynamic>?> getDiskJson(String key) async {
    final raw = await getDisk(key);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  /// 删除磁盘缓存
  Future<bool> removeDisk(String key) async {
    await _ensureInit();
    if (_cacheDir == null) return false;
    try {
      final fileName = _hashKey(key);
      final file = File('${_cacheDir!.path}/$fileName');
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================================
  // 缓存大小计算与清理
  // ==========================================================================

  /// 获取磁盘缓存大小（字节）
  Future<int> getDiskCacheSize() async {
    await _ensureInit();
    if (_cacheDir == null) return 0;

    try {
      int total = 0;
      if (_cacheDir!.existsSync()) {
        await for (final entity in _cacheDir!.list()) {
          if (entity is File) {
            total += await entity.length();
          }
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// 获取磁盘缓存大小的可读文本
  Future<String> getDiskCacheSizeText() async {
    final bytes = await getDiskCacheSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 清除所有磁盘缓存
  Future<int> clearDisk() async {
    await _ensureInit();
    if (_cacheDir == null) return 0;

    try {
      int count = 0;
      if (_cacheDir!.existsSync()) {
        await for (final entity in _cacheDir!.list()) {
          await entity.delete(recursive: true);
          count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// 清理过期的磁盘缓存
  Future<int> cleanupExpiredDisk() async {
    await _ensureInit();
    if (_cacheDir == null) return 0;

    try {
      int count = 0;
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          try {
            final content = await entity.readAsString();
            final entry = _DiskCacheEntry.fromJson(
                Map<String, dynamic>.from(jsonDecode(content) as Map));
            if (entry.isExpired) {
              await entity.delete();
              count++;
            }
          } catch (_) {
            // 损坏的缓存文件直接删除
            await entity.delete();
            count++;
          }
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// 如果磁盘缓存超过上限，按时间清理最旧的缓存
  Future<int> enforceDiskLimit() async {
    final size = await getDiskCacheSize();
    if (size <= _maxDiskBytes) return 0;

    await _ensureInit();
    if (_cacheDir == null) return 0;

    // 收集所有缓存文件及其创建时间
    final files = <_FileWithTime>[];
    await for (final entity in _cacheDir!.list()) {
      if (entity is File) {
        try {
          final stat = await entity.stat();
          files.add(_FileWithTime(file: entity, modified: stat.modified));
        } catch (_) {}
      }
    }

    // 按修改时间排序（最旧的在前）
    files.sort((a, b) => a.modified.compareTo(b.modified));

    int removed = 0;
    int currentSize = size;
    for (final f in files) {
      if (currentSize <= _maxDiskBytes * 0.8) break;
      try {
        final fileSize = await f.file.length();
        await f.file.delete();
        currentSize -= fileSize;
        removed++;
      } catch (_) {}
    }
    return removed;
  }

  /// 清除所有缓存（内存 + 磁盘）
  Future<void> clearAll() async {
    clearMemory();
    await clearDisk();
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  /// 将缓存键哈希为文件名
  String _hashKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

/// 内存缓存条目
class _CacheEntry {
  final dynamic value;
  final DateTime createdAt;
  final int ttlMs;
  DateTime lastAccess;

  _CacheEntry({
    required this.value,
    required this.createdAt,
    required this.ttlMs,
    required this.lastAccess,
  });

  /// 是否已过期
  bool get isExpired {
    final age = DateTime.now().difference(createdAt).inMilliseconds;
    return age > ttlMs;
  }
}

/// 磁盘缓存条目
class _DiskCacheEntry {
  final String key;
  final String data;
  final DateTime createdAt;
  final int ttlMs;

  _DiskCacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.ttlMs,
  });

  bool get isExpired {
    final age = DateTime.now().difference(createdAt).inMilliseconds;
    return age > ttlMs;
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'ttl_ms': ttlMs,
    };
  }

  factory _DiskCacheEntry.fromJson(Map<String, dynamic> json) {
    return _DiskCacheEntry(
      key: json['key']?.toString() ?? '',
      data: json['data']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      ttlMs: (json['ttl_ms'] as num?)?.toInt() ?? 3600000,
    );
  }
}

/// 带时间的文件引用
class _FileWithTime {
  final File file;
  final DateTime modified;

  _FileWithTime({required this.file, required this.modified});
}
