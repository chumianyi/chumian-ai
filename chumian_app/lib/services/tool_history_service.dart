import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chumian_ai/models/tool_history.dart';

/// ============================================================================
/// ToolHistoryService —— 工具使用历史记录服务
///
/// 基于 SharedPreferences 提供 AI 工具调用历史的完整 CRUD 能力，
/// 支持按工具类型筛选、全文搜索、批量清除与使用统计。
/// ============================================================================
class ToolHistoryService {
  // ===== 存储键 =====
  static const String _prefixHistory = 'tool_history_';
  static const String _keyIdList = 'tool_history_id_list';
  static const String _keyUsageStats = 'tool_usage_stats';

  /// 单例实例
  static final ToolHistoryService _instance =
      ToolHistoryService._internal();
  factory ToolHistoryService() => _instance;
  ToolHistoryService._internal();

  SharedPreferences? _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _ensurePrefs async {
    if (_prefs == null) await init();
    return _prefs!;
  }

  // ==========================================================================
  // ID 列表维护（用于保持顺序）
  // ==========================================================================

  Future<List<String>> _getIdList() async {
    final prefs = await _ensurePrefs;
    final raw = prefs.getString(_keyIdList);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _setIdList(List<String> ids) async {
    final prefs = await _ensurePrefs;
    await prefs.setString(_keyIdList, jsonEncode(ids));
  }

  // ==========================================================================
  // CRUD
  // ==========================================================================

  /// 添加一条工具使用记录
  Future<ToolHistory> addRecord({
    required ToolType toolType,
    required String input,
    required String output,
    Map<String, dynamic>? params,
    int durationMs = 0,
    bool isSuccess = true,
  }) async {
    final record = ToolHistory.create(
      toolType: toolType,
      input: input,
      output: output,
      params: params,
      durationMs: durationMs,
      isSuccess: isSuccess,
    );

    final prefs = await _ensurePrefs;
    await prefs.setString(
      '$_prefixHistory${record.id}',
      jsonEncode(record.toJson()),
    );

    // 更新 ID 列表（插入到最前面）
    final ids = await _getIdList();
    ids.insert(0, record.id);
    // 最多保留 500 条
    if (ids.length > 500) {
      final removed = ids.sublist(500);
      for (final id in removed) {
        await prefs.remove('$_prefixHistory$id');
      }
      ids.removeRange(500, ids.length);
    }
    await _setIdList(ids);

    // 更新使用统计
    await _incrementUsage(toolType);

    return record;
  }

  /// 获取单条记录
  Future<ToolHistory?> getRecord(String id) async {
    final prefs = await _ensurePrefs;
    final raw = prefs.getString('$_prefixHistory$id');
    if (raw == null || raw.isEmpty) return null;
    try {
      return ToolHistory.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  /// 获取所有记录（按时间倒序）
  Future<List<ToolHistory>> getAllRecords({int limit = 100}) async {
    final ids = await _getIdList();
    final records = <ToolHistory>[];
    for (final id in ids) {
      final record = await getRecord(id);
      if (record != null) {
        records.add(record);
        if (records.length >= limit) break;
      }
    }
    return records;
  }

  /// 按工具类型筛选
  Future<List<ToolHistory>> getRecordsByType(ToolType toolType,
      {int limit = 50}) async {
    final ids = await _getIdList();
    final records = <ToolHistory>[];
    for (final id in ids) {
      final record = await getRecord(id);
      if (record != null && record.toolType == toolType) {
        records.add(record);
        if (records.length >= limit) break;
      }
    }
    return records;
  }

  /// 全文搜索
  Future<List<ToolHistory>> searchRecords(String keyword,
      {ToolType? toolType, int limit = 50}) async {
    if (keyword.isEmpty) {
      return toolType != null
          ? getRecordsByType(toolType, limit: limit)
          : getAllRecords(limit: limit);
    }
    final ids = await _getIdList();
    final records = <ToolHistory>[];
    for (final id in ids) {
      final record = await getRecord(id);
      if (record != null &&
          (toolType == null || record.toolType == toolType) &&
          record.matches(keyword)) {
        records.add(record);
        if (records.length >= limit) break;
      }
    }
    return records;
  }

  /// 更新一条记录
  Future<bool> updateRecord(ToolHistory record) async {
    final prefs = await _ensurePrefs;
    final key = '$_prefixHistory${record.id}';
    if (!prefs.containsKey(key)) return false;
    await prefs.setString(key, jsonEncode(record.toJson()));
    return true;
  }

  /// 删除单条记录
  Future<bool> deleteRecord(String id) async {
    final prefs = await _ensurePrefs;
    final key = '$_prefixHistory$id';
    if (!prefs.containsKey(key)) return false;
    await prefs.remove(key);
    // 从 ID 列表移除
    final ids = await _getIdList();
    ids.remove(id);
    await _setIdList(ids);
    return true;
  }

  /// 批量删除
  Future<int> deleteRecords(List<String> ids) async {
    int count = 0;
    for (final id in ids) {
      if (await deleteRecord(id)) count++;
    }
    return count;
  }

  /// 按工具类型清除
  Future<int> clearByType(ToolType toolType) async {
    final ids = await _getIdList();
    final toRemove = <String>[];
    for (final id in ids) {
      final record = await getRecord(id);
      if (record != null && record.toolType == toolType) {
        toRemove.add(id);
      }
    }
    return deleteRecords(toRemove);
  }

  /// 清除所有记录
  Future<int> clearAll() async {
    final prefs = await _ensurePrefs;
    final ids = await _getIdList();
    int count = 0;
    for (final id in ids) {
      await prefs.remove('$_prefixHistory$id');
      count++;
    }
    await _setIdList([]);
    return count;
  }

  // ==========================================================================
  // 使用统计
  // ==========================================================================

  Future<Map<String, int>> _getUsageStats() async {
    final prefs = await _ensurePrefs;
    final raw = prefs.getString(_keyUsageStats);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return map.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _incrementUsage(ToolType toolType) async {
    final prefs = await _ensurePrefs;
    final stats = await _getUsageStats();
    stats[toolType.value] = (stats[toolType.value] ?? 0) + 1;
    await prefs.setString(_keyUsageStats, jsonEncode(stats));
  }

  /// 获取某工具的使用次数
  Future<int> getUsageCount(ToolType toolType) async {
    final stats = await _getUsageStats();
    return stats[toolType.value] ?? 0;
  }

  /// 获取所有工具的使用统计
  Future<Map<ToolType, int>> getAllUsageStats() async {
    final stats = await _getUsageStats();
    final result = <ToolType, int>{};
    stats.forEach((key, value) {
      result[ToolTypeExtension.fromString(key)] = value;
    });
    return result;
  }

  /// 获取总记录数
  Future<int> getTotalCount() async {
    final ids = await _getIdList();
    return ids.length;
  }

  /// 获取最近使用的工具类型（按使用次数排序）
  Future<List<ToolType>> getRecentToolTypes({int limit = 5}) async {
    final stats = await getAllUsageStats();
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }
}
